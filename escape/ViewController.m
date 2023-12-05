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
    
    // Set up constraints
    self.jailbreakButton.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.jailbreakButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.jailbreakButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:50]
    ]];
    
    self.logView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.logView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.logView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.logView.topAnchor constraintEqualToAnchor:self.jailbreakButton.bottomAnchor constant:20],
        [self.logView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-20]
    ]];
    
    [[LogHelper sharedInstance] setLogView:self.logView];
    
    // Log a message to the log view
    [[LogHelper sharedInstance] logMessage:@"[*] ready to start"];

    // get uname and log with format
    struct utsname u = { 0 };
    uname(&u);
    [[LogHelper sharedInstance] logWithFormat:@"[*] sysname: %s", u.sysname];
    [[LogHelper sharedInstance] logWithFormat:@"[*] nodename: %s", u.nodename];
    [[LogHelper sharedInstance] logWithFormat:@"[*] release: %s", u.release];
    [[LogHelper sharedInstance] logWithFormat:@"[*] version: %s", u.version];
    [[LogHelper sharedInstance] logWithFormat:@"[*] machine: %s", u.machine];
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
    uint64_t kfd = kopen(2048, puaf_smith, kread_method, kwrite_IOSurface);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        post_exp(kfd);
        kclose(kfd);
    });
}

- (void)logMessage:(NSString *)message {
    // Append message to log view
    self.logView.text = [NSString stringWithFormat:@"%@\n%@", self.logView.text, message];
    
    // Scroll to bottom of log view
    NSRange range = NSMakeRange(self.logView.text.length - 1, 1);
    [self.logView scrollRangeToVisible:range];
}

@end

