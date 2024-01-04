#import "proc.h"
#import "kernel/kernel.h"
#import "offsets.h"
#import <libproc.h>

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
        pid_t pid = kread32(proc + off_p_pid);
        proc_name(pid, name, 0x100);
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

pid_t pid_for_name(char *nm) {
    uint64_t proc = proc_for_name(nm);
    if (proc == -1)
        return -1;
    return kread32(proc + off_p_pid);
}

uint64_t taskptr_for_pid(pid_t pid) {
    uint64_t proc_ro = kread64(proc_for_pid(pid) + off_proc_proc_ro);
    return kread64(proc_ro + 0x8);
}

uint64_t proc_get_task(uint64_t proc) {
    uint64_t proc_ro = kread64(proc + off_proc_proc_ro);
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

void proc_updatecsflags(uint64_t proc, uint32_t csflags) {
    kcall(kernel_info.kernel_functions.proc_updatecsflags, proc, csflags, 0, 0, 0, 0);
}

void pid_set_csflags(pid_t pid, uint32_t csflags) {
    uint64_t proc = proc_for_pid(pid);
    if (proc == 0) {
        return;
    }
    proc_updatecsflags(proc, csflags);
}

uint32_t proc_get_csflags(uint64_t proc) {
    uint64_t proc_ro = kread64(proc + off_proc_proc_ro);
    if (@available(iOS 16, *)) {
        uint64_t p_csflags_with_p_idversion = kread64(proc_ro + 0x1c);
        return p_csflags_with_p_idversion & 0xFFFFFFFF;
    }
    uint64_t p_csflags_with_p_idversion = kread64(proc_ro + 0x1c);
    return p_csflags_with_p_idversion & 0xFFFFFFFF;
}
