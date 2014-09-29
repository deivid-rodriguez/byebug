#include <byebug.h>

static VALUE mByebug; /* Ruby Byebug Module object */

static VALUE tracing     = Qfalse;
static VALUE post_mortem = Qfalse;
static VALUE verbose     = Qfalse;

static VALUE catchpoints = Qnil;
static VALUE breakpoints = Qnil;
static VALUE tracepoints = Qnil;

static VALUE raised_exception = Qnil;

/* To allow thread syncronization, we must stop threads when debugging */
VALUE locker = Qnil;

/* Hash table with active threads and their associated contexts */
VALUE threads = Qnil;

/*
 *  call-seq:
 *    Byebug.breakpoints -> array
 *
 *  Returns an array of breakpoints.
 */
static VALUE
bb_breakpoints(VALUE self)
{
  if (NIL_P(breakpoints))
    breakpoints = rb_ary_new();

  return breakpoints;
}

/*
 *  call-seq:
 *    Byebug.catchpoints -> array
 *
 *  Returns an array of catchpoints.
 */
static VALUE
bb_catchpoints(VALUE self)
{
  return catchpoints;
}

/*
 *  call-seq:
 *    Byebug.raised_exception -> exception
 *
 *  Returns raised exception when in post_mortem mode.
 */
static VALUE
bb_raised_exception(VALUE self)
{
  return raised_exception;
}

#define IS_STARTED  (catchpoints != Qnil)
static void
check_started()
{
  if (!IS_STARTED)
  {
    rb_raise(rb_eRuntimeError, "Byebug is not started yet.");
  }
}

static void
trace_print(rb_trace_arg_t *trace_arg, debug_context_t *dc)
{
  if (trace_arg)
  {
    const char *event = rb_id2name(SYM2ID(rb_tracearg_event(trace_arg)));
    char *path = RSTRING_PTR(rb_tracearg_path(trace_arg));
    int line = NUM2INT(rb_tracearg_lineno(trace_arg));
    VALUE v_mid_sym = rb_tracearg_method_id(trace_arg);
    VALUE v_mid_id = NIL_P(v_mid_sym) ? Qnil : SYM2ID(v_mid_sym);
    const char *mid = NIL_P(v_mid_id) ? "" : rb_id2name(v_mid_id);
    printf("%*s (%d)->[#%d] %s@%s:%d %s\n", dc->calced_stack_size, "",
           dc->calced_stack_size, dc->thnum, event, path, line, mid);
  }
}

static void
cleanup(debug_context_t *dc)
{
  VALUE thread;

  dc->stop_reason = CTX_STOP_NONE;

  /* checks for dead threads */
  check_threads_table();

  /* release a lock */
  locker = Qnil;

  /* let the next thread to run */
  thread = remove_from_locked();
  if (thread != Qnil)
    rb_thread_run(thread);
}

#define EVENT_SETUP                                                     \
  rb_trace_arg_t *trace_arg = rb_tracearg_from_tracepoint(trace_point); \
  debug_context_t *dc;                                                  \
  VALUE context;                                                        \
  thread_context_lookup(rb_thread_current(), &context);                 \
  Data_Get_Struct(context, debug_context_t, dc);                        \

#define EVENT_COMMON                                                    \
  if (verbose == Qtrue) trace_print(trace_arg, dc);                     \
  if (!trace_common(trace_arg, dc)) { return; }                         \

static int
trace_common(rb_trace_arg_t *trace_arg, debug_context_t *dc)
{
  /* return if thread marked as 'ignored', like byebug's control thread */
  if (CTX_FL_TEST(dc, CTX_FL_IGNORE))
  {
    cleanup(dc);
    return 0;
  }

  halt_while_other_thread_is_active(dc);

  /* Get the lock! */
  locker = rb_thread_current();

  /* Many events per line, but only *one* breakpoint */
  if (dc->last_line != rb_tracearg_lineno(trace_arg) ||
      dc->last_file != rb_tracearg_path(trace_arg))
  {
    CTX_FL_SET(dc, CTX_FL_ENABLE_BKPT);
  }

  return 1;
}

static void
save_current_position(debug_context_t *dc, VALUE file, VALUE line)
{
  dc->last_file = file;
  dc->last_line = line;
  CTX_FL_UNSET(dc, CTX_FL_ENABLE_BKPT);
  CTX_FL_UNSET(dc, CTX_FL_FORCE_MOVE);
}

/* Functions that return control to byebug after the different events */

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

static VALUE
call_at_return(VALUE context_obj, debug_context_t *dc, VALUE file, VALUE line)
{
  CTX_FL_UNSET(dc, CTX_FL_STOP_ON_RET);
  return call_at(context_obj, dc, rb_intern("at_return"), 2, file, line);
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


/* TracePoint API event handlers */

static void
line_event(VALUE trace_point, void *data)
{
  VALUE breakpoint, file, line, binding, self;
  int moved = 0;

  EVENT_SETUP

  breakpoint = Qnil;
  file    = rb_tracearg_path(trace_arg);
  line    = rb_tracearg_lineno(trace_arg);
  binding = rb_tracearg_binding(trace_arg);
  self    = rb_tracearg_self(trace_arg);

  EVENT_COMMON

  if (dc->calced_stack_size == 0) dc->calced_stack_size++;

  if (dc->last_line != rb_tracearg_lineno(trace_arg) ||
      dc->last_file != rb_tracearg_path(trace_arg))
  {
    moved = 1;
  }

  if (RTEST(tracing))
    call_at_tracing(context, dc, file, line);

  if (moved || !CTX_FL_TEST(dc, CTX_FL_FORCE_MOVE))
  {
    dc->steps = dc->steps <= 0 ? -1 : dc->steps - 1;
    if (dc->calced_stack_size <= dc->dest_frame)
    {
      dc->lines = dc->lines <= 0 ? -1 : dc->lines - 1;
      if (dc->calced_stack_size < dc->dest_frame)
      {
        dc->dest_frame = dc->calced_stack_size;
        rb_funcall(mByebug, rb_intern("puts"), 1,
          rb_str_new2("Next went up a frame because previous frame finished\n"));
      }
    }
  }

  if (dc->steps == 0 || dc->lines == 0 ||
      (CTX_FL_TEST(dc, CTX_FL_ENABLE_BKPT) &&
      (!NIL_P(
       breakpoint = find_breakpoint_by_pos(bb_breakpoints(self), file, line, binding)))))
  {
    call_at_line_check(context, dc, breakpoint, file, line);
  }

  cleanup(dc);
}

static void
call_event(VALUE trace_point, void *data)
{
  VALUE breakpoint, klass, msym, mid, binding, self, file, line;

  EVENT_SETUP

  dc->calced_stack_size++;

  if (CTX_FL_TEST(dc, CTX_FL_STOP_ON_RET))
    dc->steps_out = dc->steps_out <= 0 ? -1 : dc->steps_out + 1;

  EVENT_COMMON

  breakpoint = Qnil;
  klass   = rb_tracearg_defined_class(trace_arg);
  msym    = rb_tracearg_method_id(trace_arg);
  mid     = NIL_P(msym) ? Qnil : SYM2ID(msym);
  binding = rb_tracearg_binding(trace_arg);
  self    = rb_tracearg_self(trace_arg);
  file    = rb_tracearg_path(trace_arg);
  line    = rb_tracearg_lineno(trace_arg);

  breakpoint = find_breakpoint_by_method(bb_breakpoints(self), klass, mid, binding, self);
  if (breakpoint != Qnil)
  {
    call_at_breakpoint(context, dc, breakpoint);
    call_at_line(context, dc, file, line);
  }

  cleanup(dc);
}

static void
return_event(VALUE trace_point, void *data)
{
  EVENT_SETUP

  if (dc->calced_stack_size > 0) dc->calced_stack_size--;

  EVENT_COMMON

  if (dc->steps_out == 1)
  {
    dc->steps = 1;
  }
  else if ((dc->steps_out == 0) && (CTX_FL_TEST(dc, CTX_FL_STOP_ON_RET)))
  {
    VALUE file, line;

    reset_stepping_stop_points(dc);
    file = rb_tracearg_path(trace_arg);
    line = rb_tracearg_lineno(trace_arg);
    call_at_return(context, dc, file, line);
  }

  dc->steps_out = dc->steps_out <= 0 ? -1 : dc->steps_out - 1;

  cleanup(dc);
}

static void
c_call_event(VALUE trace_point, void *data)
{
  EVENT_SETUP

  dc->calced_stack_size++;

  EVENT_COMMON

  cleanup(dc);
}

static void
c_return_event(VALUE trace_point, void *data)
{
  EVENT_SETUP

  if (dc->calced_stack_size > 0) dc->calced_stack_size--;

  EVENT_COMMON

  cleanup(dc);
}

static void
thread_event(VALUE trace_point, void *data)
{
  EVENT_SETUP

  EVENT_COMMON

  cleanup(dc);
}

static void
raise_event(VALUE trace_point, void *data)
{
  VALUE expn_class, ancestors;
  VALUE path, lineno, binding, post_mortem_context;
  int i;
  debug_context_t *new_dc;

  EVENT_SETUP

  EVENT_COMMON

  path             = rb_tracearg_path(trace_arg);
  lineno           = rb_tracearg_lineno(trace_arg);
  binding          = rb_tracearg_binding(trace_arg);
  raised_exception = rb_tracearg_raised_exception(trace_arg);

  if (post_mortem == Qtrue)
  {
    post_mortem_context = context_dup(dc);
    rb_ivar_set(raised_exception, rb_intern("@__bb_file")   , path);
    rb_ivar_set(raised_exception, rb_intern("@__bb_line")   , lineno);
    rb_ivar_set(raised_exception, rb_intern("@__bb_binding"), binding);
    rb_ivar_set(raised_exception, rb_intern("@__bb_context"), post_mortem_context);

    Data_Get_Struct(post_mortem_context, debug_context_t, new_dc);
    rb_debug_inspector_open(context_backtrace_set, (void *)new_dc);
  }

  if (catchpoints == Qnil ||
      dc->calced_stack_size == 0 ||
      RHASH_TBL(catchpoints)->num_entries == 0)
  {
    cleanup(dc);
    return;
  }

  expn_class = rb_obj_class(raised_exception);
  ancestors = rb_mod_ancestors(expn_class);
  for (i = 0; i < RARRAY_LENINT(ancestors); i++)
  {
    VALUE ancestor_class, module_name, hit_count;

    ancestor_class = rb_ary_entry(ancestors, i);
    module_name    = rb_mod_name(ancestor_class);
    hit_count      = rb_hash_aref(catchpoints, module_name);

    /* increment exception */
    if (hit_count != Qnil)
    {
      rb_hash_aset(catchpoints, module_name, INT2FIX(FIX2INT(hit_count) + 1));
      call_at_catchpoint(context, dc, raised_exception);
      call_at_line(context, dc, path, lineno);
      break;
    }
  }

  cleanup(dc);
}


/* Setup TracePoint functionality */

static void
register_tracepoints(VALUE self)
{
  int i;
  VALUE traces = tracepoints;

  if (NIL_P(traces))
  {
    int line_msk   = RUBY_EVENT_LINE;
    int call_msk   = RUBY_EVENT_CALL | RUBY_EVENT_B_CALL | RUBY_EVENT_CLASS;
    int return_msk = RUBY_EVENT_RETURN | RUBY_EVENT_B_RETURN | RUBY_EVENT_END;
    int c_call_msk = RUBY_EVENT_C_CALL;
    int c_ret_msk  = RUBY_EVENT_C_RETURN;
    int raise_msk  = RUBY_EVENT_RAISE;
    int thread_msk = RUBY_EVENT_THREAD_BEGIN | RUBY_EVENT_THREAD_END;

    VALUE tpLine    = rb_tracepoint_new(Qnil, line_msk  , line_event    , 0);
    VALUE tpCall    = rb_tracepoint_new(Qnil, call_msk  , call_event    , 0);
    VALUE tpReturn  = rb_tracepoint_new(Qnil, return_msk, return_event  , 0);
    VALUE tpCCall   = rb_tracepoint_new(Qnil, c_call_msk, c_call_event  , 0);
    VALUE tpCReturn = rb_tracepoint_new(Qnil, c_ret_msk , c_return_event, 0);
    VALUE tpRaise   = rb_tracepoint_new(Qnil, raise_msk , raise_event   , 0);
    VALUE tpThread  = rb_tracepoint_new(Qnil, thread_msk, thread_event  , 0);

    traces = rb_ary_new();
    rb_ary_push(traces, tpLine);
    rb_ary_push(traces, tpCall);
    rb_ary_push(traces, tpReturn);
    rb_ary_push(traces, tpCCall);
    rb_ary_push(traces, tpCReturn);
    rb_ary_push(traces, tpRaise);
    rb_ary_push(traces, tpThread);

    tracepoints = traces;
  }

  for (i = 0; i < RARRAY_LENINT(traces); i++)
    rb_tracepoint_enable(rb_ary_entry(traces, i));
}

static void
clear_tracepoints(VALUE self)
{
  int i;

  for (i = RARRAY_LENINT(tracepoints)-1; i >= 0; i--)
    rb_tracepoint_disable(rb_ary_entry(tracepoints, i));
}


/* Byebug's Public API */

/*
 *  call-seq:
 *    Byebug.contexts -> array
 *
 *   Returns an array of all contexts.
 */
static VALUE
bb_contexts(VALUE self)
{
  volatile VALUE list;
  volatile VALUE new_list;
  VALUE context;
  threads_table_t *t_tbl;
  debug_context_t *dc;
  int i;

  check_started();

  new_list = rb_ary_new();
  list = rb_funcall(rb_cThread, rb_intern("list"), 0);

  for (i = 0; i < RARRAY_LENINT(list); i++)
  {
    VALUE thread = rb_ary_entry(list, i);
    thread_context_lookup(thread, &context);
    rb_ary_push(new_list, context);
  }

  Data_Get_Struct(threads, threads_table_t, t_tbl);
  st_clear(t_tbl->tbl);

  for (i = 0; i < RARRAY_LENINT(new_list); i++)
  {
    context = rb_ary_entry(new_list, i);
    Data_Get_Struct(context, debug_context_t, dc);
    st_insert(t_tbl->tbl, dc->thread, context);
  }

  return new_list;
}

/*
 *  call-seq:
 *    Byebug.thread_context(thread) -> context
 *
 *   Returns context of the thread passed as an argument.
 */
static VALUE
bb_thread_context(VALUE self, VALUE thread)
{
  VALUE context;

  check_started();

  thread_context_lookup(thread, &context);

  return context;
}

/*
 *  call-seq:
 *    Byebug.current_context -> context
 *
 *  Returns the current context.
 *    <i>Note:</i> Byebug.current_context.thread == Thread.current
 */
static VALUE
bb_current_context(VALUE self)
{
  VALUE context;

  check_started();

  thread_context_lookup(rb_thread_current(), &context);

  return context;
}

/*
 *  call-seq:
 *    Byebug.started? -> bool
 *
 *  Returns +true+ byebug is started.
 */
static VALUE
bb_started(VALUE self)
{
  return IS_STARTED;
}

/*
 *  call-seq:
 *    Byebug.stop -> bool
 *
 *  This method disables byebug. It returns +true+ if byebug was already
 *  disabled, otherwise it returns +false+.
 */
static VALUE
bb_stop(VALUE self)
{
  if (IS_STARTED)
  {
    clear_tracepoints(self);

    breakpoints = Qnil;
    catchpoints = Qnil;
    threads     = Qnil;

    return Qfalse;
  }
  return Qtrue;
}

/*
 *  call-seq:
 *    Byebug.start -> bool
 *    Byebug.start { ... } -> bool
 *
 *  If a block is given, it starts byebug and yields block. After the block is
 *  executed it stops byebug with Byebug.stop method. Inside the block you
 *  will probably want to have a call to Byebug.byebug. For example:
 *
 *      Byebug.start { byebug; foo }  # Stop inside of foo
 *
 *  The return value is the value of !Byebug.started? <i>before</i> issuing the
 *  +start+; That is, +true+ is returned, unless byebug was previously started.
 */
static VALUE
bb_start(VALUE self)
{
  VALUE result;

  if (IS_STARTED)
    result = Qfalse;
  else
  {
    locker      = Qnil;
    catchpoints = rb_hash_new();
    threads     = create_threads_table();

    register_tracepoints(self);
    result = Qtrue;
  }

  if (rb_block_given_p())
    rb_ensure(rb_yield, self, bb_stop, self);

  return result;
}

/*
 *  call-seq:
 *    Byebug.debug_load(file, stop = false) -> nil
 *
 *  Same as Kernel#load but resets current context's frames.
 *  +stop+ parameter forces byebug to stop at the first line of code in +file+
 */
static VALUE
bb_load(int argc, VALUE *argv, VALUE self)
{
  VALUE file, stop, context;
  debug_context_t *dc;
  VALUE status = Qnil;
  int state = 0;

  if (rb_scan_args(argc, argv, "11", &file, &stop) == 1)
  {
    stop = Qfalse;
  }

  bb_start(self);

  context = bb_current_context(self);
  Data_Get_Struct(context, debug_context_t, dc);

  dc->calced_stack_size = 1;

  if (RTEST(stop)) dc->steps = 1;

  /* Initializing $0 to the script's path */
  ruby_script(RSTRING_PTR(file));
  rb_load_protect(file, 0, &state);
  if (0 != state)
  {
    status = rb_errinfo();
    reset_stepping_stop_points(dc);
  }

  /* We should run all at_exit handler's in order to provide, for instance, a
   * chance to run all defined test cases */
  rb_exec_end_proc();

  return status;
}

/*
 *  call-seq:
 *    Byebug.verbose? -> bool
 *
 *  Returns +true+ if verbose output of TracePoint API events is enabled.
 */
static VALUE
bb_verbose(VALUE self)
{
  return verbose;
}

/*
 *  call-seq:
 *    Byebug.verbose = bool
 *
 *  Enable verbose output of every TracePoint API events, useful for debugging
 *  byebug.
 */
static VALUE
bb_set_verbose(VALUE self, VALUE value)
{
  verbose = RTEST(value) ? Qtrue : Qfalse;
  return value;
}

/*
 *  call-seq:
 *    Byebug.tracing? -> bool
 *
 *  Returns +true+ if global tracing is enabled.
 */
static VALUE
bb_tracing(VALUE self)
{
  return tracing;
}

/*
 *  call-seq:
 *    Byebug.tracing = bool
 *
 *  Sets the global tracing flag.
 */
static VALUE
bb_set_tracing(VALUE self, VALUE value)
{
  tracing = RTEST(value) ? Qtrue : Qfalse;
  return value;
}

/*
 *  call-seq:
 *    Byebug.post_mortem? -> bool
 *
 *  Returns +true+ if post-mortem debugging is enabled.
 */
static VALUE
bb_post_mortem(VALUE self)
{
  return post_mortem;
}

/*
 *  call-seq:
 *    Byebug.post_mortem = bool
 *
 *  Sets post-moterm flag.
 */
static VALUE
bb_set_post_mortem(VALUE self, VALUE value)
{
  post_mortem = RTEST(value) ? Qtrue : Qfalse;
  return value;
}

/*
 *  call-seq:
 *    Byebug.add_catchpoint(exception) -> exception
 *
 *  Adds a new exception to the catchpoints array.
 */
static VALUE
bb_add_catchpoint(VALUE self, VALUE value)
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

  rb_define_module_function(mByebug, "add_catchpoint"  , bb_add_catchpoint  ,  1);
  rb_define_module_function(mByebug, "breakpoints"     , bb_breakpoints     ,  0);
  rb_define_module_function(mByebug, "catchpoints"     , bb_catchpoints     ,  0);
  rb_define_module_function(mByebug, "contexts"        , bb_contexts        ,  0);
  rb_define_module_function(mByebug, "current_context" , bb_current_context ,  0);
  rb_define_module_function(mByebug, "debug_load"      , bb_load            , -1);
  rb_define_module_function(mByebug, "post_mortem?"    , bb_post_mortem     ,  0);
  rb_define_module_function(mByebug, "post_mortem="    , bb_set_post_mortem ,  1);
  rb_define_module_function(mByebug, "raised_exception", bb_raised_exception,  0);
  rb_define_module_function(mByebug, "start"           , bb_start           ,  0);
  rb_define_module_function(mByebug, "started?"        , bb_started         ,  0);
  rb_define_module_function(mByebug, "stop"            , bb_stop            ,  0);
  rb_define_module_function(mByebug, "thread_context"  , bb_thread_context  ,  1);
  rb_define_module_function(mByebug, "tracing?"        , bb_tracing         ,  0);
  rb_define_module_function(mByebug, "tracing="        , bb_set_tracing     ,  1);
  rb_define_module_function(mByebug, "verbose?"        , bb_verbose         ,  0);
  rb_define_module_function(mByebug, "verbose="        , bb_set_verbose     ,  1);

  Init_threads_table(mByebug);
  Init_context(mByebug);
  Init_breakpoint(mByebug);

  rb_global_variable(&breakpoints);
  rb_global_variable(&catchpoints);
  rb_global_variable(&tracepoints);
  rb_global_variable(&raised_exception);
  rb_global_variable(&threads);
}
