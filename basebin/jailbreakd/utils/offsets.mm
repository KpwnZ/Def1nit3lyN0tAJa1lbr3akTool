//
//  offsets.m
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/08/10.
//

#import "offsets.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <sys/utsname.h>

uint32_t off_p_list_le_prev = 0;
uint32_t off_p_name = 0;
uint32_t off_p_pid = 0;
uint32_t off_p_ucred = 0;
uint32_t off_p_task = 0;
uint32_t off_p_csflags = 0;
uint32_t off_p_uid = 0;
uint32_t off_p_gid = 0;
uint32_t off_p_ruid = 0;
uint32_t off_p_rgid = 0;
uint32_t off_p_svuid = 0;
uint32_t off_p_svgid = 0;
uint32_t off_p_textvp = 0;
uint32_t off_p_pfd = 0;
uint32_t off_u_cr_label = 0;
uint32_t off_u_cr_uid = 0;
uint32_t off_u_cr_ruid = 0;
uint32_t off_u_cr_svuid = 0;
uint32_t off_u_cr_ngroups = 0;
uint32_t off_u_cr_groups = 0;
uint32_t off_u_cr_rgid = 0;
uint32_t off_u_cr_svgid = 0;
uint32_t off_task_t_flags = 0;
uint32_t off_task_itk_space = 0;
uint32_t off_task_map = 0;
uint32_t off_vm_map_pmap = 0;
uint32_t off_pmap_ttep = 0;
uint32_t off_vnode_v_name = 0;
uint32_t off_vnode_v_parent = 0;
uint32_t off_vnode_v_data = 0;
uint32_t off_fp_glob = 0;
uint32_t off_fg_data = 0;
uint32_t off_vnode_vu_ubcinfo = 0;
uint32_t off_ubc_info_cs_blobs = 0;
uint32_t off_cs_blob_csb_platform_binary = 0;
uint32_t off_ipc_port_ip_kobject = 0;
uint32_t off_ipc_space_is_table = 0;
uint32_t off_amfi_slot = 0;
uint32_t off_sandbox_slot = 0;


//kernel func
uint64_t off_kalloc_data_external = 0;
uint64_t off_kfree_data_external = 0;
uint64_t off_add_x0_x0_0x40_ret = 0;
uint64_t off_empty_kdata_page = 0;
uint64_t off_trustcache = 0;
uint64_t off_gphysbase = 0;
uint64_t off_gphyssize = 0;
uint64_t off_pmap_enter_options_addr = 0;
uint64_t off_allproc = 0;
uint64_t off_pmap_find_phys = 0;
uint64_t off_ml_phys_read_data = 0;
uint64_t off_ml_phys_write_data = 0;

// kcall
uint64_t off_proc_set_ucred = 0;
uint64_t off_zm_fix_alloc = 0;
uint64_t off_proc_updatecsflags = 0;
uint64_t off_container_init = 0;
uint64_t off_proc_proc_ro = 0;

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

char *_cur_deviceModel = NULL;
char *get_current_deviceModel(void){
    if(_cur_deviceModel)
        return _cur_deviceModel;
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    static NSDictionary* deviceNamesByCode = nil;
    if (!deviceNamesByCode) {
        deviceNamesByCode = @{ @"iPhone8,1" : @"iPhone 6S",         //
                              @"iPhone8,2" : @"iPhone 6S Plus",    //
                              @"iPhone8,4" : @"iPhone SE",         //
                              @"iPhone9,1" : @"iPhone 7",          //
                              @"iPhone9,3" : @"iPhone 7",          //
                              @"iPhone9,2" : @"iPhone 7 Plus",     //
                              @"iPhone9,4" : @"iPhone 7 Plus",     //
                              @"iPhone10,1": @"iPhone 8",          // CDMA
                              @"iPhone10,4": @"iPhone 8",          // GSM
                              @"iPhone10,2": @"iPhone 8 Plus",     // CDMA
                              @"iPhone10,5": @"iPhone 8 Plus",     // GSM
                              @"iPhone10,3": @"iPhone X",          // CDMA
                              @"iPhone10,6": @"iPhone X",          // GSM
                               @"iPad6,11": @"iPad 5 WiFi",          // 7th Generation iPad (iPad Air) - Wifi
                               @"iPad6,12": @"iPad 5 Cellular",          // 7th Generation iPad (iPad Air) - Wifi
                               @"iPad7,5": @"iPad 6 WiFi",          // 7th Generation iPad (iPad Air) - Wifi
                               @"iPad7,6": @"iPad 6 Cellular",          // 7th Generation iPad (iPad Air) - Wifi
                               @"iPad7,11": @"iPad 7 WiFi",          // 7th Generation iPad (iPad Air) - Wifi
                               @"iPad7,12": @"iPad 7 Cellular",          // 7th Generation iPad (iPad Air) - Wifi
                               @"iPad4,1": @"iPad Air",          // 5th Generation iPad (iPad Air) - Wifi
                               @"iPad4,2": @"iPad Air",          // 5th Generation iPad (iPad Air) - Cellular
                               @"iPad4,4": @"iPad Mini",         // (2nd Generation iPad Mini - Wifi)
                               @"iPad4,5": @"iPad Mini",         // (2nd Generation iPad Mini - Cellular)
                               @"iPad5,3": @"iPad Air 2 WiFi",          // 2nd Generation iPad (iPad Air 2) - Wifi
                               @"iPad5,4": @"iPad Air 2 Cellular",          // 2nd Generation iPad (iPad Air 2) - Cellular
                               @"iPad4,7": @"iPad Mini",         // (3rd Generation iPad Mini - Wifi (model A1599))
                               @"iPad5,1": @"iPad Mini 4 WiFi",         // (4th Generation iPad Mini - Cellular)
                               @"iPad5,2": @"iPad Mini 4 Cellular",         // (4th Generation iPad Mini - Wifi)
                               @"iPad6,7": @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1584)
                               @"iPad6,8": @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1652)
                               @"iPad6,3": @"iPad Pro (9.7\")",  // iPad Pro 9.7 inches - (model A1673)
                               @"iPad6,4": @"iPad Pro (9.7\")"   // iPad Pro 9.7 inches - (models A1674 and A1675)
        };
    }
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    if (!deviceName) {
        // Not found on database. At least guess main device type from string contents:
        
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        }
        else if([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        }
        else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = @"iPhone";
        }
        else {
            deviceName = @"Unknown";
        }
    }
    _cur_deviceModel = strdup([deviceName UTF8String]);
    return _cur_deviceModel;
}


void _offsets_init(void) {
    NSString *device = [NSString stringWithUTF8String: get_current_deviceModel()];

    //https://github.com/apple-oss-distributions/xnu/blob/xnu-8019.41.5/bsd/sys/proc_internal.h#L227
    off_p_list_le_prev = 0x8;
    
    
    off_p_uid = 0x2c;
    off_p_gid = 0x30;
    off_p_ruid = 0x34;
    off_p_rgid = 0x38;
    off_p_svuid = 0x3c;
    off_p_svgid = 0x40;
    
    off_p_ucred = 0xd8;
    off_p_task = 0x10;
    // https://github.com/apple-oss-distributions/xnu/blob/xnu-8019.41.5/bsd/sys/ucred.h#L91
    off_u_cr_label = 0x78;
    off_u_cr_uid = 0x18;
    off_u_cr_ruid = 0x1c;
    off_u_cr_svuid = 0x20;
    off_u_cr_ngroups = 0x24;
    off_u_cr_groups = 0x28;
    off_u_cr_rgid = 0x68;
    off_u_cr_svgid = 0x6c;
    
    
    off_p_pfd = 0x100;
    off_task_map = 0x28;    //_get_task_pmap
    // https://github.com/apple-oss-distributions/xnu/blob/xnu-8019.41.5/osfmk/vm/vm_map.h#L471
    off_vm_map_pmap = 0x48;
    
    // https://github.com/apple-oss-distributions/xnu/blob/xnu-8019.41.5/osfmk/arm/pmap.h#L377
    off_pmap_ttep = 0x8;
    
    // https://github.com/apple-oss-distributions/xnu/blob/xnu-8019.41.5/bsd/sys/vnode_internal.h#L142
    off_vnode_vu_ubcinfo = 0x78;
    off_vnode_v_name = 0xb8;
    off_vnode_v_parent = 0xc0;
    off_vnode_v_data = 0xe0;
    
    off_fp_glob = 0x10;
    
    off_fg_data = 0x38;
    
    // https://github.com/apple-oss-distributions/xnu/blob/xnu-8019.41.5/bsd/sys/ubc_internal.h#L149
    off_ubc_info_cs_blobs = 0x50;
    
    off_ipc_space_is_table = 0x20;
    
    off_amfi_slot = 0x8;
    off_sandbox_slot = 0x10;


    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"16.0")) {
        off_p_name = 0x381;
        off_p_pid = 0x60;
        off_p_csflags = 0x1c;
        off_p_textvp = 0x548;//0x350;
        off_proc_proc_ro = 0x18;
        off_task_t_flags = 0x3A0;//0x3e8;
        off_task_itk_space = 0x3A0;//0x300;
        off_cs_blob_csb_platform_binary = 0xac;//??
        off_ipc_port_ip_kobject = 0x48;
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"15.7")) {
        off_p_name = 0x389;
        off_p_pid = 0x68;
        off_p_csflags = 0x1c;
        off_p_textvp = 0x350;
        off_proc_proc_ro = 0x20;
        off_task_t_flags = 0x3B8;//0x3B8
        off_task_itk_space = 0x308;//or 3e0//0x3B8?
        off_cs_blob_csb_platform_binary = 0xac;
      //off_cs_blob_csb_platform_binary = 0xb8;
        off_ipc_port_ip_kobject = 0x48;
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"15.4")) {
        off_p_name = 0x389;
        off_p_pid = 0x68;
        off_p_csflags = 0x1c;
        off_p_textvp = 0x350;
        off_proc_proc_ro = 0x20;
        off_task_t_flags = 0x3B8;//0x3B8
        off_task_itk_space = 0x308;//or 3e0//0x3B8?
        off_cs_blob_csb_platform_binary = 0xac;
      //off_cs_blob_csb_platform_binary = 0xb8;
        off_ipc_port_ip_kobject = 0x48;
        
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"15.2")) {
        off_p_name = 0x389;
        off_p_pid = 0x68;
        off_p_csflags = 0x1c;
        off_p_textvp = 0x358;
        off_proc_proc_ro = 0x20;
        off_task_t_flags = 0x3b8;
        off_task_itk_space = 0x308;//or 3e0//0x3B8?
        off_cs_blob_csb_platform_binary = 0xac;
        off_ipc_port_ip_kobject = 0x58;

        
    } else {
        off_p_name = 0x2d9;
        off_p_pid = 0x68;
        off_p_csflags = 0x300;
        off_p_textvp = 0x2a8;  //ios14.8 = 0x220; ???
        off_task_t_flags = 0x3e8;
        off_task_itk_space = 0x330;//or 3e0//0x3B8?
        off_cs_blob_csb_platform_binary = 0xb8;
        off_ipc_port_ip_kobject = 0x58;


    }
    

    if ([device  isEqual: @"iPhone 7"]) {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"15.7.3")) {
            off_kalloc_data_external = 0xFFFFFFF0071D480C;
            off_kfree_data_external = 0xFFFFFFF0071D4E78;
            off_empty_kdata_page = 0xFFFFFFF007820000 + 0x200;
            off_trustcache = 0xFFFFFFF0078B6570;
            off_gphysbase = 0xFFFFFFF00714E7C0; //xref pmap_attribute_cache_sync size: 0x%llx @%s:%d
            off_gphyssize = 0xFFFFFFF00714E7C8;//0xFFFFFFF00714CA70; //xref pmap_attribute_cache_sync size: 0x%llx @%s:%d
            off_pmap_enter_options_addr = 0xFFFFFFF0072C9C54;
            off_allproc = 0xFFFFFF007896198;
            off_pmap_find_phys = 0xFFFFFFF0072D0B58;
            off_ml_phys_read_data = 0xFFFFFFF0072E1F7C;
            off_ml_phys_write_data = 0xFFFFFFF0072E21E4;
            off_zm_fix_alloc = 0xFFFFFFF007137450;
            off_container_init = 0xFFFFFFF0076DFDA4;
        } else {
           ////printf("[-] No matching offsets.\n");
            // exit(EXIT_FAILURE);

        }
        
    } else if ([device  isEqual: @"iPhone 7 Plus"]) {
        if (SYSTEM_VERSION_EQUAL_TO(@"15.7.5")) {
            //printf("[i] %s offsets selected for iOS 15.7.5\n", device.UTF8String);

            off_kalloc_data_external = 0xFFFFFFF0071D480C;//done dec13
            off_kfree_data_external = 0xFFFFFFF0071D4E78;//done
            
            off_add_x0_x0_0x40_ret = 0xFFFFFFF00596E60C;//FFFFFFF0059260B4;//0xFFFFFFF005C13DF0;//
            off_empty_kdata_page = 0xFFFFFFF007820000 + 0x200;//done me
            off_trustcache = 0xFFFFFFF0078B6570;//done me
            off_gphysbase = 0xFFFFFFF00714E7C0;//done me
            off_gphyssize = 0xFFFFFFF00714CA70;//done me
            off_pmap_enter_options_addr = 0xFFFFFFF0072C9C54;//done me
            
            off_allproc = 0xFFFFFF007896198;//done me
            off_pmap_find_phys = 0xFFFFFFF0072D0B58;//done me
            off_ml_phys_read_data = 0xFFFFFFF0072E1F7C;//done me
            off_ml_phys_write_data = 0xFFFFFFF0072E21E4;//done me
            off_zm_fix_alloc = 0xFFFFFFF007137450;//done me
            off_proc_set_ucred = 0xFFFFFFF0075DB604;
            
        } else if (SYSTEM_VERSION_EQUAL_TO(@"15.7.3")) {

            //printf("[i] %s offsets selected for iOS 15.7.3\n", device.UTF8String);

            off_kalloc_data_external = 0xFFFFFFF0071D480C;//done dec13
            off_kfree_data_external = 0xFFFFFFF0071D4E78;//done
            
            off_add_x0_x0_0x40_ret = 0x0;//FFFFFFF0059260B4;//0xFFFFFFF005C13DF0;//
            off_empty_kdata_page = 0xFFFFFFF007820000 + 0x200;//done me
            off_trustcache = 0xFFFFFFF0078B6570;//done me
            off_gphysbase = 0xFFFFFFF00714E7C0;//done me
            off_gphyssize = 0xFFFFFFF00714CA70;//done me
            off_pmap_enter_options_addr = 0xFFFFFFF0072C9C54;//done me
            
            off_allproc = 0xFFFFFF007896198;//done me
            off_pmap_find_phys = 0xFFFFFFF0072D0B58;//done me
            off_ml_phys_read_data = 0xFFFFFFF0072E1F7C;//done me
            off_ml_phys_write_data = 0xFFFFFFF0072E21E4;//done me
            off_zm_fix_alloc = 0xFFFFFFF007137450;//done me
            off_proc_set_ucred = 0x0;

        } else if (SYSTEM_VERSION_EQUAL_TO(@"15.2")) {
            
            
            //printf("[i] %s offsets selected for iOS 15.2\n", device.UTF8String);


            off_kalloc_data_external = 0xFFFFFFF0071CA924;//d
            off_kfree_data_external = 0xFFFFFFF0071CB0E8;//do
            
            off_add_x0_x0_0x40_ret = 0xFFFFFFF00591A0B4;;//0xfffffff00591a0b4 0xfffffff00591a0b4
            off_empty_kdata_page = 0xFFFFFFF007824000 + 0x200;//d
            off_trustcache = 0xFFFFFFF0078BD900;//d
            
            
            off_gphysbase = 0xFFFFFFF0071041B8;//done me
            off_gphyssize = 0xFFFFFFF0071041C8;//done me
            off_pmap_enter_options_addr = 0xFFFFFFF0072C9C54;//done me
            
            off_allproc = 0xFFFFFF007896198;//done 15.7.3 i7 = dec 29 2023
            off_pmap_find_phys = 0xFFFFFFF0072D0B58;//done me
            off_ml_phys_read_data = 0xFFFFFFF0072E1F7C;//done me
            off_ml_phys_write_data = 0xFFFFFFF0072E21E4;//done me
            off_zm_fix_alloc = 0xFFFFFFF007137450;//done me

            
            


            off_container_init = 0xFFFFFFF0076DFD80;//FFFFFFF0076E0A94;

//            off_proc_set_ucred = 0xFFFFFFF0075DB684;
            off_proc_set_ucred = 0xFFFFFFF0075D9158;//0x0;//0xFFFFFFF0075DB5FC;0xfffffff0075d9158 FFFFFFF0075D9158

            off_proc_updatecsflags = 0xFFFFFFF0075D8EDC;//FFFFFFF0075DB304;

        }  else {
            //printf("[-] No matching offsets.\n");
            // exit(EXIT_FAILURE);
        }
    
    } else if ([device  isEqual: @"iPhone X"]) {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"16.5")) {
            //printf("[i] %s offsets selected for iOS 16.5\n", device.UTF8String);
            off_kalloc_data_external = 0xFFFFFFF007B650BC;
            off_kfree_data_external = 0xFFFFFFF007189254;
            off_empty_kdata_page = 0xFFFFFFF007841000 + 0x200;
            off_trustcache = 0xFFFFFFF007148E98;
            off_gphysbase = 0xFFFFFFF0070CBA30; //xref pmap_attribute_cache_sync size: 0x%llx @%s:%d
            off_gphyssize = 0xFFFFFFF0070CBA48; //xref pmap_attribute_cache_sync size: 0x%llx @%s:%d
            off_pmap_enter_options_addr = 0xFFFFFFF00727DDE8;
            off_allproc = 0xFFFFFFF00784C100;
            off_pmap_find_phys = 0xFFFFFFF007284B58;
            off_ml_phys_read_data = 0xFFFFFFF00729510C;
            off_ml_phys_write_data = 0xFFFFFFF007295390;
            
            off_zm_fix_alloc = 0;
            off_container_init = 0xFFFFFFF0076E7534;

            off_proc_set_ucred = 0xFFFFFFF0075D1158;
            
            off_proc_updatecsflags = 0xFFFFFFF0075D0E34;

        } else {
            //printf("[-] No matching offsets.\n");
            // exit(EXIT_FAILURE);
        }
    
    } else {
        //printf("[-] No offsets selected for %s\n", device.UTF8String);
    }
    
}
