#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <spawn.h>

#import <sandbox.h>
#import "boot_info.h"
#import "common.h"
#import "daemon_hook.h"
#import "ipc_hook.h"
#import "jailbreakd.h"
#import "spawn_hook.h"

int gLaunchdImageIndex = -1;

NSString *generateSystemWideSandboxExtensions(void) {
    NSMutableString *extensionString = [NSMutableString new];

    // Make /var/jb readable
    [extensionString
        appendString:[NSString
                         stringWithUTF8String:sandbox_extension_issue_file(
                                                  "com.apple.app-sandbox.read",
                                                  prebootPath(nil)
                                                      .fileSystemRepresentation,
                                                  0)]];
    [extensionString appendString:@"|"];

    // Make binaries in /var/jb executable
    [extensionString
        appendString:[NSString
                         stringWithUTF8String:sandbox_extension_issue_file(
                                                  "com.apple.sandbox.executable",
                                                  prebootPath(nil)
                                                      .fileSystemRepresentation,
                                                  0)]];
    [extensionString appendString:@"|"];

    [extensionString
        appendString:[NSString
                         stringWithUTF8String:sandbox_extension_issue_mach(
                                                  "com.apple.app-sandbox.mach",
                                                  "com.xia0o0o0o.jailbreakd.systemwide",
                                                  0)]];
    [extensionString appendString:@"|"];
    [extensionString
        appendString:[NSString
                         stringWithUTF8String:sandbox_extension_issue_mach(
                                                  "com.apple.security.exception."
                                                  "mach-lookup.global-name",
                                                  "com.xia0o0o0o.jailbreakd.systemwide",
                                                  0)]];

    return extensionString;
}

__attribute__((constructor)) static void initializer(void) {
    // Launchd hook loaded for first time, get primitives from jailbreakd
    // jbdInitPPLRW();
    // recoverPACPrimitives();

    for (int i = 0; i < _dyld_image_count(); i++) {
        if (!strcmp(_dyld_get_image_name(i), "/sbin/launchd")) {
            gLaunchdImageIndex = i;
            break;
        }
    }
    // System wide sandbox extensions and root path
    setenv("JB_SANDBOX_EXTENSIONS",
           generateSystemWideSandboxExtensions().UTF8String, 1);
    setenv("JB_ROOT_PATH", prebootPath(nil).fileSystemRepresentation, 1);
    JB_SandboxExtensions = strdup(getenv("JB_SANDBOX_EXTENSIONS"));
    JB_RootPath = strdup(getenv("JB_ROOT_PATH"));
    bootInfo_setObject(
        @"JB_SANDBOX_EXTENSIONS",
        [NSString stringWithUTF8String:JB_SandboxExtensions]);  // XXX temporary
    bootInfo_setObject(
        @"JB_ROOT_PATH",
        [NSString stringWithUTF8String:JB_RootPath]);  // XXX temporary

    NSLog(@"[launchdhook] Hello World");

    //   proc_set_debugged_pid(getpid(), false);
    // jbdDebugMe(); // XXX BROKEN, when hook launchd, it just panic :(
    //   jbdPlatformize(getpid());	<- implemented in kfd app instead, idk
    //   why stuck here?

    //   initXPCHooks(void)	//XXX NOT IMPLEMENETED
    initDaemonHooks();
    initSpawnHooks();
    initIPCHooks();

    // This will ensure launchdhook is always reinjected after userspace
    // reboots As this launchd will pass environ to the next launchd...
    setenv("DYLD_INSERT_LIBRARIES",
           prebootPath(@"basebin/launchdhook.dylib").fileSystemRepresentation, 1);

    bootInfo_setObject(@"environmentInitialized", @1);
}