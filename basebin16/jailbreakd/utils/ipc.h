#include <stdio.h>
#include <mach/mach.h>
#include <unistd.h>

uint64_t ipc_entry_lookup(mach_port_t port_name);

uint64_t port_name_to_ipc_port(mach_port_t port_name);

uint64_t port_name_to_kobject(mach_port_t port_name);