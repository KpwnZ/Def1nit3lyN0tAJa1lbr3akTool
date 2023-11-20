#import "ipc.h"
#import "kernel/kernel.h"
#import "offsets.h"
#import "proc.h"

uint64_t ipc_entry_lookup(mach_port_t port_name) {
    uint64_t proc = proc_for_pid(getpid());
    uint64_t task = kread64(proc + off_p_task);
    uint64_t itk_space = kread64(task + off_task_itk_space);
    uint32_t port_index = MACH_PORT_INDEX(port_name);
    uint64_t is_table = kread64(itk_space + off_ipc_space_is_table);
    uint64_t entry = is_table + port_index * 0x18;  // SIZE(ipc_entry);
    return entry;
}

uint64_t port_name_to_ipc_port(mach_port_t port_name) {
    uint64_t entry = ipc_entry_lookup(port_name);
    uint64_t ipc_port = kread64(entry + 0x0);
    return ipc_port;
}

uint64_t port_name_to_kobject(mach_port_t port_name) {
    uint64_t ipc_port = port_name_to_ipc_port(port_name);
    uint64_t kobject = kread64(ipc_port + off_ipc_port_ip_kobject);
    return kobject;
}
