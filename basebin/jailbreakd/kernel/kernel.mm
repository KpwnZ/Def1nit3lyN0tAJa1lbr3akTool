#import "kernel.h"
#import "utils.h"
#import "offsets.h"

io_connect_t user_client = 0;

extern struct kinfo kernel_info;

BOOL setup_client() {
    static bool offset_init = false;
    if (!offset_init)
        _offsets_init();
    offset_init = true;
    JBLogDebug("[*] setup kcall");

    io_service_t service = IOServiceGetMatchingService(
        kIOMasterPortDefault, IOServiceMatching("IOSurfaceRoot"));

    if (service == IO_OBJECT_NULL) {
        JBLogDebug("[-] Failed to get IOSurfaceRoot service");
        return NO;
    }

    io_connect_t conn = MACH_PORT_NULL;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &conn);
    if (kr != KERN_SUCCESS) {
        JBLogDebug("[-] Failed to open IOSurfaceRoot service");
        return NO;
    }
    user_client = conn;
    IOObjectRelease(service);

    JBLogDebug("[+] Got user client: 0x%x", user_client);

    return YES;
}

uint64_t get_kernel_slide() {
    return kernel_info.kslide;
}

// uint64_t kcall(uint64_t addr, uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3, uint64_t x4, uint64_t x5) {
//     uint64_t x6 = addr;  // BR X6
//     x2 = x0;             // MOV X0, X2
//     return IOConnectTrap6(user_client, 0, x1, x2, x3, x4, x5, x6);
// }
/*
 uint64_t zm_fix_addr_kalloc(uint64_t addr) {
   // se2 15.0.2 = 0xFFFFFFF00782E718, 6s 15.1 = 0xFFFFFFF0071024B8;
   // XXX guess what is that address xD
   uint64_t kmem = off_zm_fix_addr_kalloc + get_kslide();
   uint64_t zm_alloc = kread64(kmem); // idk?
   uint64_t zm_stripped = zm_alloc & 0xffffffff00000000;

   return (zm_stripped | ((addr)&0xffffffff));
 }

 uint64_t kcall(uint64_t addr, uint64_t x0, uint64_t x1, uint64_t x2,
                uint64_t x3, uint64_t x4, uint64_t x5, uint64_t x6) {
   uint64_t offx20 = kread64(_fake_client + 0x40);
   uint64_t offx28 = kread64(_fake_client + 0x48);
   kwrite64(_fake_client + 0x40, x0);
   kwrite64(_fake_client + 0x48, addr);
   uint64_t returnval = IOConnectTrap6(
       _user_client, 0, (uint64_t)(x1), (uint64_t)(x2), (uint64_t)(x3),
       (uint64_t)(x4), (uint64_t)(x5), (uint64_t)(x6));
   kwrite64(_fake_client + 0x40, offx20);
   kwrite64(_fake_client + 0x48, offx28);
   return returnval;
 }
 
 */
uint64_t kcall(uint64_t addr, uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3, uint64_t x4, uint64_t x5) {
    if (@available(iOS 16, *)) {
        // mov x0, x3
        // br x4
        x4 = addr;
        x3 = x0;
        return IOConnectTrap6(user_client, 0, x1, x2, x3, x4, x5, 0);
    }

    uint64_t x6 = addr;  // BR X6
    // x0 -> x1
    // x1 -> x2
    // x2 -> x3
    // x3 -> x4
    // x4 -> x5
    // IOConnectTrap6(port, 0, x1, x2, x3, x4, x5, x6)
    return IOConnectTrap6(user_client, 0, x0, x1, x2, x3, x4, x6);
}

uint32_t kread32(uint64_t addr) {
    if (@available(iOS 16, *)) {
        return (uint32_t)kcall(kernel_info.kernel_functions.kread_gadget, addr, 0, 0, 0, 0, 0);
    }

    return (uint32_t)kcall(kernel_info.kernel_functions.kread_gadget, 0, addr, 0, 0, 0, 0);
}

uint8_t kread8(uint64_t addr) {
    return kread32(addr) & 0xff;
}

uint64_t kread64(uint64_t addr) {
    uint32_t low32 = kread32(addr);
    uint32_t high32 = kread32(addr + 0x4);
    uint64_t ret = (((uint64_t)high32) << 32) | low32;
    return ret;
}

void kread_string(uint64_t addr, char *out) {
    while (true) {
        uint64_t val = kread64(addr);
        for (int i = 0; i < 8; i++) {
            out[i] = (val >> (i * 8)) & 0xFF;
            if (out[i] == '\0') {
                return;
            }
        }
        addr += 8;
    }
}

uint64_t kalloc(size_t ksize) {
    // kalloc slightly more
    JBLogDebug("[+] Attempting KALLOC");
    JBLogDebug("[+] kernel_info.fake_userclient: 0x%x", kernel_info.fake_userclient);
    JBLogDebug("[+] off_empty_kdata_page + slide: 0x%llx", off_empty_kdata_page + kernel_info.kslide);
    JBLogDebug("[+] off_empty_kdata_page - slide: 0x%llx", off_empty_kdata_page - kernel_info.kslide);
    JBLogDebug("[+] off_empty_kdata_page: 0x%llx", off_empty_kdata_page);
    JBLogDebug("[+] kernel_info.kernel_functions.container_init: 0x%llx", kernel_info.kernel_functions.container_init);
//
     uint64_t r = kcall(kernel_info.kernel_functions.container_init, kernel_info.fake_userclient + 0x200, ksize / 8 + 8, 0, 0, 0, 0);
 //   uint64_t r = kcall(kernel_info.kernel_functions.container_init, off_empty_kdata_page + kernel_info.kslide + 0x200, ksize / 8, 0, 0, 0, 0);
  //  uint64_t r = kcall(off_kalloc_data_external + kernel_info.kslide, ksize, 1, 0, 0, 0, 0);
//    allocated_kmem = zm_fix_addr_kalloc(allocated_kmem);
  //  term_kcall();
    //return allocated_kmem;

    
    if (r == 0) return 0;
    JBLogDebug("[+] r not 0");

//    uint32_t low32 = kread32(kernel_info.fake_userclient + 0x200 + 0x20);
//    uint32_t high32 = kread32(kernel_info.fake_userclient + 0x200 + 0x20 + 0x4);
    uint32_t low32 = kread32(off_empty_kdata_page + kernel_info.kslide + 0x200 + 0x20);
    uint32_t high32 = kread32(off_empty_kdata_page + kernel_info.kslide + 0x200 + 0x20 + 0x4);
    JBLogDebug("[+] high32: 0x%x", high32);

    return (((uint64_t)high32) << 32) | low32;
}

void kwrite64(uint64_t addr, uint64_t data) {
    if (@available(iOS 16, *)) {
        kcall(kernel_info.kernel_functions.kwrite_gadget, addr, data, 0, 0, 0, 0);
        return;
    }

    kcall(kernel_info.kernel_functions.kwrite_gadget, addr, data, addr, 0, 0, 0);
}

void kwrite32(uint64_t addr, uint32_t data) {
    uint32_t low32 = data;
    uint32_t high32 = kread32(addr + 0x4);
    kwrite64(addr, (((uint64_t)high32) << 32) | low32);
}

void kwrite8(uint64_t addr, uint8_t data) {
    uint64_t val = kread64(addr);
    val &= ~((uint64_t)(0xFF));
    val |= data;
    kwrite64(addr, val);
}

void kwritebuf(uint64_t addr, void *buf, size_t size) {
    uint8_t *bytes = (uint8_t *)buf;
    for (int i = 0; i < size; i++) {
        kwrite8(addr + i, bytes[i]);
    }
}

void kreadbuf(uint64_t addr, void *buf, size_t size) {
    uint8_t *bytes = (uint8_t *)buf;
    // group by 32 bit
    for (int i = 0; i < size / 4; i++) {
        uint32_t val = kread32(addr + i * 4);
        for (int j = 0; j < 4; j++) {
            if (i * 4 + j >= size) break;
            bytes[i * 4 + j] = (val >> (j * 8)) & 0xFF;
        }
    }
}
