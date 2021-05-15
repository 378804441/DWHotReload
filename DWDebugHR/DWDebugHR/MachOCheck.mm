//
//  MachOCheck.m
//  SwiftAndC
//
//  Created by 张坤 on 2019/9/29.
//  Copyright © 2019 张坤. All rights reserved.
//


#import "MachOCheck.h"
#import "MachOParser.h"
@implementation MachOCheck
+(NSString*)machO_md5{
    MachOParser *mach = new MachOParser();
    NSString * t = mach->get_text_data_md5();
    return t;
}
+(NSArray *)load_dylib{
    MachOParser *mach = new MachOParser();
    NSArray *arr = mach->find_load_dylib();
    return arr;
}
+ (segment_info_t *)find_segment:(NSString *)segname{
    MachOParser *mach = new MachOParser();
    const char * segname_CC = [segname UTF8String];
    segment_info_t *find_segment = mach->find_segment(segname_CC);
    return find_segment;
}
+(section_info_t *)find_section:(NSString * )segnameA with:(NSString * )segnameB{
    MachOParser *mach = new MachOParser();
    const char * segnameA_CC = [segnameA UTF8String];
    const char * segnameB_CC = [segnameB UTF8String];
    section_info_t *section_info = mach->find_section(segnameA_CC,segnameB_CC);
    return section_info;
}
@end
