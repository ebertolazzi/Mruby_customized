#include <mruby.h>
#include <mruby/string.h>
#include <mruby/array.h>
#if defined(_WIN32) || defined(_WIN64)
  #include <stdio.h>
  #define popen _popen
  #define pclose _pclose
#endif


static mrb_value
mrb_s_popen(mrb_state *mrb, mrb_value * s_cmd)
{
  mrb_value s_out = mrb_str_new_cstr(mrb, "");
  mrb_value a_result = mrb_ary_new(mrb);
  FILE *cmd;
  char line[80];
  int exit_status = 0;
  mrb_int n_arg = 0;

  cmd = popen(mrb_string_value_cstr(mrb, s_cmd), "r");
  while(fgets(line, 80, cmd) != NULL)
  {
    mrb_str_concat(mrb, s_out, mrb_str_new_cstr(mrb, line));
  }
  exit_status = pclose(cmd);
  mrb_ary_push(mrb, a_result, s_out);
  mrb_ary_push(mrb, a_result, mrb_fixnum_value(exit_status));
  return a_result;
}

static mrb_value
mrb_s_pipe(mrb_state *mrb, mrb_value * s_cmd, mrb_value * s_in)
{
  mrb_value s_out = mrb_str_new_cstr(mrb, "");
  FILE *cmd;
  char line[80];
  int exit_status = 0;
  mrb_int n_arg = 0;

  cmd = popen(mrb_string_value_cstr(mrb, s_cmd), "w");
  fputs(mrb_string_value_cstr(mrb, s_in), cmd);
  fflush(cmd);
  exit_status = pclose(cmd);
  return mrb_fixnum_value(exit_status);
}


static mrb_value
mrb_shell_call(mrb_state *mrb, mrb_value self)
{
  mrb_value s_cmd, s_in;
  mrb_value a_result = mrb_ary_new(mrb);
  mrb_int n_arg = 0;
  
  n_arg = mrb_get_args(mrb, "S|S", &s_cmd, &s_in);
  if (n_arg == 2) {
    a_result = mrb_s_pipe(mrb, &s_cmd, &s_in);
  }
  else {
    a_result = mrb_s_popen(mrb, &s_cmd);
  }
  return a_result;
}


void
mrb_mruby_shell_gem_init(mrb_state* mrb)
{
  mrb_define_method(mrb, mrb->kernel_module, "shell", mrb_shell_call, MRB_ARGS_ARG(1,1));
#if defined(_WIN32) || defined(_WIN64)
  mrb_define_const(mrb, mrb->kernel_module, "RUBY_PLATFORM", mrb_str_new_cstr(mrb, "mswin"));
#elif defined(__APPLE__)
  mrb_define_const(mrb, mrb->kernel_module, "RUBY_PLATFORM", mrb_str_new_cstr(mrb, "darwin"));
#else
  mrb_define_const(mrb, mrb->kernel_module, "RUBY_PLATFORM", mrb_str_new_cstr(mrb, "linux"));
#endif  
}

void
mrb_mruby_shell_gem_final(mrb_state* mrb)
{
}
