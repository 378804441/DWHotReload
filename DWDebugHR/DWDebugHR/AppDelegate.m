//
//  AppDelegate.m
//  DWDebugHR
//
//  Created by 丁巍 on 2020/12/27.
//

#import "AppDelegate.h"
#import "DWServerUploaderManager.h"
#import "DWViewController.h"


@interface AppDelegate ()

@property (nonatomic, strong) DWViewController *mainVC;

@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    self.mainVC = [[DWViewController alloc] init];
    self.window.rootViewController = self.mainVC;
    
    [serverUploadMg startServerWithIndexHTML:@"index.html"];
    
    return YES;
}





@end
