/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef vm_map_entry_h
#define vm_map_entry_h

#include "vm_object.h"
#include "libkfd.h"

#define vme_prev     links.prev
#define vme_next     links.next
#define vme_start    links.start
#define vme_end      links.end

struct vm_map_links {
    u64 prev;
    u64 next;
    u64 start;
    u64 end;
};

struct vm_map_store {
    struct {
        u64 rbe_left;
        u64 rbe_right;
        u64 rbe_parent;
    } entry;
};

struct vm_map_entry {
    struct vm_map_links links;
    struct vm_map_store store;
    union {
        u64 vme_object_value;
        struct {
            u64 vme_atomic:1;
            u64 is_sub_map:1;
            u64 vme_submap:60;
        };
        struct {
            u32 vme_ctx_atomic:1;
            u32 vme_ctx_is_sub_map:1;
            u32 vme_context:30;
            u32 vme_object;
        };
    };
    u64
        vme_alias:12,
        vme_offset:52,
        is_shared:1,
        __unused1:1,
        in_transition:1,
        needs_wakeup:1,
        behavior:2,
        needs_copy:1,
        protection:3,
        used_for_tpro:1,
        max_protection:4,
        inheritance:2,
        use_pmap:1,
        no_cache:1,
        vme_permanent:1,
        superpage_size:1,
        map_aligned:1,
        zero_wired_pages:1,
        used_for_jit:1,
        pmap_cs_associated:1,
        iokit_acct:1,
        vme_resilient_codesign:1,
        vme_resilient_media:1,
        __unused2:1,
        vme_no_copy_on_read:1,
        translated_allow_execute:1,
        vme_kernel_object:1;
    u16 wired_count;
    u16 user_wired_count;
};

#define vme_for_store(kaddr) ((kaddr) ? (((kaddr) - sizeof(struct vm_map_links)) & (~1ull)) : (kaddr))
#define store_for_vme(kaddr) ((kaddr) ? (((kaddr) + sizeof(struct vm_map_links))) : (kaddr))

static inline u64 VME_SUBMAP(struct vm_map_entry* entry)
{
    assert(entry->is_sub_map);
    u64 submap_kaddr = (entry->vme_submap << 2) | 0xf000000000000000;
    return submap_kaddr;
}

static inline u64 VME_OBJECT(struct vm_map_entry* entry)
{
    assert(!entry->is_sub_map);
    assert(!entry->vme_kernel_object);
    u64 object_kaddr = VM_OBJECT_UNPACK(entry->vme_object);
    return object_kaddr;
}

static inline u64 VME_OFFSET(struct vm_map_entry* entry)
{
    return entry->vme_offset << 12;
}

void print_vm_map_entry(struct kfd* kfd, struct vm_map_entry* entry, u64 entry_kaddr)
{

    u64 object_kaddr = 0;
    if (!entry->is_sub_map) {
        object_kaddr = VME_OBJECT(entry);
    }

    if (object_kaddr) {
        struct vm_object object = {};
        kread((u64)(kfd), object_kaddr, &object, sizeof(object));
    }
}

#endif /* vm_map_entry_h */
