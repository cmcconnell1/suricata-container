#include <stdio.h>
#include <stdint.h>
#include <stddef.h>

typedef struct {
    int cmd;
    union {
        struct {
            uint64_t pktsDropped;
        } streamDrop;
    } u;
} NtNetRxCmd_t;
typedef NtNetRxCmd_t* NtNetRxCmd_p;

int NT_Init(int x) { return 0; }
int NT_Done(void) { return 0; }
void NT_ExplainError(int status, char* buffer, int size) { 
    snprintf(buffer, size, "Napatech stub error %d", status); 
}
int NT_NetRxOpen(void* stream, const char* name, int interface, int streamId, int hba) { return 0; }
int NT_NetRxClose(void* stream) { return 0; }
int NT_NetRxGet(void* stream, void* buffer, int timeout) { return -2; }
int NT_NetRxRelease(void* stream, void* buf) { return 0; }
int NT_NetRxRead(void* stream, NtNetRxCmd_p cmd) { 
    if(cmd) { 
        cmd->u.streamDrop.pktsDropped = 0; 
    } 
    return 0; 
}
int NT_NET_GET_PKT_TIMESTAMP(void* buffer) { return 0; }
int NT_NET_GET_PKT_TIMESTAMP_TYPE(void* buffer) { return 1; }
void* NT_NET_GET_PKT_L2_PTR(void* buffer) { return NULL; }
int NT_NET_GET_PKT_WIRE_LENGTH(void* buffer) { return 0; }
