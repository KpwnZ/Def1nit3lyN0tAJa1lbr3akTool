#import <Foundation/Foundation.h>
#import <kern_memorystatus.h>
#import <libproc.h>
#import <stdint.h>
#import <utils.h>
#import <xpc/xpc.h>
#import "kernel/kernel.h"
#import "server.h"
#import "trustcache.h"
#import "fakelib.h"
#import <pthread.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <spawn.h>
#import "utils/proc.h"

#ifdef __cplusplus
extern "C" {
#endif

xpc_object_t launchd_xpc_send_message(xpc_object_t xdict);
uid_t audit_token_to_euid(audit_token_t);
uid_t audit_token_to_pid(audit_token_t);

kern_return_t bootstrap_check_in(mach_port_t bootstrap_port,
                                 const char *service, mach_port_t *server_port);
SInt32 CFUserNotificationDisplayAlert(
    CFTimeInterval timeout, CFOptionFlags flags, CFURLRef iconURL,
    CFURLRef soundURL, CFURLRef localizationURL, CFStringRef alertHeader,
    CFStringRef alertMessage, CFStringRef defaultButtonTitle,
    CFStringRef alternateButtonTitle, CFStringRef otherButtonTitle,
    CFOptionFlags *responseFlags);

#ifdef __cplusplus
}
#endif

static int log_to_stdout = 1;

struct kinfo kernel_info = {0};

void JBLogDebug(const char *format, ...) {
    va_list va;
    va_start(va, format);
    char buf[0x1000];

    FILE *launchdLog = fopen("/var/mobile/jailbreakd-xpc.log", "a");
    if (launchdLog) {
        vfprintf(launchdLog, format, va);
        fprintf(launchdLog, "\n");
        fclose(launchdLog);
    }

    if (log_to_stdout) {
        vsnprintf(buf, sizeof(buf), format, va);
        NSLog(@"%s", buf);
    }

    va_end(va);
}
extern char **environ;
int runCommandv(const char *cmd, int argc, const char *const *argv, void (^unrestrict)(pid_t)) {
    pid_t pid;
    posix_spawn_file_actions_t *actions = NULL;
    posix_spawn_file_actions_t actionsStruct;
    int out_pipe[2];
    bool valid_pipe = false;
    posix_spawnattr_t *attr = NULL;
    posix_spawnattr_t attrStruct;

    valid_pipe = pipe(out_pipe) == 0;
    if (valid_pipe && posix_spawn_file_actions_init(&actionsStruct) == 0) {
        actions = &actionsStruct;
        posix_spawn_file_actions_adddup2(actions, out_pipe[1], 1);
        posix_spawn_file_actions_adddup2(actions, out_pipe[1], 2);
        posix_spawn_file_actions_addclose(actions, out_pipe[0]);
        posix_spawn_file_actions_addclose(actions, out_pipe[1]);
    }

    if (unrestrict && posix_spawnattr_init(&attrStruct) == 0) {
        attr = &attrStruct;
        posix_spawnattr_setflags(attr, POSIX_SPAWN_START_SUSPENDED);
    }

    int rv = posix_spawn(&pid, cmd, actions, attr, (char *const *)argv, environ);

    if (unrestrict) {
        unrestrict(pid);
        kill(pid, SIGCONT);
    }

    if (valid_pipe) {
        close(out_pipe[1]);
    }

    if (rv == 0) {
        if (valid_pipe) {
            char buf[256];
            ssize_t len;
            while (1) {
                len = read(out_pipe[0], buf, sizeof(buf) - 1);
                if (len == 0) {
                    break;
                } else if (len == -1) {
                    perror("posix_spawn, read pipe\n");
                }
                buf[len] = 0;
                NSLog(@"%s\n", buf);
            }
        }
        if (waitpid(pid, &rv, 0) == -1) {
            NSLog(@"ERROR: Waitpid failed\n");
        } else {
            NSLog(@"%s(%d) completed with exit status %d\n", __FUNCTION__, pid, WEXITSTATUS(rv));
        }

    } else {
        NSLog(@"%s(%d): ERROR posix_spawn failed (%d): %s\n", __FUNCTION__, pid, rv, strerror(rv));
        rv <<= 8;  // Put error into WEXITSTATUS
    }
    if (valid_pipe) {
        close(out_pipe[0]);
    }
    return rv;
}

int util_runCommand(const char *cmd, ...) {
    va_list ap, ap2;
    int argc = 1;

    va_start(ap, cmd);
    va_copy(ap2, ap);

    while (va_arg(ap, const char *) != NULL) {
        argc++;
    }
    va_end(ap);

    const char *argv[argc + 1];
    argv[0] = cmd;
    for (int i = 1; i < argc; i++) {
        argv[i] = va_arg(ap2, const char *);
    }
    va_end(ap2);
    argv[argc] = NULL;

    int rv = runCommandv(cmd, argc, argv, NULL);
    return WEXITSTATUS(rv);
}

void jailbreakd_received_message(mach_port_t machPort, bool systemwide) {
    @autoreleasepool {
        xpc_object_t message = nil;
        int err = xpc_pipe_receive(machPort, &message);
        if (err != 0) {
            JBLogDebug("[jailbreakd] xpc_pipe_receive error %d", err);
            return;
        }

        xpc_object_t reply = xpc_dictionary_create_reply(message);
        xpc_type_t messageType = xpc_get_type(message);
        int msgId = -1;
        if (messageType == XPC_TYPE_DICTIONARY) {
            audit_token_t auditToken = {};
            xpc_dictionary_get_audit_token(message, &auditToken);
            pid_t clientPid = audit_token_to_pid(auditToken);

            msgId = xpc_dictionary_get_uint64(message, "id");

            char *description = xpc_copy_description(message);
            JBLogDebug("[jailbreakd] received %s message %d with dictionary: %s "
                       "(from binary: %s)",
                       systemwide ? "systemwide" : "", msgId, description,
                       proc_get_path(clientPid).UTF8String);
            free(description);

            if (msgId == JBD_MSG_PING) {
                uint64_t remote_pid = xpc_dictionary_get_uint64(message, "pid");
                JBLogDebug("[jailbreakd] received ping from %d", remote_pid);
                xpc_dictionary_set_uint64(reply, "id", msgId);
                xpc_dictionary_set_uint64(reply, "jbdpid", (uint64_t)getpid());
                xpc_dictionary_set_uint64(reply, "ret", 0xc0ffee);
            }
            if (msgId == JBD_MSG_START_CLIENT) {
                BOOL success = setup_client();
                if (!success) {
                    JBLogDebug("[-] failed to setup client");
                    xpc_dictionary_set_uint64(reply, "id", msgId);
                    xpc_dictionary_set_uint64(reply, "ret", 0xdeadc0de);
                } else {
                    JBLogDebug("[+] setup client success");
                    xpc_dictionary_set_uint64(reply, "id", msgId);
                    xpc_dictionary_set_uint64(reply, "clientport", (uint64_t)user_client);
                    xpc_dictionary_set_uint64(reply, "ret", 0);
                }
            }
            if (msgId == JBD_MSG_SETUP_KERNEL) {
                kernel_info.kbase = xpc_dictionary_get_uint64(message, "kbase");
                kernel_info.kslide = xpc_dictionary_get_uint64(message, "kslide");
                kernel_info.pmap_image4_trust_caches = xpc_dictionary_get_uint64(message, "pmap_image4_trust_caches");
                kernel_info.fake_userclient = xpc_dictionary_get_uint64(message, "fake_userclient");
                kernel_info.fake_userclient_vtable = xpc_dictionary_get_uint64(message, "fake_userclient_vtable");
                kernel_info.kproc = xpc_dictionary_get_uint64(message, "kproc");
                kernel_info.self_proc = xpc_dictionary_get_uint64(message, "self_proc");
                kernel_info.kernel_functions.addr_proc_set_ucred = xpc_dictionary_get_uint64(message, "addr_proc_set_ucred");
                kernel_info.kernel_functions.container_init = xpc_dictionary_get_uint64(message, "off_container_init");
                kernel_info.kernel_functions.kcall_gadget = xpc_dictionary_get_uint64(message, "kcall_gadget");
                kernel_info.kernel_functions.kread_gadget = xpc_dictionary_get_uint64(message, "kread_gadget");
                kernel_info.kernel_functions.kwrite_gadget = xpc_dictionary_get_uint64(message, "kwrite_gadget");
                kernel_info.kernel_functions.proc_updatecsflags = xpc_dictionary_get_uint64(message, "proc_updatecsflags");
                
                JBLogDebug("[jailbreakd] received kernel info: kbase: 0x%llx, kslide: 0x%llx", kernel_info.kbase, kernel_info.kslide);
                JBLogDebug("[jailbreakd] received kernel info: fake_userclient: 0x%llx, fake_userclient_vtable: 0x%llx", kernel_info.fake_userclient, kernel_info.fake_userclient_vtable);
                JBLogDebug("[jailbreakd] received kernel info: kproc: 0x%llx", kernel_info.kproc);
                JBLogDebug("[+] setup kernel success");
                xpc_dictionary_set_uint64(reply, "ret", 0);
                xpc_dictionary_set_uint64(reply, "id", msgId);
            }

            // kbase
            if (msgId == JBD_MSG_KRW_LIB_KINFO_KBASE) {
                xpc_dictionary_set_uint64(reply, "kbase", kernel_info.kbase);
                xpc_dictionary_set_uint64(reply, "ret", 0);
            }

            // kread32
            if (msgId == JBD_MSG_KREAD32) {
                uint64_t kaddr = xpc_dictionary_get_uint64(message, "kaddr");
                xpc_dictionary_set_uint64(reply, "ret", kread32(kaddr));
            }

            // kread64
            if (msgId == JBD_MSG_KREAD64) {
                uint64_t kaddr = xpc_dictionary_get_uint64(message, "kaddr");
                xpc_dictionary_set_uint64(reply, "ret", kread64(kaddr));
            }

            //  kwrite32
            if (msgId == JBD_MSG_KWRITE32) {
                uint64_t kaddr = xpc_dictionary_get_uint64(message, "kaddr");
                uint32_t val = xpc_dictionary_get_uint64(message, "val");
                kwrite32(kaddr, val);
                xpc_dictionary_set_uint64(reply, "ret", kread32(kaddr) != val);
            }

            //  kwrite64
            if (msgId == JBD_MSG_KWRITE64) {
                uint64_t kaddr = xpc_dictionary_get_uint64(message, "kaddr");
                uint64_t val = xpc_dictionary_get_uint64(message, "val");
                kwrite64(kaddr, val);
                xpc_dictionary_set_uint64(reply, "ret", kread64(kaddr) != val);
            }

            //  kalloc
            if (msgId == JBD_MSG_KALLOC) {
                uint64_t ksize = xpc_dictionary_get_uint64(message, "ksize");
                uint64_t allocated_kmem = kalloc(ksize);
                xpc_dictionary_set_uint64(reply, "ret", allocated_kmem);
            }

            //  kcall
            if (msgId == JBD_MSG_KCALL) {
                uint64_t kaddr = xpc_dictionary_get_uint64(message, "kaddr");
                xpc_object_t args = xpc_dictionary_get_value(message, "args");
                uint64_t argc = xpc_array_get_count(args);
                uint64_t argv[7] = {0};
                for (uint64_t i = 0; i < argc; i++) {
                    @autoreleasepool {
                        argv[i] = xpc_array_get_uint64(args, i);
                    }
                }
                uint64_t kcall_ret = kcall(kaddr, argv[0], argv[1], argv[2],
                                           argv[3], argv[4], argv[5]);
                xpc_dictionary_set_uint64(reply, "ret", kcall_ret);
            }

            //  load trustcache from bin
            if (msgId == JBD_MSG_PROCESS_BINARY) {
                int64_t ret = 0;
                const char *filePath =
                    xpc_dictionary_get_string(message, "filePath");
                if (filePath) {
                    NSString *nsFilePath = [NSString stringWithUTF8String:filePath];
                    ret = processBinary(nsFilePath);
                } else {
                    ret = -1;
                }
                xpc_dictionary_set_int64(reply, "ret", ret);
            }

            //  rebuild trustcache, it does load all trustcache from /var/jb
            if (msgId == JBD_MSG_REBUILD_TRUSTCACHE) {
                int64_t ret = 0;
                rebuildDynamicTrustCache();
                xpc_dictionary_set_int64(reply, "ret", ret);
            }

            // patch dyld and bind mount
            if (msgId == JBD_MSG_INIT_ENVIRONMENT) {
                int64_t result = 0;
                result = makeFakeLib();
                if (result == 0) {
                    result = setFakeLibBindMountActive(true);
                    if (result) {
                        JBLogDebug("[jailbreakd] failed to set fake lib bind mount active");
                    }
                } else {
                    JBLogDebug("[jailbreakd] failed to make fake lib");
                }
                xpc_dictionary_set_int64(reply, "ret", result);
            }

            // setuid
            if (msgId == JBD_MSG_SETUID_FIX) {
                int64_t result = 0;
                JBLogDebug("[jailbreakd] not implemented yet");
                xpc_dictionary_set_int64(reply, "ret", result);
            }

            if (msgId == JBD_MSG_PROC_SET_DEBUGGED) {
                int64_t result = 0;
                pid_t pid = xpc_dictionary_get_int64(message, "pid");
                JBLogDebug("[jailbreakd] setting other process %s as debugged",
                           proc_get_path(pid).UTF8String);
                uint64_t proc = proc_for_pid(pid);
                if (proc == 0) {
                    JBLogDebug("[-] Failed to find proc for pid %d", clientPid);
                    result = -1;
                } else {
                    uint32_t csflags = proc_get_csflags(proc);
                    JBLogDebug("[jailbreakd] orig_csflags: 0x%x", csflags);
                    csflags = csflags | CS_DEBUGGED | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW;
                    csflags &= ~(CS_RESTRICT | CS_HARD | CS_KILL);
                    proc_updatecsflags(proc, csflags);
                }
                xpc_dictionary_set_int64(reply, "ret", result);
            }

            if (msgId == JBD_MSG_DEBUG_ME) {
                int64_t result = 0;
                uint64_t proc = proc_for_pid(clientPid);
                if (proc == 0) {
                    JBLogDebug("[-] Failed to find proc for pid %d", clientPid);
                    result = -1;
                } else {
                    uint32_t csflags = proc_get_csflags(proc);
                    JBLogDebug("[jailbreakd] orig_csflags: 0x%x", csflags);
                    csflags = csflags | CS_DEBUGGED | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW;
                    csflags &= ~(CS_RESTRICT | CS_HARD | CS_KILL);
                    proc_updatecsflags(proc, csflags);
                }
                xpc_dictionary_set_int64(reply, "ret", result);
            }

            if (msgId == JBD_MSG_PLATFORMIZE) {
                int64_t result = 0;
                pid_t pid = xpc_dictionary_get_int64(message, "pid");
                JBLogDebug("[jailbreakd] Platformizing pid: %d\n", pid);
                uint64_t proc = proc_for_pid(pid);
                if (proc == 0) {
                    JBLogDebug("[-] Failed to find proc for pid %d", pid);
                    result = -1;
                } else {
                    uint32_t csflags = proc_get_csflags(proc);
                    JBLogDebug("[jailbreakd] orig_csflags: 0x%x", csflags);
                    csflags = csflags | CS_DEBUGGED | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW;
                    csflags &= ~(CS_RESTRICT | CS_HARD | CS_KILL);
                    proc_updatecsflags(proc, csflags);
                }
                xpc_dictionary_set_int64(reply, "ret", result);
            }

            if (reply) {
                char *description = xpc_copy_description(reply);
                JBLogDebug("[jailbreakd] responding to %s message %d with %s",
                           systemwide ? "systemwide" : "", msgId, description);
                free(description);
                err = xpc_pipe_routine_reply(reply);
                if (err != 0) {
                    JBLogDebug("[jailbreakd] Error %d sending response", err);
                }
            }
        }
    }
}

void setJetsamEnabled(bool enabled) {
    pid_t me = getpid();
    int priorityToSet = -1;
    if (enabled) {
        priorityToSet = 10;
    }
    int rc = memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK, me,
                                  priorityToSet, NULL, 0);
    if (rc < 0) {
        perror("memorystatus_control");
    }
}

// this is from Dopamine's jailbreakd
int main(int argc, char *argv[]) {
    @autoreleasepool {
        JBLogDebug("Hello from the other side!");

        setJetsamEnabled(true);

        mach_port_t machPort = 0;
        kern_return_t kr = bootstrap_check_in(bootstrap_port, "com.xia0o0o0o.jailbreakd", &machPort);
        if (kr != KERN_SUCCESS) {
            JBLogDebug("[-] failed to bootstrap com.xia0o0o0o.jailbreakd check in: %d (%s)", kr, mach_error_string(kr));
            return 1;
        }

        mach_port_t machPortSystemWide = 0;
        kr = bootstrap_check_in(bootstrap_port, "com.xia0o0o0o.jailbreakd.systemwide", &machPortSystemWide);
        if (kr != KERN_SUCCESS) {
            JBLogDebug("[-] failed bootstrap com.xia0o0o0o.jailbreakd.systemwide check in: %d (%s)", kr, mach_error_string(kr));
            return 1;
        }

        dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_RECV, (uintptr_t)machPort, 0, dispatch_get_main_queue());
        dispatch_source_set_event_handler(source, ^{
          mach_port_t lMachPort = (mach_port_t)dispatch_source_get_handle(source);
          jailbreakd_received_message(lMachPort, false);
        });
        dispatch_resume(source);

        dispatch_source_t sourceSystemWide = dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_RECV, (uintptr_t)machPortSystemWide, 0, dispatch_get_main_queue());
        dispatch_source_set_event_handler(sourceSystemWide, ^{
          mach_port_t lMachPort = (mach_port_t)dispatch_source_get_handle(sourceSystemWide);
          jailbreakd_received_message(lMachPort, true);
        });
        dispatch_resume(sourceSystemWide);

        dispatch_main();
        return 0;
    }
}