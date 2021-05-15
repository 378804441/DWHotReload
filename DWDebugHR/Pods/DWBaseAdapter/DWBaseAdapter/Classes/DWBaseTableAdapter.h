//
//  DWBaseTableAdapter.h
//  BaseTableView 适配器
//
//  Created by 丁巍 on 2018/12/11.
//  Copyright © 2018年 丁巍. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "DWBaseTableDataSourceModel.h"
#import "DWBaseTableViewProtocol.h"
#import "DWBaseCellProtocol.h"
#import "DWAdapterCoinf.h"

/** tableView 类型 */
typedef NS_ENUM(NSInteger, DWBaseTableAdapterRowEnum){
    DWBaseTableAdapterRow_noGrop = 0, //不分组
    DWBaseTableAdapterRow_grop,       //分组
    DWBaseTableAdapterRow_normal      //数据源为空
};

/** 指定获取dataSourceModel里面字段 */
typedef NS_ENUM(NSInteger, DWBaseTableAdapterRowType){
    DWBaseTableAdapterRowType_rowType = 0,  // Cell类型
    DWBaseTableAdapterRowType_rowData,      // Cell绑定数据
    DWBaseTableAdapterRowType_rowCell,      // Cell类对象
    DWBaseTableAdapterRowType_rowDelegate,  // delegate
    DWBaseTableAdapterRowType_rowModel      // 绑定上的model
};

@interface DWBaseTableAdapter : NSObject<UITableViewDataSource, UITableViewDelegate, DWBaseTableViewProtocol>

#pragma mark - 禁用初始化方法

-(instancetype) init __attribute__((unavailable("此框架禁用init方法, 请使用提供的初始化方。")));
+(instancetype) new  __attribute__((unavailable("此框架禁用init方法, 请使用提供的初始化方。")));


#pragma mark - public property

/** delegate */
@property (nonatomic, weak)   id<DWBaseTableViewProtocol> tableProtocolDelegate;

/** 新的数据源 （需要diff判断的新数据源） */
@property (nonatomic, strong)           NSArray *diffDataSource;

/** 不遵循 DWBaseTableViewProtocol 协议时候安全数组高度*/
@property (nonatomic, assign)           CGFloat securityCellHeight;

/** 最大线程 */
@property (nonatomic, strong)           dispatch_semaphore_t semaphore;

/** 是否关闭高度缓存 - 默认是开启的 (YES:关闭  NO:开启) */
@property (nonatomic, assign)           BOOL closeHighlyCache;

/** 数据源 */
@property (nonatomic, strong, readonly) NSArray  *dataSource;     

/** 注册tableView */
@property (nonatomic, strong, readonly) UITableView *tableView;

/** tableView 依附VC */
@property (nonatomic, strong, readonly) UIViewController *controller;


#pragma mark - public method

/** 初始化 adapter */
-(instancetype)initAdapterWithTableView:(UITableView *)tableView;

/** 更改绑定的tableView */
-(void)updateAdapterTableView:(UITableView *)tableView;

/** 初始化dataSource */
-(NSArray <DWBaseTableDataSourceModel *>*)instanceDataSource;

/** 检测tableView类型 */
-(DWBaseTableAdapterRowEnum)checkRowType;

/** 刷新adapter (更改数据源将会进行 diff计算 并精准刷新) */
-(void)reloadAdapter;

/** 清除dataSource */
-(void)clearDataSource;

/** 清除高度缓存 */
-(void)clearCache;


#pragma mark - dataSource method

/** 获取 指定的dataSource内容 */
-(id)getDataSourceWithIndexPath:(NSIndexPath *)indexPath type:(DWBaseTableAdapterRowType)type;

/** 删除相应数据源 */
- (void)removeDataSource:(NSIndexPath *)indexPath indexSet:(NSIndexSet *)indexSet;

/**
 替换相应数据源
 如果传进来的是 indexSet  (整条session替换), newModel 就一定要是 存有 DWBaseTableDataSourceModel 类型的 数组
 如果传进来的是 indexPath newModel 需要是 DWBaseTableDataSourceModel 对象
 */
- (NSArray *)replaceDataSource:(NSIndexPath *)indexPath indexSet:(NSIndexSet *)indexSet newModel:(id)newModel;


/**
 插入相应数据源, 返回合并后的新数组
 如果传进来的是 indexSet  (整条session替换), newModel 就一定要是 存有 DWBaseTableDataSourceModel 类型的 数组
 如果传进来的是 indexPath newModel 需要是 DWBaseTableDataSourceModel 对象
 */
- (NSArray *)inserDataSource:(NSIndexPath *__nullable)indexPath indexSet:(NSIndexSet *__nullable)indexSet newModel:(id)newModel;


@end
