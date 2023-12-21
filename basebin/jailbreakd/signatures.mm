#import "signatures.h"
#import "macho.h"

int evaluateSignature(NSURL *fileURL, NSData **cdHashOut,
                      BOOL *isAdhocSignedOut) {
    if (!fileURL || (!cdHashOut && !isAdhocSignedOut))
        return 1;
    if (![fileURL checkResourceIsReachableAndReturnError:nil])
        return 2;

    FILE *machoFile = fopen(fileURL.fileSystemRepresentation, "rb");
    if (!machoFile)
        return 3;

    BOOL isMacho = NO;
    machoGetInfo(machoFile, &isMacho, NULL);

    if (!isMacho) {
        fclose(machoFile);
        return 4;
    }

    int64_t archOffset = machoFindBestArch(machoFile);
    if (archOffset < 0) {
        fclose(machoFile);
        return 5;
    }

    uint32_t CSDataStart = 0, CSDataSize = 0;
    machoFindCSData(machoFile, archOffset, &CSDataStart, &CSDataSize);
    if (CSDataStart == 0 || CSDataSize == 0) {
        fclose(machoFile);
        return 6;
    }

    BOOL isAdhocSigned =
        machoCSDataIsAdHocSigned(machoFile, CSDataStart, CSDataSize);
    if (isAdhocSignedOut) {
        *isAdhocSignedOut = isAdhocSigned;
    }

    // we only care about the cd hash on stuff that's already verified to be ad
    // hoc signed
    if (isAdhocSigned && cdHashOut) {
        *cdHashOut = machoCSDataCalculateCDHash(machoFile, CSDataStart, CSDataSize);
    }

    fclose(machoFile);
    return 0;
}