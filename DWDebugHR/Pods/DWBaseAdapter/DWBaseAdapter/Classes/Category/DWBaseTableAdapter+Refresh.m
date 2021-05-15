//
//  DWBaseTableAdapter+Refresh.m
//  tieba
//
//  Created by 丁巍 on 2019/4/8.
//  Copyright © 2019 XiaoChuan Technology Co.,Ltd. All rights reserved.
//

#import "DWBaseTableAdapter+Refresh.h"


@implementation DWBaseTableAdapter (Refresh)

/**
 刷新tableView协议
 @param clearCache : 清除缓存
 */
-(void)reloadTableViewWithClearCache:(BOOL)clearCache{
    NSParameterAssert(self.tableView);
    [self reloadTableViewWithIndexSet:nil indexPath:nil clearCache:clearCache];
}


/**
 刷新tableView协议
 @param cell      刷新cell对象
 @param clearCache : 清除缓存
 */
-(void)reloadTableViewWithCell:(UITableViewCell *)cell clearCache:(BOOL)clearCache{
    NSParameterAssert(self.tableView);
    if (IsNull(cell)) return;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self reloadTableViewWithIndexSet:nil indexPath:indexPath clearCache:clearCache];
}

/**
 刷新tableView协议
 @param indexSet  刷新section
 @param clearCache : 清除缓存
 */
-(void)reloadTableViewWithIndexSet:(NSIndexSet *)indexSet clearCache:(BOOL)clearCache{
    NSParameterAssert(self.tableView);
    [self reloadTableViewWithIndexSet:indexSet indexPath:nil clearCache:clearCache];
}

/**
 刷新tableView协议
 @param indexPath 刷新row
 @param clearCache : 清除缓存
 */
-(void)reloadTableViewWithIndexPath:(NSIndexPath *)indexPath clearCache:(BOOL)clearCache{
    NSParameterAssert(self.tableView);
    [self reloadTableViewWithIndexSet:nil indexPath:indexPath clearCache:clearCache];
}

/**
 刷新tableView协议
 @param indexSet  刷新section
 @param indexPath 刷新row
 @param clearCache : 清除缓存
 */
-(void)reloadTableViewWithIndexSet:(NSIndexSet *__nullable)indexSet indexPath:(NSIndexPath * __nullable)indexPath clearCache:(BOOL)clearCache{
    NSParameterAssert(self.tableView);
    [self clearDataSource];
    if (clearCache) [self clearCache];
    if (indexSet) {
        [UIView performWithoutAnimation:^{
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }else if(indexPath){
        [UIView performWithoutAnimation:^{
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }else{
        [self.tableView reloadData];
    }
}


@end
