#include <byebug.h>

#ifdef _WIN32
#include <ctype.h>
#endif

#if defined DOSISH
#define isdirsep(x) ((x) == '/' || (x) == '\\')
#else
#define isdirsep(x) ((x) == '/')
#endif

static VALUE cBreakpoint;
static int breakpoint_max;

static ID idEval;

static VALUE
eval_expression(VALUE args)
{
  return rb_funcall2(rb_mKernel, idEval, 2, RARRAY_PTR(args));
}

static VALUE
Breakpoint_hit_count(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return INT2FIX(breakpoint->hit_count);
}


static VALUE
Breakpoint_hit_value(VALUE self)
{
    breakpoint_t *breakpoint;

    Data_Get_Struct(self, breakpoint_t, breakpoint);
    return INT2FIX(breakpoint->hit_value);
}

static VALUE
Breakpoint_set_hit_value(VALUE self, VALUE value)
{
    breakpoint_t *breakpoint;

    Data_Get_Struct(self, breakpoint_t, breakpoint);
    breakpoint->hit_value = FIX2INT(value);
    return value;
}

static VALUE
Breakpoint_hit_condition(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  switch(breakpoint->hit_condition)
  {
    case HIT_COND_GE:
      return ID2SYM(rb_intern("greater_or_equal"));
    case HIT_COND_EQ:
      return ID2SYM(rb_intern("equal"));
    case HIT_COND_MOD:
      return ID2SYM(rb_intern("modulo"));
    case HIT_COND_NONE:
    default:
      return Qnil;
  }
}

static VALUE
Breakpoint_set_hit_condition(VALUE self, VALUE value)
{
  breakpoint_t *breakpoint;
  ID id_value;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  id_value = rb_to_id(value);

  if(rb_intern("greater_or_equal") == id_value || rb_intern("ge") == id_value)
    breakpoint->hit_condition = HIT_COND_GE;
  else if(rb_intern("equal") == id_value || rb_intern("eq") == id_value)
    breakpoint->hit_condition = HIT_COND_EQ;
  else if(rb_intern("modulo") == id_value || rb_intern("mod") == id_value)
    breakpoint->hit_condition = HIT_COND_MOD;
  else
    rb_raise(rb_eArgError, "Invalid condition parameter");
  return value;
}

static void
Breakpoint_mark(breakpoint_t *breakpoint)
{
  rb_gc_mark(breakpoint->source);
  rb_gc_mark(breakpoint->expr);
}

static VALUE
Breakpoint_create(VALUE klass)
{
    breakpoint_t *breakpoint;

    breakpoint = ALLOC(breakpoint_t);
    return Data_Wrap_Struct(klass, Breakpoint_mark, xfree, breakpoint);
}

static VALUE
Breakpoint_initialize(VALUE self, VALUE source, VALUE pos, VALUE expr)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);

  breakpoint->type = FIXNUM_P(pos) ? BP_POS_TYPE : BP_METHOD_TYPE;
  if(breakpoint->type == BP_POS_TYPE)
      breakpoint->pos.line = FIX2INT(pos);
  else
      breakpoint->pos.mid = SYM2ID(pos);

  breakpoint->id = ++breakpoint_max;
  breakpoint->source = StringValue(source);
  breakpoint->enabled = Qtrue;
  breakpoint->expr = NIL_P(expr) ? expr : StringValue(expr);
  breakpoint->hit_count = 0;
  breakpoint->hit_value = 0;
  breakpoint->hit_condition = HIT_COND_NONE;

  return Qnil;
}

static VALUE
Breakpoint_remove(VALUE self, VALUE breakpoints, VALUE id_value)
{
  int i;
  int id;
  VALUE breakpoint_object;
  breakpoint_t *breakpoint;

  if (breakpoints == Qnil) return Qnil;

  id = FIX2INT(id_value);

  for(i = 0; i < RARRAY_LEN(breakpoints); i++)
  {
    breakpoint_object = rb_ary_entry(breakpoints, i);
    Data_Get_Struct(breakpoint_object, breakpoint_t, breakpoint);
    if(breakpoint->id == id)
    {
      rb_ary_delete_at(breakpoints, i);
      return breakpoint_object;
    }
  }
  return Qnil;
}

static VALUE
Breakpoint_id(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return INT2FIX(breakpoint->id);
}

static VALUE
Breakpoint_source(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return breakpoint->source;
}

static VALUE
Breakpoint_pos(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  if(breakpoint->type == BP_METHOD_TYPE)
      return rb_str_new2(rb_id2name(breakpoint->pos.mid));
  else
      return INT2FIX(breakpoint->pos.line);
}


static VALUE
Breakpoint_expr(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return breakpoint->expr;
}

static VALUE
Breakpoint_set_expr(VALUE self, VALUE expr)
{
    breakpoint_t *breakpoint;

    Data_Get_Struct(self, breakpoint_t, breakpoint);
    breakpoint->expr = NIL_P(expr) ? expr: StringValue(expr);
    return expr;
}

static VALUE
Breakpoint_enabled(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return breakpoint->enabled;
}

static VALUE
Breakpoint_set_enabled(VALUE self, VALUE bool)
{
    breakpoint_t *breakpoint;

    Data_Get_Struct(self, breakpoint_t, breakpoint);
    return breakpoint->enabled = bool;
}

int
filename_cmp_impl(VALUE source, char *file)
{
  char *source_ptr, *file_ptr;
  long s_len, f_len, min_len;
  long s,f;
  int dirsep_flag = 0;

  s_len = RSTRING_LEN(source);
  f_len = strlen(file);
  min_len = s_len < f_len ? s_len : f_len;

  source_ptr = RSTRING_PTR(source);
  file_ptr   = file;

  for( s = s_len - 1, f = f_len - 1; s >= s_len - min_len && f >= f_len - min_len; s--, f-- )
  {
    if((source_ptr[s] == '.' || file_ptr[f] == '.') && dirsep_flag)
      return 1;
    if(isdirsep(source_ptr[s]) && isdirsep(file_ptr[f]))
      dirsep_flag = 1;
#ifdef DOSISH_DRIVE_LETTER
    else if (s == 0)
      return(toupper(source_ptr[s]) == toupper(file_ptr[f]));
#endif
    else if(source_ptr[s] != file_ptr[f])
      return 0;
  }
  return 1;
}

int
filename_cmp(VALUE source, char *file)
{
#ifdef _WIN32
  return filename_cmp_impl(source, file);
#else
#ifdef PATH_MAX
  char path[PATH_MAX + 1];
  path[PATH_MAX] = 0;
  return filename_cmp_impl(source, realpath(file, path) != NULL ? path : file);
#else
  char *path;
  int result;
  path = realpath(file, NULL);
  result = filename_cmp_impl(source, path == NULL ? file : path);
  free(path);
  return result;
#endif
#endif
}

static int
check_breakpoint_by_hit_condition(VALUE breakpoint_object)
{
  breakpoint_t *breakpoint;

  if (breakpoint_object == Qnil)
    return 0;
  Data_Get_Struct(breakpoint_object, breakpoint_t, breakpoint);

  breakpoint->hit_count++;

  if (Qtrue != breakpoint->enabled)
    return 0;

  switch (breakpoint->hit_condition)
  {
    case HIT_COND_NONE:
      return 1;
    case HIT_COND_GE:
    {
      if (breakpoint->hit_count >= breakpoint->hit_value)
        return 1;
      break;
    }
    case HIT_COND_EQ:
    {
      if (breakpoint->hit_count == breakpoint->hit_value)
        return 1;
      break;
    }
    case HIT_COND_MOD:
    {
      if (breakpoint->hit_count % breakpoint->hit_value == 0)
        return 1;
      break;
    }
  }
  return 0;
}

static int
check_breakpoint_by_pos(VALUE breakpoint_object, char *file, int line)
{
    breakpoint_t *breakpoint;

    if(breakpoint_object == Qnil)
        return 0;
    Data_Get_Struct(breakpoint_object, breakpoint_t, breakpoint);

    if (Qtrue != breakpoint->enabled)
        return 0;
    if(breakpoint->type != BP_POS_TYPE)
        return 0;
    if(breakpoint->pos.line != line)
        return 0;
    if(filename_cmp(breakpoint->source, file))
        return 1;
    return 0;
}

static int
check_breakpoint_by_method(VALUE breakpoint_object, VALUE klass, ID mid,
                           VALUE self)
{
  breakpoint_t *breakpoint;

  if (breakpoint_object == Qnil)
    return 0;
  Data_Get_Struct(breakpoint_object, breakpoint_t, breakpoint);

  if (!Qtrue == breakpoint->enabled)
    return 0;
  if (breakpoint->type != BP_METHOD_TYPE)
    return 0;
  if (breakpoint->pos.mid != mid)
    return 0;
  if (classname_cmp(breakpoint->source, klass))
    return 1;
  if ((rb_type(self) == T_CLASS) && classname_cmp(breakpoint->source, self))
    return 1;
  return 0;
}

static int
check_breakpoint_by_expr(VALUE breakpoint_object, VALUE binding)
{
  breakpoint_t *breakpoint;
  VALUE args, expr_result;

  if (breakpoint_object == Qnil)
    return 0;
  Data_Get_Struct(breakpoint_object, breakpoint_t, breakpoint);

  if (Qtrue != breakpoint->enabled)
    return 0;
  if (NIL_P(breakpoint->expr))
    return 1;
  args = rb_ary_new3(2, breakpoint->expr, binding);
  expr_result = rb_protect(eval_expression, args, 0);
  return RTEST(expr_result);
}

extern VALUE
find_breakpoint_by_pos(VALUE breakpoints, VALUE source, VALUE pos,
                       VALUE binding)
{
  VALUE breakpoint_object;
  char *file;
  int line;
  int i;

  file = RSTRING_PTR(source);
  line = FIX2INT(pos);
  for(i = 0; i < RARRAY_LEN(breakpoints); i++)
  {
    breakpoint_object = rb_ary_entry(breakpoints, i);
    if ( check_breakpoint_by_pos(breakpoint_object, file, line) &&
         check_breakpoint_by_expr(breakpoint_object, binding)   &&
         check_breakpoint_by_hit_condition(breakpoint_object) )
    {
      return breakpoint_object;
    }
  }
  return Qnil;
}

extern VALUE
find_breakpoint_by_method(VALUE breakpoints, VALUE klass, ID mid, VALUE binding,
                          VALUE self)
{
  VALUE breakpoint_object;
  int i;

  for(i = 0; i < RARRAY_LEN(breakpoints); i++)
  {
    breakpoint_object = rb_ary_entry(breakpoints, i);
    if ( check_breakpoint_by_method(breakpoint_object, klass, mid, self) &&
         check_breakpoint_by_expr(breakpoint_object, binding)            &&
         check_breakpoint_by_hit_condition(breakpoint_object) )
      return breakpoint_object;
  }
  return Qnil;
}

extern void
Init_breakpoint(VALUE mByebug)
{
  breakpoint_max = 0;
  cBreakpoint = rb_define_class_under(mByebug, "Breakpoint", rb_cObject);
  rb_define_singleton_method(cBreakpoint, "remove", Breakpoint_remove, 2);
  rb_define_method(cBreakpoint, "initialize", Breakpoint_initialize, 3);
  rb_define_method(cBreakpoint, "id", Breakpoint_id, 0);
  rb_define_method(cBreakpoint, "source", Breakpoint_source, 0);
  rb_define_method(cBreakpoint, "pos", Breakpoint_pos, 0);
  rb_define_method(cBreakpoint, "expr", Breakpoint_expr, 0);
  rb_define_method(cBreakpoint, "expr=", Breakpoint_set_expr, 1);
  rb_define_method(cBreakpoint, "hit_count", Breakpoint_hit_count, 0);
  rb_define_method(cBreakpoint, "hit_condition", Breakpoint_hit_condition, 0);
  rb_define_method(cBreakpoint, "hit_condition=", Breakpoint_set_hit_condition, 1);
  rb_define_method(cBreakpoint, "enabled?", Breakpoint_enabled, 0);
  rb_define_method(cBreakpoint, "enabled=", Breakpoint_set_enabled, 1);
  rb_define_method(cBreakpoint, "hit_value", Breakpoint_hit_value, 0);
  rb_define_method(cBreakpoint, "hit_value=", Breakpoint_set_hit_value, 1);
  rb_define_alloc_func(cBreakpoint, Breakpoint_create);

  idEval = rb_intern("eval");
}
