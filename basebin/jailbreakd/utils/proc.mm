#import "proc.h"
#import "kernel/kernel.h"
#import "offsets.h"

uint64_t proc_for_pid(pid_t pid) {
    uint64_t proc = kernel_info.kproc;

    while (true) {
        if (kread32(proc + off_p_pid) == pid) {
            return proc;
        }
        proc = kread64(proc + off_p_list_le_prev);
        if (!proc) {
            return -1;
        }
    }

    return 0;
}

uint64_t proc_for_name(char *nm) {
    uint64_t proc = kernel_info.kproc;
    char name[0x100];
    while (true) {
        uint64_t nameptr = proc + off_p_name;
        kread_string(nameptr, name);
        if (strcmp(name, nm) == 0) {
            return proc;
        }
        proc = kread64(proc + off_p_list_le_prev);
        if (!proc) {
            return -1;
        }
    }

    return 0;
}

pid_t pid_by_name(char *nm) {
    uint64_t proc = proc_for_name(nm);
    if (proc == -1)
        return -1;
    return kread32(proc + off_p_pid);
}

uint64_t taskptr_for_pid(pid_t pid) {
    uint64_t proc_ro = kread64(proc_for_pid(pid) + 0x20);
    return kread64(proc_ro + 0x8);
}

uint64_t proc_get_task(uint64_t proc) {
    uint64_t proc_ro = kread64(proc + 0x20);
    return kread64(proc_ro + 0x8);
}

uint64_t task_get_vm_map(uint64_t task) {
    return kread64(task + off_task_map);
}

uint64_t vm_map_get_pmap(uint64_t vm_map) {
    return kread64(vm_map + off_vm_map_pmap);
}

uint64_t pmap_get_ttep(uint64_t pmap) {
    return kread64(pmap + off_pmap_ttep);
}