//
//  HTTaskManager.m
//  ExecShellCMD
//
//  Created by  guogh on 2017/4/5.
//  Copyright © 2017年  guogh. All rights reserved.
//

#import "HTTaskManager.h"

@implementation HTTaskManager{
    NSTask *_task;
    NSPipe *_outPipe;
    NSPipe *_errorPipe;
}

static id _instance;
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    return _instance;
}


#pragma mark - API

- (void)execShellCMDWith:(NSString *)cmdStr completeBlock:(void (^)(NSString *, NSString *))completeBlock{
    if (cmdStr == nil || cmdStr.length == 0) {
        if(completeBlock != nil) completeBlock(nil,@"cmd为空!!!");
        return;
    }
    if ([cmdStr hasPrefix:@"sudo"] || [cmdStr hasPrefix:@"su"]) {
        if(completeBlock != nil) completeBlock(nil,@"请使用 execShellCMDAsAdmin:completeBlock: 方法执行root命令!!!");
        return;
    }
    
    _task = [[NSTask alloc] init];
    _task.launchPath = @"/bin/bash";
    _task.currentDirectoryPath = @"~";//默认家目录
    
    _outPipe = [NSPipe pipe];
    _errorPipe = [NSPipe pipe];
    _task.standardOutput = _outPipe;
    _task.standardError = _errorPipe;
    _task.arguments = @[@"-l",@"-c",cmdStr];
    
    
    [_task launch];
    [_task waitUntilExit];
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *outData = _outPipe.fileHandleForReading.availableData;
        [_outPipe.fileHandleForReading readInBackgroundAndNotify];
        NSData *errorData = _errorPipe.fileHandleForReading.availableData;
        [_errorPipe.fileHandleForReading readInBackgroundAndNotify];
        NSString *outStr = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
        NSString *errorStr = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            _task = nil;
            _outPipe = nil;
            _errorPipe = nil;
            if (completeBlock != nil) {
                completeBlock(outStr,errorStr);
            }
        });
    });
}

- (void)execShellCMDAsAdmin:(NSString *)cmdStr completeBlock:(void (^)(NSString *, NSString *))completeBlock{
    if (cmdStr == nil || cmdStr.length == 0) {
        if(completeBlock != nil) completeBlock(nil,@"cmd为空!!!");
        return;
    }
//    do shell script "sudo apachectl -k restart" with administrator privileges
    NSString *cmd = [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges",cmdStr];
    NSAppleScript *scpipt = [[NSAppleScript alloc] initWithSource:cmd];
    if (scpipt == nil) {
        if(completeBlock != nil) completeBlock(nil,@"转换脚本错误!!!");
        return;
    }
    NSDictionary *dict = nil;
    NSAppleEventDescriptor *descriptor = nil;
    descriptor = [scpipt executeAndReturnError:&dict];
//    NSLog(@"%@",dict);
    if (!dict)
    {
        if(completeBlock != nil) completeBlock(descriptor.stringValue,nil);
//        NSLog(@"success = %@",descriptor.stringValue);
    }else{
        NSLog(@"error = %@",dict);
        if(completeBlock != nil) completeBlock(nil,dict[@"NSAppleScriptErrorMessage"]);
    }
    
}


@end
