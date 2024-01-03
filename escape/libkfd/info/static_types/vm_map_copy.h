/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef vm_map_copy_h
#define vm_map_copy_h

#include "vm_map_entry.h"
#include "../../libkfd.h"

#define cpy_hdr       c_u.hdr
#define cpy_object    c_u.object
#define cpy_kdata     c_u.kdata

struct rb_head {
    u64 rbh_root;
};

struct vm_map_header {
    struct vm_map_links links;
    i32 nentries;
    u16 page_shift;
    u32
        entries_pageable:1,
        __padding:15;
    struct rb_head rb_head_store;
};

struct vm_map_copy {
    i32 type;
    u64 offset;
    u64 size;
    union {
        struct vm_map_header hdr;
        u64 object;
        u64 kdata;
    } c_u;
};

void print_vm_map_copy(struct kfd* kfd, struct vm_map_copy* copy, u64 copy_kaddr)
{
  
    if (copy->type == 1) {
        u64 entry_kaddr = copy->cpy_hdr.links.next;
        u64 copy_entry_kaddr = copy_kaddr + offsetof(struct vm_map_copy, cpy_hdr.links.prev);
        struct vm_map_entry entry = {};
        while (entry_kaddr != copy_entry_kaddr) {
            kread((u64)(kfd), entry_kaddr, &entry, sizeof(entry));
            entry_kaddr = entry.vme_next;
        }
    }
}

#endif /* vm_map_copy_h */
