#import "dyld_patch.h"
#import <dlfcn.h>
#import "./_shared/CoreSymbolication.h"
#import "codesign.h"

typedef CSTypeRef CSSymbolicatorRef;

int applyDyldPatches(NSString *dyldPath) {
    // Find offsets by abusing CoreSymbolication APIs
    void *csHandle = dlopen("/System/Library/PrivateFrameworks/"
                            "CoreSymbolication.framework/CoreSymbolication",
                            RTLD_NOW);
    CSSymbolicatorRef (*__CSSymbolicatorCreateWithPathAndArchitecture)(
        const char *path, cpu_type_t type) =
        (CSSymbolicatorRef(*)(const char *, cpu_type_t))dlsym(
            csHandle, "CSSymbolicatorCreateWithPathAndArchitecture");
    CSSymbolRef (*__CSSymbolicatorGetSymbolWithMangledNameAtTime)(
        CSSymbolicatorRef cs, const char *name, uint64_t time) =
        (CSSymbolRef(*)(CSSymbolicatorRef, const char *, uint64_t))dlsym(
            csHandle, "CSSymbolicatorGetSymbolWithMangledNameAtTime");
    CSRange (*__CSSymbolGetRange)(CSSymbolRef sym) =
        (CSRange(*)(CSSymbolRef))dlsym(csHandle, "CSSymbolGetRange");
        
    CSSymbolicatorRef symbolicator =
        __CSSymbolicatorCreateWithPathAndArchitecture("/usr/lib/dyld", CPU_TYPE_ARM64);
    CSSymbolRef symbol = __CSSymbolicatorGetSymbolWithMangledNameAtTime(
        symbolicator,
        "__ZN5dyld413ProcessConfig8Security7getAMFIERKNS0_7ProcessERNS_15SyscallDelegateE",
        0);
    CSRange range = __CSSymbolGetRange(symbol);
    uint64_t getAMFIOffset = range.location;
    if (getAMFIOffset == 0) {
        return 100;
    }
    NSLog(@"[jailbreakd] found getAMFIOffset: 0x%llx", getAMFIOffset);
    FILE *dyldFile = fopen(dyldPath.fileSystemRepresentation, "rb+");
    if (!dyldFile)
        return 101;
    fseek(dyldFile, getAMFIOffset, SEEK_SET);
    uint32_t patchInstr[2] = {
        0xD2801BE0,  // mov x0, 0xDF
        0xD65F03C0   // ret
    };
    fwrite(patchInstr, sizeof(patchInstr), 1, dyldFile);

    // Def1nit3lyN0tAJa1lbr3akTool temporary workaround for iOS 16
    // In iOS 16, dyld will switch to dyld in cache
    // thus make our getAMFI patch useless
    // the following patch will make dyld always use dyld on disk
    // and we will mount the dmg to make our patched dyld visible
    // the following offsets might be different
    CSSymbolRef start_symbol = __CSSymbolicatorGetSymbolWithMangledNameAtTime(
        symbolicator,
        "start",
        0);
    uint64_t start_addr = __CSSymbolGetRange(start_symbol).location;
    if (start_addr == 0) {
        return 102;
    }
    if (@available(iOS 16, *)) {
        fseek(dyldFile, 0, SEEK_SET);
        fseek(dyldFile, start_addr + 0x184, SEEK_SET);
        NSLog(@"[jailbreakd] found patch addr: 0x%llx", start_addr + 0x184);
        uint32_t patchInstr2[1] = {
            0xD2800000,  // mov x0, 0
        };
        fwrite(patchInstr2, sizeof(patchInstr2), 1, dyldFile);
    }

    if (@available(iOS 16, *)) {
        fseek(dyldFile, 0, SEEK_SET);
        fseek(dyldFile, start_addr + 0x230, SEEK_SET);
        NSLog(@"[jailbreakd] found patch addr: 0x%llx", start_addr + 0x230);
        uint32_t patchInstr3[1] = {
            0xD2800020,  // mov x0, 1
        };
        fwrite(patchInstr3, sizeof(patchInstr3), 1, dyldFile);
    }
    fclose(dyldFile);
    NSLog(@"[jailbreakd] patched dyld");

    int csRet = resignFile(dyldPath, true);
    if (csRet != 0) {
        return csRet;
    }
    NSLog(@"[jailbreakd] resigned dyld");

    return 0;
}
