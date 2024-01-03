/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef semaphore_h
#define semaphore_h

struct semaphore {
    struct {
        uint64_t next;
        uint64_t prev;
    } task_link;
    char waitq[24];
    uint64_t owner;
    uint64_t port;
    uint32_t ref_count;
    int32_t count;
};

#endif /* semaphore_h */
