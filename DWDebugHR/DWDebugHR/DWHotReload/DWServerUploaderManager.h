//
//  PWServerUploaderManager.h
//  peiwan
//
//  Created by 丁巍 on 2019/7/18.
//  Copyright © 2019 iydzq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


#define serverUploadMg      [DWServerUploaderManager shareInstance]

typedef NS_ENUM(NSInteger, DWServerStatusCode){
    DWServerStatusCode_close = 0,       // 关闭
    DWServerStatusCode_start,           // 开启
    DWServerStatusCode_noWifi,          // 非wifi情况
};


@protocol DWServerUploaderManagerDelegate <NSObject>
@optional

/**
 * 服务器上传成功
 * localPath : 本地存储路径
 * fileName  : 上传的文件名
 */
- (void)serverUploadComplete:(NSString *)localPath fileName:(NSString *)fileName;

/** 服务状态发生改变 */
- (void)serverStatusUpdate:(DWServerStatusCode)status ip:(NSString *)ip;

@end



@interface DWServerUploaderManager : NSObject


#pragma mark - public property

/** 当前服务状态 */
@property (nonatomic, assign) DWServerStatusCode serverStatusCode;


@property(nonatomic, weak) id<DWServerUploaderManagerDelegate> delegate;



#pragma mark - public method

/** 初始化单例 */
+ (DWServerUploaderManager *)shareInstance;


/**
 开启服务
 indexHTML : 上传主页HTML
 */
- (void)startServerWithIndexHTML:(NSString *)indexHTML;


/** 停用server */
- (void)stopServer;

@end

NS_ASSUME_NONNULL_END
