#include <byebug.h>

static VALUE cContext;

/* "Step", "Next" and "Finish" do their work by saving information about where
 * to stop next. reset_stepping_stop_points removes/resets this information. */
extern void
reset_stepping_stop_points(debug_context_t *context)
{
  context->dest_frame = -1;
  context->lines      = -1;
  context->steps      = -1;
  context->stop_frame = -1;
}

static inline void
delete_frame(debug_context_t *context)
{
  debug_frame_t *frame;

  frame = context->stack;
  context->stack = frame->prev;
  context->stack_size--;
  xfree(frame);
}

extern void
update_frame(debug_frame_t *frame, char* file, int lineno, VALUE method_id,
                                   VALUE defined_class, VALUE binding, VALUE self)
{
  frame->file = file;
  frame->line = lineno;
  frame->method_id = method_id;
  frame->defined_class = defined_class;
  frame->binding = binding;
  frame->self = self;
}

static inline VALUE
Context_stack_size(VALUE self)
{
  debug_context_t *context;
  Data_Get_Struct(self, debug_context_t, context);
  return INT2FIX(context->stack_size);
}

static inline VALUE
Context_dead(VALUE self)
{
  debug_context_t *context;
  Data_Get_Struct(self, debug_context_t, context);
  return CTX_FL_TEST(context, CTX_FL_DEAD) ? Qtrue : Qfalse;
}

extern void
push_frame(debug_context_t *context, char* file, int lineno, VALUE method_id,
           VALUE defined_class, VALUE binding, VALUE self)
{
  debug_frame_t *frame;

  frame = ALLOC(debug_frame_t);
  update_frame(frame, file, lineno, method_id, defined_class, binding, self);
  frame->prev = context->stack;
  context->stack = frame;
  context->stack_size++;
}

extern void
pop_frame(debug_context_t *context)
{
  if (context->stack_size > 0) {
    delete_frame(context);
  }
}

static void
Context_mark(debug_context_t *context)
{
  debug_frame_t *frame;

  frame = context->stack;
  while (frame != NULL) {
    rb_gc_mark(frame->self);
    rb_gc_mark(frame->binding);
    frame = frame->prev;
  }
}

static void
Context_free(debug_context_t *context) {
  while (context->stack_size > 0) {
    delete_frame(context);
  }
  xfree(context);
}

extern VALUE
Context_create()
{
  debug_context_t *context;

  context = ALLOC(debug_context_t);
  context->stack_size = 0;
  context->stack = NULL;
  context->flags = 0;
  context->last_file = NULL;
  context->last_line = -1;
  reset_stepping_stop_points(context);
  return Data_Wrap_Struct(cContext, Context_mark, Context_free, context);
}

static void
frame_copy(debug_frame_t *new_frame, debug_frame_t *old_frame)
{
  new_frame->file          = old_frame->file;
  new_frame->line          = old_frame->line;
  new_frame->method_id     = old_frame->method_id;
  new_frame->defined_class = old_frame->defined_class;
  new_frame->binding       = old_frame->binding;
  new_frame->self          = old_frame->self;
}

extern VALUE
Context_dup(debug_context_t *context)
{
    debug_context_t *new_context;
    debug_frame_t *source_frame = context->stack, *dest_frame, *new_frame;

    new_context = ALLOC(debug_context_t);
    memcpy(new_context, context, sizeof(debug_context_t));
    reset_stepping_stop_points(new_context);
    new_context->stack_size = context->stack_size;
    CTX_FL_SET(new_context, CTX_FL_DEAD);
    new_context->stack = ALLOC(debug_frame_t);
    frame_copy(new_context->stack, context->stack);

    new_frame = new_context->stack;
    while ((source_frame = source_frame->prev))
    {
      dest_frame = new_frame;
      new_frame = ALLOC(debug_frame_t);
      frame_copy(new_frame, source_frame);
      dest_frame->prev = new_frame;
    }
    return Data_Wrap_Struct(cContext, 0, Context_free, new_context);
}

static debug_frame_t*
get_frame_no(debug_context_t *context, int frame_n)
{
  debug_frame_t *frame;
  int i;

  if (frame_n < 0 || frame_n >= context->stack_size) {
    rb_raise(rb_eArgError, "Invalid frame number %d, stack (0...%d)",
        frame_n, context->stack_size);
  }

  frame = context->stack;
  for (i = 0; i < frame_n; i++) {
    frame = frame->prev;
  }
  return frame;
}

static VALUE
Context_frame_file(int argc, VALUE *argv, VALUE self)
{
  debug_context_t *context;
  debug_frame_t *frame;
  VALUE frame_no;
  int frame_n;

  Data_Get_Struct(self, debug_context_t, context);
  frame_n = rb_scan_args(argc, argv, "01", &frame_no) == 0 ? 0 : FIX2INT(frame_no);
  frame = get_frame_no(context, frame_n);
  return rb_str_new2(frame->file);
}

static VALUE
Context_frame_line(int argc, VALUE *argv, VALUE self)
{
  debug_context_t *context;
  debug_frame_t *frame;
  VALUE frame_no;
  int frame_n;

  Data_Get_Struct(self, debug_context_t, context);
  frame_n = rb_scan_args(argc, argv, "01", &frame_no) == 0 ? 0 : FIX2INT(frame_no);
  frame = get_frame_no(context, frame_n);
  return INT2FIX(frame->line);
}

static VALUE
Context_frame_method(int argc, VALUE *argv, VALUE self)
{
  debug_context_t *context;
  debug_frame_t *frame;
  VALUE frame_no;
  int frame_n;

  Data_Get_Struct(self, debug_context_t, context);
  frame_n = rb_scan_args(argc, argv, "01", &frame_no) == 0 ? 0 : FIX2INT(frame_no);
  frame = get_frame_no(context, frame_n);
  return frame->method_id;
}

static VALUE
Context_frame_binding(int argc, VALUE *argv, VALUE self)
{
  debug_context_t *context;
  debug_frame_t *frame;
  VALUE frame_no;
  int frame_n;

  Data_Get_Struct(self, debug_context_t, context);
  frame_n = rb_scan_args(argc, argv, "01", &frame_no) == 0 ? 0 : FIX2INT(frame_no);
  frame = get_frame_no(context, frame_n);
  return frame->binding;
}

static VALUE
Context_frame_self(int argc, VALUE *argv, VALUE self)
{
  debug_context_t *context;
  debug_frame_t *frame;
  VALUE frame_no;
  int frame_n;

  Data_Get_Struct(self, debug_context_t, context);
  frame_n = rb_scan_args(argc, argv, "01", &frame_no) == 0 ? 0 : FIX2INT(frame_no);
  frame = get_frame_no(context, frame_n);
  return frame->self;
}

static VALUE
Context_frame_class(int argc, VALUE *argv, VALUE self)
{
  debug_context_t *context;
  debug_frame_t *frame;
  VALUE frame_no;
  int frame_n;

  Data_Get_Struct(self, debug_context_t, context);
  frame_n = rb_scan_args(argc, argv, "01", &frame_no) == 0 ? 0 : FIX2INT(frame_no);
  frame = get_frame_no(context, frame_n);
  return frame->defined_class;
}

static VALUE
Context_tracing(VALUE self)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);
  return CTX_FL_TEST(context, CTX_FL_TRACING) ? Qtrue : Qfalse;
}

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

#if 0

static VALUE
Context_jump(VALUE self, VALUE line, VALUE file)
{
  debug_context_t *context;
  debug_frame_t *frame;
  int i, lineno;

  Data_Get_Struct(self, debug_context_t, context);

  frame = context->stack;
  lineno = FIX2INT(line);

  for (i = 0; i < context->stack_size; i++) {
    if (strcmp(frame->file, RSTRING_PTR(file))) {
      /* And now? */
    }
    frame = frame->prev;
  }
}

#endif

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

  if(RTEST(force))
      CTX_FL_SET(context, CTX_FL_FORCE_MOVE);
  else
      CTX_FL_UNSET(context, CTX_FL_FORCE_MOVE);

  return steps;
}

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

  if (FIX2INT(frame) < 0 && FIX2INT(frame) >= context->stack_size)
    rb_raise(rb_eRuntimeError, "Destination frame is out of range.");
  context->dest_frame = context->stack_size - FIX2INT(frame);

  if (RTEST(force))
    CTX_FL_SET(context, CTX_FL_FORCE_MOVE);
  else
    CTX_FL_UNSET(context, CTX_FL_FORCE_MOVE);

  return Qnil;
}

static VALUE
Context_step_out(VALUE self, VALUE frame)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);
  if (FIX2INT(frame) < 0 && FIX2INT(frame) >= context->stack_size)
    rb_raise(rb_eRuntimeError, "Stop frame is out of range.");

  context->stop_frame = context->stack_size - FIX2INT(frame);

  return frame;
}

/*
 *   Document-class: Context
 *
 *   == Summary
 *
 *   Byebug keeps a single instance of this class.
 */
VALUE
Init_context(VALUE mByebug)
{
  cContext = rb_define_class_under(mByebug, "Context", rb_cObject);
  rb_define_method(cContext, "stack_size", Context_stack_size, 0);
  rb_define_method(cContext, "dead?", Context_dead, 0);
  rb_define_method(cContext, "stop_reason", Context_stop_reason, 0);
  rb_define_method(cContext, "tracing", Context_tracing, 0);
  rb_define_method(cContext, "tracing=", Context_set_tracing, 1);
  rb_define_method(cContext, "frame_file", Context_frame_file, -1);
  rb_define_method(cContext, "frame_line", Context_frame_line, -1);
  rb_define_method(cContext, "frame_method", Context_frame_method, -1);
  rb_define_method(cContext, "frame_binding", Context_frame_binding, -1);
  rb_define_method(cContext, "frame_self", Context_frame_self, -1);
  rb_define_method(cContext, "frame_class", Context_frame_class, -1);
  rb_define_method(cContext, "step_into", Context_step_into, -1);
  rb_define_method(cContext, "step_over", Context_step_over, -1);
  rb_define_method(cContext, "step_out", Context_step_out, 1);

  return cContext;
}
