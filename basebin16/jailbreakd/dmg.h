#ifndef dmg_h
#define dmg_h

#define HDI_MAGIC 0x1beeffeed
struct HDIImageCreateBlock64
{
  uint64_t magic;
  const void *props;
  uint64_t props_size;
  char padding[0x100 - 24];
};
int mount_dmg(const char *device, const char *fstype, const char *mnt, const int mntopts);

#endif
