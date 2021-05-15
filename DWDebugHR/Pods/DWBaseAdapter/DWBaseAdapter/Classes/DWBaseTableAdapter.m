//
//  DWBaseTableAdapter.m
//  BaseTableView 适配器
//
//  Created by 丁巍 on 2018/12/11.
//  Copyright © 2018年 丁巍. All rights reserved.
//

#import "DWBaseTableAdapter.h"
#import "GDiffCore.h"
#import "DWBaseTableAdapter+Action.h"


@interface DWBaseTableAdapter()

@property (nonatomic, strong, readwrite) NSArray  *dataSource;      // 数据源

@property (nonatomic, strong) NSMutableDictionary *heightCache;     //高度缓存

@end

@implementation DWBaseTableAdapter


#pragma mark - init method

/** 初始化 adapter */
-(instancetype)initAdapterWithTableView:(UITableView *)tableView{
    self = [super init];
    if (self) {
        NSParameterAssert(tableView);
        _tableView              = tableView;
        self.securityCellHeight = 44;
        self.semaphore          = dispatch_semaphore_create(1);
        self.heightCache        = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)updateAdapterTableView:(UITableView *)tableView{
    NSParameterAssert(tableView);
    _tableView = tableView;
}


#pragma mark - 初始化DataSource方法

//数据源初始化
-(NSArray *)dataSource{
    if (!_dataSource) {
        _dataSource = [self instanceDataSource];
    }
    return _dataSource;
}

-(NSArray <DWBaseTableDataSourceModel *>*)instanceDataSource{
    NSMutableArray *array = [NSMutableArray array];
    return [array copy];
}


#pragma mark - public method

/** 刷新adapter (更改数据源将会进行 diff计算 并精准刷新) */
-(void)reloadAdapter{
    if (IsNull(self.diffDataSource)) {
        self.diffDataSource = self.dataSource;
    }
    
//    GDiffCore *diff = [GDiffCore new];
//    DWIndexManager *result = [diff diff:self.dataSource newArray:self.diffDataSource];
//    
//    [self deleteCellWithIndexPaths:result.deletes];
}

//清除高度缓存
-(void)clearCache{
    [self.heightCache removeAllObjects];
}

/** 清除dataSource */
-(void)clearDataSource{
    self.dataSource = nil;
}


#pragma mark - getter & setter

// 缓存高度不让生效
-(void)setCloseHighlyCache:(BOOL)closeHighlyCache{
    if (closeHighlyCache) {
        self.heightCache = nil;
    }
}

-(UIViewController *)controller{
    return [self getControllerFromView:self.tableView];
}


#pragma mark - tableview dataSource and delegate

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if([self checkRowType] == DWBaseTableAdapterRow_noGrop) return 1; //不分组类型
    else if([self checkRowType] == DWBaseTableAdapterRow_grop) return self.dataSource.count; //分组类型
    return 0; //数据源没有数据
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if([self checkRowType] == DWBaseTableAdapterRow_noGrop) return self.dataSource.count; //不分组类型
    else if([self checkRowType] == DWBaseTableAdapterRow_grop) return ((NSArray *)self.dataSource[section]).count; //分组类型
    return 0; //数据源没有数据
}


#pragma mark - headHeight & footerHeight

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if([self checkRowType] == DWBaseTableAdapterRow_grop){
        if (section == 0) return CGFLOAT_MIN;
        return 10;
    }
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (![tableView.dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) return 0;
    if (tableView.style == UITableViewStylePlain) return 0;
    if (section == ([tableView.dataSource numberOfSectionsInTableView:tableView] - 1)) return CGFLOAT_MIN;
    return CGFLOAT_MIN;
}


#pragma mark - 常规 tableView delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    id <DWBaseCellProtocol>cellObjc = [self getDataSourceWithIndexPath:indexPath type:DWBaseTableAdapterRowType_rowCell];
    // 数据源添加进来的Cell如果没有遵循该协议直接返回安全高度
    if (![cellObjc conformsToProtocol:@protocol(DWBaseCellProtocol)]) return self.securityCellHeight==0 ? CGFLOAT_MIN : self.securityCellHeight;
    
    //高度缓存
    DWBaseTableDataSourceModel *dataModel = [self getDataSourceWithIndexPath:indexPath type:DWBaseTableAdapterRowType_rowModel];
    NSString *heightKey = [NSString stringWithFormat:@"%lu", (unsigned long)dataModel.hash];
    NSNumber *heightNumber = heightKey ? self.heightCache[heightKey] : nil;
    if (heightNumber) {
        return [heightNumber floatValue];
    } else {
        CGFloat cellH;
        /** 需要传Model 动态计算高度 */
        if([cellObjc respondsToSelector:@selector(getAutoCellHeightWithModel:)]){
            id cellData = [self getDataSourceWithIndexPath:indexPath type:DWBaseTableAdapterRowType_rowData];
            cellH = [cellObjc getAutoCellHeightWithModel:cellData];
            
        /** 不需要传参 固定高度 */
        }else if([cellObjc respondsToSelector:@selector(getAutoCellHeight)]){
            cellH = [cellObjc getAutoCellHeight];
            
        /** 安全高度 */
        }else{
            cellH = self.securityCellHeight==0 ? CGFLOAT_MIN : self.securityCellHeight;
        }
        
        if (heightKey) self.heightCache[heightKey] = @(cellH);
        return cellH;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id cellObjc = [self getDataSourceWithIndexPath:indexPath type:DWBaseTableAdapterRowType_rowCell];
    
    // 如果没有遵循 DWBaseCellProtocol 协议将直接返回安全数组
    if (![cellObjc conformsToProtocol:@protocol(DWBaseCellProtocol)]) {
        return [self createSecurityTableView:tableView cellForRowAtIndexPath:indexPath cellName:nil];
    }
    
    id <DWBaseCellProtocol>protocolCell = cellObjc;
    
    NSString *errorStr = [NSString stringWithFormat:@"既然遵循了 DWBaseCellProtocol 协议, 就请实现协议里的初始化方法。不然直接重写 tableView cellForRowAtIndexPath 方法。\n Cell 名称 : %@", NSStringFromClass([protocolCell class])];
    NSAssert([protocolCell conformsToProtocol:@protocol(DWBaseCellProtocol)] &&
             [protocolCell respondsToSelector:@selector(cellWithTableView:)],
             errorStr);
    
    // 初始化Cell 实例对象
    id <DWBaseCellProtocol>cell = [protocolCell cellWithTableView:tableView];
    
    // 实例对象不存在直接返回一个安全Cell
    if (!cell) return [self createSecurityTableView:tableView cellForRowAtIndexPath:indexPath cellName:NSStringFromClass(cell)];
    
    // 绑定数据
    id cellData = [self getDataSourceWithIndexPath:indexPath type:DWBaseTableAdapterRowType_rowData];
    if ([cell respondsToSelector:@selector(bindWithCellModel:indexPath:)]) {
        [cell bindWithCellModel:cellData indexPath:indexPath];
    }
    
    /** 指定delegate */
    id delegateObj = [self getDataSourceWithIndexPath:indexPath type:DWBaseTableAdapterRowType_rowDelegate];
    if (delegateObj) {
        [cell setMyDelegate:delegateObj];
    }
    return cell;
}

/** 创建安全Cell */
- (UITableViewCell *)createSecurityTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath cellName:(NSString *)cellName{
    UITableViewCell *cell;
    static NSString *CellIndentifier;
    static NSString *customCellIndentifier;
    if (IsEmpty(cellName)) {
        CellIndentifier = @"Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier];
    }else{
        customCellIndentifier = cellName;
        cell = [tableView dequeueReusableCellWithIdentifier:customCellIndentifier];
    }
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIndentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}



#pragma mark - all action

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.tableProtocolDelegate respondsToSelector:@selector(didSelectTableView:indexPath:data:adapter:)]) {
        [self.tableProtocolDelegate didSelectTableView:tableView indexPath:indexPath data:nil adapter:self];
    }
}



#pragma mark - dataSource method

/** 获取 指定的dataSource内容 */
-(id)getDataSourceWithIndexPath:(NSIndexPath *)indexPath type:(DWBaseTableAdapterRowType)type{
    if([self checkRowType] == DWBaseTableAdapterRow_noGrop)    return [self noGroupRowTypeFromArray:self.dataSource indexPath:indexPath type:type];
    else if([self checkRowType] == DWBaseTableAdapterRow_grop) return [self rowTypeFromArray:self.dataSource indexPath:indexPath type:type];
    return nil; //数据源没有数据
}


//解析tableView 每组的 枚举类型
- (id)rowTypeFromArray:(NSArray *)sourceArray indexPath:(NSIndexPath *)indexPath type:(DWBaseTableAdapterRowType)type{
    NSParameterAssert(indexPath && sourceArray.count > 0 && sourceArray[indexPath.section] && sourceArray[indexPath.section][indexPath.row]);
   
    if (indexPath.section >= sourceArray.count) {
          return nil;
    }
      
    if (indexPath.row >= ((NSArray *)sourceArray[indexPath.section]).count) {
        return nil;
    }
    
    DWBaseTableDataSourceModel *dataSourceModel = sourceArray[indexPath.section][indexPath.row];
    return [self parsingDataSourceWithModel:dataSourceModel type:type];
}


//解析不是分组情况下
- (id)noGroupRowTypeFromArray:(NSArray *)sourceArray indexPath:(NSIndexPath *)indexPath type:(DWBaseTableAdapterRowType)type{
    NSParameterAssert(indexPath && sourceArray.count > 0 && sourceArray[indexPath.row] && indexPath.section == 0);
    if (indexPath.row >= sourceArray.count) return nil;
    
    DWBaseTableDataSourceModel *dataSourceModel = sourceArray[indexPath.row];
    return [self parsingDataSourceWithModel:dataSourceModel type:type];
}


- (id)parsingDataSourceWithModel:(DWBaseTableDataSourceModel *)dataSourceModel type:(DWBaseTableAdapterRowType)type{
    switch (type) {
        case DWBaseTableAdapterRowType_rowType:
            return @(dataSourceModel.tag);
            break;
        case DWBaseTableAdapterRowType_rowData:
            return dataSourceModel.data;
            break;
        case DWBaseTableAdapterRowType_rowCell:
            return dataSourceModel.cell;
            break;
        case DWBaseTableAdapterRowType_rowDelegate:
            return dataSourceModel.myDelegate;
            break;
        case DWBaseTableAdapterRowType_rowModel:
            return dataSourceModel;
            break;
        default:
            return nil;
            break;
    }
}


/** 删除相应数据源 */
- (void)removeDataSource:(NSIndexPath *)indexPath indexSet:(NSIndexSet *)indexSet{
    
    NSParameterAssert(indexPath || indexSet);
    
    NSMutableArray *tempArray = [self.dataSource mutableCopy];
    
    if([self checkRowType] == DWBaseTableAdapterRow_grop){
        NSParameterAssert(tempArray.count > 0 && tempArray[indexSet.firstIndex]);
        NSParameterAssert(tempArray.count > 0 && tempArray[indexPath.section] && tempArray[indexPath.section][indexPath.row]);
        
        if (!IsNull(indexSet)) {
            [tempArray removeObjectsAtIndexes:indexSet];
            return;
        }
        
        if (!IsNull(indexPath)) {
            [tempArray[indexPath.section] removeObjectAtIndex:indexPath.row];
        }
        
    }else if([self checkRowType] == DWBaseTableAdapterRow_noGrop){
        NSParameterAssert(indexPath && tempArray.count > 0 && tempArray[indexPath.row] && indexPath.section == 0);
        [tempArray removeObjectAtIndex:indexPath.row];
    }
    
}


/** 替换相应数据源 */
- (NSArray *)replaceDataSource:(NSIndexPath *)indexPath indexSet:(NSIndexSet *)indexSet newModel:(id)newModel{
    NSParameterAssert(indexPath || indexSet);
    NSParameterAssert(newModel);
    
    NSMutableArray *tempArray = [self.dataSource mutableCopy];
    
    if([self checkRowType] == DWBaseTableAdapterRow_grop){
        NSParameterAssert(tempArray.count > 0 && tempArray[[indexSet indexGreaterThanIndex:0]]);
        NSParameterAssert(tempArray.count > 0 && tempArray[indexPath.section] && tempArray[indexPath.section][indexPath.row]);
        
        if (!IsNull(indexSet)) {
            NSParameterAssert([newModel isKindOfClass:[NSArray class]] || [newModel isKindOfClass:[NSMutableArray class]]);
            [tempArray replaceObjectAtIndex:[indexSet indexGreaterThanIndex:0] withObject:newModel];
            return [tempArray copy];
        }
        
        if (!IsNull(indexPath)) {
            NSParameterAssert([newModel isKindOfClass:[DWBaseTableDataSourceModel class]]);
            NSMutableArray *tempSectionArray = [NSMutableArray arrayWithArray:tempArray[indexPath.section]];
            [tempSectionArray replaceObjectAtIndex:indexPath.row withObject:newModel];
            tempArray[indexPath.section] = [tempSectionArray copy];
        }
        
    }else if([self checkRowType] == DWBaseTableAdapterRow_noGrop){
        NSParameterAssert(indexPath && tempArray.count > 0 && tempArray[indexPath.row] && indexPath.section == 0);
        NSParameterAssert([newModel isKindOfClass:[DWBaseTableDataSourceModel class]]);
        
        [tempArray replaceObjectAtIndex:indexPath.row withObject:newModel];
    }
    
    return [tempArray copy];
}


/**
 插入相应数据源
 如果传进来的是 indexSet  (整条session替换), newModel 就一定要是 存有 DWBaseTableDataSourceModel 类型的 数组
 如果传进来的是 indexPath newModel 需要是 DWBaseTableDataSourceModel 对象
 */
- (NSArray *)inserDataSource:(NSIndexPath *__nullable)indexPath indexSet:(NSIndexSet *__nullable)indexSet newModel:(id)newModel{
    NSParameterAssert(indexPath || indexSet);
    NSParameterAssert(newModel);
    
    NSMutableArray *tempArray = [self.dataSource mutableCopy];
    
    if([self checkRowType] == DWBaseTableAdapterRow_grop){
        NSParameterAssert(tempArray.count > 0);
        NSParameterAssert(tempArray.count > 0 && tempArray[indexPath.section] && tempArray[indexPath.section][indexPath.row]);
        
        if (!IsNull(indexSet)) {
            NSParameterAssert([newModel isKindOfClass:[NSArray class]] || [newModel isKindOfClass:[NSMutableArray class]]);
            if (tempArray.count >= [indexSet indexGreaterThanIndex:0]) {
                [tempArray insertObject:newModel atIndex:[indexSet indexGreaterThanIndex:0]];
            }
            return [tempArray copy];
        }
        
        if (!IsNull(indexPath)) {
            NSParameterAssert([newModel isKindOfClass:[DWBaseTableDataSourceModel class]]);
            if (((NSArray *)tempArray[indexPath.section]).count > indexPath.row) {
                NSMutableArray *tempSectionArray = [NSMutableArray arrayWithArray:tempArray[indexPath.section]];
                [tempArray[indexPath.section] insertObject:newModel atIndex:indexPath.row];
                tempArray[indexPath.section] = [tempSectionArray copy];
            }
        }
        
    }else if([self checkRowType] == DWBaseTableAdapterRow_noGrop){
        NSParameterAssert(indexPath && tempArray.count > 0 && tempArray[indexPath.row] && indexPath.section == 0);
        NSParameterAssert([newModel isKindOfClass:[DWBaseTableDataSourceModel class]]);
        if (tempArray.count > indexPath.row) {
            [tempArray insertObject:newModel atIndex:indexPath.row];
        }
    }
    
    return [tempArray copy];
}




#pragma mark - private method

/** 通过View 找到view 依附VC */
- (UIViewController *)getControllerFromView:(UIView *)view {
    // 遍历响应者链。返回第一个找到视图控制器
    UIResponder *responder = view;
    while ((responder = [responder nextResponder])){
        if ([responder isKindOfClass: [UIViewController class]]){
            return (UIViewController *)responder;
        }
    }
    // 如果没有找到则返回nil
    return nil;
}

/** 判断是分组还是不分组 DataSource */

-(DWBaseTableAdapterRowEnum)checkRowType{
    if(self.dataSource.count > 0){
        if([[self.dataSource lastObject] isKindOfClass:[NSArray class]] ||
           [[self.dataSource lastObject] isKindOfClass:[NSMutableArray class]]){ //分组类型
            return DWBaseTableAdapterRow_grop;
        }else{
            return DWBaseTableAdapterRow_noGrop;
        }
    }
    return DWBaseTableAdapterRow_normal;
}


@end
