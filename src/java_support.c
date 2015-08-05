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

static mrb_value
mrb_java_support_exec(mrb_state *mrb, mrb_value obj)
{
  mrb_value *argv;
  mrb_int argc;

  fflush(stdout);
  fflush(stderr);

  mrb_get_args(mrb, "*", &argv, &argc);
  if (argc < 2) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "wrong number of arguments");
  }

  const char *java_home = mrb_string_value_cstr(mrb, &argv[0]);

  int jvmOptCount = argc - 1;
  JavaVM *jvm;
  JNIEnv *env;
  JavaVMInitArgs jvmArgs;
  JavaVMOption jvmOptions[jvmOptCount];

  for (int i = 0; i < jvmOptCount; i++) {
    jvmOptions[i].extraInfo = 0;
    jvmOptions[i].optionString = mrb_string_value_cstr(mrb, &argv[i+1]);
    if (strcmp("-client", jvmOptions[i].optionString) == 0) {
      mrb_raise(mrb, E_ARGUMENT_ERROR, "-client is not a valid option");
    } else if (strcmp("-server", jvmOptions[i].optionString) == 0) {
      mrb_raise(mrb, E_ARGUMENT_ERROR, "-server is not a valid option");
    }
  }

  // JavaVMOption jvmOptions[0];
  jvmArgs.options = jvmOptions;
  jvmArgs.nOptions = 0;
  jvmArgs.version = JNI_VERSION_1_4;
  jvmArgs.ignoreUnrecognized = JNI_FALSE;

  CreateJavaVM_t* createJavaVM = NULL;

  // jli needs to be loaded on OSX because otherwise the OS tries to run the system Java
  void *libjli = dlopen("/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Home/jre/lib/jli/libjli.dylib", RTLD_NOW + RTLD_GLOBAL);
  void *libjvm = dlopen("/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Home/jre/lib/server/libjvm.dylib", RTLD_NOW + RTLD_GLOBAL);

  createJavaVM = (CreateJavaVM_t*) dlsym(libjvm, "JNI_CreateJavaVM");
  if (createJavaVM == NULL) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not load JVM");
  }

  if (createJavaVM(&jvm, (void**)&env, &jvmArgs) < 0) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "JVM creation failed");
  }

  jclass mainClass = (*env)->FindClass(env, "Main");
  if (!mainClass) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, strcat("Cannot find class: ", "Main"));
    return mrb_false_value();
  }

  jmethodID mainMethod = (*env)->GetStaticMethodID(env, mainClass, "main", "([Ljava/lang/String;)V");
  if (!mainMethod) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "Cannot get main method.");
    return mrb_false_value();
  }

  jclass jclassString = (*env)->FindClass(env, "java/lang/String");
  jstring jstringArg = (*env)->NewStringUTF(env, "");

  jobjectArray mainArgs = (*env)->NewObjectArray(env, 0, jclassString, jstringArg);

  (*env)->CallStaticVoidMethod(env, mainClass, mainMethod, mainArgs);

  if (env && (*env)->ExceptionOccurred(env)) {
    (*env)->ExceptionDescribe(env);
  }
  (*jvm)->DestroyJavaVM(jvm);

  fflush(stdout);
  fflush(stderr);

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
