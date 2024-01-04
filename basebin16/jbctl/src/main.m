#import "jailbreakd.h"

extern char **environ;

void print_usage(void) {
    printf(
"Usage: jbctl <command> <arguments>\n"
"Available commands:\n"
"ping");
}

int main(int argc, char *argv[]) {
    setvbuf(stdout, NULL, _IOLBF, 0);

    if (argc < 2) {
        print_usage();
        return 0;
    }

    if (!strcmp(argv[1], "ping")) {
        xpc_object_t message = xpc_dictionary_create_empty();
        xpc_dictionary_set_uint64(message, "id", JBD_MSG_PING);
        xpc_dictionary_set_uint64(message, "pid", (uint64_t)getpid());

        xpc_object_t reply = sendJBDMessage(message);
        if (!reply)
            return -10;
        uint64_t ret = xpc_dictionary_get_uint64(reply, "ret");
        uint64_t _id = xpc_dictionary_get_uint64(reply, "id");
        printf("pong 0x%llx, id=%lld\n", ret, _id);
    } else {
        print_usage();
    }

    return 0;
}
