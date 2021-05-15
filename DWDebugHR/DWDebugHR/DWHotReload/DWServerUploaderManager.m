//
//  PWServerUploaderManager.m
//  peiwan
//
//  Created by 丁巍 on 2019/7/18.
//  Copyright © 2019 iydzq.com. All rights reserved.
//

#import "DWServerUploaderManager.h"
#import "GCDWebServer.h"
#import "GCDWebUploader.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerMultiPartFormRequest.h"

#import "BundleInjection.h"
#import <dlfcn.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#import <mach-o/arch.h>
#import <mach-o/getsect.h>


typedef struct mach_header_64 mach_header_t;

#define IsNull(obj)   (obj == nil || [obj isEqual:[NSNull null]])
#define IsEmpty(str)  (str == nil || ![str respondsToSelector:@selector(isEqualToString:)] || [str isEqualToString:@""])

#define WS(weakSelf)    __weak __typeof(&*self)weakSelf = self
#define SS(strongSelf)  __strong __typeof__(weakSelf) strongSelf = weakSelf

#ifndef xc_dispatch_queue_async_safe
#define xc_dispatch_queue_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
block();\
} else {\
dispatch_async(queue, block);\
}
#endif

FOUNDATION_STATIC_INLINE void DWSafeThread(dispatch_block_t block) {
    xc_dispatch_queue_async_safe(dispatch_get_main_queue(), block)
}


@interface DWServerUploaderManager()<GCDWebServerDelegate, GCDWebUploaderDelegate>

/** server manager */
@property (nonatomic, strong) GCDWebUploader *webUploaderManager;

/** 上传HTML首页 */
@property (nonatomic, strong) NSString *indexHTML;

/** 动态加载类对象 */
@property (nonatomic, strong) Class MyClass;

@end



@implementation DWServerUploaderManager


+ (DWServerUploaderManager *)shareInstance {
    static DWServerUploaderManager *instance = nil;
    static dispatch_once_t obj;
    dispatch_once(&obj, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}


#pragma mark - public method

/**
 开启服务
 indexHTML :
 */
- (void)startServerWithIndexHTML:(NSString *)indexHTML{
    if (self.serverStatusCode == DWServerStatusCode_start) return;
    self.indexHTML = indexHTML;
    [self.webUploader startWithPort:8080 bonjourName:nil];
}


/** 停用server */
- (void)stopServer{
    if (self.serverStatusCode == DWServerStatusCode_close) return;
    [self.webUploader stop];
}



#pragma mark - private method


/* 上传成功后触发的方法 */
- (GCDWebServerResponse*)__uploadFile:(GCDWebServerMultiPartFormRequest*)request {
    NSString *contentType = @"application/json";
    
    // 文件管理manager
    NSFileManager *fileManage = [NSFileManager defaultManager];
    
    // 上传文件临时存储路径
    NSString *tempPath = [request.files firstObject].temporaryPath;
    
    // 文件名称
    NSString* fileName = [request.files firstObject].fileName;
    
    // 创建文件夹
    [self __createDownloadPath];
    
    // 文件移动目标路径
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@/%@", @"DW_HOTRELOAD_LOCAL_PATH", fileName]];

    
    // 进行文件移动
    if (![fileManage fileExistsAtPath:path]) {
        BOOL isSuccess = [fileManage moveItemAtPath:tempPath toPath:path error:nil];
        if (isSuccess) {
            if ([self.delegate respondsToSelector:@selector(serverUploadComplete:fileName:)]) {
                DWSafeThread(^{
                    [self.delegate serverUploadComplete:path fileName:fileName];
                });
            }

            [self hotReload:path];
            return [GCDWebServerDataResponse responseWithJSONObject:@{@"ret":@(1), @"message":@"上传成功"} contentType:contentType];
        }
        
    // 文件存在
    }else{
        [fileManage removeItemAtPath:path error:nil]; // 先删除
        BOOL isSuccess = [fileManage moveItemAtPath:tempPath toPath:path error:nil];
        if (isSuccess) {
            if ([self.delegate respondsToSelector:@selector(serverUploadComplete:fileName:)]) {
                DWSafeThread(^{
                    [self.delegate serverUploadComplete:path fileName:fileName];
                });
            }
            [self hotReload:path];
            return [GCDWebServerDataResponse responseWithJSONObject:@{@"ret":@(1), @"message":@"上传成功"} contentType:contentType];
        }
    }
    
    return [GCDWebServerDataResponse responseWithJSONObject:@{@"ret":@(0), @"message":@"未知错误"} contentType:contentType];
}


/** 创建下载路径 */
- (void)__createDownloadPath{
    NSString * docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * rarFilePath = [docsdir stringByAppendingPathComponent:@"DW_HOTRELOAD_LOCAL_PATH"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir   = NO;
    
    // 判断一个文件或目录是否有效
    BOOL existed = [fileManager fileExistsAtPath:rarFilePath isDirectory:&isDir];
    
    // 如果文件夹不存在
    if ( !(isDir == YES && existed == YES) ) {
        [fileManager createDirectoryAtPath:rarFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}



// 热梗dylib
- (void)hotReload:(NSString *)patch{
    
    // 如果是真机的话路径需要改一下
    if([patch rangeOfString:@"Simulator"].location == NSNotFound){
        patch = [NSString stringWithFormat:@"/private%@", patch];
    }
    
    char *dylibPatch = [patch UTF8String];
    const struct mach_header *machHeader1 = NULL;
    
    // ① 通过 dlopen 打开传进来的 dylib
    if (dlopen(dylibPatch, RTLD_NOW) != nil) {
        
        // ② 获取内存中所有镜像
        int32_t images= _dyld_image_count();
        const char *pszModName = NULL;
        void* base;
        long slide;
        
        /** 越狱情况下 某些插件会为了规避 越狱检测 hook _dyld_image_count() 返回值。让它一直返回0 所以会出现获取镜像为空问题。
            遍历内存中加载镜像，查看是否有非法加载镜像也是防逆向的一个常用招式。
         */
        if (images == 0) return;
        
        // ③ 循环镜像获取刚刚注入的动态库镜像。
        for (uint32_t i = 0; i < images; i++) {
            pszModName = _dyld_get_image_name(i);
            
            // 匹配刚刚上传的dylib 获取到加载的动态库的基地址等信息
            if(!strcmp(pszModName, dylibPatch)){
                base  = (void*)_dyld_get_image_header(i);
                slide = _dyld_get_image_vmaddr_slide(i);
            }
        }
        
        uintptr_t cur = (uintptr_t)base + sizeof(mach_header_t);
        unsigned long byteCount = 0;

        if (machHeader1 == NULL)
        {
            // ④ 获取注入动态库结构体地址
            Dl_info info;
            dladdr((mach_header_t*)base, &info);
            machHeader1 = (struct mach_header_64*)info.dli_fbase;
            
            // ⑤ mach-O 文件里面的 class列表信息存在Data断。
            // 获取data段 classList 信息 (这个节列出了所有的class，包括元类对象)
            uint64_t size = 0;
            char *referencesSection = getsectdatafromheader_64(machHeader1,
                                                               "__DATA", "__objc_classlist", &size );
            
            unsigned int count;
            const char **classes;
            classes = objc_copyClassNamesForImage(info.dli_fname, &count);
            
            Class *classReferences = (Class *)(void *)((char *)info.dli_fbase+(uint64_t)referencesSection);
            
            for (int i = 0; i < count; i++) {
                // ⑥ 获取注入dylib 类对象, 元类对象
                self.MyClass = classReferences[i];
                
                // ⑦ 对象替换
                [BundleInjection loadedClass:self.MyClass notify:false];
                
                // ⑨ 调用渲染方法
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"DWHotReload" object: self.MyClass];
                });
            }
        }
        
        // 删除掉传上来的动态库
        [[NSFileManager defaultManager] removeItemAtPath:patch error:nil];
    }
}



#pragma mark - delegate

/** 开启了服务 */
- (void)webServerDidStart:(GCDWebServer*)server{
    self.serverStatusCode = DWServerStatusCode_start;
}


/** 关闭服务 */
- (void)webServerDidStop:(GCDWebServer*)server{
    self.serverStatusCode = DWServerStatusCode_close;
}



#pragma mark - getter & setter

- (void)setServerStatusCode:(DWServerStatusCode)serverStatusCode{
    _serverStatusCode = serverStatusCode;
    if ([self.delegate respondsToSelector:@selector(serverStatusUpdate:ip:)]) {
        NSString *ipStr = @"";
        if (serverStatusCode == DWServerStatusCode_start) {
            ipStr = self.webUploader.serverURL.absoluteString;
            NSLog(@"服务已开启。 ip : %@", self.webUploader.serverURL);
        }
        DWSafeThread(^{
            [self.delegate serverStatusUpdate:serverStatusCode ip:ipStr];
        });
    }
}



#pragma mark - 懒加载

- (GCDWebUploader *)webUploader{
    if (!_webUploaderManager) {
        
        NSString *path      = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        _webUploaderManager = [[GCDWebUploader alloc] initWithUploadDirectory:path];
        _webUploaderManager.delegate      = self;
        self.webUploader.allowHiddenItems = YES;  //目的是不允许通过地址直接访问资源
        WS(weakSelf);
        
        // 上传HTML页面
        [_webUploaderManager addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
            SS(strongSelf);
            NSString *mainBundleDirectory = [[NSBundle mainBundle] bundlePath];
            NSString *path = [mainBundleDirectory stringByAppendingPathComponent:strongSelf.indexHTML];
            NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            
            GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithHTML:html];
            completionBlock(response);
        }];
        
        
        // 文件上传处理
        [_webUploaderManager addHandlerForMethod:@"POST" path:@"/upload" requestClass:[GCDWebServerMultiPartFormRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
            SS(strongSelf);
            //这里的Block是上传成功后才进入，GCDWebServer先把目标文件上传到临时目录中。
            GCDWebServerResponse *response = [strongSelf __uploadFile:(GCDWebServerMultiPartFormRequest*)request];
            [response setValue:@"*" forAdditionalHeader:@"Access-Control-Allow-Origin"];
            completionBlock(response);
        }];
        
    }
    return _webUploaderManager;
}


@end
