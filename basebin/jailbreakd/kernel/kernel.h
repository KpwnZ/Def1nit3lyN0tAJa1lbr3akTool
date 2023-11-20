#ifndef _KERNEL_H
#define _KERNEL_H

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <stdint.h>
#import <stdio.h>
#import <stdlib.h>
#import <unistd.h>

extern io_connect_t user_client;

struct kinfo {
    uint64_t kbase;
    uint64_t kslide;
    uint64_t fake_userclient;
    uint64_t fake_userclient_vtable;
};

BOOL setup_client();

#endif