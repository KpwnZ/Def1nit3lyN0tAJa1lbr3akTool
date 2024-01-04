#import "IOKit/IOKitLib.h"
#import <stdio.h>
#import <CoreFoundation/CoreFoundation.h>
#import <sys/mount.h>
#import <mach/error.h>
#import "dmg.h"
#include <mach/mach.h>
#import <Foundation/Foundation.h>

void run_unsandboxed(void (^block)(void));

int mount_dmg(const char *device, const char *fstype, const char *mnt, const int mntopts) {
    CFDictionaryKeyCallBacks key_callback = kCFTypeDictionaryKeyCallBacks;
    CFDictionaryValueCallBacks value_callback = kCFTypeDictionaryValueCallBacks;
    CFAllocatorRef allocator = kCFAllocatorDefault;
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOHDIXController"));
    io_connect_t connect;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &connect);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[jailbreakd] IOServiceOpen(service, mach_task_self(), 0, &connect) returned %x %s\n", kr, mach_error_string(kr));
        return kr;
    }
    CFMutableDictionaryRef props = CFDictionaryCreateMutable(allocator, 0, &key_callback, &value_callback);
    CFUUIDRef uuid = CFUUIDCreate(allocator);
    CFStringRef uuid_string = CFUUIDCreateString(0, uuid);
    size_t device_path_len = strlen(device);
    CFDataRef path_bytes = CFDataCreateWithBytesNoCopy(allocator, (unsigned char *)device, device_path_len, kCFAllocatorNull);
    CFDictionarySetValue(props, CFSTR("hdik-unique-identifier"), uuid_string);
    CFDictionarySetValue(props, CFSTR("image-path"), path_bytes);
    CFDictionarySetValue(props, CFSTR("autodiskmount"), kCFBooleanFalse);
    CFDictionarySetValue(props, CFSTR("removable"), kCFBooleanTrue);
    CFDataRef hdi_props = CFPropertyListCreateData(allocator, props, kCFPropertyListXMLFormat_v1_0, 0, 0);
    struct HDIImageCreateBlock64 hdi_stru = {
        .magic = HDI_MAGIC,
        .props = (char *)CFDataGetBytePtr(hdi_props),
        .props_size = static_cast<uint64_t>(CFDataGetLength(hdi_props)),
    };
    volatile unsigned long four_L = 4L;
    uint32_t val;
    size_t val_size = sizeof(val);
    kr = IOConnectCallStructMethod(connect, 0, &hdi_stru, sizeof(hdi_stru), &val, &val_size);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[jailbreakd] failed to call external method");
        return kr;
    }
    CFMutableDictionaryRef pmatch = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(pmatch, CFSTR("hdik-unique-identifier"), uuid_string);
    CFMutableDictionaryRef matching = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(matching, CFSTR("IOPropertyMatch"), pmatch);
    io_service_t hdix_service = IOServiceGetMatchingService(kIOMasterPortDefault, matching);
    if (hdix_service == 0) {
        NSLog(@"[jailbreakd] successfully attached, but didn't find top entry in IO registry\n");
        return 1;
    }
    io_iterator_t iter;
    kr = IORegistryEntryCreateIterator(hdix_service, kIOServicePlane, kIORegistryIterateRecursively, &iter);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[jailbreakd] failed to create iterator: %x %s\n", kr, mach_error_string(kr));
        return kr;
    };
    __block uint8_t mount_ret = 0;
    while (1) {
        io_object_t next = IOIteratorNext(iter);
        if ((int)next == 0)
            break;
        CFStringRef bsd_name = (CFStringRef)IORegistryEntryCreateCFProperty(next & 0xffffffff, CFSTR("BSD Name"), 0, 0);
        char buf[1024];
        if (bsd_name == 0)
            continue;
        CFStringGetCString(bsd_name, buf, sizeof(buf), kCFStringEncodingUTF8);
        puts(buf);
        char diskdev_name_buf[512];
        bzero(&diskdev_name_buf, sizeof(diskdev_name_buf));
        snprintf(diskdev_name_buf, sizeof(diskdev_name_buf), "/dev/%s", buf);
        __block char *dev2 = strdup(diskdev_name_buf);
        NSLog(@"[jailbreakd] mounting %s\n", dev2);
        run_unsandboxed(^{ 
            mount_ret = mount(fstype, mnt, mntopts, &dev2);
        });
    }
    if (mount_ret != 0) {
        NSLog(@"[jailbreakd] failed to mount: %s\n", strerror(errno));
        return 1;
    }
    return 0;
}
