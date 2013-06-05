#include <byebug.h>

static VALUE mByebug; /* Ruby Byebug Module object */
static VALUE cContext;

static VALUE tracing     = Qfalse;
static VALUE post_mortem = Qfalse;
static VALUE debug       = Qfalse;

static VALUE context;
static VALUE catchpoints;
static VALUE breakpoints;

static VALUE tpLine;
static VALUE tpCall;
static VALUE tpCCall;
static VALUE tpReturn;
static VALUE tpCReturn;
static VALUE tpRaise;

static VALUE
tp_inspect(rb_trace_arg_t *trace_arg) {
  if (trace_arg) {
    VALUE event = rb_tracearg_event(trace_arg);
    if (ID2SYM(rb_intern("line")) == event ||
        ID2SYM(rb_intern("specified_line")) == event)
    {
       VALUE sym = rb_tracearg_method_id(trace_arg);
       if (NIL_P(sym)) sym = rb_str_new_cstr("<main>");
       return rb_sprintf("%"PRIsVALUE"@%"PRIsVALUE":%d in `%"PRIsVALUE"'",
                           rb_tracearg_event(trace_arg),
                           rb_tracearg_path(trace_arg),
                           FIX2INT(rb_tracearg_lineno(trace_arg)),
                           sym);
    }
    if (ID2SYM(rb_intern("call")) == event ||
        ID2SYM(rb_intern("c_call")) == event ||
        ID2SYM(rb_intern("return")) == event ||
        ID2SYM(rb_intern("c_return")) == event)
      return rb_sprintf("%"PRIsVALUE" `%"PRIsVALUE"'@%"PRIsVALUE":%d",
                        rb_tracearg_event(trace_arg),
                        rb_tracearg_method_id(trace_arg),
                        rb_tracearg_path(trace_arg),
                        FIX2INT(rb_tracearg_lineno(trace_arg)));
    return rb_sprintf("%"PRIsVALUE"@%"PRIsVALUE":%d",
                      rb_tracearg_event(trace_arg),
                      rb_tracearg_path(trace_arg),
                      FIX2INT(rb_tracearg_lineno(trace_arg)));
  }
  return rb_sprintf("No info");
}

static VALUE
Byebug_context(VALUE self)
{
  if (context == Qnil) {
    context = context_create();
  }
  return context;
}

static void
cleanup(debug_context_t *dc)
{
  dc->stop_reason = CTX_STOP_NONE;
}

static void
save_current_position(debug_context_t *dc, VALUE file, VALUE line)
{
  dc->last_file = file;
  dc->last_line = line;
  CTX_FL_UNSET(dc, CTX_FL_ENABLE_BKPT);
  CTX_FL_UNSET(dc, CTX_FL_FORCE_MOVE);
}

static VALUE
call_at(VALUE context_obj, debug_context_t *dc, ID mid, int argc, VALUE a0,
                                                                  VALUE a1)
{
  struct call_with_inspection_data cwi;
  VALUE argv[2];

  argv[0] = a0;
  argv[1] = a1;

  cwi.dc          = dc;
  cwi.context_obj = context_obj;
  cwi.id          = mid;
  cwi.argc        = argc;
  cwi.argv        = &argv[0];

  return call_with_debug_inspector(&cwi);
}

static VALUE
call_at_line(VALUE context_obj, debug_context_t *dc, VALUE file, VALUE line)
{
  save_current_position(dc, file, line);
  return call_at(context_obj, dc, rb_intern("at_line"), 2, file, line);
}

static VALUE
call_at_tracing(VALUE context_obj, debug_context_t *dc, VALUE file, VALUE line)
{
  return call_at(context_obj, dc, rb_intern("at_tracing"), 2, file, line);
}

static VALUE
call_at_breakpoint(VALUE context_obj, debug_context_t *dc, VALUE breakpoint)
{
  dc->stop_reason = CTX_STOP_BREAKPOINT;
  return call_at(context_obj, dc, rb_intern("at_breakpoint"), 1, breakpoint, 0);
}

static VALUE
call_at_catchpoint(VALUE context_obj, debug_context_t *dc, VALUE exp)
{
  dc->stop_reason = CTX_STOP_CATCHPOINT;
  return call_at(context_obj, dc, rb_intern("at_catchpoint"), 1, exp, 0);
}

static void
call_at_line_check(VALUE context_obj, debug_context_t *dc,
                   VALUE breakpoint, VALUE file, VALUE line)
{
  dc->stop_reason = CTX_STOP_STEP;

  if (breakpoint != Qnil)
    call_at_breakpoint(context_obj, dc, breakpoint);

  reset_stepping_stop_points(dc);
  call_at_line(context_obj, dc, file, line);
}

#define EVENT_SETUP                                                     \
  rb_trace_arg_t *trace_arg = rb_tracearg_from_tracepoint(trace_point); \
  VALUE context_obj;                                                    \
  debug_context_t *dc;                                                  \
  context_obj = Byebug_context(mByebug);                                \
  Data_Get_Struct(context_obj, debug_context_t, dc);                    \
  if (debug == Qtrue)                                                   \
    printf("%s (stack_size: %d)\n",                                     \
            RSTRING_PTR(tp_inspect(trace_arg)), dc->stack_size);        \

#define EVENT_COMMON() \
  if (trace_common(trace_arg, dc) == 0) { return; }

static int
trace_common(rb_trace_arg_t *trace_arg, debug_context_t *dc)
{
  /* ignore a skipped section of code */
  if (CTX_FL_TEST(dc, CTX_FL_SKIPPED))
  {
    cleanup(dc);
    return 0;
  }

  /* Many events per line, but only *one* breakpoint */
  if (dc->last_line != rb_tracearg_lineno(trace_arg) ||
      dc->last_file != rb_tracearg_path(trace_arg))
  {
    CTX_FL_SET(dc, CTX_FL_ENABLE_BKPT);
  }

  return 1;
}

static void
process_line_event(VALUE trace_point, void *data)
{
  EVENT_SETUP;
  VALUE breakpoint = Qnil;
  VALUE file    = rb_tracearg_path(trace_arg);
  VALUE line    = rb_tracearg_lineno(trace_arg);
  VALUE binding = rb_tracearg_binding(trace_arg);
  int moved = 0;

  EVENT_COMMON();

  if (dc->stack_size == 0) dc->stack_size++;

  if (dc->last_line != rb_tracearg_lineno(trace_arg) ||
      dc->last_file != rb_tracearg_path(trace_arg))
  {
    moved = 1;
  }

  if (RTEST(tracing))
    call_at_tracing(context_obj, dc, file, line);

  if (moved || !CTX_FL_TEST(dc, CTX_FL_FORCE_MOVE))
  {
    dc->steps = dc->steps <= 0 ? -1 : dc->steps - 1;
    if (dc->stack_size <= dc->dest_frame)
    {
      dc->lines = dc->lines <= 0 ? -1 : dc->lines - 1;
      dc->dest_frame = dc->stack_size;
    }
  }

  if (dc->steps == 0 || dc->lines == 0 ||
      (CTX_FL_TEST(dc, CTX_FL_ENABLE_BKPT) &&
      (!NIL_P(
       breakpoint = find_breakpoint_by_pos(breakpoints, file, line, binding)))))
  {
    call_at_line_check(context_obj, dc, breakpoint, file, line);
  }

  cleanup(dc);
}

static void
process_c_return_event(VALUE trace_point, void *data)
{
  EVENT_SETUP;
  if (dc->stack_size > 0) dc->stack_size--;
  EVENT_COMMON();

  cleanup(dc);
}

static void
process_return_event(VALUE trace_point, void *data)
{
  EVENT_SETUP;
  if (dc->stack_size > 0) dc->stack_size--;
  EVENT_COMMON();

  if (dc->stack_size + 1 == dc->stop_frame)
  {
    dc->steps      = 1;
    dc->stop_frame = -1;
  }

  cleanup(dc);
}

static void
process_c_call_event(VALUE trace_point, void *data)
{
  EVENT_SETUP;
  dc->stack_size++;
  EVENT_COMMON();

  cleanup(dc);
}

static void
process_call_event(VALUE trace_point, void *data)
{
  EVENT_SETUP;
  dc->stack_size++;
  EVENT_COMMON();

  VALUE breakpoint = Qnil;
  VALUE klass   = rb_tracearg_defined_class(trace_arg);
  VALUE mid     = SYM2ID(rb_tracearg_method_id(trace_arg));
  VALUE binding = rb_tracearg_binding(trace_arg);
  VALUE self    = rb_tracearg_self(trace_arg);
  VALUE file    = rb_tracearg_path(trace_arg);
  VALUE line    = rb_tracearg_lineno(trace_arg);

  breakpoint =
    find_breakpoint_by_method(breakpoints, klass, mid, binding, self);
  if (breakpoint != Qnil)
  {
    call_at_breakpoint(context_obj, dc, breakpoint);
    call_at_line(context_obj, dc, file, line);
  }

  cleanup(dc);
}

static void
process_raise_event(VALUE trace_point, void *data)
{
  EVENT_SETUP
  VALUE expn_class, aclass;
  VALUE err = rb_errinfo();
  VALUE ancestors;
  int i;
  debug_context_t *new_dc;

  EVENT_COMMON();

  VALUE binding = rb_tracearg_binding(trace_arg);
  VALUE path    = rb_tracearg_path(trace_arg);
  VALUE lineno  = rb_tracearg_lineno(trace_arg);

  if (post_mortem == Qtrue)
  {
    context = context_dup(dc);
    rb_ivar_set(err, rb_intern("@__debug_file")   , path);
    rb_ivar_set(err, rb_intern("@__debug_line")   , lineno);
    rb_ivar_set(err, rb_intern("@__debug_binding"), binding);
    rb_ivar_set(err, rb_intern("@__debug_context"), context);

    Data_Get_Struct(context, debug_context_t, new_dc);
    rb_debug_inspector_open(context_backtrace_set, (void *)new_dc);
  }

  expn_class = rb_obj_class(err);

  if (catchpoints == Qnil || dc->stack_size == 0 ||
      CTX_FL_TEST(dc, CTX_FL_CATCHING) ||
      RHASH_TBL(catchpoints)->num_entries == 0)
  {
    cleanup(dc);
    return;
  }

  ancestors = rb_mod_ancestors(expn_class);
  for (i = 0; i < RARRAY_LEN(ancestors); i++)
  {
    VALUE mod_name;
    VALUE hit_count;

    aclass    = rb_ary_entry(ancestors, i);
    mod_name  = rb_mod_name(aclass);
    hit_count = rb_hash_aref(catchpoints, mod_name);

    /* increment exception */
    if (hit_count != Qnil)
    {
      rb_hash_aset(catchpoints, mod_name, INT2FIX(FIX2INT(hit_count) + 1));
      call_at_catchpoint(context_obj, dc, err);
      call_at_line(context_obj, dc, path, lineno);
      break;
    }
  }

  cleanup(dc);
}

static VALUE
Byebug_setup_tracepoints(VALUE self)
{
  if (catchpoints != Qnil) return Qnil;

  breakpoints = rb_ary_new();
  catchpoints = rb_hash_new();

  tpLine = rb_tracepoint_new(Qnil,
    RUBY_EVENT_LINE,
    process_line_event, NULL);

  tpCall = rb_tracepoint_new(Qnil,
    RUBY_EVENT_CALL | RUBY_EVENT_B_CALL | RUBY_EVENT_CLASS,
    process_call_event, NULL);

  tpCCall = rb_tracepoint_new(Qnil,
    RUBY_EVENT_C_CALL,
    process_c_call_event, NULL);

  tpReturn = rb_tracepoint_new(Qnil,
    RUBY_EVENT_RETURN | RUBY_EVENT_B_RETURN | RUBY_EVENT_END,
    process_return_event, NULL);

  tpCReturn = rb_tracepoint_new(Qnil,
    RUBY_EVENT_C_RETURN,
    process_c_return_event, NULL);

  tpRaise = rb_tracepoint_new(Qnil,
    RUBY_EVENT_RAISE,
    process_raise_event, NULL);

  rb_tracepoint_enable(tpLine);
  rb_tracepoint_enable(tpCall);
  rb_tracepoint_enable(tpCCall);
  rb_tracepoint_enable(tpReturn);
  rb_tracepoint_enable(tpCReturn);
  rb_tracepoint_enable(tpRaise);

  return Qnil;
}

static VALUE
Byebug_remove_tracepoints(VALUE self)
{
  context = Qnil;
  breakpoints = Qnil;
  catchpoints = Qnil;

  if (tpLine != Qnil) {
    rb_tracepoint_disable(tpLine);
    tpLine = Qnil;
  }
  if (tpCall != Qnil) {
    rb_tracepoint_disable(tpCall);
    tpCall = Qnil;
  }
  if (tpCCall != Qnil) {
    rb_tracepoint_disable(tpCCall);
    tpCCall = Qnil;
  }
  if (tpReturn != Qnil) {
    rb_tracepoint_disable(tpReturn);
    tpReturn = Qnil;
  }
  if (tpCReturn != Qnil) {
    rb_tracepoint_disable(tpCReturn);
    tpCReturn = Qnil;
  }
  if (tpRaise != Qnil) {
    rb_tracepoint_disable(tpRaise);
    tpRaise = Qnil;
  }
  return Qnil;
}

#define BYEBUG_STARTED (catchpoints != Qnil)
static VALUE
Byebug_started(VALUE self)
{
  return BYEBUG_STARTED;
}

static VALUE
Byebug_stop(VALUE self)
{
  if (BYEBUG_STARTED)
  {
    Byebug_remove_tracepoints(self);
    return Qfalse;
  }
  return Qtrue;
}

static VALUE
Byebug_start(VALUE self)
{
  VALUE result;

  if (BYEBUG_STARTED)
    result = Qfalse;
  else
  {
    Byebug_setup_tracepoints(self);
    result = Qtrue;
  }

  if (rb_block_given_p())
    rb_ensure(rb_yield, self, Byebug_stop, self);

  return result;
}

static VALUE
set_current_skipped_status(VALUE status)
{
  VALUE context_obj;
  debug_context_t *dc;

  context_obj = Byebug_context(mByebug);
  Data_Get_Struct(context_obj, debug_context_t, dc);
  if (status)
    CTX_FL_SET(dc, CTX_FL_SKIPPED);
  else
    CTX_FL_UNSET(dc, CTX_FL_SKIPPED);
  return Qnil;
}

static VALUE
Byebug_load(int argc, VALUE *argv, VALUE self)
{
  VALUE file, stop, context_obj;
  debug_context_t *dc;
  int state = 0;

  if (rb_scan_args(argc, argv, "11", &file, &stop) == 1)
  {
      stop = Qfalse;
  }

  Byebug_start(self);

  context_obj = Byebug_context(self);
  Data_Get_Struct(context_obj, debug_context_t, dc);
  if (RTEST(stop)) dc->steps = 1;

  /* Resetting stack size */
  dc->stack_size = 0;

  /* Initializing $0 to the script's path */
  ruby_script(RSTRING_PTR(file));
  rb_load_protect(file, 0, &state);
  if (0 != state)
  {
      VALUE errinfo = rb_errinfo();
      reset_stepping_stop_points(dc);
      rb_set_errinfo(Qnil);
      return errinfo;
  }

  /* We should run all at_exit handler's in order to provide, for instance, a
   * chance to run all defined test cases */
  rb_exec_end_proc();

  return Qnil;
}

static VALUE
debug_at_exit_c(VALUE proc)
{
  return rb_funcall(proc, rb_intern("call"), 0);
}

static void
debug_at_exit_i(VALUE proc)
{
  if (BYEBUG_STARTED)
  {
    set_current_skipped_status(Qtrue);
    rb_ensure(debug_at_exit_c, proc, set_current_skipped_status, Qfalse);
  }
  else
    debug_at_exit_c(proc);
}

static VALUE
Byebug_at_exit(VALUE self)
{
  VALUE proc;
  if (!rb_block_given_p()) rb_raise(rb_eArgError, "called without a block");
  proc = rb_block_proc();
  rb_set_end_proc(debug_at_exit_i, proc);
  return proc;
}

static VALUE
Byebug_tracing(VALUE self)
{
  return tracing;
}

static VALUE
Byebug_set_tracing(VALUE self, VALUE value)
{
  tracing = RTEST(value) ? Qtrue : Qfalse;
  return value;
}

static VALUE
Byebug_post_mortem(VALUE self)
{
  return post_mortem;
}

static VALUE
Byebug_set_post_mortem(VALUE self, VALUE value)
{
  post_mortem = RTEST(value) ? Qtrue : Qfalse;
  return value;
}

static VALUE
Byebug_breakpoints(VALUE self)
{
  return breakpoints;
}

static VALUE
Byebug_catchpoints(VALUE self)
{
  if (catchpoints == Qnil)
    rb_raise(rb_eRuntimeError, "Byebug.start is not called yet.");
  return catchpoints;
}

static VALUE
Byebug_add_catchpoint(VALUE self, VALUE value)
{
  if (TYPE(value) != T_STRING)
    rb_raise(rb_eTypeError, "value of a catchpoint must be String");

  rb_hash_aset(catchpoints, rb_str_dup(value), INT2FIX(0));
  return value;
}

/*
 *   Document-class: Byebug
 *
 *   == Summary
 *
 *   This is a singleton class allows controlling byebug. Use it to start/stop
 *   byebug, set/remove breakpoints, etc.
 */
void
Init_byebug()
{
  mByebug = rb_define_module("Byebug");
  rb_define_module_function(mByebug, "setup_tracepoints",
                                     Byebug_setup_tracepoints, 0);
  rb_define_module_function(mByebug, "remove_tracepoints",
                                     Byebug_remove_tracepoints, 0);
  rb_define_module_function(mByebug, "context", Byebug_context, 0);
  rb_define_module_function(mByebug, "breakpoints", Byebug_breakpoints, 0);
  rb_define_module_function(mByebug, "add_catchpoint",
                                     Byebug_add_catchpoint, 1);
  rb_define_module_function(mByebug, "catchpoints", Byebug_catchpoints, 0);
  rb_define_module_function(mByebug, "_start", Byebug_start, 0);
  rb_define_module_function(mByebug, "stop", Byebug_stop, 0);
  rb_define_module_function(mByebug, "started?", Byebug_started, 0);
  rb_define_module_function(mByebug, "tracing?", Byebug_tracing, 0);
  rb_define_module_function(mByebug, "tracing=", Byebug_set_tracing, 1);
  rb_define_module_function(mByebug, "debug_load", Byebug_load, -1);
  rb_define_module_function(mByebug, "debug_at_exit", Byebug_at_exit, 0);
  rb_define_module_function(mByebug, "post_mortem?", Byebug_post_mortem, 0);
  rb_define_module_function(mByebug, "post_mortem=", Byebug_set_post_mortem, 1);

  cContext = Init_context(mByebug);

  Init_breakpoint(mByebug);

  context = Qnil;
  catchpoints = Qnil;
  breakpoints = Qnil;

  rb_global_variable(&breakpoints);
  rb_global_variable(&catchpoints);
  rb_global_variable(&context);
}
