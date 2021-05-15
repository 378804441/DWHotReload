//
//  DWBaseHandler.h
//  DWVideoPlay
//
//  Created by 丁巍 on 2019/3/11.
//  Copyright © 2019 丁巍. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DWBaseHandlerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWBaseHandler : NSObject<DWBaseHandlerProtocol>

#pragma mark - public method

/** 初始化handler --- VC专用*/
- (instancetype)initWithController:(id __nullable)controller adapter:(id __nullable)adapter;

/** 初始化handler --- adapter专用*/
- (instancetype)initWithAdapter:(id __nullable)adapter;

/** 删除绑定在该 handler上的 observer */
- (void)removeObservers;


#pragma mark - public property

/** 控制器里的处理事件 */
@property (nonatomic, weak, readonly) id controler;

/** 适配器里面的处理事件 */
@property (nonatomic, weak, readonly) id adapter;

@end

NS_ASSUME_NONNULL_END
