#import <Foundation/Foundation.h>
#import <mach-o/getsect.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <mach-o/reloc.h>
#import <mach-o/dyld_images.h>
#import <mach-o/fat.h>
#import <mach/mach.h>
#import <mach/machine.h>
#import "csblob.h"

int64_t machoFindArch(FILE *machoFile, uint32_t subtypeToSearch);
int64_t machoFindBestArch(FILE *machoFile);

void machoEnumerateArchs(FILE* machoFile, void (^archEnumBlock)(struct fat_arch* arch, uint32_t archMetadataOffset, uint32_t archOffset, BOOL* stop));;
void machoGetInfo(FILE *candidateFile, bool *isMachoOut, bool *isLibraryOut);
int64_t machoFindBestArch(FILE *machoFile);

void machoEnumerateLoadCommands(FILE *machoFile, uint32_t archOffset, void (^enumerateBlock)(struct load_command cmd, uint32_t cmdOffset));
void machoFindCSData(FILE* machoFile, uint32_t archOffset, uint32_t* outOffset, uint32_t* outSize);
void machoCSDataEnumerateBlobs(FILE *machoFile, uint32_t CSDataStart, uint32_t CSDataSize, void (^enumerateBlock)(struct CSBlob blobDescriptor, uint32_t blobDescriptorOffset, BOOL *stop));
bool machoCSDataIsAdHocSigned(FILE *machoFile, uint32_t CSDataStart, uint32_t CSDataSize);

unsigned CSCodeDirectoryRank(CS_CodeDirectory *cd);
NSData *codeDirectoryCalculateCDHash(CS_CodeDirectory *cd, void *data, size_t size);
NSData *machoCSDataCalculateCDHash(FILE *machoFile, uint32_t CSDataStart, uint32_t CSDataSize);

void machoEnumerateDependencies(FILE *machoFile, uint32_t archOffset, NSString *machoPath, void (^enumerateBlock)(NSString *dependencyPath));