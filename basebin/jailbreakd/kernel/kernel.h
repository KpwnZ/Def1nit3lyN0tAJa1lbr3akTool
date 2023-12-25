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
    uint64_t kproc;
    uint64_t self_proc;
    uint64_t fake_userclient;
    uint64_t fake_userclient_vtable;
    uint64_t pmap_image4_trust_caches;
    struct {
        uint64_t addr_proc_set_ucred;
        uint64_t container_init;
        uint64_t kcall_gadget;
        uint64_t kread_gadget;
        uint64_t kwrite_gadget;
        uint64_t proc_updatecsflags;
    } kernel_functions;
    
};

extern struct kinfo kernel_info;

BOOL setup_client();

uint8_t kread8(uint64_t addr);
uint32_t kread32(uint64_t addr);
uint64_t kread64(uint64_t addr);
void kread_string(uint64_t addr, char *out);
void kwrite8(uint64_t addr, uint8_t data);
void kwrite32(uint64_t addr, uint32_t val);
void kwrite64(uint64_t addr, uint64_t val);
uint64_t kalloc(size_t ksize);
uint64_t kcall(uint64_t addr, uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3, uint64_t x4, uint64_t x5);

void kreadbuf(uint64_t addr, void *buf, size_t size);
void kwritebuf(uint64_t addr, void *buf, size_t size);

#endif