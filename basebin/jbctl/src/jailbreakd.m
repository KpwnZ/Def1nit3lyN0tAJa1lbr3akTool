#include "jailbreakd.h"
#import <stdlib.h>
#import <string.h>
#import <sys/mount.h>
#import <unistd.h>
#import "sandbox.h"

bool jbdSystemWideIsReachable(void) {
    int sbc = sandbox_check(getpid(), "mach-lookup",
                            SANDBOX_FILTER_GLOBAL_NAME | SANDBOX_CHECK_NO_REPORT,
                            "com.xia0o0o0o.jailbreakd.systemwide");
    return sbc == 0;
}

mach_port_t jbdMachPort(void) {
    mach_port_t outPort = -1;

    if (getpid() == 1) {
        mach_port_t self_host = mach_host_self();
        host_get_special_port(self_host, HOST_LOCAL_NODE, 16, &outPort);
        mach_port_deallocate(mach_task_self(), self_host);
    } else {
        bootstrap_look_up(bootstrap_port, "com.xia0o0o0o.jailbreakd", &outPort);
    }

    return outPort;
}

xpc_object_t sendJBDMessage(xpc_object_t xdict) {
    xpc_object_t xreply = NULL;
    mach_port_t jbdPort = jbdMachPort();
    if (jbdPort != -1) {
        xpc_object_t pipe = xpc_pipe_create_from_port(jbdPort, 0);
        if (pipe) {
            int err = xpc_pipe_routine(pipe, xdict, &xreply);
            if (err != 0) {
                printf("xpc_pipe_routine error on sending message to jailbreakd: %d / "
                       "%s\n",
                       err, xpc_strerror(err));
                xreply = NULL;
            };
        }
        mach_port_deallocate(mach_task_self(), jbdPort);
    }
    return xreply;
}

mach_port_t jbdSystemWideMachPort(void) {
    mach_port_t outPort = MACH_PORT_NULL;
    kern_return_t kr = KERN_SUCCESS;

    if (getpid() == 1) {
        mach_port_t self_host = mach_host_self();
        kr = host_get_special_port(self_host, HOST_LOCAL_NODE, 16, &outPort);
        mach_port_deallocate(mach_task_self(), self_host);
    } else {
        kr = bootstrap_look_up(bootstrap_port, "com.xia0o0o0o.jailbreakd.systemwide",
                               &outPort);
    }

    if (kr != KERN_SUCCESS)
        return MACH_PORT_NULL;
    return outPort;
}

xpc_object_t sendLaunchdMessageFallback(xpc_object_t xdict) {
    xpc_dictionary_set_bool(xdict, "jailbreak", true);
    xpc_dictionary_set_bool(xdict, "jailbreak-systemwide", true);

    void *pipePtr = NULL;
    if (_os_alloc_once_table[1].once == -1) {
        pipePtr = _os_alloc_once_table[1].ptr;
    } else {
        pipePtr = _os_alloc_once(&_os_alloc_once_table[1], 472, NULL);
        if (!pipePtr)
            _os_alloc_once_table[1].once = -1;
    }

    xpc_object_t xreply = NULL;
    if (pipePtr) {
        struct xpc_global_data *globalData = pipePtr;
        xpc_object_t pipe = globalData->xpc_bootstrap_pipe;
        if (pipe) {
            int err = xpc_pipe_routine_with_flags(pipe, xdict, &xreply, 0);
            if (err != 0) {
                return NULL;
            }
        }
    }
    return xreply;
}

xpc_object_t sendJBDMessageSystemWide(xpc_object_t xdict) {
    xpc_object_t jbd_xreply = NULL;
    if (jbdSystemWideIsReachable()) {
        mach_port_t jbdPort = jbdSystemWideMachPort();
        if (jbdPort != -1) {
            xpc_object_t pipe = xpc_pipe_create_from_port(jbdPort, 0);
            if (pipe) {
                int err = xpc_pipe_routine(pipe, xdict, &jbd_xreply);
                if (err != 0)
                    jbd_xreply = NULL;
            }
            mach_port_deallocate(mach_task_self(), jbdPort);
        }
    }

    if (!jbd_xreply && getpid() != 1) {
        return sendLaunchdMessageFallback(xdict);
    }

    return jbd_xreply;
}

// JBD_MSG_KRW_READY = 1
uint64_t jbdKRWReady(void) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_KRW_READY);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;

    return xpc_dictionary_get_uint64(reply, "krw_ready");
}

// JBD_MSG_KERNINFO = 2
int jbdKernInfo(uint64_t *_kbase, uint64_t *_kslide, uint64_t *_allproc,
                uint64_t *_kernproc) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_KERNINFO);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;

    uint64_t kbase = xpc_dictionary_get_uint64(reply, "kbase");
    uint64_t kslide = xpc_dictionary_get_uint64(reply, "kslide");
    uint64_t allproc = xpc_dictionary_get_uint64(reply, "allproc");
    uint64_t kernproc = xpc_dictionary_get_uint64(reply, "kernproc");

    *_kbase = kbase;
    *_kslide = kslide;
    *_allproc = allproc;
    *_kernproc = kernproc;

    return 0;
}

// JBD_MSG_KREAD32 = 3
uint32_t jbdKread32(uint64_t kaddr) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_KREAD32);
    xpc_dictionary_set_uint64(message, "kaddr", kaddr);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;

    return (uint32_t)xpc_dictionary_get_uint64(reply, "ret");
}

// JBD_MSG_KREAD64 = 4
uint64_t jbdKread64(uint64_t kaddr) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_KREAD64);
    xpc_dictionary_set_uint64(message, "kaddr", kaddr);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;

    return xpc_dictionary_get_uint64(reply, "ret");
}

// JBD_MSG_KWRITE32 = 5
uint64_t jbdKwrite32(uint64_t kaddr, uint32_t val) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_KWRITE32);
    xpc_dictionary_set_uint64(message, "kaddr", kaddr);
    xpc_dictionary_set_uint64(message, "val", val);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;

    return xpc_dictionary_get_uint64(reply, "ret");
}

// JBD_MSG_KWRITE64 = 6
uint64_t jbdKwrite64(uint64_t kaddr, uint64_t val) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_KWRITE64);
    xpc_dictionary_set_uint64(message, "kaddr", kaddr);
    xpc_dictionary_set_uint64(message, "val", val);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;

    return xpc_dictionary_get_uint64(reply, "ret");
}

// JBD_MSG_KALLOC = 7
uint64_t jbdKalloc(uint64_t ksize) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_KALLOC);
    xpc_dictionary_set_uint64(message, "ksize", ksize);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;

    return xpc_dictionary_get_uint64(reply, "ret");
}

// JBD_MSG_KFREE = 8
uint64_t jbdKfree(uint64_t kaddr, uint64_t ksize) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_KFREE);
    xpc_dictionary_set_uint64(message, "kaddr", kaddr);
    xpc_dictionary_set_uint64(message, "ksize", ksize);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;

    return xpc_dictionary_get_uint64(reply, "ret");
}

// JBD_MSG_DO_KCALL = 9
uint64_t jbdKcall(uint64_t func, uint64_t argc, const uint64_t *argv) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_KCALL);
    xpc_dictionary_set_uint64(message, "kaddr", func);

    xpc_object_t args = xpc_array_create_empty();
    for (uint64_t i = 0; i < argc; i++) {
        xpc_array_set_uint64(args, XPC_ARRAY_APPEND, argv[i]);
    }
    xpc_dictionary_set_value(message, "args", args);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;
    return xpc_dictionary_get_uint64(reply, "ret");
}

// JBD_MSG_REBUILD_TRUSTCACHE = 10
int64_t jbdRebuildTrustCache(void) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_REBUILD_TRUSTCACHE);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;
    return xpc_dictionary_get_int64(reply, "ret");
}

// JBD_MSG_PROCESS_BINARY = 11
int64_t jbdProcessBinary(const char *filePath) {
    // if file doesn't exist, bail out
    if (access(filePath, F_OK) != 0)
        return 0;

    // if file is on rootfs mount point, it doesn't need to be
    // processed as it's guaranteed to be in static trust cache
    // same goes for our /usr/lib bind mount
    struct statfs fs;
    int sfsret = statfs(filePath, &fs);
    if (sfsret == 0) {
        if (!strcmp(fs.f_mntonname, "/") || !strcmp(fs.f_mntonname, "/usr/lib"))
            return -1;
    }

    char absolutePath[PATH_MAX];
    if (realpath(filePath, absolutePath) == NULL)
        return -1;

    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_PROCESS_BINARY);
    xpc_dictionary_set_string(message, "filePath", absolutePath);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;
    return xpc_dictionary_get_int64(reply, "ret");
    ;
}

// JBD_MSG_PROCESS_BINARY = 11 - 1
int64_t jbdswProcessBinary(const char *filePath) {
    // if file doesn't exist, bail out
    if (access(filePath, F_OK) != 0)
        return 0;

    // if file is on rootfs mount point, it doesn't need to be
    // processed as it's guaranteed to be in static trust cache
    // same goes for our /usr/lib bind mount (which is guaranteed to be in dynamic
    // trust cache)
    struct statfs fs;
    int sfsret = statfs(filePath, &fs);
    if (sfsret == 0) {
        if (!strcmp(fs.f_mntonname, "/") || !strcmp(fs.f_mntonname, "/usr/lib"))
            return -1;
    }

    char absolutePath[PATH_MAX];
    if (realpath(filePath, absolutePath) == NULL)
        return -1;

    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_PROCESS_BINARY);
    xpc_dictionary_set_string(message, "filePath", absolutePath);

    xpc_object_t reply = sendJBDMessageSystemWide(message);
    int64_t result = -1;
    if (reply) {
        result = xpc_dictionary_get_int64(reply, "ret");
    }
    return result;
}

// JBD_MSG_INIT_ENVIRONMENT = 12
int64_t jbdInitEnvironment(void) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_INIT_ENVIRONMENT);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;
    return xpc_dictionary_get_int64(reply, "ret");
}

// JBD_MSG_SETUID_FIX = 13
int64_t jbdswFixSetuid(void) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_SETUID_FIX);
    xpc_object_t reply = sendJBDMessageSystemWide(message);
    int64_t result = -1;
    if (reply) {
        result = xpc_dictionary_get_int64(reply, "ret");
    }
    return result;
}

// JBD_MSG_PROC_SET_DEBUGGED = 14
int64_t jbdProcSetDebugged(pid_t pid) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_PROC_SET_DEBUGGED);
    xpc_dictionary_set_int64(message, "pid", pid);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;
    return xpc_dictionary_get_int64(reply, "ret");
}

// JBD_MSG_DEBUG_ME = 15
int64_t jbdDebugMe(void) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_DEBUG_ME);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;
    return xpc_dictionary_get_int64(reply, "ret");
}

// JBD_MSG_PLATFORMIZE = 16
int64_t jbdPlatformize(pid_t pid) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_PLATFORMIZE);
    xpc_dictionary_set_int64(message, "pid", pid);

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply)
        return -10;
    return xpc_dictionary_get_int64(reply, "ret");
}

// JBD_MSG_PLATFORMIZE = 16-1
int64_t jbdswPlatformize(pid_t pid) {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", JBD_MSG_PLATFORMIZE);
    xpc_dictionary_set_int64(message, "pid", pid);

    xpc_object_t reply = sendJBDMessageSystemWide(message);
    if (!reply)
        return -10;
    return xpc_dictionary_get_int64(reply, "ret");
}