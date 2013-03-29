#include <byebug.h>

static VALUE mByebug; /* Ruby Byebug Module object */
static VALUE cContext;
static VALUE cDebugThread;

static VALUE tracing = Qfalse;
static VALUE debug   = Qfalse;
static VALUE locker  = Qnil;

static VALUE contexts;
static VALUE catchpoints;
static VALUE breakpoints;

static VALUE tpLine;
static VALUE tpCall;
static VALUE tpReturn;
static VALUE tpRaise;

static VALUE idAlive;

static void
print_debug_info(char *event, VALUE path, VALUE lineno, VALUE method_id,
                                            VALUE defined_class, int stack_size)
{
  char *file;
  const char *method_name, *class_name;

  file = strrchr(RSTRING_PTR(path), '/');
  method_name = rb_id2name(SYM2ID(method_id));
  class_name = NIL_P(defined_class) ? "undef" : rb_class2name(defined_class);
  fprintf(stderr, "%s: file=%s, line=%d, class=%s, method=%s, stack=%d\n",
           event, ++file, FIX2INT(lineno), class_name, method_name, stack_size);
  return;
}

static VALUE
Byebug_thread_context(VALUE self, VALUE thread)
{
  VALUE context;

  context = rb_hash_aref(contexts, thread);
  if (context == Qnil) {
    context = context_create(thread, cDebugThread);
    rb_hash_aset(contexts, thread, context);
  }
  return context;
}

static VALUE
Byebug_current_context(VALUE self)
{
  return Byebug_thread_context(self, rb_thread_current());
}

static int
remove_dead_threads(VALUE thread, VALUE context, VALUE ignored)
{
  return (IS_THREAD_ALIVE(thread)) ? ST_CONTINUE : ST_DELETE;
}

static void
cleanup(debug_context_t *context)
{
  VALUE thread;

  context->stop_reason = CTX_STOP_NONE;

  /* release a lock */
  locker = Qnil;

  /* let the next thread run */
  thread = remove_from_locked();
  if(thread != Qnil)
    rb_thread_run(thread);
}

static int
check_start_processing(debug_context_t *context, VALUE thread)
{
  /* return if thread is marked as 'ignored'.
    byebug's threads are marked this way
  */
  if(CTX_FL_TEST(context, CTX_FL_IGNORE)) return 0;

  while(1)
  {
    /* halt execution of the current thread if byebug is activated in another */
    while(locker != Qnil && locker != thread)
    {
      add_to_locked(thread);
      rb_thread_stop();
    }

    /* stop the current thread if it's marked as suspended */
    if(CTX_FL_TEST(context, CTX_FL_SUSPEND) && locker != thread)
    {
      CTX_FL_SET(context, CTX_FL_WAS_RUNNING);
      rb_thread_stop();
    }
    else break;
  }

  /* return if the current thread is the locker */
  if(locker != Qnil) return 0;

  /* only the current thread can proceed */
  locker = thread;

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
call_at_line(debug_context_t *context, char *file, int line,
             VALUE context_object, VALUE path, VALUE lineno)
{
  CTX_FL_UNSET(context, CTX_FL_ENABLE_BKPT);
  CTX_FL_UNSET(context, CTX_FL_FORCE_MOVE);
  context->last_file = file;
  context->last_line = line;
  rb_funcall(context_object, rb_intern("at_line"), 2, path, lineno);
}

static void
process_line_event(VALUE trace_point, void *data)
{
  VALUE path, lineno, method_id, defined_class, binding, self;
  VALUE context_object;
  VALUE breakpoint;
  debug_context_t *context;
  int moved = 0;

  context_object = Byebug_current_context(mByebug);
  Data_Get_Struct(context_object, debug_context_t, context);
  if (!check_start_processing(context, rb_thread_current())) return;

  load_frame_info(
      trace_point, &path, &lineno, &method_id, &defined_class, &binding, &self);
  if (debug == Qtrue)
    print_debug_info(
      "line", path, lineno, method_id, defined_class, context->stack_size);

  update_frame(context_object, RSTRING_PTR(path), FIX2INT(lineno), method_id,
                               defined_class, binding, self);

  if (context->last_line != FIX2INT(lineno) || context->last_file == NULL ||
       strcmp(context->last_file, RSTRING_PTR(path)))
  {
    CTX_FL_SET(context, CTX_FL_ENABLE_BKPT);
    moved = 1;
  }

  if (RTEST(tracing))
    rb_funcall(context_object, rb_intern("at_tracing"), 2, path, lineno);

  if (context->dest_frame == -1 || context->stack_size == context->dest_frame)
  {
    if (moved || !CTX_FL_TEST(context, CTX_FL_FORCE_MOVE)) {
      context->stop_next = context->stop_next <= 0 ? -1 : context->stop_next-1;
      context->stop_line = context->stop_line <= 0 ? -1 : context->stop_line-1;
    }
  }
  else if (context->stack_size < context->dest_frame)
  {
      context->stop_next = 0;
  }

  if (context->stop_next == 0 || context->stop_line == 0)
  {
    context->stop_reason = CTX_STOP_STEP;
    reset_stepping_stop_points(context);
    call_at_line(
      context, RSTRING_PTR(path), FIX2INT(lineno), context_object, path, lineno);
  }
  else if (CTX_FL_TEST(context, CTX_FL_ENABLE_BKPT))
  {
    breakpoint = find_breakpoint_by_pos(breakpoints, path, lineno, binding);
    if (breakpoint != Qnil) {
      context->stop_reason = CTX_STOP_BREAKPOINT;
      reset_stepping_stop_points(context);
      rb_funcall(context_object, rb_intern("at_breakpoint"), 1, breakpoint);
      call_at_line(context, RSTRING_PTR(path), FIX2INT(lineno), context_object,
                            path, lineno);
    }
  }

  cleanup(context);
}

static void
process_return_event(VALUE trace_point, void *data)
{
  VALUE path, lineno, method_id, defined_class, binding, self;
  VALUE context_object;
  debug_context_t *context;

  context_object = Byebug_current_context(mByebug);
  Data_Get_Struct(context_object, debug_context_t, context);
  if (!check_start_processing(context, rb_thread_current())) return;

  if (context->stack_size == context->stop_frame)
  {
      context->stop_next = 1;
      context->stop_frame = 0;
  }

  load_frame_info(trace_point, &path, &lineno, &method_id, &defined_class,
                               &binding, &self);
  if (debug == Qtrue)
    print_debug_info("return", path, lineno, method_id, defined_class,
                                                           context->stack_size);

  //rb_funcall(context_object, idAtReturn, 2, path, lineno);
  pop_frame(context_object);

  cleanup(context);
}

static void
process_call_event(VALUE trace_point, void *data)
{
  VALUE path, lineno, method_id, defined_class, binding, self;
  VALUE context_object;
  VALUE breakpoint;
  debug_context_t *context;

  context_object = Byebug_current_context(mByebug);
  Data_Get_Struct(context_object, debug_context_t, context);
  if (!check_start_processing(context, rb_thread_current())) return;

  load_frame_info(trace_point, &path, &lineno, &method_id, &defined_class,
                               &binding, &self);
  if (debug == Qtrue)
    print_debug_info("call", path, lineno, method_id, defined_class,
                                                           context->stack_size);

  push_frame(context_object, RSTRING_PTR(path), FIX2INT(lineno), method_id,
                             defined_class, binding, self);

  breakpoint = find_breakpoint_by_method(breakpoints, defined_class,
                                                      SYM2ID(method_id),
                                                      binding, self);
  if (breakpoint != Qnil) {
      context->stop_reason = CTX_STOP_BREAKPOINT;
      rb_funcall(context_object, rb_intern("at_breakpoint"), 1, breakpoint);
      call_at_line(context, RSTRING_PTR(path), FIX2INT(lineno), context_object,
                 path, lineno);
  }

  cleanup(context);
}

static void
process_raise_event(VALUE trace_point, void *data)
{
  VALUE path, lineno, method_id, defined_class, binding, self;
  VALUE context_object;
  VALUE expn_class, aclass;
  VALUE err = rb_errinfo();
  VALUE ancestors;
  debug_context_t *context;
  int i;

  context_object = Byebug_current_context(mByebug);
  Data_Get_Struct(context_object, debug_context_t, context);
  if (!check_start_processing(context, rb_thread_current())) return;

  load_frame_info(trace_point, &path, &lineno, &method_id, &defined_class,
                               &binding, &self);
  update_frame(context_object, RSTRING_PTR(path), FIX2INT(lineno), method_id,
                               defined_class, binding, self);

  if (debug == Qtrue)
    print_debug_info("call", path, lineno, method_id, defined_class,
                                                           context->stack_size);
  expn_class = rb_obj_class(err);

  if (catchpoints == Qnil ||
      context->stack_size == 0 ||
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
      rb_funcall(context_object, rb_intern("at_catchpoint"), 1, rb_errinfo());
      call_at_line(context, RSTRING_PTR(path), FIX2INT(lineno), context_object,
                   path, lineno);
      break;
    }
  }

  cleanup(context);
}

static VALUE
Byebug_setup_tracepoints(VALUE self)
{
  if (catchpoints != Qnil) return Qnil;

  contexts = rb_hash_new();
  breakpoints = rb_ary_new();
  catchpoints = rb_hash_new();

  tpLine = rb_tracepoint_new(Qnil,
      RUBY_EVENT_LINE,
      process_line_event, NULL);
  rb_tracepoint_enable(tpLine);

  tpReturn = rb_tracepoint_new(Qnil,
      RUBY_EVENT_RETURN | RUBY_EVENT_C_RETURN | RUBY_EVENT_B_RETURN | RUBY_EVENT_CLASS | RUBY_EVENT_END,
      process_return_event, NULL);
  rb_tracepoint_enable(tpReturn);

  tpCall = rb_tracepoint_new(Qnil,
      RUBY_EVENT_CALL | RUBY_EVENT_C_CALL | RUBY_EVENT_B_CALL,
      process_call_event, NULL);
  rb_tracepoint_enable(tpCall);

  tpRaise = rb_tracepoint_new(Qnil,
      RUBY_EVENT_RAISE, process_raise_event, NULL);
  rb_tracepoint_enable(tpRaise);

  return Qnil;
}

static VALUE
Byebug_remove_tracepoints(VALUE self)
{
  contexts = Qnil;
  breakpoints = Qnil;
  catchpoints = Qnil;

  if (tpLine != Qnil) rb_tracepoint_disable(tpLine);
  tpLine = Qnil;
  if (tpReturn != Qnil) rb_tracepoint_disable(tpReturn);
  tpReturn = Qnil;
  if (tpCall != Qnil) rb_tracepoint_disable(tpCall);
  tpCall = Qnil;
  if (tpRaise != Qnil) rb_tracepoint_disable(tpRaise);
  tpRaise = Qnil;
  return Qnil;
}

static int
values_i(VALUE key, VALUE value, VALUE ary)
{
    rb_ary_push(ary, value);
    return ST_CONTINUE;
}

static VALUE
Byebug_started(VALUE self)
{
  return catchpoints != Qnil ? Qtrue : Qfalse;
}

static VALUE
Byebug_stop(VALUE self)
{
    if (Byebug_started(self))
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

    if (Byebug_started(self))
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
Byebug_load(int argc, VALUE *argv, VALUE self)
{
    VALUE file, stop, context_object;
    debug_context_t *context;
    int state = 0;

    if (rb_scan_args(argc, argv, "11", &file, &stop) == 1)
    {
        stop = Qfalse;
    }

    Byebug_start(self);

    context_object = Byebug_current_context(self);
    Data_Get_Struct(context_object, debug_context_t, context);
    context->stack_size = 0;
    if (RTEST(stop)) context->stop_next = 1;

    /* Initializing $0 to the script's path */
    ruby_script(RSTRING_PTR(file));
    rb_load_protect(file, 0, &state);
    if (0 != state)
    {
        VALUE errinfo = rb_errinfo();
        //debug_suspend(self);
        reset_stepping_stop_points(context);
        rb_set_errinfo(Qnil);
        return errinfo;
    }

    /* We should run all at_exit handler's in order to provide, 
     * for instance, a chance to run all defined test cases */
    rb_exec_end_proc();

    return Qnil;
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
Byebug_contexts(VALUE self)
{
  VALUE ary;

  ary = rb_ary_new();

  /* check that all contexts point to alive threads */
  rb_hash_foreach(contexts, remove_dead_threads, 0);

  rb_hash_foreach(contexts, values_i, ary);

  return ary;
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
  rb_define_module_function(mByebug, "current_context",
                                     Byebug_current_context, 0);
  rb_define_module_function(mByebug, "contexts", Byebug_contexts, 0);
  rb_define_module_function(mByebug, "breakpoints", Byebug_breakpoints, 0);
  rb_define_module_function(mByebug, "add_catchpoint",
                                     Byebug_add_catchpoint, 1);
  rb_define_module_function(mByebug, "catchpoints", Byebug_catchpoints, 0);
  rb_define_module_function(mByebug, "_start", Byebug_start, 0);
  rb_define_module_function(mByebug, "stop", Byebug_stop, 0);
  rb_define_module_function(mByebug, "started?", Byebug_started, 0);
  rb_define_module_function(mByebug, "tracing", Byebug_tracing, 0);
  rb_define_module_function(mByebug, "tracing=", Byebug_set_tracing, 1);
  rb_define_module_function(mByebug, "debug_load", Byebug_load, -1);

  idAlive = rb_intern("alive?");

  cContext = Init_context(mByebug);

  Init_breakpoint(mByebug);

  cDebugThread  = rb_define_class_under(mByebug, "DebugThread", rb_cThread);
  contexts = Qnil;
  catchpoints = Qnil;
  breakpoints = Qnil;

  rb_global_variable(&locker);
  rb_global_variable(&breakpoints);
  rb_global_variable(&catchpoints);
  rb_global_variable(&contexts);
}
