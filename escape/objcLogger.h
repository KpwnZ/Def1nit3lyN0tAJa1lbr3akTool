//
//  objcLogger.h
//  escape
//
//  Created by Xiao on 2023/11/9.
//

#ifndef objcLogger_h
#define objcLogger_h

#import "LogHelper.h"

#define LOG_FMT(fmt, ...) \
    usleep(500); \
    [[LogHelper sharedInstance] logWithFormat:fmt, __VA_ARGS__]
#define LOG(msg) \
    [[LogHelper sharedInstance] logMessage:msg]

#endif /* objcLogger_h */
