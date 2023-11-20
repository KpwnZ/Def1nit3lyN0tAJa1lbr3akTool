#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

pid_t pid_by_name(char* nm);
uint64_t proc_for_name(char* nm);
uint64_t proc_for_pid(pid_t pid);
uint64_t proc_get_task(uint64_t proc);
uint64_t task_get_vm_map(uint64_t task);
uint64_t vm_map_get_pmap(uint64_t vm_map);
uint64_t pmap_get_ttep(uint64_t pmap);