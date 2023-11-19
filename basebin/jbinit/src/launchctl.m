#import <Foundation/Foundation.h>
#import <xpc/xpc.h>

#define ROUTINE_LOAD 800
#define ROUTINE_UNLOAD 801

struct _os_alloc_once_s {
  long once;
  void *ptr;
};

struct xpc_global_data {
  uint64_t a;
  uint64_t xpc_flags;
  mach_port_t task_bootstrap_port; /* 0x10 */
#ifndef _64
  uint32_t padding;
#endif
  xpc_object_t xpc_bootstrap_pipe; /* 0x18 */
  // and there's more, but you'll have to wait for MOXiI 2 for those...
  // ...
};

extern struct _os_alloc_once_s _os_alloc_once_table[];
extern void *_os_alloc_once(struct _os_alloc_once_s *slot, size_t sz,
                            os_function_t init);

xpc_object_t launchd_xpc_send_message(xpc_object_t xdict) {
  void *pipePtr = NULL;

  if (_os_alloc_once_table[1].once == -1) {
    pipePtr = _os_alloc_once_table[1].ptr;
  } else {
    pipePtr = _os_alloc_once(&_os_alloc_once_table[1], 472, NULL);
    if (!pipePtr)
      _os_alloc_once_table[1].once = -1;
  }

  xpc_object_t xreply = nil;
  if (pipePtr) {
    struct xpc_global_data *globalData = pipePtr;
    xpc_object_t pipe = globalData->xpc_bootstrap_pipe;
    if (pipe) {
      int err = xpc_pipe_routine_with_flags(pipe, xdict, &xreply, 0);
      if (err != 0) {
        return nil;
      }
    }
  }
  return xreply;
}

int64_t launchctl_load(const char *plistPath, bool unload) {
  xpc_object_t pathArray = xpc_array_create_empty();
  xpc_array_set_string(pathArray, XPC_ARRAY_APPEND, plistPath);

  xpc_object_t msgDictionary = xpc_dictionary_create_empty();
  xpc_dictionary_set_uint64(msgDictionary, "subsystem", 3);
  xpc_dictionary_set_uint64(msgDictionary, "handle", 0);
  xpc_dictionary_set_uint64(msgDictionary, "type", 1);
  xpc_dictionary_set_bool(msgDictionary, "legacy-load", true);
  xpc_dictionary_set_bool(msgDictionary, "enable", false);
  xpc_dictionary_set_uint64(msgDictionary, "routine",
                            unload ? ROUTINE_UNLOAD : ROUTINE_LOAD);
  xpc_dictionary_set_value(msgDictionary, "paths", pathArray);

  xpc_object_t msgReply = launchd_xpc_send_message(msgDictionary);

  char *msgReplyDescription = xpc_copy_description(msgReply);
  NSLog(@"[jbinit] msgReply = %s\n", msgReplyDescription);
  free(msgReplyDescription);

  int64_t bootstrapError =
      xpc_dictionary_get_int64(msgReply, "bootstrap-error");
  if (bootstrapError != 0) {
    NSLog(@"[jbinit] bootstrap-error = %s\n",
          xpc_strerror((int32_t)bootstrapError));
    return bootstrapError;
  }

  int64_t error = xpc_dictionary_get_int64(msgReply, "error");
  if (error != 0) {
    NSLog(@"[jbinit]error = %s\n", xpc_strerror((int32_t)error));
    return error;
  }

  // launchctl seems to do extra things here
  // like getting the audit token via xpc_dictionary_get_audit_token
  // or sometimes also getting msgReply["req_pid"] and msgReply["rec_execcnt"]
  // but we don't really care about that here

  return 0;
}
