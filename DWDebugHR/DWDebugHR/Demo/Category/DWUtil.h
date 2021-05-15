//
//  DWUtil.h
//  DWDebugHR
//
//  Created by 丁巍 on 2021/4/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWUtil : NSObject

+(void)swizzlingInClass:(Class)cls originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector;

@end

NS_ASSUME_NONNULL_END
