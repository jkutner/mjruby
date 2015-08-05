/*
** java_support.c - File class
*/

#include "mruby.h"
#include "mruby/class.h"
#include "mruby/data.h"
#include "mruby/string.h"
#include "mruby/ext/io.h"


#include <dlfcn.h>

#if defined(_WIN32) || defined(_WIN64)
  #include <Windows.h>
#endif

#include <jni.h>

typedef jint (JNICALL CreateJavaVM_t)(JavaVM **pvm, void **env, void *args);

static char*
str_with_dir(char *java_home, char *path)
{
  char *full_path = malloc(strlen(java_home)+strlen(path));
  strcpy(full_path, java_home);
  strcat(full_path, path);
  return full_path;
}

static mrb_value
mrb_java_support_exec(mrb_state *mrb, mrb_value obj)
{
  mrb_value *argv;
  mrb_int argc;

  fflush(stdout);
  fflush(stderr);

  mrb_get_args(mrb, "*", &argv, &argc);
  if (argc < 3) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "wrong number of arguments");
  }

  const char *java_home = mrb_string_value_cstr(mrb, &argv[0]);
  const char *java_main_class = mrb_string_value_cstr(mrb, &argv[1]);
  const int java_opts_count = mrb_fixnum(argv[2]);
  const int ruby_opts_start = 3 + java_opts_count;
  const int ruby_opts_count = argc - ruby_opts_start;

  JavaVM *jvm;
  JNIEnv *env;
  JavaVMInitArgs jvmArgs;
  JavaVMOption jvmOptions[java_opts_count];

  for (int i = 0; i < java_opts_count; i++) {
    jvmOptions[i].extraInfo = 0;
    jvmOptions[i].optionString = mrb_string_value_cstr(mrb, &argv[i+3]);
    if (strcmp("-client", jvmOptions[i].optionString) == 0) {
      mrb_raise(mrb, E_ARGUMENT_ERROR, "-client is not a valid option");
    } else if (strcmp("-server", jvmOptions[i].optionString) == 0) {
      mrb_raise(mrb, E_ARGUMENT_ERROR, "-server is not a valid option");
    }
  }

  jvmArgs.options = jvmOptions;
  jvmArgs.nOptions = java_opts_count;
  jvmArgs.version = JNI_VERSION_1_4;
  jvmArgs.ignoreUnrecognized = JNI_FALSE;

  CreateJavaVM_t* createJavaVM = NULL;

  // jli needs to be loaded on OSX because otherwise the OS tries to run the system Java
  void *libjli = dlopen(str_with_dir(java_home, "/jre/lib/jli/libjli.dylib"), RTLD_NOW + RTLD_GLOBAL);
  void *libjvm = dlopen(str_with_dir(java_home, "/jre/lib/server/libjvm.dylib"), RTLD_NOW + RTLD_GLOBAL);

  createJavaVM = (CreateJavaVM_t*) dlsym(libjvm, "JNI_CreateJavaVM");
  if (createJavaVM == NULL) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not load JVM");
  }

  if (createJavaVM(&jvm, (void**)&env, &jvmArgs) < 0) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "JVM creation failed");
  }

  jclass mainClass = (*env)->FindClass(env, java_main_class);
  if (!mainClass) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, java_main_class);
  }

  jmethodID mainMethod = (*env)->GetStaticMethodID(env, mainClass, "main", "([Ljava/lang/String;)V");
  if (!mainMethod) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "Cannot get main method.");
  }

  jclass jclassString = (*env)->FindClass(env, "java/lang/String");
  jstring jstringArg = (*env)->NewStringUTF(env, "");

  jobjectArray mainArgs = (*env)->NewObjectArray(env, ruby_opts_count, jclassString, jstringArg);

  for (int i = 0; i < ruby_opts_count; i++) {
    jstring jstringArg = (*env)->NewStringUTF(env, mrb_string_value_cstr(mrb, &argv[i+ruby_opts_start]));
    if (!jstringArg) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "NewStringUTF() failed");
    }
    (*env)->SetObjectArrayElement(env, mainArgs, i, jstringArg);
  }

  (*env)->CallStaticVoidMethod(env, mainClass, mainMethod, mainArgs);

  if (env && (*env)->ExceptionOccurred(env)) {
    (*env)->ExceptionDescribe(env);
  }
  (*jvm)->DestroyJavaVM(jvm);

  return mrb_true_value();
}

void
mrb_mjruby_gem_init(mrb_state *mrb)
{
  // struct RClass *java_support;

  // java_support   = mrb_class_get(mrb, "JavaSupport");
  mrb_define_method(mrb, mrb->kernel_module, "exec_java",  mrb_java_support_exec, MRB_ARGS_ANY());
}

void
mrb_mjruby_gem_final(mrb_state *mrb)
{
}
