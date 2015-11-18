/*
** jruby_support.c - File class
*/

#include "mruby.h"
#include "mruby/class.h"
#include "mruby/data.h"
#include "mruby/string.h"
#include "mruby/ext/io.h"

#if defined(_WIN32) || defined(_WIN64)
  #define SYSTEM_SHELL "cmd.exe"
  #define DEFAULT_JAVA_OPTS ""
  #define IS_WINDOWS "true"
#elif defined(__APPLE__)
  #define SYSTEM_SHELL "/bin/sh"
  #define DEFAULT_JAVA_OPTS "-Dfile.encoding=UTF-8"
  #define IS_WINDOWS "false"
#else
  #define SYSTEM_SHELL "/bin/sh"
  #define DEFAULT_JAVA_OPTS ""
  #define IS_WINDOWS "false"
#endif

mrb_bool mrb_is_windows(mrb_state *mrb)
{
#if defined(_WIN32) || defined(_WIN64)
  return TRUE;
#else
  return NULL;
#endif
}

void
mrb_init_jruby_support(mrb_state *mrb)
{
  struct RClass *c;
  c = mrb_define_class(mrb, "JRubySupport", mrb->object_class);

  mrb_define_const(mrb, c, "IS_WINDOWS", mrb_str_new_cstr(mrb, IS_WINDOWS));
  mrb_define_const(mrb, c, "SYSTEM_SHELL", mrb_str_new_cstr(mrb, SYSTEM_SHELL));
  mrb_define_const(mrb, c, "DEFAULT_JAVA_OPTS", mrb_str_new_cstr(mrb, DEFAULT_JAVA_OPTS));
}
