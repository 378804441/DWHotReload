//
//  HTTaskManager.h
//  ExecShellCMD
//
//  Created by  guogh on 2017/4/5.
//  Copyright © 2017年  guogh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTTaskManager : NSObject

+ (instancetype _Nonnull)sharedManager;



/**
 执行shell命令,支持多个命令,用 ' ; '(逗号)分割(非root)
 
 @param cmdStr shell命令
 @param completeBlock 输出回调
 */
- (void)execShellCMDWith:(NSString * _Nonnull )cmdStr
           completeBlock:(void(^_Nullable)(NSString * _Nullable resultStr,NSString * _Nullable errorStr))completeBlock;


/**
 执行shell脚本(可root,需要root的加sudo)

 @param cmdStr shell命令
 @param completeBlock 输出回调
 */
- (void)execShellCMDAsAdmin:(NSString  * _Nonnull )cmdStr
              completeBlock:(void(^ _Nullable)(NSString * _Nullable resultStr,NSString * _Nullable errorStr))completeBlock;


@end
