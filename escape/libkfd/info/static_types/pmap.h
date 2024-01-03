/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef pmap_h
#define pmap_h

struct pmap {
    u64 tte;
    u64 ttep;
    u64 min;
    u64 max;
    u64 pmap_pt_attr;
    u64 ledger;
    u64 rwlock[2];
    struct {
        u64 next;
        u64 prev;
    } pmaps;
    u64 tt_entry_free;
    u64 nested_pmap;
    u64 nested_region_addr;
    u64 nested_region_size;
    u64 nested_region_true_start;
    u64 nested_region_true_end;
    u64 nested_region_asid_bitmap;
    u32 nested_region_asid_bitmap_size;
    u64 reserved0;
    u64 reserved1;
    u64 reserved2;
    u64 reserved3;
    i32 ref_count;
    i32 nested_count;
    u32 nested_no_bounds_refcnt;
    u16 hw_asid;
    u8 sw_asid;
    bool reserved4;
    bool pmap_vm_map_cs_enforced;
    bool reserved5;
    u32 reserved6;
    u8 reserved7;
    u8 type;
    bool reserved8;
    bool reserved9;
    bool is_rosetta;
    bool nx_enabled;
    bool is_64bit;
    bool nested_has_no_bounds_ref;
    bool nested_bounds_set;
    bool disable_jop;
    bool reserved11;
};

void print_pmap(struct kfd* kfd, struct pmap* pmap, u64 pmap_kaddr)
{
}

#endif /* pmap_h */
