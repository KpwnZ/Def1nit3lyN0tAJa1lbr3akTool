#include <stdio.h>
#include <mach/mach.h>
#include <stdbool.h>
#include <stdlib.h>
#include <xpc/xpc.h>

typedef enum {
    JBD_MSG_KRW_READY = 1,
    JBD_MSG_KERNINFO = 2,
    JBD_MSG_KREAD32 = 3,
    JBD_MSG_KREAD64 = 4,
    JBD_MSG_KWRITE32 = 5,
    JBD_MSG_KWRITE64 = 6,
    JBD_MSG_KALLOC = 7,
    JBD_MSG_KFREE = 8,
    JBD_MSG_KCALL = 9,
    
    JBD_MSG_REBUILD_TRUSTCACHE = 10,
    JBD_MSG_PROCESS_BINARY = 11,
    JBD_MSG_INIT_ENVIRONMENT = 12,
    JBD_MSG_SETUID_FIX = 13,
    JBD_MSG_PROC_SET_DEBUGGED = 14,
    JBD_MSG_DEBUG_ME = 15,
    JBD_MSG_PLATFORMIZE = 16,
    
} JBD_MESSAGE_ID;

struct _os_alloc_once_s {
    long once;
    void *ptr;
};

extern struct _os_alloc_once_s _os_alloc_once_table[];
typedef void (*os_function_t)(void *);
extern void* _os_alloc_once(struct _os_alloc_once_s *slot, size_t sz, os_function_t init);

// typedef void * xpc_object_t;
// typedef xpc_object_t xpc_pipe_t;
// xpc_object_t xpc_array_create_empty(void);
// void xpc_dictionary_set_string(xpc_object_t xdict, const char *key, const char *string);
// xpc_object_t xpc_dictionary_create_empty(void);
// void xpc_array_set_uint64(xpc_object_t xarray, size_t index, uint64_t value);
// void xpc_array_set_string(xpc_object_t xarray, size_t index, const char *string);
// void xpc_dictionary_set_uint64(xpc_object_t xdict, const char *key, uint64_t value);
// void xpc_dictionary_set_bool(xpc_object_t xdict, const char *key, bool value);
// void xpc_dictionary_set_value(xpc_object_t xdict, const char *key, xpc_object_t _Nullable value);
// char * xpc_copy_description(xpc_object_t object);
// int64_t xpc_dictionary_get_int64(xpc_object_t xdict, const char *key);
// uint64_t xpc_dictionary_get_uint64(xpc_object_t xdict, const char *key);
// char *xpc_strerror (int);
// int xpc_pipe_routine_with_flags(xpc_pipe_t xpipe, xpc_object_t xdict, xpc_object_t* reply, uint64_t flags);
kern_return_t bootstrap_look_up(mach_port_t port, const char *service, mach_port_t *server_port);
// xpc_object_t xpc_pipe_create_from_port(mach_port_t port, uint32_t flags);
// int xpc_pipe_routine (xpc_object_t xpc_pipe, xpc_object_t inDict, xpc_object_t **out);
// void xpc_release(xpc_object_t object);

struct xpc_global_data {
    uint64_t    a;
    uint64_t    xpc_flags;
    mach_port_t    task_bootstrap_port;  /* 0x10 */
#ifndef _64
    uint32_t    padding;
#endif
    xpc_object_t    xpc_bootstrap_pipe;   /* 0x18 */
    // and there's more, but you'll have to wait for MOXiI 2 for those...
    // ...
};

#define XPC_ARRAY_APPEND ((size_t)(-1))
#define ROUTINE_LOAD   800
#define ROUTINE_UNLOAD 801

bool jbdSystemWideIsReachable(void);

mach_port_t jbdMachPort(void);
xpc_object_t sendJBDMessage(xpc_object_t xdict);

mach_port_t jbdSystemWideMachPort(void);
xpc_object_t sendLaunchdMessageFallback(xpc_object_t xdict);
xpc_object_t sendJBDMessageSystemWide(xpc_object_t xdict);

uint64_t jbdKRWReady(void); //JBD_MSG_KRW_READY = 1
int jbdKernInfo(uint64_t *_kbase, uint64_t *_kslide, uint64_t *_allproc, uint64_t *_kernproc); //JBD_MSG_KERNINFO = 2
uint32_t jbdKread32(uint64_t kaddr);    //JBD_MSG_KREAD32 = 3
uint64_t jbdKread64(uint64_t kaddr);    //JBD_MSG_KREAD64 = 4
uint64_t jbdKwrite32(uint64_t kaddr, uint32_t val); //JBD_MSG_KWRITE32 = 5
uint64_t jbdKwrite64(uint64_t kaddr, uint64_t val); //JBD_MSG_KWRITE64 = 6
uint64_t jbdKalloc(uint64_t ksize); //JBD_MSG_KALLOC = 7
uint64_t jbdKfree(uint64_t kaddr, uint64_t ksize);   //JBD_MSG_KFREE = 8
uint64_t jbdKcall(uint64_t func, uint64_t argc, const uint64_t *argv);   //JBD_MSG_DO_KCALL = 9
int64_t jbdRebuildTrustCache(void); //JBD_MSG_REBUILD_TRUSTCACHE = 10
int64_t jbdProcessBinary(const char *filePath); //JBD_MSG_PROCESS_BINARY = 11
int64_t jbdswProcessBinary(const char *filePath);    //JBD_MSG_PROCESS_BINARY = 11-1
int64_t jbdInitEnvironment(void);   //JBD_MSG_INIT_ENVIRONMENT = 12
int64_t jbdswFixSetuid(void);   //JBD_MSG_SETUID_FIX = 13
int64_t jbdProcSetDebugged(pid_t pid);  //JBD_MSG_PROC_SET_DEBUGGED = 14
int64_t jbdDebugMe(void);   //JBD_MSG_DEBUG_ME = 15
int64_t jbdPlatformize(pid_t pid);  //JBD_MSG_PLATFORMIZE = 16
int64_t jbdswPlatformize(pid_t pid);    // JBD_MSG_PLATFORMIZE = 16-1