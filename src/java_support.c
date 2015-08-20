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
  #include <string.h>
  #include <dlfcn.h>
  #include <stdlib.h>
  #include <unistd.h>

  // #include <sys/types.h>
  // #include <sys/time.h>
  // #include <sys/wait.h>
  // #include <sys/select.h>
  #include <signal.h>
  //
  // #include <errno.h>
  // #include <stdio.h>
  // #include <stdlib.h>
  // #include <string.h>
  // #include <time.h>
#endif

#include <jni.h>

static struct {
  const char *name;
  int no;
} signals[] = {
#include "signals.cstub"
  { NULL, 0 }
};

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
#elif defined(__x86_64__)
  #define JAVA_EXE "java"
  #define JAVA_SERVER_DL "/lib/amd64/server/libjvm.so"
  #define JAVA_CLIENT_DL "/lib/amd64/client/libjvm.so"
  #define JLI_DL "" // only needed for Apple
#else
  #define JAVA_EXE "java"
  #define JAVA_SERVER_DL "/lib/i386/server/libjvm.so"
  #define JAVA_CLIENT_DL "/lib/i386/client/libjvm.so"
  #define JLI_DL "" // only needed for Apple
#endif

typedef jint (JNICALL CreateJavaVM_t)(JavaVM **pvm, void **env, void *args);

static const char**
process_mrb_args(mrb_state *mrb, mrb_value *argv, int offset, int count)
{
  int i;
  const char **opts = malloc(count * sizeof(void*));;
  for (i = 0; i < count; i++) {
    opts[i] = mrb_string_value_cstr(mrb, &argv[i+offset]);
  }
  return opts;
}

#if defined(_WIN32) || defined(_WIN64)
static void
disable_folder_virtualization(HANDLE hProcess) {
  OSVERSIONINFO osvi = {0};
  osvi.dwOSVersionInfoSize = sizeof (OSVERSIONINFO);
  if (GetVersionEx(&osvi) && osvi.dwMajorVersion == 6) // check it is Win VISTA
  {
    HANDLE hToken;
    if (OpenProcessToken(hProcess, TOKEN_ALL_ACCESS, &hToken)) {
      DWORD tokenInfoVal = 0;
      if (!SetTokenInformation(hToken, (TOKEN_INFORMATION_CLASS) 24, &tokenInfoVal, sizeof (DWORD))) {
        // invalid token information class (24) is OK, it means there is no folder virtualization on current system
        if (GetLastError() != ERROR_INVALID_PARAMETER) {
            // logErr(true, true, "Failed to set token information.");
            return;
        }
      }
      CloseHandle(hToken);
    } else {
      // logErr(true, true, "Failed to open process token.");
      return;
    }
  }
}

static char *
get_string_from_registry(HKEY rootKey, const char *keyName, const char *valueName) {
  HKEY hKey = 0;
  if (RegOpenKeyEx(rootKey, keyName, 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
      DWORD valSize = 4096;
      DWORD type = 0;
      char val[4096] = "";
      if (RegQueryValueEx(hKey, valueName, 0, &type, (BYTE *) val, &valSize) == ERROR_SUCCESS && type == REG_SZ) {
          RegCloseKey(hKey);
          return val;
      } else {
          printf("RegQueryValueEx() failed.\n");
      }
      RegCloseKey(hKey);
  } else {
      printf("RegOpenKeyEx() failed.\n");
  }
  return NULL;
}

static char *
get_java_home_from_registry(char *java_key)
{
  char *version = get_string_from_registry(HKEY_LOCAL_MACHINE, java_key, "CurrentVersion");
  if (version) {
    char *sep = "\\";
    char *full_java_key = malloc(strlen(java_key)+strlen(sep)+strlen(version)+1);
    strcpy(full_java_key, java_key);
    strcat(full_java_key, sep);
    strcat(full_java_key, version);
    return get_string_from_registry(HKEY_LOCAL_MACHINE, full_java_key, "JavaHome");
  }
  return NULL;
}
#endif

static mrb_value
mrb_find_native_java(mrb_state *mrb, mrb_value obj)
{
  char *java_home = NULL;
    char buff[PATH_MAX];
#if defined(_WIN32) || defined(_WIN64)
  java_home = get_java_home_from_registry("Software\\JavaSoft\\Java Development Kit");
  if (!java_home) {
    java_home = get_java_home_from_registry("Software\\JavaSoft\\Java Runtime Environment");
  }
#elif defined(__APPLE__)
  FILE *fp = popen("/usr/libexec/java_home", "r");
  if (fp == NULL) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Failed to run `/usr/libexec/java_home'");
  }

  // Read only the first line of output
  java_home = fgets(buff, sizeof(buff)-1, fp);
  pclose(fp);
#else
  ssize_t len = readlink("/usr/bin/java", buff, sizeof(buff)-1);
  buff[len] = '\0';
  java_home = buff;
#endif
  return mrb_str_new_cstr(mrb, java_home);
}

static mrb_value
mrb_p_exec(const char **pargv, int pargc)
{
  int ret, i;
#if defined(_WIN32) || defined(_WIN64)
  char cmd[32*1024] = "";
  for (i = 0; i < pargc-1; i++) {
    strcat(cmd, pargv[i]);
    strcat(cmd, " ");
  }

  STARTUPINFO si = {0};
  si.cb = sizeof(STARTUPINFO);
  PROCESS_INFORMATION pi = {0};

  if (!CreateProcess(NULL, cmd, NULL, NULL, TRUE, CREATE_SUSPENDED, NULL, NULL, &si, &pi)) {
    // mrb_raise(mrb, E_RUNTIME_ERROR, "Failed to create process");
    return mrb_false_value();
  }

  disable_folder_virtualization(pi.hProcess);
  ResumeThread(pi.hThread);
  WaitForSingleObject(pi.hProcess, INFINITE);
  // if (retCode) {
  //   GetExitCodeProcess(pi.hProcess, retCode);
  // }
  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
  return mrb_true_value();
#else
  void (*chfunc)(int);

  chfunc = signal(SIGCHLD, SIG_DFL);
  ret = execv(pargv[0], pargv);
  signal(SIGCHLD, chfunc);

  if (WIFEXITED(ret) && WEXITSTATUS(ret) == 0) {
    return mrb_true_value();
  }

  return mrb_false_value();
#endif
}

static void
launch_jvm_out_of_proc(mrb_state *mrb, const char *java_exe, const char *java_main_class, const char **java_opts, int java_optsc, const char **ruby_opts, int ruby_optsc)
{
  int ret, i, pargvc;
  void (*chfunc)(int);

  pargvc = java_optsc + ruby_optsc + 3;
  char **pargv = malloc(pargvc * sizeof(void*));
  pargv[0] = java_exe;
  for (i = 0; i < java_optsc; i++) {
    pargv[i+1] = java_opts[i];
  }
  pargv[java_optsc+1] = java_main_class;
  for (i = 0; i < ruby_optsc; i++) {
    pargv[i+java_optsc+2] = ruby_opts[i];
  }
  pargv[pargvc-1] = NULL;

  mrb_p_exec(pargv, pargvc);
}

static void
launch_jvm_in_proc(mrb_state *mrb, CreateJavaVM_t *createJavaVM, const char *java_main_class, const char **java_opts, int java_optsc, const char **ruby_opts, int ruby_optsc)
{
  int i;
  JavaVM *jvm;
  JNIEnv *env;
  JavaVMInitArgs jvm_init_args;
  JavaVMOption jvm_opts[java_optsc];

  for (i = 0; i < java_optsc; i++) {
    jvm_opts[i].extraInfo = 0;
    jvm_opts[i].optionString = (char *) java_opts[i];
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
    jstring j_string_arg = (*env)->NewStringUTF(env, (char *) ruby_opts[i]);
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
  const char *java_exe = mrb_string_value_cstr(mrb, &argv[java_opts_start++]);
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
    launch_jvm_out_of_proc(mrb, java_exe, java_main_class, java_opts, java_opts_count, ruby_opts, ruby_opts_count);
    //launch_jvm_in_proc(mrb, createJavaVM, java_main_class, java_opts, java_opts_count, ruby_opts, ruby_opts_count);
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
mrb_init_java_support(mrb_state *mrb)
{
  struct RClass *java_support;

  mrb_define_method(mrb, mrb->kernel_module, "exec_java",  mrb_java_support_exec, MRB_ARGS_ANY());

  java_support = mrb_define_class(mrb, "JavaSupport", mrb->object_class);
  mrb_define_const(mrb, java_support, "JAVA_EXE", mrb_str_new_cstr(mrb, JAVA_EXE));
  mrb_define_const(mrb, java_support, "JAVA_SERVER_DL", mrb_str_new_cstr(mrb, JAVA_SERVER_DL));
  mrb_define_const(mrb, java_support, "JAVA_CLIENT_DL", mrb_str_new_cstr(mrb, JAVA_CLIENT_DL));
  mrb_define_const(mrb, java_support, "JLI_DL", mrb_str_new_cstr(mrb, JLI_DL));

  mrb_define_method(mrb, java_support, "find_native_java",  mrb_find_native_java, MRB_ARGS_ANY());

}
