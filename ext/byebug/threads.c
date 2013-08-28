#include <byebug.h>

static int
t_tbl_mark_keyvalue(st_data_t key, st_data_t value, st_data_t tbl)
{
  VALUE thread = (VALUE)key;

  if (!value) return ST_CONTINUE;

  rb_gc_mark((VALUE)value);
  rb_gc_mark(thread);

  return ST_CONTINUE;
}

static void
t_tbl_mark(void* data)
{
  threads_table_t *t_tbl = (threads_table_t *)data;
  st_table *tbl = t_tbl->tbl;
  st_foreach(tbl, t_tbl_mark_keyvalue, (st_data_t)tbl);
}

static void
t_tbl_free(void* data)
{
  threads_table_t *t_tbl = (threads_table_t*)data;
  st_free_table(t_tbl->tbl);
  xfree(t_tbl);
}

VALUE
threads_create(void)
{
  threads_table_t *t_tbl;

  t_tbl = ALLOC(threads_table_t);
  t_tbl->tbl = st_init_numtable();
  return Data_Wrap_Struct(cThreadsTable, t_tbl_mark, t_tbl_free, t_tbl);
}

void
threads_clear(VALUE table)
{
  threads_table_t *t_tbl;

  Data_Get_Struct(table, threads_table_t, t_tbl);
  st_clear(t_tbl->tbl);
}

static int
is_living_thread(VALUE thread)
{
  return rb_funcall(thread, rb_intern("alive?"), 0) == Qtrue;
}

static int
t_tbl_check_i(st_data_t key, st_data_t value, st_data_t dummy)
{
  VALUE thread;

  if (!value) return ST_DELETE;

  thread = (VALUE)key;

  if (!is_living_thread(thread)) return ST_DELETE;

  return ST_CONTINUE;
}

void
check_thread_contexts(void)
{
  threads_table_t *t_tbl;

  Data_Get_Struct(threads, threads_table_t, t_tbl);
  st_foreach(t_tbl->tbl, t_tbl_check_i, 0);
}

void
thread_context_lookup(VALUE thread, VALUE *context)
{
  threads_table_t *t_tbl;

  Data_Get_Struct(threads, threads_table_t, t_tbl);
  if (!st_lookup(t_tbl->tbl, thread, context) || !*context)
  {
    *context = context_create(thread);
    st_insert(t_tbl->tbl, thread, *context);
  }
}

void
halt_while_other_thread_is_active(debug_context_t *dc)
{
  while (1)
  {
    /* halt execution of current thread if debugger is activated in another */
    while (locker != Qnil && locker != rb_thread_current())
    {
      add_to_locked(rb_thread_current());
      rb_thread_stop();
    }

    /* stop the current thread if it's marked as suspended */
    if (CTX_FL_TEST(dc, CTX_FL_SUSPEND) && locker != rb_thread_current())
    {
      CTX_FL_SET(dc, CTX_FL_WAS_RUNNING);
      rb_thread_stop();
    }
    else break;
  }
}
