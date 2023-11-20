#import <Foundation/Foundation.h>

bool fileExistsOrSymlink(NSString *path, BOOL *isDirectory);

int carbonCopySingle(NSString *sourcePath, NSString *targetPath);

int carbonCopy(NSString *sourcePath, NSString *targetPath);

int setFakeLibVisible(bool visible);

int makeFakeLib(void);

bool isFakeLibBindMountActive(void);

int setFakeLibBindMountActive(bool active);