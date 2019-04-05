//
//  LLContainerCardsController.h
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/7.
//

#import <UIKit/UIKit.h>
#import "LLCardErrorCell.h"
#import "LLCardTableView.h"
#import "LLCardController.h"

NS_ASSUME_NONNULL_BEGIN

///卡片列表刷新方式
typedef NS_OPTIONS(NSUInteger, LLCardsRefreshType) {
    ///无刷新方式
    LLCardsRefreshTypeNone                = 0,
    ///下拉刷新
    LLCardsRefreshTypePullToRefresh       = 1 << 0,
    ///上拉加载更多
    LLCardsRefreshTypeInfiniteScrolling   = 1 << 1,
    ///中心加载视图
    LLCardsRefreshTypeLoadingView         = 1 << 2,
};

///卡片数据清除方式
typedef NS_ENUM(NSUInteger, LLCardsClearType) {
    ///请求前清除
    LLCardsClearTypeBeforeRequest     = 0,
    ///请求后清除
    LLCardsClearTypeAfterRequest      = 1,
};



@interface LLContainerCardsController : UIViewController <UITableViewDataSource, UITableViewDelegate, LLCardControllerDelegate>

///卡片表视图
@property (nonatomic, strong, readonly) LLCardTableView *tableView;

///卡片数据源
@property (nonatomic, strong, readonly) NSMutableArray<LLCardContext *> *cardsArray;

///卡片控制器数据源
@property (nonatomic, strong, readonly) NSMutableArray<LLCardController *> *cardControllersArray;

///卡片控制器各卡片主背景色，默认clearColor
@property (nonatomic, strong) UIColor *cardTintColor;

///获取指定类型的卡片控制器
- (NSArray<LLCardController *> *)queryCardControllersWithType:(ELLCardType)type;

///滚动到指定类型的卡片
- (void)scrollToCardType:(ELLCardType)type animated:(BOOL)animated;

@end



@interface LLContainerCardsController (Request)
///卡片列表刷新方式
@property (nonatomic, assign) LLCardsRefreshType refreshType;
///卡片数据清除方式，默认LLCardsClearTypeAfterRequest
@property (nonatomic, assign) LLCardsClearType   clearType;
///使用默认错误提示，默认YES
@property (nonatomic, assign) BOOL               enableNetworkError;
#pragma mark - 重写
/// **子类必须重写真正的网络请求，请求卡片数据
- (void)requestListData NS_REQUIRES_SUPER;

#pragma mark - 子类可调用、可继承
///请求卡片列表，子类加载数据的时候调用
- (void)requestCards;
///加载更多数据。默认回调卡片-didTriggerRequestMoreDataActionInLLContainerCardsController协议，可继承重写事件。
- (void)requestMoreData;
///请求单卡片数据，实现cardRequestDidFinishInCardsController等代理的可使用
- (void)requestCardDataWithController:(LLCardController *)cardController;

///卡片列表请求将开始
- (void)requestCardsWillStartIgnoreCenterLoading:(BOOL)ignore NS_REQUIRES_SUPER;
///卡片列表请求成功
- (void)requestCardsDidSucceedWithCardsArray:(NSArray<LLCardContext *> *)cardsArray NS_REQUIRES_SUPER;
///卡片列表请求失败
- (void)requestCardsDidFailWithError:(NSError *)error NS_REQUIRES_SUPER;

///加载更多卡片请求成功
- (void)requestMoreCardsDidSucceedWithCardsArray:(NSArray<LLCardContext *> *)cardsArray NS_REQUIRES_SUPER;
///加载更多卡片失败
- (void)requestMoreCardsDidFailWithError:(NSError *)error NS_REQUIRES_SUPER;

///单卡片数据请求成功，如自行维护请求的，可调用
- (void)requestCardDataDidSucceedWithCardContext:(LLCardContext *)cardContext NS_REQUIRES_SUPER;
///单卡片数据请求失败，如自行维护请求的，可调用
- (void)requestCardDataDidFailWithCardContext:(LLCardContext *)cardContext error:(NSError *)error NS_REQUIRES_SUPER;

@end


@interface LLContainerCardsController (Bottom)

///显示表视图封底。默认为NO。若取值为YES且刷新方式不支持LLCardsRefreshTypeInfiniteScrolling，tableFooterView自动显示封底视图。
@property (nonatomic, assign) BOOL enableTableBottomView;
///封底自定义视图。默认为nil，提示“没有更多了”
@property (nonatomic, strong) UIView *tableBottomCustomView;

///触发加载更多事件，启动加载动画
- (void)triggerInfiniteScrollingAction;
///完成加载更多事件，停止加载动画
- (void)finishInfiniteScrollingAction;
///完成所有数据加载，显示没有更多了封底图
- (void)didFinishLoadAllData;

@end




@interface LLContainerCardsController (Event)

/**
 *  是否开启列表滚动监听
 *  默认为NO。若取值为YES，可见cell所属卡片将收到滚动及滚动停止回调
 *  详见LLContainerCardsControllerDelegate的Scroll分组
 */
@property (nonatomic) BOOL observeScrollEvent;

@end



///曝光 扩展备用
@interface LLContainerCardsController (Expose)

///是否开启曝光功能
@property (nonatomic) BOOL  enableExpose;

///重置曝光
- (void)resetExposeStatistics;

///发送当前屏幕的曝光
- (void)exposeStatistics;

///获取指定视图的曝光百分比
- (void)queryExposeRangeOfView:(UIView *)view fromPercent:(NSInteger *)fromPercent toPercent:(NSInteger *)toPercent;
///获取指定区块的曝光百分比
- (void)queryExposeRangeOfRect:(CGRect)rect fromPercent:(NSInteger *)fromPercent toPercent:(NSInteger *)toPercent;

@end


NS_ASSUME_NONNULL_END
