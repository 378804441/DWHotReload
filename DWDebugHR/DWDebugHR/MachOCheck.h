//
//  MachOCheck.h
//  SwiftAndC
//
//  Created by 张坤 on 2019/9/29.
//  Copyright © 2019 张坤. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MachOInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface MachOCheck : NSObject
/**
 获取运行代码md5
 */
+(NSString *)machO_md5;
/**
 获取加载的动态库
 */
+(NSArray *)load_dylib;
/**
 查找某个段
 */
+ (segment_info_t *)find_segment:(NSString * )segname;
/**
 查找某个节
 */
+(section_info_t *)find_section:(NSString * )segnameA with:(NSString * )segnameB;
@end

NS_ASSUME_NONNULL_END
