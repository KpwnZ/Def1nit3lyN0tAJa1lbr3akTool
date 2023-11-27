#import "csblob.h"
#import <uuid/uuid.h>

typedef struct sTrustcache_entry
{
	uint8_t hash[CS_CDHASH_LEN];
	uint8_t hash_type;
	uint8_t flags;
} __attribute__((__packed__)) trustcache_entry;

typedef struct sTrustcache_entry2 {
    uint8_t hash[CS_CDHASH_LEN];
    uint8_t hash_type;
    uint8_t flags;
	uint8_t constraints;
	uint8_t padding;
} __attribute__((__packed__)) trustcache_entry2;

typedef struct sTrustcache_file
{
	uint32_t version;
	uuid_t uuid;
	uint32_t length;
	trustcache_entry entries[];
} __attribute__((__packed__)) trustcache_file;

typedef struct sTrustcache_file2 {
    uint32_t version;
    uuid_t uuid;
    uint32_t length;
    trustcache_entry2 entries[];
} __attribute__((__packed__)) trustcache_file2;

typedef struct sTrustcache_page
{
	uint64_t nextPtr;
	uint64_t selfPtr;
	trustcache_file file;
} __attribute__((__packed__)) trustcache_page;

typedef struct trustcache_module {
    uint64_t nextptr;
    uint64_t prevptr;
    uint64_t padding1;
    uint64_t module_size;
    trustcache_file2 *fileptr;
    trustcache_file2 file;
} __attribute__((__packed__)) trustcache_module;
