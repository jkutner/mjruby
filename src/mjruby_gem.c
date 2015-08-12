#include "mruby.h"

void mrb_init_java_support(mrb_state *mrb);
void mrb_init_jruby_support(mrb_state *mrb);

#define DONE mrb_gc_arena_restore(mrb, 0)

void
mrb_mjruby_gem_init(mrb_state* mrb)
{
  mrb_init_java_support(mrb); DONE;
  mrb_init_jruby_support(mrb); DONE;
}

void
mrb_mjruby_gem_final(mrb_state* mrb)
{
}
