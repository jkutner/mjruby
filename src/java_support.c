/*
** java_support.c - File class
*/

#include "mruby.h"
#include "mruby/class.h"
#include "mruby/data.h"
#include "mruby/string.h"
#include "mruby/ext/io.h"

#if defined(_WIN32) || defined(_WIN64)
  #include <windows.h>
#else
  #include <dlfcn.h>
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

static void
process_mrb_args()
{

}

static void
launch_jvm_in_process(mrb_state *mrb, CreateJavaVM_t *createJavaVM, char *java_main_class, char **java_opts, int java_optsc, char **ruby_opts, int ruby_optsc)
{
  int i;
  JavaVM *jvm;
  JNIEnv *env;
  JavaVMInitArgs jvm_init_args;
  JavaVMOption jvm_opts[java_optsc];

  for (i = 0; i < java_optsc; i++) {
    jvm_opts[i].extraInfo = 0;
    jvm_opts[i].optionString = java_opts[i];
    if (strcmp("-client", jvm_opts[i].optionString) == 0) {
      mrb_raise(mrb, E_ARGUMENT_ERROR, "-client is not a valid option");
    } else if (strcmp("-server", jvm_opts[i].optionString) == 0) {
      mrb_raise(mrb, E_ARGUMENT_ERROR, "-server is not a valid option");
    }
  }

  jvm_init_args.options = jvm_opts;
  jvm_init_args.nOptions = java_optsc;
  jvm_init_args.version = JNI_VERSION_1_4;
  jvm_init_args.ignoreUnrecognized = JNI_FALSE;

  if (createJavaVM(&jvm, (void**)&env, &jvm_init_args) < 0) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "JVM creation failed");
  }

  jclass main_class = (*env)->FindClass(env, java_main_class);
  if (!main_class) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, java_main_class);
  }

  jmethodID main_method = (*env)->GetStaticMethodID(env, main_class, "main", "([Ljava/lang/String;)V");
  if (!main_method) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "Cannot get main method.");
  }

  jclass j_class_string = (*env)->FindClass(env, "java/lang/String");
  jstring j_string_arg = (*env)->NewStringUTF(env, "");

  jobjectArray main_args = (*env)->NewObjectArray(env, ruby_optsc, j_class_string, j_string_arg);

  for (i = 0; i < ruby_optsc; i++) {
    jstring j_string_arg = (*env)->NewStringUTF(env, ruby_opts[i]);
    if (!j_string_arg) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "NewStringUTF() failed");
    }
    (*env)->SetObjectArrayElement(env, main_args, i, j_string_arg);
  }

  (*env)->CallStaticVoidMethod(env, main_class, main_method, main_args);

  if (env && (*env)->ExceptionOccurred(env)) {
    (*env)->ExceptionDescribe(env);
  }
  (*jvm)->DestroyJavaVM(jvm);
}

static mrb_value
mrb_java_support_exec(mrb_state *mrb, mrb_value obj)
{
  mrb_value *argv;
  mrb_int argc;
  int i;

  fflush(stdout);
  fflush(stderr);

  mrb_get_args(mrb, "*", &argv, &argc);
  if (argc < 3) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "wrong number of arguments");
  }

  // Process the arguments from mruby
  int java_opts_start = 0;
  const char *java_home = mrb_string_value_cstr(mrb, &argv[java_opts_start++]);
  const char *java_main_class = mrb_string_value_cstr(mrb, &argv[java_opts_start++]);
  const int java_opts_count = mrb_fixnum(argv[java_opts_start++]);
  const int ruby_opts_start = java_opts_start + java_opts_count;
  const int ruby_opts_count = argc - ruby_opts_start;

  char **java_opts = malloc(java_opts_count * sizeof(void*));;
  for (i = 0; i < java_opts_count; i++) {
    java_opts[i] = mrb_string_value_cstr(mrb, &argv[i+java_opts_start]);
  }

  char **ruby_opts = malloc(ruby_opts_count * sizeof(void*));;
  for (i = 0; i < ruby_opts_count; i++) {
    ruby_opts[i] = mrb_string_value_cstr(mrb, &argv[i+ruby_opts_start]);
  }

  CreateJavaVM_t* createJavaVM = NULL;

#if defined(_WIN32) || defined(_WIN64)
  // TODO discover jvm.dll
  char *jvmdll_path = str_with_dir("C:\\Program Files\\Java\\jdk1.8.0_51", "\\jre\\bin\\server\\jvm.dll");
  HMODULE jvmdll = LoadLibrary(jvmdll_path);
  if (!jvmdll) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Cannot load jvm.dll.");
  }

  createJavaVM = (CreateJavaVM_t*) GetProcAddress(jvmdll, "JNI_CreateJavaVM");
#elif defined(__APPLE__)
  // jli needs to be loaded on OSX because otherwise the OS tries to run the system Java
  void *libjli = dlopen(str_with_dir(java_home, "/jre/lib/jli/libjli.dylib"), RTLD_NOW + RTLD_GLOBAL);
  void *libjvm = dlopen(str_with_dir(java_home, "/jre/lib/server/libjvm.dylib"), RTLD_NOW + RTLD_GLOBAL);

  createJavaVM = (CreateJavaVM_t*) dlsym(libjvm, "JNI_CreateJavaVM");
#else
  void *libjvm = dlopen(str_with_dir(java_home, "/jre/lib/server/libjvm.so"), RTLD_NOW + RTLD_GLOBAL);

  createJavaVM = (CreateJavaVM_t*) dlsym(libjvm, "JNI_CreateJavaVM");
#endif

  if (createJavaVM == NULL) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not load JVM");
  } else {
    launch_jvm_in_process(mrb, createJavaVM, java_main_class, java_opts, java_opts_count, ruby_opts, ruby_opts_count);
  }

#if defined(_WIN32) || defined(_WIN64)
  FreeLibrary(jvmdll);
#elif defined(__APPLE__)
  dlclose(libjli);
  dlclose(libjvm);
#else
  dlclose(libjvm);
#endif

  return mrb_true_value();
}

void
mrb_mjruby_gem_init(mrb_state *mrb)
{
  mrb_define_method(mrb, mrb->kernel_module, "exec_java",  mrb_java_support_exec, MRB_ARGS_ANY());
}

void
mrb_mjruby_gem_final(mrb_state *mrb)
{
}
