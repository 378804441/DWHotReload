//
//  MachOInfo.h
//  SwiftAndC
//
//  Created by 张坤 on 2019/9/29.
//  Copyright © 2019 张坤. All rights reserved.
//

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
typedef uint64_t local_addr;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
typedef uint32_t local_addr;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

typedef struct _section_info_t{
    section_t *section;
    local_addr addr;
}section_info_t;

typedef struct _segment_info_t{
    segment_command_t *segment;
    local_addr addr;
}segment_info_t;
