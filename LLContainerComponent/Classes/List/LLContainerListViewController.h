//
//  LLContainerListViewController.h
//  LLContainerComponent
//
//  Created by lifuqing on 2018/9/13.
//

#import <UIKit/UIKit.h>
#import "LLContainerListProtocol.h"
#import <LLHttpEngine/LLListBaseDataSource.h>
#import "LLErrorView.h"
#import <YLPullToRefresh/YLPullToRefresh.h>

@protocol LLContainerListDelegate;

///列表刷新方式
typedef NS_OPTIONS(NSUInteger, ListRefreshType) {
    ///无刷新方式
    ListRefreshTypeNone                = 0,
    ///下拉刷新
    ListRefreshTypePullToRefresh       = 1 << 0,
    ///上拉加载更多
    ListRefreshTypeInfiniteScrolling   = 1 << 1,
    ///中心加载视图
    ListRefreshTypeLoadingView         = 1 << 2,
};

///列表数据清除方式
typedef NS_ENUM(NSUInteger, ListClearType) {
    ///请求前清除
    ListClearTypeBeforeRequest     = 0,
    ///请求后清除
    ListClearTypeAfterRequest      = 1,
};


///列表错误类型
typedef NS_ENUM(NSInteger, ListErrorCode) {
    ///无错误
    ListErrorCodeNone       = 0,
    ///网络错误
    ListErrorCodeNetwork    = -9900,
    ///数据获取失败
    ListErrorCodeFailed     = -9901,
};

@interface LLContainerListViewController : UIViewController
///列表delegate, 需要在viewdidload之前设置好
@property (nonatomic, weak) id <LLContainerListDelegate> listDelegate;
///事件埋点delegate，由此列表框架内容所包含的埋点事件请写在LLContainerEventDelegate里面
@property (nonatomic, weak) id <LLContainerEventDelegate> eventDelegate;
///曝光埋点delegate，由此列表框架内容所包含的曝光埋点请写在LLContainerExposeDelegate里面
@property (nonatomic, weak) id <LLContainerExposeDelegate> exposeDelegate;
@end

@interface LLContainerListViewController (List)
///列表的tableview
@property (nonatomic, strong, readonly) UITableView *listTableView;
///列表对应的LLListBaseDataSource
@property (nonatomic, strong, readonly) LLListBaseDataSource *listDataSource;
///列表数据源
@property (nonatomic, strong, readonly) NSMutableArray *listArray;

///创建之后外部需要额外设置属性的时候调用
- (void)extraConfigTableView;

@end


@interface LLContainerListViewController (Request)

///列表刷新方式
@property (nonatomic, assign) ListRefreshType refreshType;
///列表数据清除方式，默认ListClearTypeAfterRequest
@property (nonatomic, assign) ListClearType clearType;
///使用默认错误提示，默认YES
@property (nonatomic, assign) BOOL enableNetworkError;
///使用没有更多啦封底，默认NO
@property (nonatomic, assign) BOOL enableTableBottomView;
///是否支持预加载更多数据，默认NO
@property (nonatomic, assign) BOOL enablePreLoad;


///请求全部数据，包括筛选条件和列表，如果筛选条件已经请求成功则只请求列表
- (void)requestData NS_REQUIRES_SUPER;
///请求列表失败
- (void)requestListDataFailedWithError:(NSError *)error NS_REQUIRES_SUPER;
///请求列表成功
- (void)requestListDataSuccessWithArray:(NSArray *)array NS_REQUIRES_SUPER;
///刷新视图frame,在requestListDataSuccessWithArray:之后执行
- (void)refreshLayoutViews NS_REQUIRES_SUPER;

@end


@interface LLContainerListViewController (CanRewrite)

#pragma mark - 点击重新加载需要调用的
//默认点击提示信息事件
- (void)touchErrorViewAction;

#pragma mark - 重写 hud
- (void)showMessage:(NSString *)message inView:(UIView *)view;

#pragma mark - 重写 Error View

- (void)hideErrorView;
- (void)showErrorViewWithErrorType:(LLErrorType)errorType selector:(SEL)selector;


@end
