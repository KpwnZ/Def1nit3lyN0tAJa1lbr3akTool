//
//  LogHelper.m
//  escape
//
//  Created by Xiao on 2023/11/9.
//

#import "LogHelper.h"

@implementation LogHelper

+ (instancetype)sharedInstance {
    static LogHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LogHelper alloc] init];
    });
    return instance;
}

- (void)logMessage:(NSString *)message {
    // Append message to log view
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logView.text = [NSString stringWithFormat:@"%@\n%@", self.logView.text, message];
        NSRange range = NSMakeRange(self.logView.text.length - 1, 1);
        [self.logView scrollRangeToVisible:range];
    });
}

- (void)logWithFormat:(NSString *)format, ... {
    va_list arguments;
    va_start(arguments, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    [self logMessage:message];
}

@end
