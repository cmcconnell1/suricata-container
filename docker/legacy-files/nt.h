#ifndef NT_H
#define NT_H

#include <stdint.h>
#include <stddef.h>

// Basic Napatech types
typedef void* NtNetBuf_t;
typedef void* NtNetStreamRx_t;
typedef void* NtNetStreamTx_t;
typedef void* NtFlowStream_t;
typedef void* NtNetRx_t;
typedef void* NtNetTx_t;
typedef void* NtNetInterface_t;
typedef void* NtNetStreamEvent_t;
typedef void* NtStatStream_t;
typedef void* NtInfoStream_t;
typedef void* NtConfigStream_t;
typedef int NT_STATUS;

// Status codes
#define NT_SUCCESS 0
#define NT_ERROR_INVALID_PARAMETER -1
#define NT_STATUS_TIMEOUT -2
#define NT_STATUS_TRYAGAIN -3

// API version and constants
#define NTAPI_VERSION 0x03000000
#define NT_NET_INTERFACE_PACKET 1

// Timestamp types
#define NT_TIMESTAMP_TYPE_NATIVE_UNIX 1
#define NT_TIMESTAMP_TYPE_PCAP 2
#define NT_TIMESTAMP_TYPE_PCAP_NANOTIME 3
#define NT_TIMESTAMP_TYPE_NATIVE_NDIS 4

// Command types
#define NT_NETRX_READ_CMD_STREAM_DROP 1
#define NT_INFO_CMD_READ_STREAM 1
#define NT_STATISTICS_READ_CMD_USAGE_DATA_V0 1
#define NT_NTPL_PARSER_VALIDATE_NORMAL 1

// Command structure (matches Suricata expectations)
typedef struct {
    int cmd;
    union {
        struct {
            uint64_t pktsDropped;
        } streamDrop;
    } u;
} NtNetRxCmd_t;
typedef NtNetRxCmd_t* NtNetRxCmd_p;

// Complex Napatech structures
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
                    struct {
                        struct { uint64_t frames; uint64_t bytes; } rx;
                        struct { uint64_t frames; uint64_t bytes; } drop;
                    } stat;
                } hb[16]; // Max host buffers
            } data;
        } usageData_v0;
        struct {
            uint8_t clear;
        } query_v2;
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

// Function declarations
NT_STATUS NT_Init(int);
NT_STATUS NT_Done(void);
void NT_ExplainError(NT_STATUS, char*, int);
NT_STATUS NT_NetRxOpen(NtNetStreamRx_t*, const char*, int, int, int);
NT_STATUS NT_NetRxClose(NtNetStreamRx_t);
NT_STATUS NT_NetRxGet(NtNetStreamRx_t, NtNetBuf_t*, int);
NT_STATUS NT_NetRxRelease(NtNetStreamRx_t, NtNetBuf_t);
NT_STATUS NT_NetRxRead(NtNetStreamRx_t, NtNetRxCmd_p);
NT_STATUS NT_InfoOpen(NtInfoStream_t*, const char*);
NT_STATUS NT_InfoClose(NtInfoStream_t);
NT_STATUS NT_InfoRead(NtInfoStream_t, NtInfo_t*);
NT_STATUS NT_StatOpen(NtStatStream_t*, const char*);
NT_STATUS NT_StatClose(NtStatStream_t);
NT_STATUS NT_StatRead(NtStatStream_t, NtStatistics_t*);
NT_STATUS NT_ConfigOpen(NtConfigStream_t*, const char*);
NT_STATUS NT_ConfigClose(NtConfigStream_t);
NT_STATUS NT_NTPL(NtConfigStream_t, const char*, NtNtplInfo_t*, int);
int NT_NET_GET_PKT_TIMESTAMP(NtNetBuf_t);
int NT_NET_GET_PKT_TIMESTAMP_TYPE(NtNetBuf_t);
void* NT_NET_GET_PKT_L2_PTR(NtNetBuf_t);
int NT_NET_GET_PKT_WIRE_LENGTH(NtNetBuf_t);

#endif
#define NT_STATISTICS_READ_CMD_QUERY_V2 2
#define LEGACY_REFACTOR_CUSTOM_HEADER_LOADED 1
