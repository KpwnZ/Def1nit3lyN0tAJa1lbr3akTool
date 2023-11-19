#import <Foundation/Foundation.h>
#import <bsm/libbsm.h>
#import <stdint.h>
#import <xpc/xpc.h>
#import <bootstrap.h>

void JBLogDebug(const char *format, ...) {
	va_list va;
	va_start(va, format);

	FILE *launchdLog = fopen("/var/mobile/jailbreakd-xpc.log", "a");
	vfprintf(launchdLog, format, va);
	fprintf(launchdLog, "\n");
	fclose(launchdLog);

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

      if (msgId == JBD_MSG_KERNINFO)
    }
  }
}

// this is from Dopamine's jailbreakd
int main(int argc, char* argv[]) {
    @autoreleasepool {
        JBLogDebug("Hello from the other side!");
        gIsJailbreakd = YES;

        setJetsamEnabled(true);

        gTCPages = [NSMutableArray new];
        gTCUnusedAllocations = [NSMutableArray new];

        mach_port_t machPort = 0;
        kern_return_t kr = bootstrap_check_in(bootstrap_port, "com.xia0o0o0o.jailbreakd", &machPort);
        if (kr != KERN_SUCCESS) {
            JBLogDebug("Failed com.opa334.jailbreakd bootstrap check in: %d (%s)", kr, mach_error_string(kr));
            return 1;
        }

        mach_port_t machPortSystemWide = 0;
        kr = bootstrap_check_in(bootstrap_port, "com.xia0o0o0o.jailbreakd.systemwide", &machPortSystemWide);
        if (kr != KERN_SUCCESS) {
            JBLogDebug("Failed com.opa334.jailbreakd.systemwide bootstrap check in: %d (%s)", kr, mach_error_string(kr));
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