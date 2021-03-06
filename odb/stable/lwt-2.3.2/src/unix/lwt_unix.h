/* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Header lwt_unix
 * Copyright (C) 2010 Jérémie Dimino
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later
 * version. See COPYING file for details.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 */

#ifndef __LWT_UNIX_H
#define __LWT_UNIX_H

#include <caml/mlvalues.h>
#include <caml/unixsupport.h>

/* Detect the target OS */
#if defined(_WIN32) || defined(_WIN64)
#  define LWT_ON_WINDOWS
#endif

/* The macro to get the file-descriptor from a value. */
#if defined(LWT_ON_WINDOWS)
#  define FD_val(value) win_CRT_fd_of_filedescr(value)
#else
#  define FD_val(value) Int_val(value)
#endif

/* Macro to extract a libev loop from a caml value. */
#define Ev_loop_val(value) *(struct ev_loop**)Data_custom_val(value)

/* +-----------------------------------------------------------------+
   | Utils                                                           |
   +-----------------------------------------------------------------+ */

/* Allocate the given amount of memory and abort the program if there
   is no free memory left. */
void *lwt_unix_malloc(size_t size);

/* Same as [strdup] and abort hte program if there is not memory
   left. */
char *lwt_unix_strdup(char *string);

/* Helper for allocating structures. */
#define lwt_unix_new(type) (type*)lwt_unix_malloc(sizeof(type))

/* Raise [Lwt_unix.Not_available]. */
void lwt_unix_not_available(char const *feature) Noreturn;

/* +-----------------------------------------------------------------+
   | Notifications                                                   |
   +-----------------------------------------------------------------+ */

/* Sends a notification for the given id. */
void lwt_unix_send_notification(int id);

/* +-----------------------------------------------------------------+
   | Threading                                                       |
   +-----------------------------------------------------------------+ */

#if defined(LWT_ON_WINDOWS)

typedef DWORD lwt_unix_thread;
typedef CRITICAL_SECTION lwt_unix_mutex;
typedef struct lwt_unix_condition lwt_unix_condition;

#else

#include <pthread.h>

typedef pthread_t lwt_unix_thread;
typedef pthread_mutex_t lwt_unix_mutex;
typedef pthread_cond_t lwt_unix_condition;

#endif

/* Launch a thread in detached mode. */
void lwt_unix_launch_thread(void* (*start)(void*), void* data);

/* Return a handle to the currently running thread. */
lwt_unix_thread lwt_unix_thread_self();

/* Returns whether two thread handles refer to the same thread. */
int lwt_unix_thread_equal(lwt_unix_thread thread1, lwt_unix_thread thread2);

/* Initialises a mutex. */
void lwt_unix_mutex_init(lwt_unix_mutex *mutex);

/* Destroy a mutex. */
void lwt_unix_mutex_destroy(lwt_unix_mutex *mutex);

/* Lock a mutex. */
void lwt_unix_mutex_lock(lwt_unix_mutex *mutex);

/* Unlock a mutex. */
void lwt_unix_mutex_unlock(lwt_unix_mutex *mutex);

/* Initialises a condition variable. */
void lwt_unix_condition_init(lwt_unix_condition *condition);

/* Destroy a condition variable. */
void lwt_unix_condition_destroy(lwt_unix_condition *condition);

/* Signal a condition variable. */
void lwt_unix_condition_signal(lwt_unix_condition *condition);

/* Broadcast a signal on a condition variable. */
void lwt_unix_condition_broadcast(lwt_unix_condition *condition);

/* Wait for a signal on a condition variable. */
void lwt_unix_condition_wait(lwt_unix_condition *condition, lwt_unix_mutex *mutex);

/* +-----------------------------------------------------------------+
   | Detached jobs                                                   |
   +-----------------------------------------------------------------+ */

/* How job are executed. */
enum lwt_unix_async_method {
  /* Synchronously. */
  LWT_UNIX_ASYNC_METHOD_NONE = 0,

  /* Asynchronously, on another thread. */
  LWT_UNIX_ASYNC_METHOD_DETACH = 1,

  /* Asynchronously, on the main thread, switcing to another thread if
     necessary. */
  LWT_UNIX_ASYNC_METHOD_SWITCH = 2
};

/* Type of job execution modes. */
typedef enum lwt_unix_async_method lwt_unix_async_method;

/* State of a job. */
enum lwt_unix_job_state {
  /* The job has not yet started. */
  LWT_UNIX_JOB_STATE_PENDING,

  /* The job is running. */
  LWT_UNIX_JOB_STATE_RUNNING,

  /* The job is done. */
  LWT_UNIX_JOB_STATE_DONE,

  /* The job has been canceled. */
  LWT_UNIX_JOB_STATE_CANCELED
};

/* A job descriptor. */
struct lwt_unix_job {
  /* The next job in the queue. */
  struct lwt_unix_job *next;

  /* Id used to notify the main thread in case the job do not
     terminate immediatly. */
  int notification_id;

  /* The function to call to do the work. */
  void (*worker)(struct lwt_unix_job *job);

  /* State of the job. */
  enum lwt_unix_job_state state;

  /* Is the main thread still waiting for the job ? */
  int fast;

  /* Mutex to protect access to [state] and [fast]. */
  lwt_unix_mutex mutex;

  /* Thread running the job. */
  lwt_unix_thread thread;

  /* The async method in used by the job. */
  lwt_unix_async_method async_method;
};

/* Type of job descriptors. */
typedef struct lwt_unix_job* lwt_unix_job;

/* Type of worker functions. */
typedef void (*lwt_unix_job_worker)(lwt_unix_job job);

/* Allocate a caml custom value for the given job. */
value lwt_unix_alloc_job(lwt_unix_job job);

/* Free resourecs allocated for this job and free it. */
void lwt_unix_free_job(lwt_unix_job job);

/* Define not implement methods. */
#define LWT_UNIX_JOB_NOT_IMPLEMENTED(name)      \
  CAMLprim value lwt_unix_##name##_job()        \
  {                                             \
    caml_invalid_argument("not implemented");	\
  }                                             \
                                                \
  CAMLprim value lwt_unix_##name##_result()     \
  {                                             \
    caml_invalid_argument("not implemented");	\
  }                                             \
                                                \
  CAMLprim value lwt_unix_##name##_free()       \
  {                                             \
    caml_invalid_argument("not implemented");	\
  }


#endif /* __LWT_UNIX_H */
