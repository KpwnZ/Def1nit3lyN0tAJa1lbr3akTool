#ifndef _UTILS_H
#define _UTILS_H

#import <Foundation/Foundation.h>
#import <libproc.h>

NSString *proc_get_path(pid_t pid);
void JBLogDebug(const char *format, ...);
int util_runCommand(const char *cmd, ...);

#endif
