#import "utils.h"

NSString *proc_get_path(pid_t pid) {
    char pathbuf[4 * MAXPATHLEN];
    int ret = proc_pidpath(pid, pathbuf, sizeof(pathbuf));
    if (ret <= 0)
        return nil;
    return [[[NSString stringWithUTF8String:pathbuf]
        stringByResolvingSymlinksInPath] stringByStandardizingPath];
}
