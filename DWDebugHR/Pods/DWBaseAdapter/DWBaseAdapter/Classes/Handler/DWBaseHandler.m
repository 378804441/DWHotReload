//
//  DWBaseHandler.m
//  DWVideoPlay
//
//  Created by 丁巍 on 2019/3/11.
//  Copyright © 2019 丁巍. All rights reserved.
//

#import "DWBaseHandler.h"
#import <objc/runtime.h>


NSString * const DW_BIND_METHOD_KEY = @"DW_BIND_METHOD";

@interface DWBaseHandler()

@property (nonatomic, weak, readwrite) id controler;

@property (nonatomic, weak, readwrite) id adapter;

@end

@implementation DWBaseHandler

- (instancetype)initWithController:(id __nullable)controller adapter:(id __nullable)adapter{
    self = [super init];
    if (self) {
        if (controller) {
            self.controler = controller;
        }
        if (adapter) {
            self.adapter   = adapter;
        }
    }
    return self;
}

/** 初始化handler --- adapter专用*/
- (instancetype)initWithAdapter:(id __nullable)adapter{
    return [self initWithController:nil adapter:adapter];
}

#pragma mark - punlic method

/** 删除绑定在该 handler上的 observer */
- (void)removeObservers{}


#pragma mark - check method send (检查是否在没有重写协议方法时调用)

//+(BOOL)resolveInstanceMethod:(SEL)sel{
//    if (sel == @selector(networkAccessWithSuccess:fail:)) {
//        Method method = class_getInstanceMethod([self class], @selector(errorMethod));
//        objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(DW_BIND_METHOD_KEY), NSStringFromSelector(sel), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//
//        class_addMethod(self, sel,
//                        method_getImplementation(method),
//                        method_getTypeEncoding(method));
//        return YES;
//    }
//    return [super resolveInstanceMethod:sel];
//}
//
//
//-(void)errorMethod{
//    NSString *methodName = objc_getAssociatedObject([self class], (__bridge const void * _Nonnull)(DW_BIND_METHOD_KEY));
//    NSLog(@"额。。。。这个方法没实现哦  \n%@", methodName);
//}

@end
