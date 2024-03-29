//
//  ViewController.m
//  escape
//
//  Created by Xiao on 2023/11/9.
//

#import "ViewController.h"
#import "LogHelper.h"
#import <stdint.h>
#import "libkfd/libkfd.h"
#import "post_exploitation/post_exp.h"
#import <sys/utsname.h>
#import <xpc/xpc.h>
#import "jailbreakd.h"
#import "utils.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *jailbreakButton;
@property (nonatomic, strong) UITextView *logView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Create log button
    self.jailbreakButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.jailbreakButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.jailbreakButton addTarget:self action:@selector(logButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.jailbreakButton];
    
    // Create log view
    self.logView = [[UITextView alloc] init];
    self.logView.editable = NO;
    self.logView.scrollEnabled = YES;
    self.logView.layoutManager.allowsNonContiguousLayout = NO;
    self.logView.font = [UIFont monospacedSystemFontOfSize:10 weight:1];
    [self.view addSubview:self.logView];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"By xia0o0o0o";
    [label sizeToFit];
    label.font = [UIFont monospacedSystemFontOfSize:15 weight:1];
    [self.view addSubview:label];
    
    // Set up constraints
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
    ]];
    
    self.jailbreakButton.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.jailbreakButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.jailbreakButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:50],
        [label.topAnchor constraintEqualToAnchor:self.jailbreakButton.bottomAnchor constant:15],
    ]];
    
    self.logView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.logView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.logView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.logView.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:20],
        [self.logView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:0]
    ]];
    
    [[LogHelper sharedInstance] setLogView:self.logView];
    
    // Log a message to the log view
    [[LogHelper sharedInstance] logMessage:@"[*] ready to start"];
    [[LogHelper sharedInstance] logMessage:@"[*] Post exploitation by xia0o0o0o"];

    // get uname and log with format
    struct utsname u = { 0 };
    uname(&u);
    [[LogHelper sharedInstance] logWithFormat:@"[*] sysname: %s", u.sysname];
    [[LogHelper sharedInstance] logWithFormat:@"[*] nodename: %s", u.nodename];
    [[LogHelper sharedInstance] logWithFormat:@"[*] release: %s", u.release];
    [[LogHelper sharedInstance] logWithFormat:@"[*] version: %s", u.version];
    [[LogHelper sharedInstance] logWithFormat:@"[*] machine: %s", u.machine];
    
    // Get iOS Version
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    [[LogHelper sharedInstance] logWithFormat:@"[*] iOS Version: %@.%@.%@", @(version.majorVersion), @(version.minorVersion), @(version.patchVersion)];
    NSString *unsupportedMessage = @"[!] !!! Only iOS 15.7-16.5 is supported !!!";
    if (version.majorVersion < 15 || (version.majorVersion == 15 && version.minorVersion < 7)) {
        [[LogHelper sharedInstance] logMessage:unsupportedMessage];
    } else if (version.majorVersion > 16) {
        [[LogHelper sharedInstance] logMessage:unsupportedMessage];
    } else if (version.majorVersion == 16 && version.minorVersion > 5) {
        if (version.minorVersion == 6) {
            [[LogHelper sharedInstance] logMessage:@"[!] !!! iOS 16.6 support is experimental, you may encounter issues !!!"];
        } else {
            [[LogHelper sharedInstance] logMessage:unsupportedMessage];
        }
    }
}

- (void)logButtonTapped {
    [[LogHelper sharedInstance] logMessage:@"[*] start kfd"];
    self.jailbreakButton.enabled = NO;
    for (int i = 0; i < 0x10; ++i) {
        sleep(1);
    }
    [self.jailbreakButton setTitle:@"jailbreaking" forState:UIControlStateNormal];
    u64 kread_method = kread_IOSurface;
    if (@available(iOS 16, *)) {
        kread_method = kread_sem_open;
    }
    u64 puaf_method = puaf_smith;
    u64 puaf_pages = 2048;

    // check if we are on 16.1.x
    NSOperatingSystemVersion currentVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    BOOL is_on_16_5_1_and_above =
        (currentVersion.majorVersion == 16 && currentVersion.minorVersion == 5 && currentVersion.patchVersion == 1) ||
        (currentVersion.majorVersion == 16 && currentVersion.minorVersion > 5);
    if (is_on_16_5_1_and_above) {
        puaf_method = puaf_landa;
        puaf_pages = 512;
    }
    sleep(1);
    uint64_t kfd = kopen(puaf_pages, puaf_method, kread_method, kwrite_sem_open);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        post_exp(kfd);
        kclose(kfd);
        usleep(10000);
        util_runCommand("/var/jb/usr/bin/killall", "-9", "backboardd", NULL);
    });
}

- (BOOL)pingJBD {
    xpc_object_t message = xpc_dictionary_create_empty();
    xpc_dictionary_set_uint64(message, "id", 0x100);
    xpc_dictionary_set_uint64(message, "pid", (uint64_t)getpid());

    xpc_object_t reply = sendJBDMessage(message);
    if (!reply) return NO;
    return YES;
}

- (void)logMessage:(NSString *)message {
    // Append message to log view
    self.logView.text = [NSString stringWithFormat:@"%@\n%@", self.logView.text, message];
    
    // Scroll to bottom of log view
    NSRange range = NSMakeRange(self.logView.text.length - 1, 1);
    [self.logView scrollRangeToVisible:range];
}

@end

