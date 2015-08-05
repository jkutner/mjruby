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
    jvmOptions[i].optionString = (char*) mrb_string_value_cstr(mrb, &argv[i+1]);
    if (strcmp("-client", jvmOptions[i].optionString) == 0) {
      mrb_raise(mrb, E_ARGUMENT_ERROR, "-client is not a valid option");
    } else if (strcmp("-server", jvmOptions[i].optionString) == 0) {
      mrb_raise(mrb, E_ARGUMENT_ERROR, "-server is not a valid option");
    }
  }

  // jvmOptions = new JavaVMOption[options.size()];
  // int i = 0;
  // for (list<string>::iterator it = options.begin(); it != options.end(); ++it, ++i) {
  //     string &option = *it;
  //     logMsg("\t%s", option.c_str());
  //     jvmOptions[i].optionString = (char *) option.c_str();
  //     jvmOptions[i].extraInfo = 0;
  // }
  // JavaVMOption options[0];
  // options[2].optionString = "-Djava.library.path=/";  /* set native library path */
  // options[0].optionString = "Main";

  jvmArgs.options = jvmOptions;
  jvmArgs.nOptions = jvmOptCount;
  jvmArgs.version = JNI_VERSION_1_4;
  jvmArgs.ignoreUnrecognized = JNI_FALSE;

  CreateJavaVM_t* createJavaVM = NULL;

#if defined(_WIN32) || defined(_WIN64)
  // PrepareDllPath prepare(jvmLauncher->javaBinPath.c_str());
  // hDll = LoadLibrary(jvmLauncher->javaDllPath.c_str());
  // if (!hDll) {
  //   // log "Cannot load %s.", javaDllPath.c_str());
  //   return mrb_false_value();
  // }
  //
  // CreateJavaVM createJavaVM = (CreateJavaVM) GetProcAddress(hDll, JNI_CREATEVM_FUNC);
  // if (!createJavaVM) {
  //     //logErr(true, true, "GetProcAddress for %s failed.", JNI_CREATEVM_FUNC);
  //     return false;
  // }
  //
  // if (createJavaVM(&jvm, &env, &jvmArgs) < 0) {
  //   return mrb_false_value();
  // }
  // return mrb_true_value();
#else

  // jli needs to be loaded on OSX because otherwise the OS tries to run the system Java
  void *libjli = dlopen(strcat(java_home, "/jre/lib/jli/libjli.dylib"), RTLD_NOW + RTLD_GLOBAL);
  void *libjvm = dlopen(strcat(java_home, "/jre/lib/server/libjvm.dylib"), RTLD_NOW + RTLD_GLOBAL);


  createJavaVM = (CreateJavaVM_t*) dlsym(libjvm, "JNI_CreateJavaVM");
  if (createJavaVM == NULL) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not load JVM");
  }
#endif

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
  // if (!mainArgs) {
  //     logErr(false, true, "NewObjectArray() failed");
  //     return false;
  // }

  // int i = 0;
  // for (list<string>::iterator it = args.begin(); it != args.end(); ++it, ++i) {
  //     string &arg = *it;
  //     jstring jstringArg = (*env)->NewStringUTF(arg.c_str());
  //     if (!jstringArg) {
  //         logErr(false, true, "NewStringUTF() failed");
  //         return false;
  //     }
  //     (*env)->SetObjectArrayElement(mainArgs, i, jstringArg);
  // }

  (*env)->CallStaticVoidMethod(env, mainClass, mainMethod, mainArgs);

  if (env && (*env)->ExceptionOccurred(env)) {
    (*env)->ExceptionDescribe(env);
  }

  if (jvm) {
    (*jvm)->DestroyJavaVM(jvm);
  }

#if defined(_WIN32) || defined(_WIN64)
  if (hDll) {
    FreeLibrary(hDll);
  }
#endif

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
