#ifndef BYEBUG
#define BYEBUG

#include <ruby.h>
#include <ruby/debug.h>

/* flags */
#define CTX_FL_SUSPEND      (1<<1)
#define CTX_FL_TRACING      (1<<2)
#define CTX_FL_SKIPPED      (1<<3)
#define CTX_FL_DEAD         (1<<4)
#define CTX_FL_ENABLE_BKPT  (1<<5)
#define CTX_FL_FORCE_MOVE   (1<<6)
#define CTX_FL_CATCHING     (1<<7)

/* macro functions */
#define CTX_FL_TEST(c,f)  ((c)->flags & (f))
#define CTX_FL_SET(c,f)   do { (c)->flags |= (f); } while (0)
#define CTX_FL_UNSET(c,f) do { (c)->flags &= ~(f); } while (0)

/* types */
typedef enum {
  CTX_STOP_NONE,
  CTX_STOP_STEP,
  CTX_STOP_BREAKPOINT,
  CTX_STOP_CATCHPOINT
} ctx_stop_reason;

typedef struct {
  int stack_size;
  int flags;
  ctx_stop_reason stop_reason;

  int dest_frame;
  int lines;                   /* # of lines in dest_frame before stopping    */
  int steps;                   /* # of steps before stopping                  */
  int after_frame;             /* stop rigth after returning from this frame  */
  int before_frame;            /* stop right before returning from this frame */

  VALUE last_file;
  VALUE last_line;

  VALUE backtrace;             /* [[loc, self, klass, binding], ...] */
} debug_context_t;

enum frame_component { LOCATION, SELF, CLASS, BINDING };

struct call_with_inspection_data {
  debug_context_t *dc;
  VALUE context_obj;
  ID id;
  int argc;
  VALUE *argv;
};


/* functions */
extern void Init_context(VALUE mByebug);
extern VALUE context_create();
extern VALUE context_dup(debug_context_t *context);
extern void reset_stepping_stop_points(debug_context_t *context);
extern VALUE call_with_debug_inspector(struct call_with_inspection_data *data);
extern VALUE context_backtrace_set(const rb_debug_inspector_t *inspector,
                                   void *data);

static inline int
classname_cmp(VALUE name, VALUE klass)
{
    VALUE mod_name;
    VALUE class_name = (Qnil == name) ? rb_str_new2("main") : name;
    if (klass == Qnil) return(0);
    mod_name = rb_mod_name(klass);
    return (mod_name != Qnil && rb_str_cmp(class_name, mod_name) == 0);
}

/* breakpoints & catchpoints */
enum bp_type { BP_POS_TYPE, BP_METHOD_TYPE };

enum hit_condition { HIT_COND_NONE, HIT_COND_GE, HIT_COND_EQ, HIT_COND_MOD };

typedef struct {
  int id;
  enum bp_type type;
  VALUE source;
  union
  {
    int line;
    ID  mid;
  } pos;
  VALUE expr;
  VALUE enabled;
  int hit_count;
  int hit_value;
  enum hit_condition hit_condition;
} breakpoint_t;

extern VALUE catchpoint_hit_count(VALUE catchpoints, VALUE exception, VALUE *exception_name);
extern VALUE find_breakpoint_by_pos(VALUE breakpoints, VALUE source, VALUE pos,
                                    VALUE binding);
extern VALUE find_breakpoint_by_method(VALUE breakpoints, VALUE klass,
                                       VALUE mid, VALUE binding, VALUE self);
extern void Init_breakpoint(VALUE mByebug);

#endif
