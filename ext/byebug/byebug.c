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
tp_inspect(VALUE trace_point) {
  rb_trace_arg_t *trace_arg = rb_tracearg_from_tracepoint(trace_point);
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
    context = Context_create();
  }
  return context;
}

static void
cleanup(debug_context_t *context)
{
  context->stop_reason = CTX_STOP_NONE;
}

static int
check_start_processing(debug_context_t *context)
{
  /* ignore a skipped section of code */
  if(CTX_FL_TEST(context, CTX_FL_SKIPPED)) {
    cleanup(context);
    return 0;
  }
  return 1;
}

static inline void
load_frame_info(VALUE trace_point, VALUE *path, VALUE *lineno, VALUE *method_id,
                                   VALUE *defined_class, VALUE *binding,
                                   VALUE *self)
{
  rb_trace_point_t *tp;

  tp = rb_tracearg_from_tracepoint(trace_point);

  *path = rb_tracearg_path(tp);
  *lineno = rb_tracearg_lineno(tp);
  *binding = rb_tracearg_binding(tp);
  *self = rb_tracearg_self(tp);
  *method_id = rb_tracearg_method_id(tp);
  *defined_class = rb_tracearg_defined_class(tp);
}

static void
call_at_line(debug_context_t *context, VALUE context_obj,
                                       VALUE path, VALUE lineno)
{
  CTX_FL_UNSET(context, CTX_FL_ENABLE_BKPT);
  CTX_FL_UNSET(context, CTX_FL_FORCE_MOVE);
  context->last_file = RSTRING_PTR(path);
  context->last_line = FIX2INT(lineno);
  rb_funcall(context_obj, rb_intern("at_line"), 2, path, lineno);
}

#define EVENT_SETUP                                                        \
  VALUE path, lineno, method_id, defined_class, binding, self;             \
  VALUE context_obj;                                                       \
  debug_context_t *context;                                                \
  context_obj = Byebug_context(mByebug);                                   \
  Data_Get_Struct(context_obj, debug_context_t, context);                  \
  if (!check_start_processing(context)) return;                            \
  load_frame_info(trace_point, &path, &lineno, &method_id, &defined_class, \
                               &binding, &self);                           \
  if (debug == Qtrue)                                                      \
    printf("%s (stack_size: %d)\n",                                        \
            RSTRING_PTR(tp_inspect(trace_point)), context->stack_size);    \

static void
process_line_event(VALUE trace_point, void *data)
{
  EVENT_SETUP;
  VALUE breakpoint;
  int moved = 0;

  if (context->stack_size == 0)
    push_frame(context, RSTRING_PTR(path), FIX2INT(lineno), method_id,
                        defined_class, binding, self);
  else
    update_frame(context->stack, RSTRING_PTR(path), FIX2INT(lineno), method_id,
                                 defined_class, binding, self);

  if (context->last_line != FIX2INT(lineno) || context->last_file == NULL ||
       strcmp(context->last_file, RSTRING_PTR(path)))
  {
    CTX_FL_SET(context, CTX_FL_ENABLE_BKPT);
    moved = 1;
  }

  if (RTEST(tracing))
    rb_funcall(context_obj, rb_intern("at_tracing"), 2, path, lineno);

  if (context->dest_frame == -1 || context->stack_size == context->dest_frame)
  {
    if (moved || !CTX_FL_TEST(context, CTX_FL_FORCE_MOVE))
    {
      context->steps = context->steps <= 0 ? -1 : context->steps - 1;
      context->lines = context->lines <= 0 ? -1 : context->lines - 1;
    }
  }
  else if (context->stack_size < context->dest_frame)
  {
      context->steps = 0;
  }

  if (context->steps == 0 || context->lines == 0)
  {
    context->stop_reason = CTX_STOP_STEP;
    reset_stepping_stop_points(context);
    call_at_line(context, context_obj, path, lineno);
  }
  else if (CTX_FL_TEST(context, CTX_FL_ENABLE_BKPT))
  {
    breakpoint = find_breakpoint_by_pos(breakpoints, path, lineno, binding);
    if (breakpoint != Qnil)
    {
      context->stop_reason = CTX_STOP_BREAKPOINT;
      reset_stepping_stop_points(context);
      rb_funcall(context_obj, rb_intern("at_breakpoint"), 1, breakpoint);
      call_at_line(context, context_obj, path, lineno);
    }
  }

  cleanup(context);
}

static void
process_c_return_event(VALUE trace_point, void *data)
{
  EVENT_SETUP;

  pop_frame(context);

  cleanup(context);
}

static void
process_return_event(VALUE trace_point, void *data)
{
  EVENT_SETUP;

  if (context->stack_size == context->stop_frame)
  {
      context->steps      = 1;
      context->stop_frame = -1;
  }
  pop_frame(context);

  cleanup(context);
}

static void
process_c_call_event(VALUE trace_point, void *data)
{
  EVENT_SETUP;

  push_frame(context, RSTRING_PTR(path), FIX2INT(lineno), method_id,
                      defined_class, binding, self);
  cleanup(context);
}

static void
process_call_event(VALUE trace_point, void *data)
{
  EVENT_SETUP;
  VALUE breakpoint;

  push_frame(context, RSTRING_PTR(path), FIX2INT(lineno), method_id,
                      defined_class, binding, self);

  breakpoint = find_breakpoint_by_method(breakpoints, defined_class,
                                                      SYM2ID(method_id),
                                                      binding, self);
  if (breakpoint != Qnil)
  {
    context->stop_reason = CTX_STOP_BREAKPOINT;
    rb_funcall(context_obj, rb_intern("at_breakpoint"), 1, breakpoint);
    call_at_line(context, context_obj, path, lineno);
  }

  cleanup(context);
}

static void
process_raise_event(VALUE trace_point, void *data)
{
  EVENT_SETUP;
  VALUE expn_class, aclass;
  VALUE err = rb_errinfo();
  VALUE ancestors;
  int i;

  update_frame(context->stack, RSTRING_PTR(path), FIX2INT(lineno), method_id,
                               defined_class, binding, self);

  if (post_mortem == Qtrue && self)
  {
    VALUE binding = rb_binding_new();
    rb_ivar_set(rb_errinfo(), rb_intern("@__debug_file"), path);
    rb_ivar_set(rb_errinfo(), rb_intern("@__debug_line"), lineno);
    rb_ivar_set(rb_errinfo(), rb_intern("@__debug_binding"), binding);
    rb_ivar_set(rb_errinfo(), rb_intern("@__debug_context"), Context_dup(context));
  }

  expn_class = rb_obj_class(err);

  if (catchpoints == Qnil || context->stack_size == 0 ||
      CTX_FL_TEST(context, CTX_FL_CATCHING) ||
      RHASH_TBL(catchpoints)->num_entries == 0) {
    cleanup(context);
    return;
  }

  ancestors = rb_mod_ancestors(expn_class);
  for (i = 0; i < RARRAY_LEN(ancestors); i++) {
    VALUE mod_name;
    VALUE hit_count;

    aclass    = rb_ary_entry(ancestors, i);
    mod_name  = rb_mod_name(aclass);
    hit_count = rb_hash_aref(catchpoints, mod_name);

    if (hit_count != Qnil) {
      /* increment exception */
      rb_hash_aset(catchpoints, mod_name, INT2FIX(FIX2INT(hit_count) + 1));
      context->stop_reason = CTX_STOP_CATCHPOINT;
      rb_funcall(context_obj, rb_intern("at_catchpoint"), 1, rb_errinfo());
      call_at_line(context, context_obj, path, lineno);
      break;
    }
  }

  cleanup(context);
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
  debug_context_t *context;

  context_obj = Byebug_context(mByebug);
  Data_Get_Struct(context_obj, debug_context_t, context);
  if (status)
    CTX_FL_SET(context, CTX_FL_SKIPPED);
  else
    CTX_FL_UNSET(context, CTX_FL_SKIPPED);
  return Qnil;
}

static VALUE
Byebug_load(int argc, VALUE *argv, VALUE self)
{
  VALUE file, stop, context_obj;
  debug_context_t *context;
  int state = 0;

  if (rb_scan_args(argc, argv, "11", &file, &stop) == 1)
  {
      stop = Qfalse;
  }

  Byebug_start(self);

  context_obj = Byebug_context(self);
  Data_Get_Struct(context_obj, debug_context_t, context);
  context->stack_size = 0;
  if (RTEST(stop)) context->steps = 1;

  /* Initializing $0 to the script's path */
  ruby_script(RSTRING_PTR(file));
  rb_load_protect(file, 0, &state);
  if (0 != state)
  {
      VALUE errinfo = rb_errinfo();
      reset_stepping_stop_points(context);
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
