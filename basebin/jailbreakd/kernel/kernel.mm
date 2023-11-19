#import "kernel.h"
#import "utils.h"

io_connect_t user_client = 0;

BOOL setup_client() {
    JBLogDebug("[*] setup kcall");

    io_service_t service = IOServiceGetMatchingService(
        kIOMasterPortDefault, IOServiceMatching("IOSurfaceRoot"));

    if (service == IO_OBJECT_NULL) {
        JBLogDebug("[-] Failed to get IOSurfaceRoot service");
        return NO;
    }

    io_connect_t conn = MACH_PORT_NULL;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &conn);
    if (kr != KERN_SUCCESS) {
        JBLogDebug("[-] Failed to open IOSurfaceRoot service");
        return NO;
    }
    user_client = conn;
    IOObjectRelease(service);

    JBLogDebug("[+] Got user client: 0x%x", user_client);

    return YES;
}
