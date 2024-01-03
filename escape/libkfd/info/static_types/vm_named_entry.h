/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef vm_named_entry_h
#define vm_named_entry_h

#include "../../libkfd.h"

struct vm_named_entry {
    u64 Lock[2];
    union {
        u64 map;
        u64 copy;
    } backing;
    u64 offset;
    u64 size;
    u64 data_offset;
    u32
        protection:4,
        is_object:1,
        internal:1,
        is_sub_map:1,
        is_copy:1,
        is_fully_owned:1;
};

void print_vm_named_entry(struct kfd* kfd, struct vm_named_entry* named_entry, u64 named_entry_kaddr)
{
    if (!named_entry->is_sub_map) {
        u64 copy_kaddr = named_entry->backing.copy;
        struct vm_map_copy copy = {};
        kread((u64)(kfd), copy_kaddr, &copy, sizeof(copy));
    }
}

#endif /* vm_named_entry_h */
