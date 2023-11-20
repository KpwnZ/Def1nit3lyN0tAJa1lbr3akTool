#import <Foundation/Foundation.h>
#import <kern_memorystatus.h>
#import <libproc.h>
#import <stdint.h>
#import <utils.h>
#import <xpc/xpc.h>
#import "server.h"
#import "kernel/kernel.h"

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
    CFOptionFlags *responseFlags) API_AVAILABLE(ios(3.0));

#ifdef __cplusplus
}
#endif

static int log_to_stdout = 1;

struct kinfo {
    uint64_t kbase;
    uint64_t kslide;
};

struct kinfo kernel_info = { 0 };

void JBLogDebug(const char *format, ...) {
    va_list va;
    va_start(va, format);

    FILE *launchdLog = fopen("/var/mobile/jailbreakd-xpc.log", "a");
    if (launchdLog) {
        vfprintf(launchdLog, format, va);
        fprintf(launchdLog, "\n");
        fclose(launchdLog);
    }

    if (log_to_stdout) {
        printf(format, va);
        printf("\n");
    }

    va_end(va);
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
            uid_t clientUid = audit_token_to_euid(auditToken);
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
            if (msgId == JBD_MSG_SETUP_CLIENT) {
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
                JBLogDebug("[jailbreakd] received kernel info: kbase: 0x%llx, kslide: 0x%llx", kernel_info.kbase, kernel_info.kslide);
                JBLogDebug("[+] setup kernel success");
                xpc_dictionary_set_uint64(reply, "ret", 0);
                xpc_dictionary_set_uint64(reply, "pid", getpid());
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
int main(int argc, char* argv[]) {
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