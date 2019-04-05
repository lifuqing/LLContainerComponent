//
//  LLContainerComponent.m
//  LLContainerComponent
//
//  Created by lifuqing on 2018/9/13.
//

#import "LLContainerListViewController.h"
#import <LLHttpEngine/LLListBaseDataSource.h>
#import "LLLoadingView.h"
#import "LLBaseTableViewCell.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "LLErrorView.h"
#import "NSObject+LLTools.h"

@interface LLContainerListViewController () <LLListBaseDataSourceDelegate, UITableViewDelegate, UITableViewDataSource>


#pragma mark - 处理筛选和列表请求
///处理筛选和列表请求，因为涉及一次请求多次回调（有缓存）的情况，所以用group容易崩溃，用信号量代码写的较多，需要判断的逻辑多
///筛选请求完成
@property (nonatomic, assign) BOOL filterRequestCompleted;
///列表请求完成
@property (nonatomic, assign) BOOL listRequestCompleted;

#pragma mark - request
///列表刷新方式
@property (nonatomic, assign) ListRefreshType refreshType;
///列表数据清除方式
@property (nonatomic, assign) ListClearType clearType;
///使用默认错误提示，默认YES
@property (nonatomic, assign) BOOL enableNetworkError;
///loading
@property (nonatomic, strong) LLLoadingView *loadingView;


#pragma mark - 列表相关
@property (nonatomic, strong, readwrite) UITableView *listTableView;
@property (nonatomic, strong, readwrite) LLListBaseDataSource *listDataSource;
@property (nonatomic, strong, readwrite) NSMutableArray *listArray;

@end

@interface LLContainerListViewController(Expose)

#pragma mark - 曝光相关
- (void)exposeStatistics;
@end

@implementation LLContainerListViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commitInit];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;//view的底部是tabbar的顶部，不会被覆盖一部分
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.view.clipsToBounds = YES;
    
    [self.view addSubview:self.listTableView];
    
    self.refreshType = ListRefreshTypeLoadingView | ListRefreshTypePullToRefresh;
}

- (void)dealloc {
    _listTableView.delegate = nil;
    _listTableView.dataSource = nil;
}

#pragma mark - 初始化
- (void)commitInit {
    _filterRequestCompleted = NO;
    _listRequestCompleted = NO;
    
    _enableNetworkError = YES;
    _clearType = ListClearTypeAfterRequest;
    
    _listArray = [NSMutableArray array];
}

#pragma mark - 数据获取
///请求全部数据，包括筛选条件和列表，默认不忽略中间loading
- (void)requestData {
    [self requestDataIgnoreCenterLoading:NO];
}
///请求全部数据，包括筛选条件和列表ignore 是否忽略中间loading
- (void)requestDataIgnoreCenterLoading:(BOOL)ignore {
    [self requestDataWillStartIgnoreCenterLoading:ignore];
    
    ///请求列表
    [self requestListData];
}

///列表请求将开始
- (void)requestDataWillStartIgnoreCenterLoading:(BOOL)ignore {
    //清空数据源
    if (_clearType == ListClearTypeBeforeRequest) { //请求前清除数据源
        if (_listArray.count > 0) {
            [_listArray removeAllObjects];
            [_listTableView reloadData];
        }
    }
    
    //显示加载视图
    if (_refreshType & ListRefreshTypeLoadingView && !ignore) {
        if (!_loadingView) {
            _loadingView = [[LLLoadingView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 300.0)]; //给定足够大的尺寸
            _loadingView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        }
        _loadingView.center = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0);
        [self.view addSubview:_loadingView];
        [_loadingView startAnimating];
    }
    
    if (_enableNetworkError) {
        [self hideErrorView];
    }
}

///请求列表数据
- (void)requestListData {
    NSDictionary *param = nil;
    [self.listDataSource resetParams];
    if ([_listDelegate respondsToSelector:@selector(requestListPargamsForListController:)]) {
        param = [_listDelegate requestListPargamsForListController:self];
    }
    [self.listDataSource.llurl.params addEntriesFromDictionary:param];
    
    if ([_listDelegate respondsToSelector:@selector(requestListCacheTypeForListController:)]) {
        self.listDataSource.llurl.cacheType = [_listDelegate requestListCacheTypeForListController:self];
    }
    
    _listRequestCompleted = NO;
    [self.listDataSource load];
}

///请求更多列表数据
- (void)requestMoreListData {
    if (_listDataSource.hasMore) {
        _listRequestCompleted = NO;
        [self.listDataSource loadMore];
    }
    else {
        [_listTableView.infiniteScrollingView stopAnimating];
        [self showMessage:@"没有更多数据啦~" inView:self.view];
    }
}

///任意请求完成的回调
- (void)requestGroupDidFinishNotify {
    BOOL canHandle = _listRequestCompleted;
    
    if (canHandle) {
        [self handleRequestFinish];
    }
}

///请求完成后的处理
- (void)handleRequestFinish {
    if (self.listDataSource.error) {
        [self requestListDataFailedWithError:[NSError errorWithDomain:self.listDataSource.error.domain code:ListErrorCodeFailed userInfo:nil]];
    }
    else {
        [self requestListDataSuccessWithArray:self.listDataSource.list];
        if (self.listDataSource.list.count > 0) {
            if (self.listDataSource.hasMore) {
                self.refreshType |= ListRefreshTypeInfiniteScrolling;
            }
            else {
                // 与|=配对，比较靠谱 用^=有风险 0^=1就有问题了
                self.refreshType &= ~ListRefreshTypeInfiniteScrolling;
            }
        }
    }
    
    [self refreshLayoutViews];
    //曝光
    [self exposeStatistics];
}

///刷新视图frame
- (void)refreshLayoutViews {
    _listTableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
}

///请求列表成功
- (void)requestListDataSuccessWithArray:(NSArray *)array {
    [self endRefresh];
    
    if (_listArray.count
        && array.count
        && [_listArray isEqualToArray:array]) { //数据未变更
        return;
    }
    
    self.listArray.array = array;
    
    [_listTableView reloadData];
    
    //隐藏错误提示
    if (_enableNetworkError) {
        [self hideErrorView];
        if (array.count == 0) {
            [self showErrorViewWithErrorType:LLErrorTypeNoData selector:@selector(touchErrorViewAction)];
        }
    }
    
}

///请求列表失败
- (void)requestListDataFailedWithError:(NSError *)error {
    //清空数据源
    if (_clearType == ListClearTypeAfterRequest) {
        [_listArray removeAllObjects];
        [_listTableView reloadData];
    }

    [self endRefresh];
    
    //显示错误提示视图
    if (_enableNetworkError) {
        if (error.code == ListErrorCodeFailed) { //数据错误
            [self showErrorViewWithErrorType:LLErrorTypeFailed selector:@selector(touchErrorViewAction)];
            [self showMessage:error.domain inView:self.view];
        } else if (error.code == ListErrorCodeNetwork) { //网络错误
            [self showErrorViewWithErrorType:LLErrorTypeNoNetwork selector:@selector(touchErrorViewAction)];
            [self showMessage:error.domain inView:self.view];
        }
    }
}
#pragma mark - HUD
- (void)showMessage:(NSString *)message inView:(UIView *)view {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = message;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        [MBProgressHUD hideHUDForView:view animated:YES];
    });
}

#pragma mark - Error View
//默认点击提示信息事件
- (void)touchErrorViewAction
{
    if (_refreshType & ListRefreshTypeLoadingView) {
        [self requestData];
    } else if (_refreshType & ListRefreshTypePullToRefresh) {
        [_listTableView triggerPullToRefresh];
    } else {
        [self requestData];
    }
}

- (void)hideErrorView {
    [LLErrorView hideErrorViewInView:self.listTableView];
}
- (void)showErrorViewWithErrorType:(LLErrorType)errorType selector:(SEL)selector {
    BOOL shouldShowError = YES;
    if ([_listDelegate respondsToSelector:@selector(shouldShowErrorViewAndToastForListController:)]) {
        shouldShowError = [_listDelegate shouldShowErrorViewAndToastForListController:self];
    }
    if (shouldShowError) {
        __weak __typeof(self) weakSelf = self;
        [LLErrorView showErrorViewInView:self.listTableView withErrorType:errorType withClickBlock:^{
            IMP imp = [weakSelf methodForSelector:selector];
            void (*func)(id, SEL) = (void *)imp;
            func(weakSelf, selector);
        }];
    }
}


///请求之后结束刷新状态
- (void)endRefresh {
    //隐藏加载视图
    if (_refreshType & ListRefreshTypeLoadingView) { //中心加载视图
        [_loadingView stopAnimating];
        [_loadingView removeFromSuperview];
    }
    
    if (_refreshType & ListRefreshTypePullToRefresh && _listTableView.pullToRefreshView.state == SVPullToRefreshStateLoading) { //下拉刷新
        [_listTableView.pullToRefreshView stopAnimating];
    }
    if (_refreshType & ListRefreshTypeInfiniteScrolling && _listTableView.infiniteScrollingView.state == SVInfiniteScrollingStateLoading) { //上拉加载更多
        [_listTableView.infiniteScrollingView stopAnimating];
    }
}


#pragma mark - Property & setter

- (void)setRefreshType:(ListRefreshType)refreshType
{
    if (_refreshType != refreshType) {
        _refreshType = refreshType;
        //注意，很有可能在viewdidload之前调用，所以不要轻易使用lazyloading 创建tableview
        __weak typeof(self) weakSelf = self;
        //下拉刷新
        if (self.isViewLoaded) {
            if (refreshType & ListRefreshTypePullToRefresh) {
                [self.listTableView addPullToRefreshWithActionHandler:^{
                    [weakSelf requestDataIgnoreCenterLoading:YES];
                    if ([weakSelf.eventDelegate respondsToSelector:@selector(eventPullRefreshForListController:)]) {
                        [weakSelf.eventDelegate eventPullRefreshForListController:weakSelf];
                    }
                }];
            }
            else {
                [_listTableView.pullToRefreshView removeFromSuperview];
            }
        } else {
            [_listTableView.pullToRefreshView stopAnimating];
        }
        
        //上拉加载更多
        if (self.isViewLoaded) {
            if (refreshType & ListRefreshTypeInfiniteScrolling) {
                [self.listTableView addInfiniteScrollingWithActionHandler:^{
                    [weakSelf requestMoreListData];
                }];
            }
            else {
                [_listTableView.infiniteScrollingView removeFromSuperview];
            }
        }else {
            [_listTableView.infiniteScrollingView stopAnimating];
        }
    }
}

#pragma mark - Property & getter
- (LLListBaseDataSource *)listDataSource {
	if (!_listDataSource)
	{
        NSString *listParser = nil;
        if ([_listDelegate respondsToSelector:@selector(requestListParserForListController:)])
        {
            listParser = [_listDelegate requestListParserForListController:self];
        }
        
        Class listConfigClass = nil;
        if ([_listDelegate respondsToSelector:@selector(requestListURLConfigClassForListController:)])
        {
            listConfigClass = [_listDelegate requestListURLConfigClassForListController:self];
        }
        
        Class dataSourceClass = [LLListBaseDataSource class];
        if ([_listDelegate respondsToSelector:@selector(requestListDataSourceClassForListController:)])
        {
            dataSourceClass = [_listDelegate requestListDataSourceClassForListController:self];
        }
        
		_listDataSource = [[dataSourceClass alloc] initWithDelegate:self parser:listParser urlConfigClass:listConfigClass];
        
	}
	return _listDataSource;
}

- (UITableView *)listTableView {
    if (!_listTableView) {
        _listTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _listTableView.dataSource = self;
        _listTableView.delegate = self;
        _listTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _listTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        _listTableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
        
        if (@available(iOS 11, *)) {
            _listTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            _listTableView.estimatedRowHeight = 0;
            _listTableView.estimatedSectionHeaderHeight = 0;
            _listTableView.estimatedSectionFooterHeight = 0;
        }
    }
    return _listTableView;
}

#pragma mark - LLListBaseDataSourceDelegate
- (void)finishOfDataSource:(LLListBaseDataSource *)dataSource {
    self.listRequestCompleted = YES;
    [self requestGroupDidFinishNotify];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([_listDelegate respondsToSelector:@selector(listController:rowCountInSection:)]) {
        return [_listDelegate listController:self rowCountInSection:section];
    }
    return _listArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([_listDelegate respondsToSelector:@selector(listController:sectionCountInTableView:)]) {
        return [_listDelegate listController:self sectionCountInTableView:tableView];
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_listDelegate respondsToSelector:@selector(listController:rowHeightAtIndexPath:)]) {
        return [_listDelegate listController:self rowHeightAtIndexPath:indexPath];
    }
    return 0;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    //复用参数
    Class class = nil;
    NSString *identifier = nil;
    
    if ([_listDelegate respondsToSelector:@selector(listController:cellClassAtIndexPath:)]) {
        class = [_listDelegate listController:self cellClassAtIndexPath:indexPath];
    }
    if ([_listDelegate respondsToSelector:@selector(listController:cellIdentifierAtIndexPath:)]) {
        identifier = [_listDelegate listController:self cellIdentifierAtIndexPath:indexPath];
    }
    if (!class) {
        class = [UITableViewCell class];
    }
    if (!identifier.length) {
        identifier = [NSString stringWithFormat:@"%@", NSStringFromClass(class)]; //同类卡片内部复用cell
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[class alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.clipsToBounds = YES;
        cell.exclusiveTouch = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if ([_listDelegate respondsToSelector:@selector(listController:reuseCell:atIndexPath:)]) {
        [_listDelegate listController:self reuseCell:cell atIndexPath:indexPath];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_listDelegate respondsToSelector:@selector(listController:didSelectedCellAtIndexPath:)]) {
        [_listDelegate listController:self didSelectedCellAtIndexPath:indexPath];
    }
    
    if ([_eventDelegate respondsToSelector:@selector(eventListController:clickDidSelectedCellAtIndexPath:)]) {
        [_eventDelegate eventListController:self clickDidSelectedCellAtIndexPath:indexPath];
    }
}

@end

#pragma mark - 曝光 Expose

@implementation LLContainerListViewController (Expose)

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        //发送曝光埋点
        [self exposeStatistics];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //发送曝光埋点
    [self exposeStatistics];
}

///曝光埋点
- (void)exposeStatistics
{
    if (!self.exposeDelegate) return;
    
    NSMutableArray<NSIndexPath *> *exposeArray = [NSMutableArray array];
    
    NSArray<UITableViewCell *> *visibleCellArray = [self.listTableView visibleCells];
    
    [visibleCellArray enumerateObjectsUsingBlock:^(UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath *indexPath = [self.listTableView indexPathForCell:obj];
        if (CGRectContainsRect([self exposeFrame], obj.frame)) {//没有完全展示,直接跳过
            BOOL should = YES;
            if ([self.exposeDelegate respondsToSelector:@selector(exposeShouldExposeAtIndexPath:forListController:)]) {
                should = [self.exposeDelegate exposeShouldExposeAtIndexPath:indexPath forListController:self];
            }
            
            if (should) {
                [exposeArray addObject:indexPath];
            }
        }
    }];
    
    if (exposeArray.count > 0) {
        /// 数据设置曝光
        NSArray *exposeDataArray = nil;
        if ([self.exposeDelegate respondsToSelector:@selector(exposeListParseExposeArrayWithIndexPath:)]) {
            exposeDataArray = [self.exposeDelegate exposeListParseExposeArrayWithIndexPath:exposeArray];
        }
        else {
            exposeDataArray = [self parseExposeArrayWithIndexPath:exposeArray];
        }
        
        if (exposeDataArray.count > 0 && [self.exposeDelegate respondsToSelector:@selector(exposeListSendExposeStatisticsWithData:)]) {
            [self.exposeDelegate exposeListSendExposeStatisticsWithData:exposeDataArray];
        }
    }
}

///根据indexpath解析曝光数据源，遍历之后将数据源LLBaseResponseModel类型的属性ll_exposed设置为YES
- (nullable NSArray *)parseExposeArrayWithIndexPath:(nullable NSArray<NSIndexPath *> *)exposeArray {
    
    __block NSMutableArray <LLBaseResponseModel *> *exposeDataArray = [NSMutableArray array];
    
    [exposeArray enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        LLBaseTableViewCell *cell = [self.listTableView cellForRowAtIndexPath:obj];
        if ([cell isKindOfClass:[LLBaseTableViewCell class]]) {
            LLBaseResponseModel *model = cell.model;
            if (model && !model.ll_exposed) {
                model.ll_exposed = YES;
                [exposeDataArray addObject:model];
            }
        }
    }];
    return [exposeDataArray copy];
}


- (CGRect)exposeFrame
{
    CGFloat bottomInset = self.listTableView.contentInset.bottom;
    if (self.refreshType & ListRefreshTypeInfiniteScrolling) { //已设置加载更多控件
        if (self.listTableView.infiniteScrollingView) {
            bottomInset = CGRectGetHeight(self.listTableView.infiniteScrollingView.frame);
        }
    }
    return CGRectMake(0, self.listTableView.contentOffset.y + self.listTableView.contentInset.top, self.listTableView.frame.size.width, self.listTableView.frame.size.height - self.listTableView.contentInset.top - bottomInset);
}
@end
