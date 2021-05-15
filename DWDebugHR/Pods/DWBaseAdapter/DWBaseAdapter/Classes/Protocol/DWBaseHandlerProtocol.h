//
//  DWBaseHandlerProtocol.h
//  DWVideoPlay
//
//  Created by 丁巍 on 2019/3/11.
//  Copyright © 2019 丁巍. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DWBaseHandlerProtocol <NSObject>


@required   /***  必须实现方法 ***/

@optional   /***  可以不实现方法 ***/

/** UIViewcontrol 一些生命周期方法 */
- (void)viewWillDisappear;

- (void)viewDidDisappear;

- (void)viewWillAppear;

- (void)viewDidAppear;


/** handle层统一外吐网络访问成功后数据 */
- (void)networkAccessWithType:(NSInteger)netType
                      success:(void (^__nullable)(NSDictionary *data))success
                         fail:(void (^__nullable)(NSString *error))fail;


/** 对handle进行绑定数据 */
- (void)bindData:(id)data;

@end

NS_ASSUME_NONNULL_END
