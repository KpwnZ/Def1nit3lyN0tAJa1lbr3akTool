#import "trustcache.h"
#import <Foundation/Foundation.h>
#import "JBDTCPage.h"
#import "boot_info.h"
#import "kernel/kernel.h"
#import "macho.h"
#import "signatures.h"
#import "utils/proc.h"

extern struct kinfo kernel_info;

int tcentryComparator(const void *vp1, const void *vp2) {
    if (@available(iOS 16.0, *)) {
        trustcache_entry2 *tc1 = (trustcache_entry2 *)vp1;
        trustcache_entry2 *tc2 = (trustcache_entry2 *)vp2;
        return memcmp(tc1->hash, tc2->hash, CS_CDHASH_LEN);
    }

    trustcache_entry *tc1 = (trustcache_entry *)vp1;
    trustcache_entry *tc2 = (trustcache_entry *)vp2;
    return memcmp(tc1->hash, tc2->hash, CS_CDHASH_LEN);
}

JBDTCPage *trustCacheFindFreePage(void) {
    // Find page that has slots left
    NSLog(@"[jailbreakd] trustCacheFindFreePage");
    for (JBDTCPage *page in gTCPages) {
        @autoreleasepool {
            if (page.amountOfSlotsLeft > 0) {
                NSLog(@"[jailbreakd] trustCacheFindFreePage returning page: %@", page);
                return page;
            }
        }
    }

    // No page found, allocate new one
    NSLog(@"[jailbreakd] trustCacheFindFreePage No page found, allocate new one");
    return [[JBDTCPage alloc] initAllocateAndLink];
}

BOOL isCdHashInTrustCache(NSData *cdHash) {
    kern_return_t kr;

    CFMutableDictionaryRef amfiServiceDict =
        IOServiceMatching("AppleMobileFileIntegrity");
    if (amfiServiceDict) {
        io_connect_t connect;
        io_service_t amfiService =
            IOServiceGetMatchingService(kIOMasterPortDefault, amfiServiceDict);
        kr = IOServiceOpen(amfiService, mach_task_self(), 0, &connect);
        if (kr != KERN_SUCCESS) {
            NSLog(@"[jailbreakd] Failed to open amfi service %d %s", kr,
                  mach_error_string(kr));
            return -2;
        }

        uint64_t includeLoadedTC = YES;
        kr = IOConnectCallMethod(
            connect, AMFI_IS_CD_HASH_IN_TRUST_CACHE, &includeLoadedTC, 1,
            CFDataGetBytePtr((__bridge CFDataRef)cdHash),
            CFDataGetLength((__bridge CFDataRef)cdHash), 0, 0, 0, 0);
        NSLog(@"[jailbreakd] Is %s in TrustCache? %s",
              cdHash.description.UTF8String, kr == 0 ? "Yes" : "No");

        IOServiceClose(connect);
        return kr == 0;
    }

    return NO;
}

BOOL trustCacheListAdd(uint64_t trustCacheKaddr) {
    NSLog(@"[jailbreakd] trustCacheListAdd: trustCacheKaddr: 0x%llx\n",
          trustCacheKaddr);
    if (!trustCacheKaddr)
        return NO;
    NSLog(@"[jailbreakd] trustCacheListAdd: pmap_image4_trust_caches: 0x%llx\n",
          kernel_info.pmap_image4_trust_caches);
    uint64_t pmap_image4_trust_caches = kernel_info.pmap_image4_trust_caches;
    uint64_t curTc = kread64(pmap_image4_trust_caches);
    if (curTc == 0) {
        kwrite64(pmap_image4_trust_caches, trustCacheKaddr);
        kwrite64(trustCacheKaddr, 0);
    } else {
        uint64_t prevTc = 0;
        while (curTc != 0) {
            prevTc = curTc;
            curTc = kread64(curTc);
        }
        if (@available(iOS 16.0, *)) {
            kwrite64(prevTc, trustCacheKaddr);
            kwrite64(trustCacheKaddr, 0);
            kwrite64(trustCacheKaddr + 8, prevTc);
        } else {
            kwrite64(prevTc, trustCacheKaddr);
            kwrite64(trustCacheKaddr, 0);
        }
    }

    return YES;
}

BOOL trustCacheListRemove(uint64_t trustCacheKaddr) {
    if (!trustCacheKaddr)
        return NO;

    uint64_t nextPtr =
        kread64(trustCacheKaddr + offsetof(trustcache_page, nextPtr));

    uint64_t pmap_image4_trust_caches = kernel_info.pmap_image4_trust_caches;
    uint64_t curTc = kread64(pmap_image4_trust_caches);
    if (curTc == 0) {
        NSLog(@"[jailbreakd] WARNING: Tried to unlink trust cache page 0x%llX but "
               "pmap_image4_trust_caches points to 0x0",
              trustCacheKaddr);
        return NO;
    } else if (curTc == trustCacheKaddr) {
        kwrite64(pmap_image4_trust_caches, nextPtr);
    } else {
        uint64_t prevTc = 0;
        while (curTc != trustCacheKaddr) {
            if (curTc == 0) {
                NSLog(@"[jailbreakd] WARNING: Hit end of trust cache chain while "
                      @"trying to "
                       "unlink trust cache page 0x%llX",
                      trustCacheKaddr);
                return NO;
            }
            prevTc = curTc;
            curTc = kread64(curTc);
        }
        kwrite64(prevTc, nextPtr);
    }
    return YES;
}

uint64_t staticTrustCacheUploadFile(trustcache_file *fileToUpload,
                                    size_t fileSize, size_t *outMapSize) {
    NSLog(@"[jailbreakd] staticTrustCacheUploadFile: fileSize: 0x%zx\n", fileSize);
    if (fileSize < sizeof(trustcache_file)) {
        NSLog(@"[jailbreakd] attempted to load a trustcache file that's too "
              @"small.\n");
        return 0;
    }

    size_t expectedSize =
        sizeof(trustcache_file) + fileToUpload->length * sizeof(trustcache_entry);
    if (@available(iOS 16.0, *)) {
        expectedSize = sizeof(trustcache_file2) +
                       fileToUpload->length * sizeof(trustcache_entry2);
    }
    if (expectedSize != fileSize) {
        NSLog(@"[jailbreakd] attempted to load a trustcache file with an invalid "
              @"size (0x%zX vs 0x%zX)\n",
              expectedSize, fileSize);
        return 0;
    }

    uint64_t mapSize = sizeof(trustcache_page) + fileSize;
    if (@available(iOS 16.0, *)) {
        mapSize = sizeof(trustcache_module) + fileSize;
    }

    uint64_t mapKaddr = kalloc(mapSize);
    NSLog(@"[jailbreakd]: kalloc(%llu) -> 0x%llx\n", mapSize, mapKaddr);
    kwrite64(mapKaddr, 0x4141414141414141);
    uint64_t test = kread64(mapKaddr);
    NSLog(@"[jailbreakd]: kread64(0x%llx) -> 0x%llx\n", mapKaddr, test);
    kwrite64(mapKaddr, 0x0);

    if (!mapKaddr) {
        NSLog(@"[jailbreakd] failed to allocate memory for trust cache file with "
              @"size %zX\n",
              fileSize);
        return 0;
    }

    if (outMapSize)
        *outMapSize = mapSize;

    if (@available(iOS 16.0, *)) {
        uint64_t module_size_ptr = mapKaddr + offsetof(trustcache_module, module_size);
        kwrite64(module_size_ptr, fileSize);
        uint64_t module_fileptr_ptr = mapKaddr + offsetof(trustcache_module, fileptr);
        kwrite64(module_fileptr_ptr, mapKaddr + 0x28);
        kwritebuf(mapKaddr + 0x28, fileToUpload, fileSize);
        trustCacheListAdd(mapKaddr);
        return mapKaddr;
    }

    uint64_t mapSelfPtrPtr = mapKaddr + offsetof(trustcache_page, selfPtr);
    uint64_t mapSelfPtr = mapKaddr + offsetof(trustcache_page, file);

    kwrite64(mapSelfPtrPtr, mapSelfPtr);

    kwritebuf(mapSelfPtr, fileToUpload, fileSize);

    trustCacheListAdd(mapKaddr);
    return mapKaddr;
}

void dynamicTrustCacheUploadCDHashesFromArray(NSArray *cdHashArray) {
    __block JBDTCPage *mappedInPage = nil;
    for (NSData *cdHash in cdHashArray) {
        @autoreleasepool {
            if (!mappedInPage || mappedInPage.amountOfSlotsLeft == 0) {
                // If there is still a page mapped, map it out now
                if (mappedInPage) {
                    NSLog(@"[jailbreakd] there is still a page mapped, map it out now");
                    [mappedInPage sort];
                }
                mappedInPage = trustCacheFindFreePage();
                NSLog(@"[jailbreakd] mappedInPage self: %@, kaddr: 0x%llx\n",
                      mappedInPage, mappedInPage.kaddr);
            }

            if (@available(iOS 16.0, *)) {
                trustcache_entry2 entry;
                memcpy(&entry.hash, cdHash.bytes, CS_CDHASH_LEN);
                entry.hash_type = 0x2;
                entry.flags = 0x0;
                NSLog(@"[jailbreakd] [dynamicTrustCacheUploadCDHashesFromArray] "
                      @"uploading %s",
                      cdHash.description.UTF8String);
                [mappedInPage addEntry2:entry];
                continue;
            }

            trustcache_entry entry;
            memcpy(&entry.hash, cdHash.bytes, CS_CDHASH_LEN);
            entry.hash_type = 0x2;
            entry.flags = 0x0;
            NSLog(@"[jailbreakd] [dynamicTrustCacheUploadCDHashesFromArray] "
                  @"uploading %s",
                  cdHash.description.UTF8String);
            [mappedInPage addEntry:entry];
        }
    }

    if (mappedInPage) {
        [mappedInPage sort];
    }
    NSLog(@"[jailbreakd] [dynamicTrustCacheUploadCDHashesFromArray] trigger updateTCPage");
    usleep(10000);
    [mappedInPage updateTCPage];
}

int processBinary(NSString *binaryPath) {
    if (!binaryPath)
        return 0;
    if (![[NSFileManager defaultManager] fileExistsAtPath:binaryPath])
        return 0;

    int ret = 0;

    FILE *machoFile = fopen(binaryPath.fileSystemRepresentation, "rb");
    if (!machoFile)
        return 1;

    if (machoFile) {

        bool isMacho = NO;
        bool isLibrary = NO;
        machoGetInfo(machoFile, &isMacho, &isLibrary);

        if (isMacho) {
            int64_t bestArchCandidate = machoFindBestArch(machoFile);
            if (bestArchCandidate >= 0) {
                uint32_t bestArch = bestArchCandidate;
                NSMutableArray *nonTrustCachedCDHashes = [NSMutableArray new];

                void (^tcCheckBlock)(NSString *) = ^(NSString *dependencyPath) {
                  if (dependencyPath) {
                      NSURL *dependencyURL = [NSURL fileURLWithPath:dependencyPath];
                      NSData *cdHash = nil;
                      BOOL isAdhocSigned = NO;
                      evaluateSignature(dependencyURL, &cdHash, &isAdhocSigned);
                      if (isAdhocSigned) {
                          if (!isCdHashInTrustCache(cdHash)) {
                              [nonTrustCachedCDHashes addObject:cdHash];
                          }
                      }
                  }
                };

                tcCheckBlock(binaryPath);

                machoEnumerateDependencies(machoFile, bestArch, binaryPath,
                                           tcCheckBlock);

                dynamicTrustCacheUploadCDHashesFromArray(nonTrustCachedCDHashes);
            } else {
                ret = 3;
            }
        } else {
            ret = 2;
        }
        fclose(machoFile);
    } else {
        ret = 1;
    }

    return ret;
}

void fileEnumerateTrustCacheEntries(
    NSURL *fileURL, void (^enumerateBlock)(trustcache_entry entry)) {
    NSData *cdHash = nil;
    BOOL adhocSigned = NO;
    int evalRet = evaluateSignature(fileURL, &cdHash, &adhocSigned);
    if (evalRet == 0) {
        NSLog(@"[jailbreakd] %s cdHash: %s, adhocSigned: %d",
              fileURL.path.UTF8String, cdHash.description.UTF8String, adhocSigned);
        if (adhocSigned) {
            if ([cdHash length] == CS_CDHASH_LEN) {
                trustcache_entry entry;
                memcpy(&entry.hash, [cdHash bytes], CS_CDHASH_LEN);
                entry.hash_type = 0x2;
                entry.flags = 0x0;
                enumerateBlock(entry);
            }
        }
    } else if (evalRet != 4) {
        NSLog(@"[jailbreakd] evaluateSignature failed with error %d", evalRet);
    }
}

void dynamicTrustCacheUploadDirectory(NSString *directoryPath) {
    NSString *basebinPath = [[prebootPath(@"basebin")
        stringByResolvingSymlinksInPath] stringByStandardizingPath];
    NSString *resolvedPath = [[directoryPath stringByResolvingSymlinksInPath]
        stringByStandardizingPath];
    NSDirectoryEnumerator<NSURL *> *directoryEnumerator =
        [[NSFileManager defaultManager]
                       enumeratorAtURL:[NSURL fileURLWithPath:resolvedPath
                                                  isDirectory:YES]
            includingPropertiesForKeys:@[ NSURLIsSymbolicLinkKey ]
                               options:0
                          errorHandler:nil];
    __block JBDTCPage *mappedInPage = nil;
    for (NSURL *enumURL in directoryEnumerator) {
        @autoreleasepool {
            NSNumber *isSymlink;
            [enumURL getResourceValue:&isSymlink
                               forKey:NSURLIsSymbolicLinkKey
                                error:nil];
            if (isSymlink && ![isSymlink boolValue]) {
                // never inject basebin binaries here
                if ([[[enumURL.path stringByResolvingSymlinksInPath]
                        stringByStandardizingPath] hasPrefix:basebinPath])
                    continue;
                fileEnumerateTrustCacheEntries(enumURL, ^(trustcache_entry entry) {
                  if (!mappedInPage || mappedInPage.amountOfSlotsLeft == 0) {
                      // If there is still a page mapped, map it out now
                      if (mappedInPage) {
                          [mappedInPage sort];
                      }
                      NSLog(@"[jailbreakd] mapping in a new tc page");
                      mappedInPage = trustCacheFindFreePage();
                  }

                  // [mappedInPage updateTCPage];
                  NSLog(@"[jailbreakd] [dynamicTrustCacheUploadDirectory %s] Uploading "
                        @"cdhash of %s",
                        directoryPath.UTF8String, enumURL.path.UTF8String);
                  if (@available(iOS 16.0, *)) {
                      trustcache_entry2 entry2;
                      memcpy(&entry2.hash, entry.hash, CS_CDHASH_LEN);
                      entry2.hash_type = entry.hash_type;
                      entry2.flags = entry.flags;
                      [mappedInPage addEntry2:entry2];
                  } else {
                      [mappedInPage addEntry:entry];
                  }
                });
            }
        }
    }

    if (mappedInPage) {
        [mappedInPage sort];
    }
    NSLog(@"[jailbreakd] [dynamicTrustCacheUploadDirectory] trigger updateTCPage");
    [mappedInPage updateTCPage];
}

void rebuildDynamicTrustCache(void) {
    // nuke existing
    for (JBDTCPage *page in [gTCPages reverseObjectEnumerator]) {
        @autoreleasepool {
            [page unlinkAndFree];
        }
    }

    NSLog(@"[jailbreakd] Triggering initial trustcache upload...");
    dynamicTrustCacheUploadDirectory(prebootPath(nil));
    NSLog(@"[jailbreakd] Initial TrustCache upload done!");
}

uint64_t staticTrustCacheUploadCDHashesFromArray(NSArray *cdHashArray,
                                                 size_t *outMapSize) {
    size_t fileSize =
        sizeof(trustcache_file) + cdHashArray.count * sizeof(trustcache_entry);
    trustcache_file *fileToUpload = (trustcache_file *)malloc(fileSize);

    if (@available(iOS 16.0, *)) {
        fileSize = sizeof(trustcache_file2) +
                   cdHashArray.count * sizeof(trustcache_entry2);
        fileToUpload = (trustcache_file *)malloc(fileSize);
        uuid_generate(((trustcache_file2 *)fileToUpload)->uuid);
        ((trustcache_file2 *)fileToUpload)->version = 2;
        ((trustcache_file2 *)fileToUpload)->length = cdHashArray.count;
    } else {
        uuid_generate(fileToUpload->uuid);
        fileToUpload->version = 1;
        fileToUpload->length = cdHashArray.count;
    }

    [cdHashArray
        enumerateObjectsUsingBlock:^(NSData *cdHash, NSUInteger idx, BOOL *stop) {
          if (![cdHash isKindOfClass:[NSData class]])
              return;
          if (cdHash.length != CS_CDHASH_LEN)
              return;
          if (@available(iOS 16.0, *)) {
              trustcache_entry2 entry;
              memcpy(&entry.hash, cdHash.bytes, CS_CDHASH_LEN);
              entry.hash_type = 0x2;
              entry.flags = 0x0;
              ((trustcache_file2 *)fileToUpload)->entries[idx] = entry;
              return;
          } else {
              memcpy(&fileToUpload->entries[idx].hash, cdHash.bytes, cdHash.length);
              fileToUpload->entries[idx].hash_type = 0x2;
              fileToUpload->entries[idx].flags = 0x0;
          }
        }];

    if (@available(iOS 16.0, *)) {
        qsort(((trustcache_file2 *)fileToUpload)->entries, cdHashArray.count, sizeof(trustcache_entry2),
            tcentryComparator);
    } else {
        qsort(fileToUpload->entries, cdHashArray.count, sizeof(trustcache_entry),
            tcentryComparator);
    }

    uint64_t mapKaddr =
        staticTrustCacheUploadFile(fileToUpload, fileSize, outMapSize);
    free(fileToUpload);
    return mapKaddr;
}