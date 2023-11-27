//
//  offsets.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/08/10.
//

#import <stdint.h>

extern uint32_t off_p_list_le_prev;
extern uint32_t off_p_name;
extern uint32_t off_p_pid;
extern uint32_t off_p_ucred;
extern uint32_t off_p_task;
extern uint32_t off_p_csflags;
extern uint32_t off_p_uid;
extern uint32_t off_p_gid;
extern uint32_t off_p_ruid;
extern uint32_t off_p_rgid;
extern uint32_t off_p_svuid;
extern uint32_t off_p_svgid;
extern uint32_t off_p_textvp;
extern uint32_t off_p_pfd;
extern uint32_t off_u_cr_label;
extern uint32_t off_u_cr_uid;
extern uint32_t off_u_cr_ruid;
extern uint32_t off_u_cr_svuid;
extern uint32_t off_u_cr_ngroups;
extern uint32_t off_u_cr_groups;
extern uint32_t off_u_cr_rgid;
extern uint32_t off_u_cr_svgid;
extern uint32_t off_task_t_flags;
extern uint32_t off_task_itk_space;
extern uint32_t off_task_map;
extern uint32_t off_vm_map_pmap;
extern uint32_t off_pmap_ttep;
extern uint32_t off_vnode_v_name;
extern uint32_t off_vnode_v_parent;
extern uint32_t off_vnode_vu_ubcinfo;
extern uint32_t off_vnode_v_data;
extern uint32_t off_fp_glob;
extern uint32_t off_fg_data;
extern uint32_t off_ubc_info_cs_blobs;
extern uint32_t off_cs_blob_csb_platform_binary;
extern uint32_t off_ipc_port_ip_kobject;
extern uint32_t off_ipc_space_is_table;
extern uint32_t off_amfi_slot;
extern uint32_t off_sandbox_slot;
extern uint64_t off_kalloc_data_external;
extern uint64_t off_kfree_data_external;
extern uint64_t off_add_x0_x0_0x40_ret;
extern uint64_t off_empty_kdata_page;
extern uint64_t off_trustcache;
extern uint64_t off_gphysbase;
extern uint64_t off_gphyssize;
extern uint64_t off_pmap_enter_options_addr;
extern uint64_t off_allproc;
extern uint64_t off_pmap_find_phys;
extern uint64_t off_ml_phys_read_data;
extern uint64_t off_ml_phys_write_data;

// kcall
extern uint64_t off_add_x0_x0_0x40_ret;
extern uint64_t off_proc_set_ucred;
extern uint64_t off_zm_fix_alloc;
extern uint64_t off_container_init;
// csflag
extern uint64_t off_proc_updatecsflags;

// zone ro
extern uint64_t off_proc_proc_ro;
void _offsets_init(void);
