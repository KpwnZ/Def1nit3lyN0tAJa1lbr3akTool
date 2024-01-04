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

    const char *readble = sandbox_extension_issue_file("com.apple.app-sandbox.read",
                                                       prebootPath(nil).fileSystemRepresentation,
                                                       0);
    if (readble) [extensionString appendString:[NSString stringWithUTF8String:readble]];
    else NSLog(@"[launchdhook] Failed to generate sandbox extension for com.apple.app-sandbox.read");
    [extensionString appendString:@"|"];

    const char *executable = sandbox_extension_issue_file("com.apple.sandbox.executable",
                                                          prebootPath(nil).fileSystemRepresentation,
                                                          0);
    if (executable) [extensionString appendString:[NSString stringWithUTF8String:executable]];
    else NSLog(@"[launchdhook] Failed to generate sandbox extension for com.apple.sandbox.executable");
    [extensionString appendString:@"|"];

    const char *mach = sandbox_extension_issue_mach("com.apple.app-sandbox.mach",
                                                    "com.xia0o0o0o.jailbreakd.systemwide",
                                                    0);
    if (mach) [extensionString appendString:[NSString stringWithUTF8String:mach]];
    else NSLog(@"[launchdhook] Failed to generate sandbox extension for com.apple.app-sandbox.mach");
    [extensionString appendString:@"|"];

    const char *machLookup = sandbox_extension_issue_mach("com.apple.security.exception.mach-lookup.global-name",
                                                          "com.xia0o0o0o.jailbreakd.systemwide",
                                                          0);
    if (machLookup) [extensionString appendString:[NSString stringWithUTF8String:machLookup]];
    else NSLog(@"[launchdhook] Failed to generate sandbox extension for com.apple.security.exception.mach-lookup.global-name");

    return extensionString;
}

__attribute__((constructor)) static void initializer(void) {
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

    initDaemonHooks();
    initSpawnHooks();
    initIPCHooks();

    // This will ensure launchdhook is always reinjected after userspace
    // reboots As this launchd will pass environ to the next launchd...
    setenv("DYLD_INSERT_LIBRARIES",
           prebootPath(@"basebin/launchdhook.dylib").fileSystemRepresentation, 1);

    bootInfo_setObject(@"environmentInitialized", @1);
}