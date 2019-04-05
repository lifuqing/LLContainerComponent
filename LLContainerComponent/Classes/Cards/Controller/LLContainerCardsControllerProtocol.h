//
//  LLContainerCardsControllerProtocol.h
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/7.
//

/**
 *  卡片结构示意图,每个卡片控制器就是一个section
 *
 *  |————————————————————|
 *  |   Suspend Header   |
 *  |————————————————————|
 *  |       Header       |
 *  |————————————————————|
 *  |                    |
 *  |       Content      |
 *  |                    |
 *  |————————————————————|
 *  |       Footer       |
 *  |————————————————————|
 *  |       Spacing      |
 *  |————————————————————|
 *
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LLCardContext.h"

NS_ASSUME_NONNULL_BEGIN


@class LLContainerCardsController, LLCardTableView, LLURL;

@protocol LLContainerCardsControllerDelegate <NSObject>

#pragma mark - 必须实现的卡片内容Card Content代理
/**
 * Card Content
 * @brief 卡片内容
 */

///内容行数
- (NSInteger)cardsController:(LLContainerCardsController *)cardsController rowCountForCardContentInTableView:(LLCardTableView *)tableView;

///内容行高
- (CGFloat)cardsController:(LLContainerCardsController *)cardsController rowHeightForCardContentAtIndex:(NSInteger)index;

///复用内容视图
- (void)cardsController:(LLContainerCardsController *)cardsController reuseCell:(UITableViewCell *)cell forCardContentAtIndex:(NSInteger)index;



@optional

#pragma mark - 生命周期Life Circle
/**
 * Life Circle
 * @brief 生命周期
 */

///卡片完成初始化
- (void)didFinishInitConfigurationInCardsController:(LLContainerCardsController *)cardsController;

///卡片父控制器（卡片化容器）将显示
- (void)cardsControllerViewWillAppear:(LLContainerCardsController *)cardsController;

///卡片父控制器（卡片化容器）已显示
- (void)cardsControllerViewDidAppear:(LLContainerCardsController *)cardsController;

///卡片父控制器（卡片化容器）将隐藏
- (void)cardsControllerViewWillDisappear:(LLContainerCardsController *)cardsController;

///卡片父控制器（卡片化容器）已隐藏
- (void)cardsControllerViewDidDisappear:(LLContainerCardsController *)cardsController;


#pragma mark - 卡片内容Card Content
/**
 * Card Content
 * @brief 卡片内容
 */

///内容视图Class。默认为UITableViewCell。
- (Class)cardsController:(LLContainerCardsController *)cardsController cellClassForCardContentAtIndex:(NSInteger)index;

///内容视图复用标识符。默认为"CellClass_CardType"的形式。
- (NSString *)cardsController:(LLContainerCardsController *)cardsController cellIdentifierForCardContentAtIndex:(NSInteger)index;

///点击内容事件
- (void)cardsController:(LLContainerCardsController *)cardsController didSelectCardContentAtIndex:(NSInteger)index;

///内容将显示
- (void)cardsController:(LLContainerCardsController *)cardsController willDisplayCell:(UITableViewCell *)cell forCardContentAtIndex:(NSInteger)index;

///内容已隐藏
- (void)cardsController:(LLContainerCardsController *)cardsController didEndDisplayingCell:(UITableViewCell *)cell forCardContentAtIndex:(NSInteger)index;

///头部将要显示
- (void)cardsController:(LLContainerCardsController *)cardsController willDisplayingHeaderCell:(UITableViewCell *)cell;

///头部已隐藏
- (void)cardsController:(LLContainerCardsController *)cardsController didEndDisplayingHeaderCell:(UITableViewCell *)cell;


#pragma mark - 顶部悬浮视图Suspend Header
/**
 * Suspend Header
 * @brief 顶部悬浮视图
 */

///悬浮视图高度。默认为0.0。
- (CGFloat)cardsController:(LLContainerCardsController *)cardsController heightForSuspendHeaderInTableView:(LLCardTableView *)tableView;

///悬浮视图。默认为nil。
- (UIView *)cardsController:(LLContainerCardsController *)cardsController viewForSuspendHeaderInTableView:(LLCardTableView *)tableView;


#pragma mark - 顶部永久悬浮视图Forever Suspend Header
/**
 * Forever Suspend Header
 * @brief 顶部永久悬浮视图,同一个卡片只能有一种悬浮视图
 */

///永久悬浮视图高度。默认为0.0。
- (CGFloat)cardsController:(LLContainerCardsController *)cardsController heightForForeverSuspendHeaderInTableView:(LLCardTableView *)tableView;

///永久悬浮视图。默认为nil。
- (UIView *)cardsController:(LLContainerCardsController *)cardsController viewForForeverSuspendHeaderInTableView:(LLCardTableView *)tableView;


#pragma mark - 卡片头部Card Header
/**
 * Card Header
 * @brief 卡片头部
 */

///是否显示头部视图。默认为NO。
- (BOOL)cardsController:(LLContainerCardsController *)cardsController shouldShowCardHeaderInTableView:(LLCardTableView *)tableView;

///头部行高
- (CGFloat)cardsController:(LLContainerCardsController *)cardsController heightForCardHeaderInTableView:(LLCardTableView *)tableView;

///头部视图Class。默认为UITableViewCell。
- (Class)cardsController:(LLContainerCardsController *)cardsController cellClassForCardHeaderInTableView:(LLCardTableView *)tableView;

///头部视图复用标识符。默认为"CellClass_CardType"的形式。
- (NSString *)cardsController:(LLContainerCardsController *)cardsController cellIdentifierForCardHeaderInTableView:(LLCardTableView *)tableView;

///复用头部视图
- (void)cardsController:(LLContainerCardsController *)cardsController reuseCell:(UITableViewCell *)cell forCardHeaderInTableView:(LLCardTableView *)tableView;

///点击头部事件
- (void)cardsController:(LLContainerCardsController *)cardsController didSelectCardHeaderInTableView:(LLCardTableView *)tableView;

///是否一直显示头部视图，无论有无卡片内容。默认为NO。
- (BOOL)cardsController:(LLContainerCardsController *)cardsController alwaysShouldShowCardHeaderInTableView:(LLCardTableView *)tableView;


#pragma mark - 卡片尾部Card Footer
/**
 * Card Footer
 * @brief 卡片尾部
 */

///是否显示尾部视图。默认为NO。
- (BOOL)cardsController:(LLContainerCardsController *)cardsController shouldShowCardFooterInTableView:(LLCardTableView *)tableView;

///尾部行高
- (CGFloat)cardsController:(LLContainerCardsController *)cardsController heightForCardFooterInTableView:(LLCardTableView *)tableView;

///尾部视图Class。默认为UITableViewCell。
- (Class)cardsController:(LLContainerCardsController *)cardsController cellClassForCardFooterInTableView:(LLCardTableView *)tableView;

///尾部视图复用标识符。默认为"CellClass_CardType"的形式。
- (NSString *)cardsController:(LLContainerCardsController *)cardsController cellIdentifierForCardFooterInTableView:(LLCardTableView *)tableView;

///复用尾部视图
- (void)cardsController:(LLContainerCardsController *)cardsController reuseCell:(UITableViewCell *)cell forCardFooterInTableView:(LLCardTableView *)tableView;

///点击尾部事件
- (void)cardsController:(LLContainerCardsController *)cardsController didSelectCardFooterInTableView:(LLCardTableView *)tableView;


#pragma mark - 卡片底部间距Card Spacing
/**
 * Card Spacing
 * @brief 卡片底部间距
 */

///卡片间距大小。默认为10.0，当高度为0.0时无间距（不占用cell）。
- (CGFloat)cardsController:(LLContainerCardsController *)cardsController heightForCardSpacingInTableView:(LLCardTableView *)tableView;

///卡片间距颜色。默认为透明。
- (UIColor *)cardsController:(LLContainerCardsController *)cardsController colorForCardSpacingInTableView:(LLCardTableView *)tableView;

///复用卡片底部间距视图
- (void)cardsController:(LLContainerCardsController *)cardsController reuseCell:(UITableViewCell *)cell forCardSpaingInTableView:(LLCardTableView *)tableView;


#pragma mark - 卡片错误Card Error
/**
 * Card Error
 * @brief 卡片错误
 */

///是否显示卡片错误提示。默认为NO。
- (BOOL)cardsController:(LLContainerCardsController *)cardsController shouldShowCardErrorWithCode:(ELLCardErrorCode)errorCode;

///是否忽略卡片错误。默认为NO。
- (BOOL)cardsController:(LLContainerCardsController *)cardsController shouldIgnoreCardErrorWithCode:(ELLCardErrorCode)errorCode;

///卡片错误描述。默认为"获取失败 点击重试"
- (NSAttributedString *)cardsController:(LLContainerCardsController *)cardsController errorDescriptionWithCode:(ELLCardErrorCode)errorCode;

///错误卡片的背景色 默认clearColor
- (UIColor *)cardsController:(LLContainerCardsController *)cardsController errorBackgroundColorWithCode:(ELLCardErrorCode)errorCode;


#pragma mark - 滚动监听Scroll 当前可见卡片
/**
 *  Scroll 当前可见卡片
 *  @brief 滚动监听（需开启页面滚动监听开关observeScrollEvent）
 */

///向可见卡片发送列表滚动事件（同一个卡片只接收一次回调）
- (void)cardsController:(LLContainerCardsController *)cardsController didScrollVisibleCellsInTableView:(LLCardTableView *)tableView;

///向可见卡片发送每个cell的滚动事件
- (void)cardsController:(LLContainerCardsController *)cardsController didScrollVisibleCell:(UITableViewCell *)cell forCardContentAtIndex:(NSInteger)index;

///向可见卡片发送列表滚动停止事件（同一个卡片只接收一次回调）
- (void)cardsController:(LLContainerCardsController *)cardsController didEndScrollingVisibleCellsInTableView:(LLCardTableView *)tableView;

///列表滚动停止时，向可见卡片发送每个cell的曝光百分比
- (void)cardsController:(LLContainerCardsController *)cardsController didEndScrollingVisibleCell:(UITableViewCell *)cell exposeFromPercent:(NSInteger)fromPercent toPercent:(NSInteger)toPercent forCardContentAtIndex:(NSInteger)index;

///向当前视图可见卡片透传scrollView scrollViewWillBeginDragging代理
- (void)cardsController:(LLContainerCardsController *)cardsController scrollViewWillBeginDraggingForCell:(UITableViewCell *)cell;
///向当前视图可见卡片发送停止事件
- (void)cardsController:(LLContainerCardsController *)cardsController didEndScrollingForCell:(UITableViewCell *)cell;


#pragma mark - 滚动监听 所有卡片
/**
 *  Scroll 所有卡片
 *  @brief 滚动监听（无需开启页面滚动监听开关observeScrollEvent）
 */

///向所有卡片发送tableview的scrollViewDidScroll事件
- (void)cardsController:(LLContainerCardsController *)cardsController scrollViewDidScroll:(UIScrollView *)scrollView;


#pragma mark - 加载更多Request More
/**
 * Request More
 * @brief 加载更多（属性canRequestMoreData为YES的卡片可响应）
 */

///触发加载更多事件监听
- (void)didTriggerRequestMoreDataActionInCardsController:(LLContainerCardsController *)cardsController;


#pragma mark - 单卡片请求Single Card Request
/**
 * Single Card Request
 * @brief 单卡片请求
 */

///单卡片网络请求结束，包括成功or失败,如果请求失败cardContext.error不为空；如果请求成功但是数据为空，应该设置该卡片isNoData = YES,然后会执行Card Error相关代理
- (void)cardRequestDidFinishInCardsController:(LLContainerCardsController *)cardsController;

//方式一
///请求的LLURL 对象，可支持缓存
- (LLURL *)cardRequestLLURLInCardsController:(LLContainerCardsController *)cardsController;

//方式二
///请求的url, 异步请求必须实现
- (NSString *)cardRequestURLInCardsController:(LLContainerCardsController *)cardsController;
///解析数据源的model的class,默认LLBaseResponseModel
- (Class)cardRequestParserModelClassInCardsController:(LLContainerCardsController *)cardsController;

///方式一二均可使用，请求的参数
- (NSDictionary *)cardRequestParametersInCardsController:(LLContainerCardsController *)cardsController;


#pragma mark - 曝光统计Expose
/**
 * Expose
 * @brief 曝光统计
 */
///曝光头部
- (NSArray *)cardsController:(LLContainerCardsController *)cardsController exposureForCardHeaderAtIndex:(NSInteger)index;
///曝光底部
- (NSArray *)cardsController:(LLContainerCardsController *)cardsController exposureForCardFooterAtIndex:(NSInteger)index;
///曝光内容，默认曝光toPercent>0 就曝光，曝光区域fromPercent-toPercent
- (NSArray *)cardsController:(LLContainerCardsController *)cardsController exposureForCardContentAtIndex:(NSInteger)index exposeFromPercent:(NSInteger)fromPercent toPercent:(NSInteger)toPercent;

///发送未曝光过的卡片内容，外部无需对object进行是否曝光的处理,仅埋点即可
- (void)cardsController:(LLContainerCardsController *)cardsController sendCardContentExposeWithData:(NSArray *)data;
///发送未曝光过的头部内容，外部无需对object进行是否曝光的处理,仅埋点即可
- (void)cardsController:(LLContainerCardsController *)cardsController sendCardHeaderExposeWithData:(NSArray *)data;
///发送未曝光过的底部内容，外部无需对object进行是否曝光的处理,仅埋点即可
- (void)cardsController:(LLContainerCardsController *)cardsController sendCardFooterExposeWithData:(NSArray *)data;


@end

NS_ASSUME_NONNULL_END
