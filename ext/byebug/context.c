#include <byebug.h>

static VALUE cContext;
static VALUE cDebugThread;
static int thnum_max = 0;

/* "Step", "Next" and "Finish" do their work by saving information about where
 * to stop next. reset_stepping_stop_points removes/resets this information. */
extern void
reset_stepping_stop_points(debug_context_t *context)
{
  context->dest_frame   = -1;
  context->lines        = -1;
  context->steps        = -1;
  context->after_frame  = -1;
  context->before_frame = -1;
}

/*
 *  call-seq:
 *    context.dead? -> bool
 *
 *  Returns +true+ if context doesn't represent a live context and is created
 *  during post-mortem exception handling.
 */
static inline VALUE
Context_dead(VALUE self)
{
  debug_context_t *context;
  Data_Get_Struct(self, debug_context_t, context);
  return CTX_FL_TEST(context, CTX_FL_DEAD) ? Qtrue : Qfalse;
}

static void
context_mark(void *data)
{
  debug_context_t *context = (debug_context_t *)data;
  rb_gc_mark(context->backtrace);
}

static void
context_free(void *data)
{

}

static int
real_stack_size()
{
  return FIX2INT(rb_funcall(cContext, rb_intern("real_stack_size"), 0));
}

extern VALUE
context_create(VALUE thread)
{
  debug_context_t *context = ALLOC(debug_context_t);

  context->last_file   = Qnil;
  context->last_line   = Qnil;
  context->flags       = 0;
  context->stack_size  = real_stack_size();
  context->thnum       = ++thnum_max;
  context->thread      = thread;
  reset_stepping_stop_points(context);
  context->stop_reason = CTX_STOP_NONE;
  context->backtrace   = Qnil;

  if (rb_obj_class(thread) == cDebugThread) CTX_FL_SET(context, CTX_FL_IGNORE);

  return Data_Wrap_Struct(cContext, context_mark, context_free, context);
}

extern VALUE
context_dup(debug_context_t *context)
{
  debug_context_t *new_context = ALLOC(debug_context_t);

  memcpy(new_context, context, sizeof(debug_context_t));
  reset_stepping_stop_points(new_context);
  new_context->backtrace = context->backtrace;
  CTX_FL_SET(new_context, CTX_FL_DEAD);

  return Data_Wrap_Struct(cContext, context_mark, context_free, new_context);
}

static VALUE
dc_backtrace(const debug_context_t *context)
{
  return context->backtrace;
}

static VALUE
dc_frame_get(const debug_context_t *context, int frame_index,
                                             enum frame_component type)
{
  VALUE frame;

  if (NIL_P(dc_backtrace(context)))
    rb_raise(rb_eRuntimeError, "Backtrace information is not available");

  if (frame_index >= RARRAY_LEN(dc_backtrace(context)))
    rb_raise(rb_eRuntimeError, "That frame doesn't exist!");

  frame = rb_ary_entry(dc_backtrace(context), frame_index);
  return rb_ary_entry(frame, type);
}

static VALUE
dc_frame_location(const debug_context_t *context, int frame_index)
{
  return dc_frame_get(context, frame_index, LOCATION);
}

static VALUE
dc_frame_self(const debug_context_t *context, int frame_index)
{
  return dc_frame_get(context, frame_index, SELF);
}

static VALUE
dc_frame_class(const debug_context_t *context, int frame_index)
{
  return dc_frame_get(context, frame_index, CLASS);
}

static VALUE
dc_frame_binding(const debug_context_t *context, int frame_index)
{
  return dc_frame_get(context, frame_index, BINDING);
}

static VALUE
load_backtrace(const rb_debug_inspector_t *inspector)
{
  VALUE backtrace = rb_ary_new();
  VALUE locs = rb_debug_inspector_backtrace_locations(inspector);
  int i;

  for (i=0; i<RARRAY_LEN(locs); i++)
  {
    VALUE frame = rb_ary_new();
    rb_ary_push(frame, rb_ary_entry(locs, i));
    rb_ary_push(frame, rb_debug_inspector_frame_self_get(inspector, i));
    rb_ary_push(frame, rb_debug_inspector_frame_class_get(inspector, i));
    rb_ary_push(frame, rb_debug_inspector_frame_binding_get(inspector, i));

    rb_ary_push(backtrace, frame);
  }

  return backtrace;
}

extern VALUE
context_backtrace_set(const rb_debug_inspector_t *inspector, void *data)
{
  debug_context_t *dc = (debug_context_t *)data;
  dc->backtrace = load_backtrace(inspector);

  return Qnil;
}

static VALUE
open_debug_inspector_i(const rb_debug_inspector_t *inspector, void *data)
{
  struct call_with_inspection_data *cwi =
    (struct call_with_inspection_data *)data;
  cwi->dc->backtrace = load_backtrace(inspector);

  return rb_funcall2(cwi->context_obj, cwi->id, cwi->argc, cwi->argv);
}

static VALUE
open_debug_inspector(struct call_with_inspection_data *cwi)
{
  return rb_debug_inspector_open(open_debug_inspector_i, cwi);
}

static VALUE
close_debug_inspector(struct call_with_inspection_data *cwi)
{
  cwi->dc->backtrace = Qnil;
  return Qnil;
}

extern VALUE
call_with_debug_inspector(struct call_with_inspection_data *data)
{
  return rb_ensure(open_debug_inspector, (VALUE)data,
                   close_debug_inspector, (VALUE)data);
}

#define FRAME_SETUP                                                   \
  debug_context_t *context;                                           \
  VALUE frame_no;                                                     \
  int frame_n;                                                        \
  Data_Get_Struct(self, debug_context_t, context);                    \
  if (!rb_scan_args(argc, argv, "01", &frame_no))                     \
    frame_n = 0;                                                      \
  else                                                                \
    frame_n = FIX2INT(frame_no);                                      \
  if (frame_n < 0 || frame_n >= real_stack_size(rb_thread_current())) \
  {                                                                   \
    rb_raise(rb_eArgError, "Invalid frame number %d, stack (0...%d)", \
             frame_n, real_stack_size(rb_thread_current() - 1));      \
  }                                                                   \

/*
 *  call-seq:
 *    context.frame_binding(frame_position=0) -> binding
 *
 *  Returns frame's binding.
 */
static VALUE
Context_frame_binding(int argc, VALUE *argv, VALUE self)
{
  FRAME_SETUP

  return dc_frame_binding(context, frame_n);
}

/*
 *  call-seq:
 *    context.frame_class(frame_position=0) -> binding
 *
 *  Returns frame's defined class.
 */
 static VALUE
Context_frame_class(int argc, VALUE *argv, VALUE self)
{
  FRAME_SETUP

  return dc_frame_class(context, frame_n);
}

/*
 *  call-seq:
 *    context.frame_file(frame_position=0) -> string
 *
 *  Returns the name of the file in the frame.
 */
static VALUE
Context_frame_file(int argc, VALUE *argv, VALUE self)
{
  VALUE loc;

  FRAME_SETUP

  loc = dc_frame_location(context, frame_n);

  return rb_funcall(loc, rb_intern("path"), 0);
}

/*
 *  call-seq:
 *    context.frame_line(frame_position) -> int
 *
 *  Returns the line number in the file.
 */
static VALUE
Context_frame_line(int argc, VALUE *argv, VALUE self)
{
  VALUE loc;

  FRAME_SETUP

  loc = dc_frame_location(context, frame_n);

  return rb_funcall(loc, rb_intern("lineno"), 0);
}

/*
 *  call-seq:
 *    context.frame_method(frame_position=0) -> sym
 *
 *  Returns the sym of the called method.
 */
static VALUE
Context_frame_method(int argc, VALUE *argv, VALUE self)
{
  VALUE loc;

  FRAME_SETUP

  loc = dc_frame_location(context, frame_n);

  return rb_str_intern(rb_funcall(loc, rb_intern("label"), 0));
}

/*
 *  call-seq:
 *    context.frame_self(frame_postion=0) -> obj
 *
 *  Returns self object of the frame.
 */
static VALUE
Context_frame_self(int argc, VALUE *argv, VALUE self)
{
  FRAME_SETUP

  return dc_frame_self(context, frame_n);
}

/*
 *  call-seq:
 *    context.ignored? -> bool
 *
 *  Returns the ignore flag for the context, which marks whether the associated
 *  thread is ignored while debugging.
 */
static inline VALUE
Context_ignored(VALUE self)
{
  debug_context_t *context;
  Data_Get_Struct(self, debug_context_t, context);
  return CTX_FL_TEST(context, CTX_FL_IGNORE) ? Qtrue : Qfalse;
}

static void
context_resume_0(debug_context_t *context)
{
  if (!CTX_FL_TEST(context, CTX_FL_SUSPEND)) return;

  CTX_FL_UNSET(context, CTX_FL_SUSPEND);

  if (CTX_FL_TEST(context, CTX_FL_WAS_RUNNING))
    rb_thread_wakeup(context->thread);
}

/*
 *  call-seq:
 *    context.resume -> nil
 *
 *  Resumes thread from the suspended mode.
 */
static VALUE
Context_resume(VALUE self)
{
    debug_context_t *context;

    Data_Get_Struct(self, debug_context_t, context);

    if (!CTX_FL_TEST(context, CTX_FL_SUSPEND))
      rb_raise(rb_eRuntimeError, "Thread is not suspended.");

    context_resume_0(context);

    return Qnil;
}

/*
 *  call-seq:
 *    context.stack_size-> int
 *
 *  Returns the size of the context stack.
 */
static inline VALUE
Context_stack_size(VALUE self)
{
  debug_context_t *context;
  Data_Get_Struct(self, debug_context_t, context);

  return INT2FIX(context->stack_size);
}

static VALUE
Context_stop_reason(VALUE self)
{
  debug_context_t *context;
  const char *symbol;

  Data_Get_Struct(self, debug_context_t, context);

  if (CTX_FL_TEST(context, CTX_FL_DEAD))
    symbol = "post-mortem";
  else switch (context->stop_reason)
  {
    case CTX_STOP_STEP:
      symbol = "step";
      break;
    case CTX_STOP_BREAKPOINT:
      symbol = "breakpoint";
      break;
    case CTX_STOP_CATCHPOINT:
      symbol = "catchpoint";
      break;
    case CTX_STOP_NONE:
    default:
      symbol = "none";
  }
  return ID2SYM(rb_intern(symbol));
}

/*
 *  call-seq:
 *    context.step_into(steps, force = false)
 *
 *  Stops the current context after a number of +steps+ are made.
 *  +force+ parameter (if true) ensures that the cursor moves away from the
 *  current line.
 */
static VALUE
Context_step_into(int argc, VALUE *argv, VALUE self)
{
  VALUE steps;
  VALUE force;
  debug_context_t *context;

  rb_scan_args(argc, argv, "11", &steps, &force);
  if (FIX2INT(steps) < 0)
    rb_raise(rb_eRuntimeError, "Steps argument can't be negative.");

  Data_Get_Struct(self, debug_context_t, context);
  context->steps = FIX2INT(steps);

  if (RTEST(force))
    CTX_FL_SET(context, CTX_FL_FORCE_MOVE);
  else
    CTX_FL_UNSET(context, CTX_FL_FORCE_MOVE);

  return steps;
}

/*
 *  call-seq:
 *    context.step_out(frame)
 *
 *  Stops after frame number +frame+ is activated. Implements +finish+ and
 *  +next+ commands.
 */
static VALUE
Context_step_out(VALUE self, VALUE frame)
{
  debug_context_t *context;
  Data_Get_Struct(self, debug_context_t, context);

  if (FIX2INT(frame) < 0 || FIX2INT(frame) >= context->stack_size)
    rb_raise(rb_eRuntimeError, "Stop frame is out of range.");

  context->after_frame = context->stack_size - FIX2INT(frame);

  return frame;
}

/*
 *  call-seq:
 *    context.step_over(lines, frame = nil, force = false)
 *
 *  Steps over +lines+ lines.
 *  Make step over operation on +frame+, by default the current frame.
 *  +force+ parameter (if true) ensures that the cursor moves away from the
 *  current line.
 */
static VALUE
Context_step_over(int argc, VALUE *argv, VALUE self)
{
  VALUE lines, frame, force;
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);

  if (context->stack_size == 0)
    rb_raise(rb_eRuntimeError, "No frames collected.");

  rb_scan_args(argc, argv, "12", &lines, &frame, &force);
  context->lines = FIX2INT(lines);

  if (FIX2INT(frame) < 0 || FIX2INT(frame) >= context->stack_size)
    rb_raise(rb_eRuntimeError, "Destination frame is out of range.");
  context->dest_frame = context->stack_size - FIX2INT(frame);

  if (RTEST(force))
    CTX_FL_SET(context, CTX_FL_FORCE_MOVE);
  else
    CTX_FL_UNSET(context, CTX_FL_FORCE_MOVE);

  return Qnil;
}

/*
 *  call-seq:
 *    context.stop_return(frame)
 *
 *  Stops before frame number +frame+ is activated. Useful when you enter the
 *  debugger after the last statement in a method.
 */
static VALUE
Context_stop_return(VALUE self, VALUE frame)
{
  debug_context_t *context;
  Data_Get_Struct(self, debug_context_t, context);

  if (FIX2INT(frame) < 0 || FIX2INT(frame) >= context->stack_size)
    rb_raise(rb_eRuntimeError, "Stop frame is out of range.");

  context->before_frame = context->stack_size - FIX2INT(frame);

  return frame;
}

static void
context_suspend_0(debug_context_t *context)
{
  VALUE status = rb_funcall(context->thread, rb_intern("status"), 0);

  if (rb_str_cmp(status, rb_str_new2("run")) == 0)
    CTX_FL_SET(context, CTX_FL_WAS_RUNNING);
  else if (rb_str_cmp(status, rb_str_new2("sleep")) == 0)
    CTX_FL_UNSET(context, CTX_FL_WAS_RUNNING);
  else
    return;

  CTX_FL_SET(context, CTX_FL_SUSPEND);
}

/*
 *  call-seq:
 *    context.suspend -> nil
 *
 *  Suspends the thread when it is running.
 */
static VALUE
Context_suspend(VALUE self)
{
  debug_context_t *context;
  Data_Get_Struct(self, debug_context_t, context);

  if (CTX_FL_TEST(context, CTX_FL_SUSPEND))
    rb_raise(rb_eRuntimeError, "Already suspended.");

  context_suspend_0(context);
  return Qnil;
}

/*
 *  call-seq:
 *    context.suspended? -> bool
 *
 *  Returns +true+ if the thread is suspended by debugger.
 */
static VALUE
Context_is_suspended(VALUE self)
{
  debug_context_t *context;
  Data_Get_Struct(self, debug_context_t, context);

  return CTX_FL_TEST(context, CTX_FL_SUSPEND) ? Qtrue : Qfalse;
}

/*
 *  call-seq:
 *    context.thnum -> int
 *
 *  Returns the context's number.
 */
static inline VALUE
Context_thnum(VALUE self) {
  debug_context_t *context;
  Data_Get_Struct(self, debug_context_t, context);
  return INT2FIX(context->thnum);
}

/*
 *  call-seq:
 *    context.thread -> thread
 *
 *  Returns the thread this context is associated with.
 */
static inline VALUE
Context_thread(VALUE self)
{
  debug_context_t *context;
  Data_Get_Struct(self, debug_context_t, context);
  return context->thread;
}

/*
 *  call-seq:
 *    context.tracing -> bool
 *
 *  Returns the tracing flag for the current context.
 */
static VALUE
Context_tracing(VALUE self)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);
  return CTX_FL_TEST(context, CTX_FL_TRACING) ? Qtrue : Qfalse;
}

/*
 *  call-seq:
 *    context.tracing = bool
 *
 *  Controls the tracing for this context.
 */
static VALUE
Context_set_tracing(VALUE self, VALUE value)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);

  if (RTEST(value))
      CTX_FL_SET(context, CTX_FL_TRACING);
  else
      CTX_FL_UNSET(context, CTX_FL_TRACING);
  return value;
}


/* :nodoc: */
static VALUE
DebugThread_inherited(VALUE klass)
{
  rb_raise(rb_eRuntimeError, "Can't inherit Byebug::DebugThread class");
}

/*
 *   Document-class: Context
 *
 *   == Summary
 *
 *   Byebug keeps a single instance of this class.
 */
void
Init_context(VALUE mByebug)
{
  cContext = rb_define_class_under(mByebug, "Context", rb_cObject);

  rb_define_method(cContext, "dead?"        , Context_dead         ,  0);
  rb_define_method(cContext, "frame_binding", Context_frame_binding, -1);
  rb_define_method(cContext, "frame_class"  , Context_frame_class  , -1);
  rb_define_method(cContext, "frame_file"   , Context_frame_file   , -1);
  rb_define_method(cContext, "frame_line"   , Context_frame_line   , -1);
  rb_define_method(cContext, "frame_method" , Context_frame_method , -1);
  rb_define_method(cContext, "frame_self"   , Context_frame_self   , -1);
  rb_define_method(cContext, "ignored?"     , Context_ignored      ,  0);
  rb_define_method(cContext, "resume"       , Context_resume       ,  0);
  rb_define_method(cContext, "stack_size"   , Context_stack_size   ,  0);
  rb_define_method(cContext, "step_into"    , Context_step_into    , -1);
  rb_define_method(cContext, "step_out"     , Context_step_out     ,  1);
  rb_define_method(cContext, "step_over"    , Context_step_over    , -1);
  rb_define_method(cContext, "stop_return"  , Context_stop_return  ,  1);
  rb_define_method(cContext, "stop_reason"  , Context_stop_reason  ,  0);
  rb_define_method(cContext, "suspend"      , Context_suspend      ,  0);
  rb_define_method(cContext, "suspended?"   , Context_is_suspended ,  0);
  rb_define_method(cContext, "thnum"        , Context_thnum        ,  0);
  rb_define_method(cContext, "thread"       , Context_thread       ,  0);
  rb_define_method(cContext, "tracing"      , Context_tracing      ,  0);
  rb_define_method(cContext, "tracing="     , Context_set_tracing  ,  1);

  cDebugThread  = rb_define_class_under(mByebug, "DebugThread", rb_cThread);
  rb_define_singleton_method(cDebugThread, "inherited", DebugThread_inherited, 1);
}
