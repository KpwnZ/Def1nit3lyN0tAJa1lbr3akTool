#import "dyld_patch.h"
#import <dlfcn.h>
#import "./_shared/CoreSymbolication.h"
#import "codesign.h"

// /*
//  * Types
//  */
// // Under the hood the framework basically just calls through to a set of C++
// libraries struct sCSTypeRef { 	void* csCppData;	// typically
// retrieved using CSCppSymbol...::data(csData & 0xFFFFFFF8) 	void* csCppObj;
// // a pointer to the actual CSCppObject
// };
// typedef struct sCSTypeRef CSTypeRef;

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
    // void (*__CSRelease)(CSTypeRef ptr) = dlsym(csHandle, "CSRelease");

    CSSymbolicatorRef symbolicator =
        __CSSymbolicatorCreateWithPathAndArchitecture("/usr/lib/dyld",
                                                      CPU_TYPE_ARM64);
    CSSymbolRef symbol = __CSSymbolicatorGetSymbolWithMangledNameAtTime(
        symbolicator,
        "__ZN5dyld413ProcessConfig8Security7getAMFIERKNS0_7ProcessERNS_"
        "15SyscallDelegateE",
        0);
    CSRange range = __CSSymbolGetRange(symbol);
    //__CSRelease(symbolicator);
    //__CSRelease(symbol);
    uint64_t getAMFIOffset = range.location;
    if (getAMFIOffset == 0) {
        return 100;
    }

    FILE *dyldFile = fopen(dyldPath.fileSystemRepresentation, "rb+");
    if (!dyldFile)
        return 101;
    fseek(dyldFile, getAMFIOffset, SEEK_SET);
    uint32_t patchInstr[2] = {
        0xD2801BE0,  // mov x0, 0xDF
        0xD65F03C0   // ret
    };
    fwrite(patchInstr, sizeof(patchInstr), 1, dyldFile);
    fclose(dyldFile);
    NSLog(@"[jailbreakd] patched dyld");

    int csRet = resignFile(dyldPath, true);
    if (csRet != 0) {
        return csRet;
    }
    NSLog(@"[jailbreakd] resigned dyld");

    return 0;
}