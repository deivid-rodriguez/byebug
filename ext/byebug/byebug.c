#include <byebug.h>

static VALUE mByebug; /* Ruby Byebug Module object */
static VALUE cContext;
static VALUE cDebugThread;

static VALUE debug = Qfalse;
static VALUE locker = Qnil;
static VALUE contexts;
static VALUE catchpoints;
static VALUE breakpoints;

static VALUE tpLine;
static VALUE tpCall;
static VALUE tpReturn;
static VALUE tpRaise;

static VALUE idAlive;
static VALUE idAtLine;
static VALUE idAtBreakpoint;
static VALUE idAtCatchpoint;

static void
print_debug_info(char *event, VALUE path, VALUE lineno, VALUE method_id,
                                            VALUE defined_class, int stack_size)
{
  char *file;
  const char *method_name, *class_name;
  //const char *method_name;

  file = strrchr(RSTRING_PTR(path), '/');
  method_name = rb_id2name(SYM2ID(method_id));
  class_name = rb_class2name(defined_class);
  fprintf(stderr, "%s: file=%s, line=%d, class=%s, method=%s, stack=%d\n",
           event, ++file, FIX2INT(lineno), class_name, method_name, stack_size);
  //fprintf(stderr, "%s: file=%s, line=%d, method=%s, stack=%d\n",
  //                   event, ++file, FIX2INT(lineno), method_name, stack_size);
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

  /* let the next thread to run */
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
    /* halt execution of the current thread if the byebug
       is activated in another
    */
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
  CTX_FL_UNSET(context, CTX_FL_STEPPED);
  CTX_FL_UNSET(context, CTX_FL_FORCE_MOVE);
  context->last_file = file;
  context->last_line = line;
  rb_funcall(context_object, idAtLine, 2, path, lineno);
}

static void
process_line_event(VALUE trace_point, void *data)
{
  VALUE path, lineno, method_id, defined_class, binding, self;
  VALUE context_object;
  VALUE breakpoint;
  debug_context_t *context;
  int moved;

  context_object = Byebug_current_context(mByebug);
  Data_Get_Struct(context_object, debug_context_t, context);
  if (!check_start_processing(context, rb_thread_current())) return;

  load_frame_info(trace_point, &path, &lineno, &method_id, &defined_class,
                               &binding, &self);
  if (debug == Qtrue)
    print_debug_info("line", path, lineno, method_id, defined_class,
                                                           context->stack_size);

  update_frame(context_object, RSTRING_PTR(path), FIX2INT(lineno), method_id,
                               defined_class, binding, self);

  moved = context->last_line != FIX2INT(lineno) || context->last_file == NULL ||
          strcmp(context->last_file, RSTRING_PTR(path)) != 0;

  if(context->dest_frame == -1 || context->stack_size == context->dest_frame)
  {
      if(moved || !CTX_FL_TEST(context, CTX_FL_FORCE_MOVE))
          context->stop_next--;
      if(context->stop_next < 0)
          context->stop_next = -1;
      if(moved || (CTX_FL_TEST(context, CTX_FL_STEPPED) && !CTX_FL_TEST(context, CTX_FL_FORCE_MOVE)))
      {
          context->stop_line--;
          CTX_FL_UNSET(context, CTX_FL_STEPPED);
      }
  }
  else if(context->stack_size < context->dest_frame)
  {
      context->stop_next = 0;
  }

  breakpoint = find_breakpoint_by_pos(breakpoints, path, lineno, binding);
  if(context->stop_next == 0 || context->stop_line == 0 || breakpoint != Qnil){
    context->stop_reason = CTX_STOP_STEP;
    if (breakpoint != Qnil) {
      rb_funcall(context_object, idAtBreakpoint, 1, breakpoint);
    }
    reset_stepping_stop_points(context);
    call_at_line(context, RSTRING_PTR(path), FIX2INT(lineno), context_object,
                 path, lineno);
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

  if(context->stack_size == context->stop_frame)
  {
      context->stop_next = 1;
      context->stop_frame = 0;
  }

  load_frame_info(trace_point, &path, &lineno, &method_id, &defined_class,
                               &binding, &self);
  if (debug == Qtrue)
    print_debug_info("return", path, lineno, method_id, defined_class,
                                                           context->stack_size);

  // rb_funcall(context_object, idAtReturn, 2, path, lineno);

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
      rb_funcall(context_object, idAtBreakpoint, 1, breakpoint);
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
  VALUE hit_count;
  VALUE exception_name;
  debug_context_t *context;
  int c_hit_count;

  context_object = Byebug_current_context(mByebug);
  Data_Get_Struct(context_object, debug_context_t, context);
  if (!check_start_processing(context, rb_thread_current())) return;

  load_frame_info(trace_point, &path, &lineno, &method_id, &defined_class,
                               &binding, &self);
  update_frame(context_object, RSTRING_PTR(path), FIX2INT(lineno), method_id,
                               defined_class, binding, self);

  if (catchpoint_hit_count(catchpoints, rb_errinfo(), &exception_name) != Qnil) {
    /* On 64-bit systems with gcc and -O2 there seems to be
       an optimization bug in running INT2FIX(FIX2INT...)..)
       So we do this in two steps.
      */
    c_hit_count = FIX2INT(rb_hash_aref(catchpoints, exception_name)) + 1;
    hit_count = INT2FIX(c_hit_count);
    rb_hash_aset(catchpoints, exception_name, hit_count);
    context->stop_reason = CTX_STOP_CATCHPOINT;
    rb_funcall(context_object, idAtCatchpoint, 1, rb_errinfo());
    call_at_line(context, RSTRING_PTR(path), FIX2INT(lineno), context_object,
                 path, lineno);
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
Byebug_started(VALUE self)
{
  return catchpoints != Qnil ? Qtrue : Qfalse;
}

/*
 *   call-seq:
 *      Byebug.stop -> bool
 *
 *   This method disables the byebug. It returns +true+ if the byebug is
 *   disabled, otherwise it returns +false+.
 */
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

/*
 *   call-seq:
 *      Byebug.start_ -> bool
 *      Byebug.start_ { ... } -> bool
 *
 *   This method is internal and activates the byebug. Use Byebug.start (from
 *   <tt>lib/byebug.rb</tt>) instead.
 *
 *   The return value is the value of !Byebug.started? <i>before</i> issuing the +start+;
 *   That is, +true+ is returned, unless byebug was previously started.
 *
 *   If a block is given, it starts byebug and yields to block. When the block is finished
 *   executing it stops the byebug with Byebug.stop method. Inside the block you will
 *   probably want to have a call to Byebug.byebug. For example:
 *
 *     Byebug.start{byebug; foo}  # Stop inside of foo
 *
 *   Also, byebug only allows one invocation of byebug at a time; nested Byebug.start's
 *   have no effect and you can't use this inside the byebug itself.
 *
 *   <i>Note that if you want to completely remove the byebug hook, you must call
 *   Byebug.stop as many times as you called Byebug.start method.</i>
 */
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


/*
 *   Document-class: Byebug
 *
 *   == Summary
 *
 *   This is a singleton class allows controlling the byebug. Use it to start/stop byebug,
 *   set/remove breakpoints, etc.
 */
void
Init_byebug()
{
  mByebug = rb_define_module("Byebug");
  rb_define_module_function(mByebug, "setup_tracepoints", Byebug_setup_tracepoints, 0);
  rb_define_module_function(mByebug, "remove_tracepoints", Byebug_remove_tracepoints, 0);
  rb_define_module_function(mByebug, "current_context", Byebug_current_context, 0);
  rb_define_module_function(mByebug, "contexts", Byebug_contexts, 0);
  rb_define_module_function(mByebug, "breakpoints", Byebug_breakpoints, 0);
  rb_define_module_function(mByebug, "catchpoints", Byebug_catchpoints, 0);
  rb_define_module_function(mByebug, "_start", Byebug_start, 0);
  rb_define_module_function(mByebug, "stop", Byebug_stop, 0);
  rb_define_module_function(mByebug, "started?", Byebug_started, 0);

  idAlive = rb_intern("alive?");
  idAtLine = rb_intern("at_line");
  idAtBreakpoint = rb_intern("at_breakpoint");
  idAtCatchpoint = rb_intern("at_catchpoint");

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
