#ifndef _COMMON_H
#define _COMMON_H

#include <CoreFoundation/CoreFoundation.h>
#include <spawn.h>

extern char *JB_SandboxExtensions;
extern char *JB_RootPath;

typedef enum {
  kBinaryConfigDontInject = 1 << 0,
  kBinaryConfigDontProcess = 1 << 1
} kBinaryConfig;

bool stringEndsWith(const char *str, const char *suffix);

kBinaryConfig configForBinary(const char *path, char *const argv[restrict]);

void enumeratePathString(const char *pathsString, void (^enumBlock)(const char *pathString, bool *stop));

int spawn_hook_common(pid_t *restrict pid, const char *restrict path,
					   const posix_spawn_file_actions_t *restrict file_actions,
					   const posix_spawnattr_t *restrict attrp,
					   char *const argv[restrict],
					   char *const envp[restrict],
					   void *pspawn_org);
#endif