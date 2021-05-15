//
//  ViewController.m
//  FSEventStreamDemo
//
//  Created by 曾文斌 on 2017/7/26.
//  Copyright © 2017年 yww. All rights reserved.
//

#import "ViewController.h"
#import "HTTaskManager.h"
#import <CoreServices/CoreServices.h>

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]);

@interface ViewController()

@property(nonatomic) NSInteger syncEventID;

@property(nonatomic, assign) FSEventStreamRef syncEventStream;

@property (weak) IBOutlet NSTextField *input;

@property (weak) IBOutlet NSButton *isPhone;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}


#pragma mark - event

- (IBAction)startWatchClicked:(id)sender {
    if(self.syncEventStream) {
        FSEventStreamStop(self.syncEventStream);
        FSEventStreamInvalidate(self.syncEventStream);
        FSEventStreamRelease(self.syncEventStream);
        self.syncEventStream = NULL;
    }
    
//    NSString *patch = [self get_current_app_path];
    
    NSArray *paths = @[@"/Users/dingwei/Desktop/自研/DWDebugHR/DWDebugHR"];// 这里填入需要监控的文件夹
    FSEventStreamContext context;
    context.info = (__bridge void * _Nullable)(self);
    context.version = 0;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;
    self.syncEventStream = FSEventStreamCreate(NULL, &fsevents_callback, &context, (__bridge CFArrayRef _Nonnull)(paths), self.syncEventID, 1, kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes);
    FSEventStreamScheduleWithRunLoop(self.syncEventStream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    FSEventStreamStart(self.syncEventStream);

}
- (IBAction)stopWatchClicked:(id)sender {
    if(self.syncEventStream) {
        FSEventStreamStop(self.syncEventStream);
        FSEventStreamInvalidate(self.syncEventStream);
        FSEventStreamRelease(self.syncEventStream);
        self.syncEventStream = NULL;
    }
}
#pragma mark - private method
-(void)updateEventID {
    self.syncEventID = FSEventStreamGetLatestEventId(self.syncEventStream);
}
#pragma mark - setter
-(void)setSyncEventID:(NSInteger)syncEventID{
    [[NSUserDefaults standardUserDefaults] setInteger:syncEventID forKey:@"SyncEventID"];
}
-(NSInteger)syncEventID {
    NSInteger syncEventID = [[NSUserDefaults standardUserDefaults] integerForKey:@"SyncEventID"];
    if(syncEventID == 0) {
        syncEventID = kFSEventStreamEventIdSinceNow;
    }
    return syncEventID;
}



-(NSString *)get_current_app_path{
    NSString* path = @"";
    NSString* str_app_full_file_name = [[NSBundle mainBundle] bundlePath];
    NSRange range = [str_app_full_file_name rangeOfString:@"/" options:NSBackwardsSearch];
    if (range.location != NSNotFound)
    {
        path = [str_app_full_file_name substringToIndex:range.location];
        path = [path stringByAppendingFormat:@"%@",@"/"];
    }
    return path;
}

@end

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]) {
    ViewController *self = (__bridge ViewController *)userData;
    NSArray *pathArr = (__bridge NSArray*)eventPaths;
    FSEventStreamEventId lastRenameEventID = 0;
    NSString* lastPath = nil;
    for(int i=0; i<numEvents; i++){
        FSEventStreamEventFlags flag = eventFlags[i];
        if(kFSEventStreamEventFlagItemCreated & flag) {
            NSLog(@"create file: %@", pathArr[i]);
        }
        if(kFSEventStreamEventFlagItemRenamed & flag) {
            FSEventStreamEventId currentEventID = eventIds[i];
            NSString* currentPath = pathArr[i];
            if (currentEventID == lastRenameEventID + 1) {
                // 重命名或者是移动文件
                NSLog(@"mv %@ %@", lastPath, currentPath);
            } else {
                // 其他情况, 例如移动进来一个文件, 移动出去一个文件, 移动文件到回收站, 修改文件
                if ([[NSFileManager defaultManager] fileExistsAtPath:currentPath]) {
                    
                    NSString *isPhone = self.isPhone.state ? @"phone" : @"";
                    NSString *phoneIp = [self.input stringValue];
                    if (self.isPhone.state && phoneIp.length == 0) {
                        NSLog(@"真机运行的话请填写ip地址");
                        return;
                    }
                    
                    NSString *fileName = [[[[currentPath componentsSeparatedByString:@"/"] lastObject] componentsSeparatedByString:@"."] firstObject];
                    NSString *shellStr = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", @"/Users/dingwei/Desktop/热重载/run.sh", currentPath, fileName, isPhone, phoneIp];
                    [[HTTaskManager sharedManager] execShellCMDWith:shellStr completeBlock:^(NSString *resultStr, NSString *errorStr) {

                    }];
                    
                    // 移动进来一个文件
                    NSLog(@"move in file: %@", currentPath);
                    break;
                } else {
                    // 移出一个文件
                    NSLog(@"move out file: %@", currentPath);
                }
            }
            lastRenameEventID = currentEventID;
            lastPath = currentPath;
        }
        if(kFSEventStreamEventFlagItemRemoved & flag) {
            NSLog(@"remove: %@", pathArr[i]);
        }
        if(kFSEventStreamEventFlagItemModified & flag) {
            NSLog(@"modify: %@", pathArr[i]);
        }
    }
    [self updateEventID];
}
