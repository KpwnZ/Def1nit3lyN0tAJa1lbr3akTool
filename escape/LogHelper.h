//
//  LogHelper.h
//  escape
//
//  Created by Xiao on 2023/11/9.
//

#ifndef LOGHELPER_H
#define LOGHELPER_H

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogHelper : NSObject

@property (nonatomic, retain) UITextView *logView;

+ (instancetype)sharedInstance;
- (void)logMessage:(NSString *)message;
- (void)logWithFormat:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END

#endif
