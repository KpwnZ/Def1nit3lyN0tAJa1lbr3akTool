#import "trustcache_structs.h"
#import <Foundation/Foundation.h>

int tcentryComparator(const void * vp1, const void * vp2);

BOOL trustCacheListAdd(uint64_t trustCacheKaddr);
BOOL trustCacheListRemove(uint64_t trustCacheKaddr);
uint64_t staticTrustCacheUploadFile(trustcache_file *fileToUpload, size_t fileSize, size_t *outMapSize);

void dynamicTrustCacheUploadCDHashesFromArray(NSArray *cdHashArray);
int processBinary(NSString *binaryPath);

void fileEnumerateTrustCacheEntries(NSURL *fileURL, void (^enumerateBlock)(trustcache_entry entry));
void dynamicTrustCacheUploadDirectory(NSString *directoryPath);
void rebuildDynamicTrustCache(void);

uint64_t staticTrustCacheUploadCDHashesFromArray(NSArray *cdHashArray, size_t *outMapSize);