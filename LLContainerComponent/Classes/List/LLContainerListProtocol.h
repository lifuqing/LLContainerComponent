//
//  LLContainerListProtocol.h
//  LLContainerComponent
//
//  Created by lifuqing on 2018/9/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <LLHttpEngine/LLURL.h>

/**
 beta 版本，有任何需求不满足、或者用着不方便的，联系@lifuqing
 */
@class LLContainerListViewController, LLBaseResponseModel;

#pragma mark - 列表代理

@protocol LLContainerListDelegate <NSObject>
/**
 * List Content Request
 * @brief 列表网络请求
 */

///列表请求在URLConfig里面的Parser唯一标识
- (nonnull NSString *)requestListParserForListController:(nonnull LLContainerListViewController *)listController;
///parser所在的urlconfig类
- (nonnull Class)requestListURLConfigClassForListController:(nonnull LLContainerListViewController *)listController;

/**
 * List Content
 * @brief 列表内容
 */

///内容行高，如果用约束实现cell高度动态计算，return UITableViewAutomaticDimension即可
- (CGFloat)listController:(nonnull LLContainerListViewController *)listController rowHeightAtIndexPath:(nonnull NSIndexPath *)indexPath;

///复用内容视图
- (void)listController:(nonnull LLContainerListViewController *)listController reuseCell:(nonnull UITableViewCell *)cell atIndexPath:(nonnull NSIndexPath *)indexPath;

@optional

#pragma mark - 列表网络请求
/**
 * List Content Request
 * @brief 列表网络请求
 */

///列表LLListBaseDataSource子类，不实现默认为LLListBaseDataSource
- (nullable Class)requestListDataSourceClassForListController:(nonnull LLContainerListViewController *)listController;

///列表请求额外配置的参数，内部refresh第一页数据请求的时候会清空参数，需要重新传参。
- (nullable NSDictionary *)requestListPargamsForListController:(nonnull LLContainerListViewController *)listController;

///列表请求缓存类型，默认ELLURLCacheTypeDefault
- (ELLURLCacheType)requestListCacheTypeForListController:(nonnull LLContainerListViewController *)listController;


#pragma mark - 列表内容
/**
 * List Content
 * @brief 列表内容
 */

///section数量 默认1
- (NSInteger)listController:(nonnull LLContainerListViewController *)listController sectionCountInTableView:(nonnull UITableView *)tableView;

///内容行数,默认为requestListParserForListController:所提供的parser对应的ListResponseModel list 的数量
- (NSInteger)listController:(nonnull LLContainerListViewController *)listController rowCountInSection:(NSInteger)section;

///内容视图Class。默认为UITableViewCell。
- (nullable Class)listController:(nonnull LLContainerListViewController *)listController cellClassAtIndexPath:(nonnull NSIndexPath *)indexPath;

///内容视图复用标识符。默认为"CellClass"的形式。
- (nullable NSString *)listController:(nonnull LLContainerListViewController *)listController cellIdentifierAtIndexPath:(nonnull NSIndexPath *)indexPath;

///点击内容事件
- (void)listController:(nonnull LLContainerListViewController *)listController didSelectedCellAtIndexPath:(nonnull NSIndexPath *)indexPath;


#pragma mark - 其他
/**
 * Other
 * @brief 其他
 */

///当请求失败或者数据为空是否显示失败页面、失败toast，默认YES
- (BOOL)shouldShowErrorViewAndToastForListController:(nonnull LLContainerListViewController *)listController;

///是否当筛选条件存在之后再请求列表数据,默认NO
- (BOOL)shouldRequestListAfterFiterIsExistForListController:(nonnull LLContainerListViewController *)listController;

@end


#pragma mark - 事件埋点代理
/**
 * 事件埋点
 * @brief 事件埋点
 */
@protocol LLContainerEventDelegate <NSObject>

@optional
///列表cell点击埋点
- (void)eventListController:(nonnull LLContainerListViewController *)listController clickDidSelectedCellAtIndexPath:(nonnull NSIndexPath *)indexPath;

///下拉刷新事件触发的埋点
- (void)eventPullRefreshForListController:(nonnull LLContainerListViewController *)listController;
@end

#pragma mark - 曝光埋点代理
/**
 * 曝光埋点
 * @brief 曝光埋点
 */
@protocol LLContainerExposeDelegate <NSObject>

@optional

///上报曝光统计
- (void)exposeListSendExposeStatisticsWithData:(nullable NSArray<LLBaseResponseModel *> *)exposeDataArray;

///是否应该发送曝光,默认YES
- (BOOL)exposeShouldExposeAtIndexPath:(NSIndexPath *)indexPath forListController:(nonnull LLContainerListViewController *)listController;

///列表数据，如果cell继承自LLBaseTableViewCell并且使用里面的model属性作为数据源，则无需实现此解析。否则请根据indexpath解析曝光数据源，遍历之后将数据源LLBaseResponseModel类型的属性ll_exposed设置为YES。之后会自动调用exposeListSendExposeStatisticsWithData:上报.具体解析方法可参考parseExposeArrayWithIndexPath:
- (nullable NSArray *)exposeListParseExposeArrayWithIndexPath:(nullable NSArray<NSIndexPath *> *)exposeArray;

@end
