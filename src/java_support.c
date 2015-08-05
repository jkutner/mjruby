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
  // const char *JNI_CREATEVM_FUNC = "JNI_CreateJavaVM";

  mrb_value *argv;
  mrb_value pathv;
  mrb_int argc, i;
  const char *java_home;

  fflush(stdout);
  fflush(stderr);

  mrb_get_args(mrb, "*", &argv, &argc);
  if (argc < 2) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "wrong number of arguments");
  }

  java_home = mrb_string_value_cstr(mrb, &argv[0]);

  JavaVM *jvm;
  JNIEnv *env;
  JavaVMInitArgs jvmArgs;
  // JavaVMOption *jvmOptions;

  // jvmOptions = new JavaVMOption[options.size()];
  // int i = 0;
  // for (list<string>::iterator it = options.begin(); it != options.end(); ++it, ++i) {
  //     string &option = *it;
  //     logMsg("\t%s", option.c_str());
  //     jvmOptions[i].optionString = (char *) option.c_str();
  //     jvmOptions[i].extraInfo = 0;
  // }
  JavaVMOption options[0];
  // options[2].optionString = "-Djava.library.path=/";  /* set native library path */
  // options[0].optionString = "Main";

  jvmArgs.options = options;
  jvmArgs.nOptions = 0;
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

#define JVM_DLL "libjvm.dylib"
#define JAVA_DLL "libjava.dylib"
#define LD_LIBRARY_PATH "DYLD_LIBRARY_PATH"

  // HMODULE hDll;
  // PrepareDllPath prepare("/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Home/bin");
  // hDll = LoadLibrary("/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Home/jre/lib/server/libjvm.dylib");
  // if (!hDll) {
  //   // log "Cannot load %s.", javaDllPath.c_str());
  //   return mrb_false_value();
  // }

  // CreateJavaVM createJavaVM = (CreateJavaVM) GetProcAddress(hDll, JNI_CREATEVM_FUNC);

  // if (!createJavaVM) {
  //     //logErr(true, true, "GetProcAddress for %s failed.", JNI_CREATEVM_FUNC);
  //     return false;
  // }

  // This is necessary on OSX because it tries to run the system Java otherwise.
  void *libjli = dlopen(strcat(java_home, "/jre/lib/jli/libjli.dylib"), RTLD_NOW + RTLD_GLOBAL);
  void *libjvm = dlopen(strcat(java_home, "/jre/lib/server/libjvm.dylib"), RTLD_NOW + RTLD_GLOBAL);


  createJavaVM = (CreateJavaVM_t*) dlsym(libjvm, "JNI_CreateJavaVM");
#endif

  if (createJavaVM(&jvm, (void**)&env, &jvmArgs) < 0) {
    return mrb_false_value();
  }

  jclass mainClass = (*env)->FindClass(env, "Main");
  // if (!mainClass) {
  //     logErr(false, true, "Cannot find class %s.", mainClassName);
  //     return false;
  // }

  jmethodID mainMethod = (*env)->GetStaticMethodID(env, mainClass, "main", "([Ljava/lang/String;)V");
  // if (!mainMethod) {
  //     logErr(false, true, "Cannot get main method.");
  //     return false;
  // }

  jclass jclassString = (*env)->FindClass(env, "java/lang/String");
  // if (!jclassString) {
  //     logErr(false, true, "Cannot find java/lang/String class");
  //     return false;
  // }

  jstring jstringArg = (*env)->NewStringUTF(env, "");
  // if (!jstringArg) {
  //     logErr(false, true, "NewStringUTF() failed");
  //     return false;
  // }

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
  return mrb_true_value();
}

void
mrb_mjruby_gem_init(mrb_state *mrb)
{
  struct RClass *java_support;

  // java_support   = mrb_class_get(mrb, "JavaSupport");
  mrb_define_method(mrb, mrb->kernel_module, "exec_java",  mrb_java_support_exec, MRB_ARGS_ANY());
}

void
mrb_mjruby_gem_final(mrb_state *mrb)
{
}
