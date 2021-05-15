//
//  main.m
//  DWDebugHR
//
//  Created by 丁巍 on 2020/12/27.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <dlfcn.h>
#import <mach/mach.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>



int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}

