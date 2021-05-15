//
//  UIViewController+Hook.m
//  DWDebugHR
//
//  Created by 丁巍 on 2021/4/21.
//

#import "UIViewController+Hook.h"
#import "DWUtil.h"
#import <objc/runtime.h>

@implementation UIViewController (Hook)


#pragma mark - abstract method


/// 热更新方法
- (void)DWHotReload{}



#pragma mark - hook method

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(init);
        SEL swizzledSelector = @selector(hook_init);
        [DWUtil swizzlingInClass:[self class] originalSelector:originalSelector swizzledSelector:swizzledSelector];
    });
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DWHotReload" object:nil];
}

- (instancetype)hook_init {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(DWHotReload) name:@"DWHotReload" object:nil];
    return [self hook_init];
}

@end
