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

#if defined(_WIN32) || defined(_WIN64)
  #define JAVA_EXE "java.exe"
  #define JAVA_SERVER_DL "\\bin\\server\\jvm.dll"
  #define JAVA_CLIENT_DL "\\bin\\client\\jvm.dll"
  #define JLI_DL "" // only needed for Apple
#elif defined(__APPLE__)
  #define JAVA_EXE "java"
  #define JAVA_SERVER_DL "/lib/server/libjvm.dylib"
  #define JAVA_CLIENT_DL "/lib/client/libjvm.dylib"
  #define JLI_DL "/lib/jli/libjli.dylib"
#else
  #define JAVA_EXE "java"
  #define JAVA_SERVER_DL "/lib/amd64/server/libjvm.so"
  #define JAVA_CLIENT_DL "/lib/amd64/client/libjvm.so"
  #define JLI_DL "" // only needed for Apple
#endif

typedef jint (JNICALL CreateJavaVM_t)(JavaVM **pvm, void **env, void *args);

static char**
process_mrb_args(mrb_state *mrb, mrb_value *argv, int offset, int count)
{
  int i;
  char **opts = malloc(count * sizeof(void*));;
  for (i = 0; i < count; i++) {
    opts[i] = mrb_string_value_cstr(mrb, &argv[i+offset]);
  }
  return opts;
}

static void
launch_jvm_in_proc(mrb_state *mrb, CreateJavaVM_t *createJavaVM, char *java_main_class, char **java_opts, int java_optsc, char **ruby_opts, int ruby_optsc)
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

  fflush(stdout);
  fflush(stderr);

  mrb_get_args(mrb, "*", &argv, &argc);
  if (argc < 3) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "wrong number of arguments");
  }

  // Process the arguments from mruby
  int java_opts_start = 0;
  const char *java_dl = mrb_string_value_cstr(mrb, &argv[java_opts_start++]);
  const char *jli_dl = mrb_string_value_cstr(mrb, &argv[java_opts_start++]);
  const char *java_main_class = mrb_string_value_cstr(mrb, &argv[java_opts_start++]);
  const int java_opts_count = mrb_fixnum(argv[java_opts_start++]);
  const int ruby_opts_start = java_opts_start + java_opts_count;
  const int ruby_opts_count = argc - ruby_opts_start;
  const char **java_opts = process_mrb_args(mrb, argv, java_opts_start, java_opts_count);
  const char **ruby_opts = process_mrb_args(mrb, argv, ruby_opts_start, ruby_opts_count);

  CreateJavaVM_t* createJavaVM = NULL;

#if defined(_WIN32) || defined(_WIN64)
  HMODULE jvmdll = LoadLibrary(java_dl);
  if (!jvmdll) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Cannot load jvm.dll");
  }

  createJavaVM = (CreateJavaVM_t*) GetProcAddress(jvmdll, "JNI_CreateJavaVM");
#elif defined(__APPLE__)
  // jli needs to be loaded on OSX because otherwise the OS tries to run the system Java
  void *libjli = dlopen(jli_dl, RTLD_NOW + RTLD_GLOBAL);
  void *libjvm = dlopen(java_dl, RTLD_NOW + RTLD_GLOBAL);
  if (!libjvm) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Cannot load libjvm.dylib");
  }

  createJavaVM = (CreateJavaVM_t*) dlsym(libjvm, "JNI_CreateJavaVM");
#else
  void *libjvm = dlopen(java_dl, RTLD_NOW + RTLD_GLOBAL);
  if (!libjvm) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Cannot load libjvm.so");
  }

  createJavaVM = (CreateJavaVM_t*) dlsym(libjvm, "JNI_CreateJavaVM");
#endif

  if (createJavaVM == NULL) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not load JVM");
  } else {
    launch_jvm_in_proc(mrb, createJavaVM, java_main_class, java_opts, java_opts_count, ruby_opts, ruby_opts_count);
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
  struct RClass *java_support;

  mrb_define_method(mrb, mrb->kernel_module, "exec_java",  mrb_java_support_exec, MRB_ARGS_ANY());

  java_support = mrb_define_class(mrb, "JavaSupport", mrb->object_class);
  mrb_define_const(mrb, java_support, "JAVA_EXE", mrb_str_new_cstr(mrb, JAVA_EXE));
  mrb_define_const(mrb, java_support, "JAVA_SERVER_DL", mrb_str_new_cstr(mrb, JAVA_SERVER_DL));
  mrb_define_const(mrb, java_support, "JAVA_CLIENT_DL", mrb_str_new_cstr(mrb, JAVA_CLIENT_DL));
  mrb_define_const(mrb, java_support, "JLI_DL", mrb_str_new_cstr(mrb, JLI_DL));
}

void
mrb_mjruby_gem_final(mrb_state *mrb)
{
}
