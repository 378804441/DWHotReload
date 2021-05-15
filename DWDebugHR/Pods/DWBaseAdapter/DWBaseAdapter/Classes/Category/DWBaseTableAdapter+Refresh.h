//
//  DWBaseTableAdapter+Refresh.h
//  tieba
//
//  Created by 丁巍 on 2019/4/8.
//  Copyright © 2019 XiaoChuan Technology Co.,Ltd. All rights reserved.
//
//
//  所有 刷新操作


#import "DWBaseTableAdapter.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWBaseTableAdapter (Refresh)

/**
 刷新tableView协议 - 只刷新内容 不清除高度缓存
 */
-(void)reloadTableViewWithClearCache:(BOOL)clearCache;


/**
 刷新tableView协议
 @param cell      刷新cell对象
 */
-(void)reloadTableViewWithCell:(UITableViewCell *)cell clearCache:(BOOL)clearCache;


/**
 刷新tableView协议
 @param indexSet  刷新section
 */
-(void)reloadTableViewWithIndexSet:(NSIndexSet *)indexSet clearCache:(BOOL)clearCache;


/**
 刷新tableView协议
 @param indexPath 刷新row
 */
-(void)reloadTableViewWithIndexPath:(NSIndexPath *)indexPath clearCache:(BOOL)clearCache;


/**
 刷新tableView协议
 @param indexSet  刷新section
 @param indexPath 刷新row
 */
-(void)reloadTableViewWithIndexSet:(NSIndexSet *__nullable)indexSet indexPath:(NSIndexPath * __nullable)indexPath clearCache:(BOOL)clearCache;

@end

NS_ASSUME_NONNULL_END
