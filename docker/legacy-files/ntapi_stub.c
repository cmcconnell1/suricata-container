#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>

// Replicate the structures from nt.h
typedef struct {
    int cmd;
    union {
        struct {
            uint64_t pktsDropped;
        } streamDrop;
    } u;
} NtNetRxCmd_t;
typedef NtNetRxCmd_t* NtNetRxCmd_p;

typedef struct {
    int cmd;
    union {
        struct {
            struct {
                uint32_t count;
            } data;
        } stream;
        struct {
            char errBuffer[3][256];
        } errorData;
    } u;
} NtInfo_t;

typedef struct {
    int cmd;
    union {
        struct {
            uint8_t streamid;
            struct {
                uint32_t numHostBufferUsed;
                struct {
                    struct {
                        uint64_t used;
                        uint64_t size;
                    } onboardBuffering;
                    uint64_t enQueuedAdapter;
                    uint64_t deQueued;
                    uint64_t enQueued;
                    uint32_t numaNode;
                } hb[16];
            } data;
        } usageData_v0;
    } u;
} NtStatistics_t;

typedef struct {
    int ntplId;
    union {
        struct {
            char errBuffer[3][256];
        } errorData;
    } u;
} NtNtplInfo_t;

// Basic function implementations
int NT_Init(int x) { return 0; }
int NT_Done(void) { return 0; }
void NT_ExplainError(int status, char* buffer, int size) { 
    snprintf(buffer, size, "Napatech stub error %d", status); 
}

// Network stream functions
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

// Info stream functions
int NT_InfoOpen(void* info_stream, const char* name) { return 0; }
int NT_InfoClose(void* info_stream) { return 0; }
int NT_InfoRead(void* info_stream, NtInfo_t* info) {
    if(info) {
        info->cmd = 1;
        info->u.stream.data.count = 1; // Simulate 1 stream
        // Clear error buffers
        memset(info->u.errorData.errBuffer[0], 0, 256);
        memset(info->u.errorData.errBuffer[1], 0, 256);
        memset(info->u.errorData.errBuffer[2], 0, 256);
    }
    return 0;
}

// Statistics functions
int NT_StatOpen(void* stat_stream, const char* name) { return 0; }
int NT_StatClose(void* stat_stream) { return 0; }
int NT_StatRead(void* stat_stream, NtStatistics_t* stat) {
    if(stat) {
        stat->cmd = 1;
        stat->u.usageData_v0.streamid = 0;
        stat->u.usageData_v0.data.numHostBufferUsed = 1;
        // Initialize first host buffer
        stat->u.usageData_v0.data.hb[0].onboardBuffering.used = 0;
        stat->u.usageData_v0.data.hb[0].onboardBuffering.size = 1024;
        stat->u.usageData_v0.data.hb[0].enQueuedAdapter = 0;
        stat->u.usageData_v0.data.hb[0].deQueued = 0;
        stat->u.usageData_v0.data.hb[0].enQueued = 0;
        stat->u.usageData_v0.data.hb[0].numaNode = 0;
    }
    return 0;
}

// Configuration functions
int NT_ConfigOpen(void* config_stream, const char* name) { return 0; }
int NT_ConfigClose(void* config_stream) { return 0; }
int NT_NTPL(void* config_stream, const char* ntpl_cmd, NtNtplInfo_t* info, int validate_mode) {
    if(info) {
        info->ntplId = 1; // Simulate successful filter ID
        // Clear error buffers
        memset(info->u.errorData.errBuffer[0], 0, 256);
        memset(info->u.errorData.errBuffer[1], 0, 256);
        memset(info->u.errorData.errBuffer[2], 0, 256);
    }
    return 0;
}

// Packet access functions
int NT_NET_GET_PKT_TIMESTAMP(void* buffer) { return 0; }
int NT_NET_GET_PKT_TIMESTAMP_TYPE(void* buffer) { return 1; }
void* NT_NET_GET_PKT_L2_PTR(void* buffer) { return NULL; }
int NT_NET_GET_PKT_WIRE_LENGTH(void* buffer) { return 0; }
