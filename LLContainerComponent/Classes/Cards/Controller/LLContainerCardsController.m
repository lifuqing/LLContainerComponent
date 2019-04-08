//
//  LLContainerCardsController.m
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/7.
//

#import "LLContainerCardsController.h"
#import "LLLoadingView.h"
#import "LLCardTableFooterView.h"
#import <LLHttpEngine/LLHttpEngine.h>
#import <SVPullToRefresh/SVPullToRefresh.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <NSObject+LLTools.h>

#define kTagTableBottomView     1111    //卡片封底视图标记


@interface LLContainerCardsController ()
{
}

@property (nonatomic, strong) LLLoadingView *loadingView; //加载视图

@property (nonatomic, strong, readwrite) LLCardTableView *tableView;

/* Request */
///卡片列表刷新方式
@property (nonatomic, assign) LLCardsRefreshType refreshType;
///卡片数据清除方式
@property (nonatomic, assign) LLCardsClearType   clearType;
///使用默认错误提示
@property (nonatomic, assign) BOOL               enableNetworkError;

/* Bottom */
@property (nonatomic, assign) BOOL               enableTableBottomView;  //显示表视图封底
@property (nonatomic, strong) UIView             *tableBottomCustomView; //封底自定义视图

/* Event */
@property (nonatomic, assign) BOOL               observeScrollEvent;     //是否开启列表滚动监听

/*Expose */
@property (nonatomic, assign) BOOL               enableExpose;           //是否开启曝光统计

@end

@interface LLContainerCardsController (BottomPrivate)
- (void)refreshTableBottomView;
@end



@implementation LLContainerCardsController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cardsArray = [[NSMutableArray alloc] init];
        _cardControllersArray = [[NSMutableArray alloc] init];
        
        _cardTintColor = [UIColor clearColor];
        _enableNetworkError = YES;
        _clearType = LLCardsClearTypeAfterRequest;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;//view的底部是tabbar的顶部，不会被覆盖一部分
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.view.clipsToBounds = YES;
    
    [self.view addSubview:self.tableView];
    
    self.refreshType = LLCardsRefreshTypeLoadingView | LLCardsRefreshTypePullToRefresh;
    //封底视图
    [self refreshTableBottomView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    
    [_loadingView stopAnimating];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_cardControllersArray enumerateObjectsUsingBlock:^(LLCardController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(cardsControllerViewWillAppear:)]) {
            [obj cardsControllerViewWillAppear:self];
        }
    }];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_cardControllersArray enumerateObjectsUsingBlock:^(LLCardController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(cardsControllerViewDidAppear:)]) {
            [obj cardsControllerViewDidAppear:self];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_cardControllersArray enumerateObjectsUsingBlock:^(LLCardController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(cardsControllerViewWillDisappear:)]) {
            [obj cardsControllerViewWillDisappear:self];
        }
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_cardControllersArray enumerateObjectsUsingBlock:^(LLCardController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(cardsControllerViewDidDisappear:)]) {
            [obj cardsControllerViewDidDisappear:self];
        }
    }];
}


#pragma mark - Property

- (LLCardTableView *)tableView {
    if (!_tableView) {
        _tableView = [[LLCardTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        _tableView.cardControllersArray = _cardControllersArray;
        _tableView.cardsController = self;
        _tableView.backgroundColor = self.cardTintColor;
        _tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
        
        if (@available(iOS 11, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            _tableView.estimatedRowHeight = 0;
            _tableView.estimatedSectionHeaderHeight = 0;
            _tableView.estimatedSectionFooterHeight = 0;
        }
    }
    return _tableView;
}

- (void)setRefreshType:(LLCardsRefreshType)refreshType
{
    if (_refreshType != refreshType) {
        _refreshType = refreshType;
        
        //注意，很有可能在viewdidload之前调用，所以不要轻易使用lazyloading 创建tableview
        __weak typeof(self) weakSelf = self;
        //下拉刷新
        if (self.isViewLoaded) {
            if (refreshType & LLCardsRefreshTypePullToRefresh) {
                [self.tableView addPullToRefreshWithActionHandler:^{
                    [weakSelf requestCardsIgnoreCenterLoading:YES];
                }];
            }
            else {
                [_tableView.pullToRefreshView removeFromSuperview];
            }
        } else {
            [_tableView.pullToRefreshView stopAnimating];
        }
        
        //上拉加载更多//上拉加载更多控件依赖于表视图加载
        if (self.isViewLoaded) {
            if (refreshType & LLCardsRefreshTypeInfiniteScrolling) {
                [self.tableView addInfiniteScrollingWithActionHandler:^{
                    [weakSelf requestMoreData];
                }];
            }
            else {
                [_tableView.infiniteScrollingView removeFromSuperview];
            }
        }else {
            [_tableView.infiniteScrollingView stopAnimating];
        }
        
        //封底视图
        if (self.isViewLoaded) {
            [self refreshTableBottomView];
        }
    }
}


#pragma mark - Private Methods

//获取index对应的卡片控制器
- (LLCardController *)cardControllerAtIndex:(NSInteger)index
{
    return (index < _cardControllersArray.count) ? _cardControllersArray[index] : nil;
}

//是否为卡片间距
- (BOOL)isCardSpacing:(LLCardController *)cardController atIndexPath:(NSIndexPath *)indexPath
{
    return (cardController.showCardSpacing && indexPath && indexPath.row == cardController.rowCountCache - 1);
}

//是否为卡片头部
- (BOOL)isCardHeader:(LLCardController *)cardController atIndexPath:(NSIndexPath *)indexPath
{
    return (cardController.showCardHeader && indexPath && indexPath.row == 0);
}

//是否为卡片尾部
- (BOOL)isCardFooter:(LLCardController *)cardController atIndexPath:(NSIndexPath *)indexPath
{
    BOOL isCardFooter = NO;
    if (cardController.showCardFooter && indexPath) {
        if (cardController.showCardSpacing && indexPath.row == cardController.rowCountCache - 2) {
            isCardFooter = YES;
        }
        if (!cardController.showCardSpacing && indexPath.row == cardController.rowCountCache - 1) {
            isCardFooter = YES;
        }
    }
    return isCardFooter;
}

//是否为有效卡片内容
- (BOOL)isValidCardContent:(LLCardController *)cardController atIndexPath:(NSIndexPath *)indexPath
{
    if (!cardController || !indexPath) return NO;
    
    if ([self isCardSpacing:cardController atIndexPath:indexPath]) return NO; //卡片间距
    if ([self isCardHeader:cardController atIndexPath:indexPath]) return NO; //头部视图
    if ([self isCardFooter:cardController atIndexPath:indexPath]) return NO; //尾部视图
    if (cardController.showCardError) return NO; //错误卡片
    
    return YES;
}



#pragma mark - Public Methods

//获取指定类型的卡片控制器
- (NSArray<LLCardController *> *)queryCardControllersWithType:(ELLCardType)type
{
    NSMutableArray *cardControllersArray = nil;
    for (int i = 0; i < _cardControllersArray.count; i++) {
        LLCardController *cardController = _cardControllersArray[i];
        if (cardController.cardContext.type == type) {
            if (!cardControllersArray) {
                cardControllersArray = [NSMutableArray array];
            }
            [cardControllersArray addObject:cardController];
        }
    }
    return cardControllersArray;
}

- (void)scrollToCardType:(ELLCardType)type animated:(BOOL)animated {
    [_cardControllersArray enumerateObjectsUsingBlock:^(LLCardController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.cardContext.type == type &&
            [self.tableView numberOfSections] > idx &&
            [self.tableView numberOfRowsInSection:idx] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:idx] atScrollPosition:UITableViewScrollPositionTop animated:animated];
            *stop = YES;
        }
    }];
    
}

#pragma mark Parser

//解析卡片数据源，创建卡片控制器
- (NSArray<LLCardController *> *)parseCardControllersWithCardsArray:(NSArray<LLCardContext *> *)cardsArray
{
    NSMutableArray *cardControllersArray = [NSMutableArray array];
    for (LLCardContext *cardContext in cardsArray) {
        //初始化卡片控制器
        Class class = NSClassFromString(cardContext.clazz);
        if (![class isSubclassOfClass:[LLCardController class]]) {
            class = [LLCardController class];
        }
        
        LLCardController *cardController = [[class alloc] init];
        cardController.delegate = self;
        cardController.cardsController = self;
        cardController.cardContext = cardContext;
        [cardControllersArray addObject:cardController];
        
    }
    return cardControllersArray;
}


#pragma mark Cards

//请求卡片列表
- (void)requestCards
{
    [self requestCardsIgnoreCenterLoading:NO];
}


///请求卡片列表 ignore 是否忽略中间loading
- (void)requestCardsIgnoreCenterLoading:(BOOL)ignore {
    [self requestCardsWillStartIgnoreCenterLoading:ignore];
    
    ///请求列表
    [self requestListData];
}


///卡片请求即将开始 是否忽略中间loading
- (void)requestCardsWillStartIgnoreCenterLoading:(BOOL)ignore {
    //清空数据源
    if (_clearType == LLCardsClearTypeBeforeRequest) { //请求前清除数据源
        if (_cardControllersArray.count > 0) {
            [_cardsArray removeAllObjects];
            [_cardControllersArray removeAllObjects];
            
            [self refreshTableBottomView]; //清空数据源后，刷新封底
            
            [_tableView reloadData];
        }
    }
    
    //显示加载视图
    if (_refreshType & LLCardsRefreshTypeLoadingView && !ignore) {
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


//卡片列表请求成功
- (void)requestCardsDidSucceedWithCardsArray:(NSArray<LLCardContext *> *)cardsArray {
    [self endRefresh];
    
    if (_cardsArray.count
        && cardsArray.count
        && [_cardsArray isEqualToArray:cardsArray]) { //数据未变更
        return;
    }
    
    //解析数据源
    NSArray<LLCardController *> *cardControllersArray = [self parseCardControllersWithCardsArray:cardsArray];
    
    //更新数据源
    _cardControllersArray.array = cardControllersArray;
    _cardsArray.array = cardsArray;
    
    //执行卡片初始化监听（可能调用了UI刷新和数据请求，需在_cardsArray和_cardControllersArray赋值后调用）
    [cardControllersArray enumerateObjectsUsingBlock:^(LLCardController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(didFinishInitConfigurationInCardsController:)]) {
            [obj didFinishInitConfigurationInCardsController:self];
        }
    }];
    
    //修改数据源后，刷新封底
    [self refreshTableBottomView];
    
    [_tableView reloadData];
    
    //请求独立数据源
    [self fetchIndependentCardDataWhenRequestCards];
    
    //隐藏错误提示
    if (_enableNetworkError) {
        [self hideErrorView];
        if (cardsArray.count == 0) {
            [self showErrorViewWithErrorType:LLErrorTypeNoData selector:@selector(touchErrorViewAction)];
        }
    }
    
}

//卡片列表请求失败
- (void)requestCardsDidFailWithError:(NSError *)error {
    //清空数据源
    if (_clearType == LLCardsClearTypeAfterRequest) {
        [_cardsArray removeAllObjects];
        [_cardControllersArray removeAllObjects];
        
        [self refreshTableBottomView]; //清空数据源后，刷新封底
        [_tableView reloadData];
    }
    
    [self endRefresh];
    
    //显示错误提示视图
    if (_enableNetworkError) {
        if (error.code == ELLCardErrorCodeFailed) { //数据错误
            [self showErrorViewWithErrorType:LLErrorTypeFailed selector:@selector(touchErrorViewAction)];
            [self showMessage:error.domain inView:self.view];
        } else if (error.code == ELLCardErrorCodeNetwork) { //网络错误
            [self showErrorViewWithErrorType:LLErrorTypeNoNetwork selector:@selector(touchErrorViewAction)];
            [self showMessage:error.domain inView:self.view];
        }
    }
    
}

///请求之后结束刷新状态
- (void)endRefresh {
    //隐藏加载视图
    if (_refreshType & LLCardsRefreshTypeLoadingView) { //中心加载视图
        [_loadingView stopAnimating];
        [_loadingView removeFromSuperview];
    }
    
    if (_refreshType & LLCardsRefreshTypePullToRefresh && _tableView.pullToRefreshView.state == SVPullToRefreshStateLoading) { //下拉刷新
        [_tableView.pullToRefreshView stopAnimating];
    }
    if (_refreshType & LLCardsRefreshTypeInfiniteScrolling && _tableView.infiniteScrollingView.state == SVInfiniteScrollingStateLoading) { //上拉加载更多
        [_tableView.infiniteScrollingView stopAnimating];
    }
}

#pragma mark Card Data

//请求独立数据源
- (void)fetchIndependentCardDataWhenRequestCards{
    [self.cardControllersArray enumerateObjectsUsingBlock:^(LLCardController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.cardContext.asyncLoad) {
            [self requestCardDataWithController:obj];
        }
    }];
}

//请求单卡片数据
- (void)requestCardDataWithController:(LLCardController *)cardController
{
    __weak typeof(self) weakSelf = self;

    void(^successBlock)(NSDictionary *result, LLBaseResponseModel *model, BOOL isLocalCache) = ^(NSDictionary *result, LLBaseResponseModel *model, BOOL isLocalCache) {
        cardController.cardContext.responseError = nil;
        
        if ([result isKindOfClass:[NSDictionary class]]
            && result[@"errno"] && [result[@"errno"] integerValue] == 0
            && result[@"data"]) {
            cardController.cardContext.model = model;
            cardController.cardContext.cardInfo = result[@"data"];
            [weakSelf cardSeparateDataBeReady:cardController.cardContext];
        }
        else {
            NSError *cardError = [NSError errorWithDomain:@"CardError" code:ELLCardErrorCodeFailed userInfo:nil];
            [weakSelf cardSeparateDataUnavailable:cardController.cardContext error:cardError];
        }
    };
    
    void(^failureBlock)(LLBaseResponseModel *model) = ^(LLBaseResponseModel *model) {
        cardController.cardContext.responseError = [NSError errorWithDomain:model.errorMsg code:model.errorCode userInfo:nil];
        
        NSError *cardError = [NSError errorWithDomain:@"CardError" code:ELLCardErrorCodeNetwork userInfo:nil];
        [weakSelf cardSeparateDataUnavailable:cardController.cardContext error:cardError];
    };
    
    NSDictionary *param = nil;
    if ([cardController respondsToSelector:@selector(cardRequestParametersInCardsController:)]) {
        param = [cardController cardRequestParametersInCardsController:self];
    }

    LLURL *ljurl = nil;
    if ([cardController respondsToSelector:@selector(cardRequestLLURLInCardsController:)]) {
        ljurl = [cardController cardRequestLLURLInCardsController:self];
        [ljurl.params addEntriesFromDictionary:param];
    }
    
    if (ljurl) {
        [[LLHttpEngine sharedInstance] sendRequestWithLLURL:ljurl target:self success:successBlock failure:failureBlock];
    }
    else {
        NSString *url = nil;
        if ([cardController respondsToSelector:@selector(cardRequestURLInCardsController:)]) {
            url = [cardController cardRequestURLInCardsController:self];
        }
        
        if (url) {
            Class modelClass = nil;
            if ([cardController respondsToSelector:@selector(cardRequestParserModelClassInCardsController:)]) {
                modelClass = [cardController cardRequestParserModelClassInCardsController:self];
            }
            
            [[LLHttpEngine sharedInstance] getRequestWithURLPath:url params:param modelClass:modelClass target:self success:successBlock failure:failureBlock];
        }
    }
    
}

//单卡片请求成功回调
- (void)cardSeparateDataBeReady:(LLCardContext *)cardContext
{
    NSUInteger cardIndex = [_cardsArray indexOfObject:cardContext];
    if (cardIndex != NSNotFound && cardIndex < _cardControllersArray.count) {
        [self requestCardDataDidSucceedWithCardContext:cardContext];
    }
}

//单卡片请求失败回调
- (void)cardSeparateDataUnavailable:(LLCardContext *)cardContext error:(NSError *)error{
    NSUInteger cardIndex = [_cardsArray indexOfObject:cardContext];
    if (cardIndex != NSNotFound && cardIndex < _cardControllersArray.count) {
        [self requestCardDataDidFailWithCardContext:cardContext error:error];
    }
}


//卡片数据请求成功
- (void)requestCardDataDidSucceedWithCardContext:(LLCardContext *)cardContext
{
    cardContext.error = nil;
    
    NSUInteger index = [_cardsArray indexOfObject:cardContext];
    LLCardController *cardController = [self cardControllerAtIndex:index];
    if (cardController) { //刷新卡片视图
        cardController.cardContext = cardContext;
        if ([cardController respondsToSelector:@selector(cardRequestDidFinishInCardsController:)]) {
            [cardController cardRequestDidFinishInCardsController:self];
        }
        
        if (cardController.isNoData) {
            cardContext.error = [NSError errorWithDomain:@"CardError" code:ELLCardErrorCodeNoData userInfo:nil];
        
            if ([cardController respondsToSelector:@selector(cardsController:shouldIgnoreCardErrorWithCode:)]) {
                if ([cardController cardsController:self shouldIgnoreCardErrorWithCode:cardContext.error.code]) {
                    cardContext.error = nil; //忽略当前类型错误
                }
            }
        }
        
        [_tableView reloadSection:index];
    }
}

//卡片数据请求失败
- (void)requestCardDataDidFailWithCardContext:(LLCardContext *)cardContext error:(NSError *)error
{
    NSUInteger index = [_cardsArray indexOfObject:cardContext];
    LLCardController *cardController = [self cardControllerAtIndex:index];
    if (cardController) {
        if ([error.domain isEqualToString:@"CardError"]) {
            cardContext.error = error;
        } else {
            cardContext.error = [NSError errorWithDomain:@"CardError" code:ELLCardErrorCodeNetwork userInfo:nil];
        }
        
        if ([cardController respondsToSelector:@selector(cardsController:shouldIgnoreCardErrorWithCode:)]) {
            if ([cardController cardsController:self shouldIgnoreCardErrorWithCode:cardContext.error.code]) {
                cardContext.error = nil; //忽略当前类型错误
            }
        }
        
        if ([cardController respondsToSelector:@selector(cardRequestDidFinishInCardsController:)]) {
            [cardController cardRequestDidFinishInCardsController:self];
        }
        
        [_tableView reloadSection:index];
    }
}



#pragma mark More

//加载更多事件
- (void)requestMoreData
{
    //触发加载更多事件
    [_cardControllersArray enumerateObjectsUsingBlock:^(LLCardController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.canRequestMoreData && [obj respondsToSelector:@selector(didTriggerRequestMoreDataActionInCardsController:)]) {
            [obj didTriggerRequestMoreDataActionInCardsController:self];
        }
    }];
}

//加载更多卡片
- (void)requestMoreCardsDidSucceedWithCardsArray:(NSArray *)cardsArray
{
    if (!cardsArray.count) return;
    
    //记录参数
    NSMutableIndexSet *sections = [NSMutableIndexSet indexSet]; //新增卡片对应的sections
    NSInteger startSection = _cardsArray.count;
    
    //解析数据源
    NSArray<LLCardController *> *cardControllersArray = [self parseCardControllersWithCardsArray:cardsArray];
    
    //更新数据源
    [_cardControllersArray addObjectsFromArray:cardControllersArray];
    [_cardsArray addObjectsFromArray:cardsArray];
    
    //执行卡片初始化监听（可能调用了UI刷新和数据请求，需在_cardsArray和_cardControllersArray赋值后调用）
    [cardControllersArray enumerateObjectsUsingBlock:^(LLCardController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(didFinishInitConfigurationInCardsController:)]) {
            [obj didFinishInitConfigurationInCardsController:self];
        }
        
        [sections addIndex:(startSection + idx)];
    }];
    
    //隐藏加载视图
    if (_refreshType & LLCardsRefreshTypeInfiniteScrolling) { //上拉加载更多
        [self finishInfiniteScrollingAction];
    }
    
    //刷新视图
    [_tableView reloadSections:sections];
}

- (void)requestMoreCardsDidFailWithError:(NSError *)error
{
    
}

#pragma mark - HUD
- (void)showMessage:(NSString *)message inView:(UIView *)view {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = message;
    hud.userInteractionEnabled = NO;
    [hud hideAnimated:YES afterDelay:1];
}

#pragma mark - Error View
//默认点击提示信息事件
- (void)touchErrorViewAction
{
    if (_refreshType & LLCardsRefreshTypeLoadingView) {
        [self requestCards];
    } else if (_refreshType & LLCardsRefreshTypePullToRefresh) {
        [_tableView triggerPullToRefresh];
    } else {
        [self requestCards];
    }
}

- (void)hideErrorView {
    [LLErrorView hideErrorViewInView:self.tableView];
}
- (void)showErrorViewWithErrorType:(LLErrorType)errorType selector:(SEL)selector {
    __weak __typeof(self) weakSelf = self;
    [LLErrorView showErrorViewInView:self.tableView withErrorType:errorType withClickBlock:^{
        IMP imp = [weakSelf methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(weakSelf, selector);
    }];
}

#pragma mark - LLCardControllerDelegate
//刷新指定类型的卡片
- (void)refreshCardWithType:(ELLCardType)type
{
    [self refreshCardWithType:type animation:UITableViewRowAnimationNone];
}

- (void)refreshCardWithType:(ELLCardType)type animation:(UITableViewRowAnimation)animation
{
    NSMutableIndexSet *sections = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < _cardControllersArray.count; i++) {
        LLCardController *cardController = _cardControllersArray[i];
        if (cardController.cardContext.type == type) {
            [sections addIndex:i];
        }
    }
    
    if (sections.count > 0) {
        if (animation != UITableViewRowAnimationNone) {
            @synchronized(self) {
                [_tableView beginUpdates];
                [_tableView reloadSections:sections withRowAnimation:animation];
                [_tableView endUpdates];
            }
        }
        else {
            [_tableView reloadSections:sections];
        }
    }
}



#pragma mark - Scroll Event

//向可见卡片发送滚动事件
- (void)sendScrollEventToVisibleCards
{
    if (_observeScrollEvent) {
        NSMutableArray *visibleCards = nil;
        
        NSArray *visibleCells = [self.tableView visibleCells];
        for (int i = 0; i < visibleCells.count; i++) {
            UITableViewCell *visibleCell = visibleCells[i];
            
            NSIndexPath *indexPath = [self.tableView indexPathForCell:visibleCell];
            LLCardController *cardController = [self cardControllerAtIndex:indexPath.section];
            
            if (![self isValidCardContent:cardController atIndexPath:indexPath]) continue; //过滤卡片头部、尾部、间距和错误
            
            if ([cardController respondsToSelector:@selector(cardsController:didScrollVisibleCell:forCardContentAtIndex:)]) { //可响应回调，再执行计算
                NSInteger rowIndex = cardController.showCardHeader ? indexPath.row - 1 : indexPath.row; //数据源对应的index
                [cardController cardsController:self didScrollVisibleCell:visibleCell forCardContentAtIndex:rowIndex];
            }
            
            if ([cardController respondsToSelector:@selector(cardsController:didScrollVisibleCellsInTableView:)]) { //可响应回调，再执行计算
                if ([visibleCards containsObject:cardController]) continue; //跳过已回调卡片
                
                //发送滚动事件
                [cardController cardsController:self didScrollVisibleCellsInTableView:_tableView];
                
                //记录已回调卡片
                if (!visibleCards) {
                    visibleCards = [NSMutableArray array];
                }
                [visibleCards addObject:cardController];
            }
        }
    }
}

//向可见卡片发送滚动结束事件
- (void)sendScrollEndEventToVisibleCards
{
    if (_observeScrollEvent) {
        NSMutableArray *visibleCards = nil;
        
        NSArray *visibleCells = [self.tableView visibleCells];
        for (int i = 0; i < visibleCells.count; i++) {
            UITableViewCell *visibleCell = visibleCells[i];
            
            NSIndexPath *indexPath = [self.tableView indexPathForCell:visibleCell];
            LLCardController *cardController = [self cardControllerAtIndex:indexPath.section];
            
            if ([cardController respondsToSelector:@selector(cardsController:didEndScrollingForCell:)]) {
                [cardController cardsController:self didEndScrollingForCell:visibleCell];
            }
            
            if (![self isValidCardContent:cardController atIndexPath:indexPath]) continue; //过滤卡片头部、尾部、间距和错误
            
            //发送cell曝光百分比
            if ([cardController respondsToSelector:@selector(cardsController:didEndScrollingVisibleCell:exposeFromPercent:toPercent:forCardContentAtIndex:)]) {
                
                NSInteger fromPercent = 0; //顶部曝光百分比
                NSInteger toPercent = 0; //底部曝光百分比
                [self queryExposeRangeOfRect:visibleCell.frame fromPercent:&fromPercent toPercent:&toPercent];
                
                if (fromPercent < toPercent) {
                    NSInteger rowIndex = cardController.showCardHeader ? indexPath.row - 1 : indexPath.row; //数据源对应的index
                    [cardController cardsController:self
                         didEndScrollingVisibleCell:visibleCell
                                  exposeFromPercent:fromPercent
                                          toPercent:toPercent
                              forCardContentAtIndex:rowIndex];
                }
            }
            
            //发送滚动停止事件
            if ([cardController respondsToSelector:@selector(cardsController:didEndScrollingVisibleCellsInTableView:)]) { //可响应回调，再执行计算
                if ([visibleCards containsObject:cardController]) continue; //跳过已回调卡片
                
                //发送滚动停止事件
                [cardController cardsController:self didEndScrollingVisibleCellsInTableView:_tableView];
                
                //记录已回调卡片
                if (!visibleCards) {
                    visibleCards = [NSMutableArray array];
                }
                [visibleCards addObject:cardController];
            }
        }
    }
}



#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    for (LLCardController *cardController in self.cardControllersArray) {
        if ([cardController respondsToSelector:@selector(cardsController:scrollViewDidScroll:)]) {
            [cardController cardsController:self scrollViewDidScroll:scrollView];
        }
    }
    
    //向可见卡片发送滚动事件
    [self sendScrollEventToVisibleCards];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    NSArray *visibleCells = [self.tableView visibleCells];
    for (UITableViewCell *visibleCell in visibleCells) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:visibleCell];
        LLCardController *cardController = [self cardControllerAtIndex:indexPath.section];
        
        if ([cardController respondsToSelector:@selector(cardsController:scrollViewWillBeginDraggingForCell:)]) {
            [cardController cardsController:self scrollViewWillBeginDraggingForCell:visibleCell];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        //向可见卡片发送滚动结束事件
        [self sendScrollEndEventToVisibleCards];
        
        //发送曝光埋点
        [self exposeStatistics];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //向可见卡片发送滚动结束事件
    [self sendScrollEndEventToVisibleCards];
    
    //发送曝光埋点
    [self exposeStatistics];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    //向可见卡片发送滚动结束事件
    [self sendScrollEndEventToVisibleCards];
}



#pragma mark - Expose

- (void)exposeStatistics
{
    if (!self.enableExpose) return;
    
    NSArray *visibleCellArray = [self.tableView visibleCells];
    for (NSInteger i = 0; i < visibleCellArray.count; i ++) {
        UITableViewCell *cell = [visibleCellArray objectAtIndex:i];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        LLCardController *cardController = [self cardControllerAtIndex:indexPath.section];
        
        if ([self isCardSpacing:cardController atIndexPath:indexPath]) {//卡片间距,直接跳过
            continue;
        }
        
        if (!CGRectContainsRect([self exposeFrame], cell.frame)) {//没有完全展示,直接跳过
            continue;
        }
        
        //每个卡片单独发送曝光
        if ([self isCardHeader:cardController atIndexPath:indexPath]) {//头部视图
            if (!cardController.headerExposed) {//没有曝光过,曝光
                cardController.headerExposed = YES;
                if ([cardController respondsToSelector:@selector(cardsController:exposureForCardHeaderAtIndex:)]) {
                    NSArray *filterArr = [cardController cardsController:self exposureForCardHeaderAtIndex:indexPath.row];
                    
                    if (filterArr.count > 0 && [cardController respondsToSelector:@selector(cardsController:sendCardHeaderExposeWithData:)]) {
                        [cardController cardsController:self sendCardHeaderExposeWithData:filterArr];
                    }
                }
            }
        } else if ([self isCardFooter:cardController atIndexPath:indexPath]) {//尾部视图
            if (!cardController.footerExposed) {//没有曝光过,曝光
                cardController.footerExposed = YES;
                if ([cardController respondsToSelector:@selector(cardsController:exposureForCardFooterAtIndex:)]) {
                    NSArray *filterArr = [cardController cardsController:self exposureForCardFooterAtIndex:indexPath.row];
                    
                    if (filterArr.count > 0 && [cardController respondsToSelector:@selector(cardsController:sendCardFooterExposeWithData:)]) {
                        [cardController cardsController:self sendCardFooterExposeWithData:filterArr];
                    }
                }
            }
        } else {
            NSInteger rowIndex = cardController.showCardHeader ? indexPath.row - 1 : indexPath.row; //数据源对应的index
            if ([cardController respondsToSelector:@selector(cardsController:exposureForCardContentAtIndex:exposeFromPercent:toPercent:)]) {
                
                NSInteger fromPercent = 0; //顶部曝光百分比
                NSInteger toPercent = 0; //底部曝光百分比
                [self queryExposeRangeOfRect:cell.frame fromPercent:&fromPercent toPercent:&toPercent];
                
                ///获取可见cell里面未曝光的
                NSArray *filterArr = [self filterExposeArray:[cardController cardsController:self exposureForCardContentAtIndex:rowIndex exposeFromPercent:fromPercent toPercent:toPercent]];
                
                if (filterArr.count > 0 && [cardController respondsToSelector:@selector(cardsController:sendCardContentExposeWithData:)]) {
                    [cardController cardsController:self sendCardContentExposeWithData:filterArr];
                }
                
                [cardController.exposedArray addObjectsFromArray:filterArr];
            }
        }
        
    }
}

///获取数组里面未曝光过的数组
- (nullable NSArray *)filterExposeArray:(nullable NSArray<NSObject *> *)exposeArray {
    __block NSMutableArray <NSObject *> *exposeDataArray = [NSMutableArray array];
    
    [exposeArray enumerateObjectsUsingBlock:^(NSObject *  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (model && !model.ll_exposed) {
            model.ll_exposed = YES;
            [exposeDataArray addObject:model];
        }
    }];
    
    return [exposeDataArray copy];
}

- (void)resetExposeStatistics
{
    if (!self.enableExpose) return;
    for (NSInteger i = 0; i < _cardControllersArray.count; i++) {
        LLCardController *cardController = [_cardControllersArray objectAtIndex:i];
        [cardController.exposedArray enumerateObjectsUsingBlock:^(NSObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.ll_exposed = NO;
        }];
        [cardController.exposedArray removeAllObjects];
        cardController.headerExposed = NO;
        cardController.footerExposed = NO;
    }
}

- (CGRect)exposeFrame
{
    CGFloat bottomInset = self.tableView.contentInset.bottom;
    if (self.refreshType & LLCardsRefreshTypeInfiniteScrolling) { //已设置加载更多控件
        if (self.tableView.infiniteScrollingView) {
            bottomInset = CGRectGetHeight(self.tableView.infiniteScrollingView.frame);
        }
        
    }
    return CGRectMake(0, self.tableView.contentOffset.y + self.tableView.contentInset.top, self.tableView.frame.size.width, self.tableView.frame.size.height - self.tableView.contentInset.top - bottomInset);
}

//获取指定视图的曝光百分比
- (void)queryExposeRangeOfView:(UIView *)view fromPercent:(NSInteger *)fromPercent toPercent:(NSInteger *)toPercent
{
    CGRect rect = [view.superview convertRect:view.frame toView:_tableView];
    [self queryExposeRangeOfRect:rect fromPercent:fromPercent toPercent:toPercent];
}

//获取指定区块的曝光百分比
- (void)queryExposeRangeOfRect:(CGRect)rect fromPercent:(NSInteger *)fromPercent toPercent:(NSInteger *)toPercent
{
    CGRect visibleFrame = [self exposeFrame]; //列表当前可见范围
    NSInteger visibleTop = CGRectGetMinY(visibleFrame); //列表顶部偏移量
    NSInteger visibleBottom = CGRectGetMaxY(visibleFrame); //列表底部偏移量
    
    NSInteger percentTop = 0; //顶部曝光百分比
    NSInteger percentBottom = 0; //底部曝光百分比
    NSInteger rectHeight = CGRectGetHeight(rect); //区块高度
    NSInteger rectTop = CGRectGetMinY(rect); //区块顶部偏移量
    NSInteger rectBottom = CGRectGetMaxY(rect); //区块底部偏移量
    
    if (rectBottom > visibleTop && rectTop < visibleBottom && rectHeight > 0) {
        if (rectTop < visibleTop) { //区块顶部未完全露出
            percentTop = (NSInteger)((double)(visibleTop - rectTop) / rectHeight * 100);
        } else {
            percentTop = 0;
        }
        
        if (rectBottom > visibleBottom) { //区块底部未完全露出
            percentBottom = 100 - (NSInteger)((double)(rectBottom - visibleBottom) / rectHeight * 100);
        } else {
            percentBottom = 100;
        }
    }
    
    if (percentTop <= percentBottom) {
        *fromPercent = percentTop;
        *toPercent = percentBottom;
    }
}



#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(LLCardTableView *)tableView
{
    return _cardControllersArray.count;
}

- (CGFloat)tableView:(LLCardTableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    LLCardController *cardController = [self cardControllerAtIndex:section];
    
    CGFloat headerHeight = cardController.cardSuspendHeaderHeight;
    
    if ([cardController respondsToSelector:@selector(cardsController:heightForSuspendHeaderInTableView:)]) {
        headerHeight = [cardController cardsController:self heightForSuspendHeaderInTableView:tableView];
    }
    
    ///扩展支持永久悬停
    if (cardController.cardHasForeverSuspendHeader && [cardController respondsToSelector:@selector(cardsController:heightForForeverSuspendHeaderInTableView:)]) {
        headerHeight = [cardController cardsController:self heightForForeverSuspendHeaderInTableView:tableView];
        if ([cardController respondsToSelector:@selector(cardsController:viewForForeverSuspendHeaderInTableView:)]) {
            UIView *foreverView = [cardController cardsController:self viewForForeverSuspendHeaderInTableView:tableView];
            if (![[tableView.foreverSuspendHeader subviews] containsObject:foreverView]) {
                [tableView.foreverSuspendHeader addSubview:foreverView];
            }
            tableView.foreverSuspendHeader.frame = CGRectMake(0, 0, CGRectGetWidth(tableView.frame), headerHeight);
            if (![[tableView subviews] containsObject:tableView.foreverSuspendHeader]) {
                [tableView addSubview:tableView.foreverSuspendHeader];
            }
            else {
                [tableView bringSubviewToFront:tableView.foreverSuspendHeader];
            }
        }
    }
    return headerHeight;
}

- (UIView *)tableView:(LLCardTableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    LLCardController *cardController = [self cardControllerAtIndex:section];
    
    UIView *headerView = nil;
    if ([cardController respondsToSelector:@selector(cardsController:viewForSuspendHeaderInTableView:)]) {
        headerView = [cardController cardsController:self viewForSuspendHeaderInTableView:tableView];
    }
    return headerView;
}

- (NSInteger)tableView:(LLCardTableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    LLCardController *cardController = [self cardControllerAtIndex:section];
    return cardController.rowCountCache;
}

- (CGFloat)tableView:(LLCardTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LLCardController *cardController = [self cardControllerAtIndex:indexPath.section];
    return (indexPath.row < cardController.rowHeightsCache.count) ? ceil([cardController.rowHeightsCache[indexPath.row] floatValue]) : 0.0;
}

- (UITableViewCell *)tableView:(LLCardTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LLCardController *cardController = [self cardControllerAtIndex:indexPath.section];
    
    //布局参数
    BOOL isCardSpacing = [self isCardSpacing:cardController atIndexPath:indexPath]; //卡片间距
    BOOL isCardHeader = [self isCardHeader:cardController atIndexPath:indexPath]; //头部视图
    BOOL isCardFooter = [self isCardFooter:cardController atIndexPath:indexPath]; //尾部视图
    
    //复用参数
    Class class = nil;
    NSString *identifier = nil;
    if (isCardSpacing) { //卡片间距
        class = [UITableViewCell class];
        identifier = @"CardSpacingCell";
    } else if (isCardHeader) { //头部视图
        class = cardController.cardHeaderClass;
        if ([cardController respondsToSelector:@selector(cardsController:cellClassForCardHeaderInTableView:)]) {
            class = [cardController cardsController:self cellClassForCardHeaderInTableView:tableView];
        }
        if ([cardController respondsToSelector:@selector(cardsController:cellIdentifierForCardHeaderInTableView:)]) {
            identifier = [cardController cardsController:self cellIdentifierForCardHeaderInTableView:tableView];
        }
    } else if (isCardFooter) { //尾部视图
        if ([cardController respondsToSelector:@selector(cardsController:cellClassForCardFooterInTableView:)]) {
            class = [cardController cardsController:self cellClassForCardFooterInTableView:tableView];
        }
        if ([cardController respondsToSelector:@selector(cardsController:cellIdentifierForCardFooterInTableView:)]) {
            identifier = [cardController cardsController:self cellIdentifierForCardFooterInTableView:tableView];
        }
    } else {
        if (cardController.showCardError) { //错误卡片
            class = [LLCardErrorCell class];
            identifier = NSStringFromClass(class);
        } else { //数据源
            NSInteger rowIndex = cardController.showCardHeader ? indexPath.row - 1 : indexPath.row; //数据源对应的index
            class = cardController.cardContentClass;
            if ([cardController respondsToSelector:@selector(cardsController:cellClassForCardContentAtIndex:)]) {
                class = [cardController cardsController:self cellClassForCardContentAtIndex:rowIndex];
            }
            if ([cardController respondsToSelector:@selector(cardsController:cellIdentifierForCardContentAtIndex:)]) {
                identifier = [cardController cardsController:self cellIdentifierForCardContentAtIndex:rowIndex];
            }
        }
    }
    
    if (!class) {
        class = [UITableViewCell class];
    }
    if (!identifier.length) {
        identifier = [NSString stringWithFormat:@"%@_%ld", NSStringFromClass(class), (long)cardController.cardContext.type]; //同类卡片内部复用cell
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[class alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.clipsToBounds = YES;
        cell.exclusiveTouch = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.backgroundColor = self.cardTintColor;
        cell.contentView.backgroundColor = self.cardTintColor;
    }
    
    if (isCardSpacing) { //卡片间距
        UIColor *backgroundColor = self.cardTintColor;
        if ([cardController respondsToSelector:@selector(cardsController:colorForCardSpacingInTableView:)]) {
            backgroundColor = [cardController cardsController:self colorForCardSpacingInTableView:tableView];
        }
        cell.backgroundColor = backgroundColor;
        cell.contentView.backgroundColor = backgroundColor;
        if ([cardController respondsToSelector:@selector(cardsController:reuseCell:forCardSpaingInTableView:)]) {
            [cardController cardsController:self reuseCell:cell forCardSpaingInTableView:tableView];
        }
    } else if (isCardHeader) { //头部视图
        [cardController cardsController:self reuseCell:cell forCardHeaderInTableView:tableView];
    } else if (isCardFooter) { //尾部视图
        [cardController cardsController:self reuseCell:cell forCardFooterInTableView:tableView];
    } else { //数据源
        if (cardController.showCardError) { //错误卡片
            LLCardErrorCell *cardErrorCell = (LLCardErrorCell *)cell;
            cardErrorCell.cardController = cardController;
            [cardErrorCell refreshCardErrorView];
        } else {
            NSInteger rowIndex = cardController.showCardHeader ? indexPath.row - 1 : indexPath.row; //数据源对应的index
            [cardController cardsController:self reuseCell:cell forCardContentAtIndex:rowIndex];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    LLCardController *cardController = [self cardControllerAtIndex:indexPath.section];
    
    //布局参数
    BOOL isCardSpacing = [self isCardSpacing:cardController atIndexPath:indexPath]; //卡片间距
    BOOL isCardHeader = [self isCardHeader:cardController atIndexPath:indexPath]; //头部视图
    BOOL isCardFooter = [self isCardFooter:cardController atIndexPath:indexPath]; //尾部视图
    
    //卡片回调
    if (!isCardSpacing && !isCardHeader && !isCardFooter && !cardController.showCardError) { //数据源
        //卡片内容
        if ([cardController respondsToSelector:@selector(cardsController:willDisplayCell:forCardContentAtIndex:)]) {
            NSInteger rowIndex = cardController.showCardHeader ? indexPath.row - 1 : indexPath.row; //数据源对应的index
            [cardController cardsController:self willDisplayCell:cell forCardContentAtIndex:rowIndex];
        }
    } else if (isCardHeader) {
        if ([cardController respondsToSelector:@selector(cardsController:willDisplayingHeaderCell:)]) {
            [cardController cardsController:self willDisplayingHeaderCell:cell];
        }
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    LLCardController *cardController = [self cardControllerAtIndex:indexPath.section];
    
    //布局参数
    BOOL isCardSpacing = [self isCardSpacing:cardController atIndexPath:indexPath]; //卡片间距
    BOOL isCardHeader = [self isCardHeader:cardController atIndexPath:indexPath]; //头部视图
    BOOL isCardFooter = [self isCardFooter:cardController atIndexPath:indexPath]; //尾部视图
    
    //卡片回调
    if (!isCardSpacing && !isCardHeader && !isCardFooter && !cardController.showCardError) { //数据源
        //卡片内容
        if ([cardController respondsToSelector:@selector(cardsController:didEndDisplayingCell:forCardContentAtIndex:)]) {
            NSInteger rowIndex = cardController.showCardHeader ? indexPath.row - 1 : indexPath.row; //数据源对应的index
            [cardController cardsController:self didEndDisplayingCell:cell forCardContentAtIndex:rowIndex];
        }
    }else if (isCardHeader){
        
        if ([cardController respondsToSelector:@selector(cardsController:didEndDisplayingHeaderCell:)]) {
            [cardController cardsController:self didEndDisplayingHeaderCell:cell];
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.tintColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    view.tintColor = [UIColor clearColor];
}

- (void)tableView:(LLCardTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LLCardController *cardController = [self cardControllerAtIndex:indexPath.section];
    
    //布局参数
    BOOL isCardSpacing = [self isCardSpacing:cardController atIndexPath:indexPath]; //卡片间距
    BOOL isCardHeader = [self isCardHeader:cardController atIndexPath:indexPath]; //头部视图
    BOOL isCardFooter = [self isCardFooter:cardController atIndexPath:indexPath]; //尾部视图
    
    //点击事件
    if (isCardSpacing) { //卡片间距
        //无效点击
    } else if (isCardHeader) { //头部视图
        if ([cardController respondsToSelector:@selector(cardsController:didSelectCardHeaderInTableView:)]) {
            [cardController cardsController:self didSelectCardHeaderInTableView:tableView];
        }
    } else if (isCardFooter) { //尾部视图
        if ([cardController respondsToSelector:@selector(cardsController:didSelectCardFooterInTableView:)]) {
            [cardController cardsController:self didSelectCardFooterInTableView:tableView];
        }
    } else { //数据源
        if (cardController.showCardError) { //错误卡片
            //无效点击
        } else {
            //卡片内容
            if ([cardController respondsToSelector:@selector(cardsController:didSelectCardContentAtIndex:)]) {
                NSInteger rowIndex = cardController.showCardHeader ? indexPath.row - 1 : indexPath.row; //数据源对应的index
                [cardController cardsController:self didSelectCardContentAtIndex:rowIndex];
            }
        }
    }
}
@end

#pragma mark - Bottom

@implementation LLContainerCardsController (Bottom)

//设置封底开关
- (void)setEnableTableBottomView:(BOOL)enableTableBottomView
{
    if (_enableTableBottomView != enableTableBottomView) {
        _enableTableBottomView = enableTableBottomView;
        
        if (self.isViewLoaded) {
            [self refreshTableBottomView];
        }
    }
}

//设置封底自定义视图
- (void)setTableBottomCustomView:(UIView *)tableBottomCustomView
{
    if (_tableBottomCustomView != tableBottomCustomView) {
        _tableBottomCustomView = tableBottomCustomView;
        
        if (self.isViewLoaded) {
            [self refreshTableBottomView];
        }
    }
}

//触发加载更多事件，启动加载动画
- (void)triggerInfiniteScrollingAction
{
    if (_tableView.pullToRefreshView.state != SVPullToRefreshStateLoading) {
        [_tableView.infiniteScrollingView startAnimating];
    }
}

//完成加载更多事件，停止加载动画
- (void)finishInfiniteScrollingAction
{
    [_tableView.infiniteScrollingView stopAnimating];
}

///完成所有数据加载，设置
- (void)didFinishLoadAllData{
    self.enableTableBottomView = YES;
    LLCardsRefreshType refreshType = self.refreshType & (LLCardsRefreshTypePullToRefresh | LLCardsRefreshTypeLoadingView);
    self.refreshType = refreshType;
}

@end

@implementation LLContainerCardsController (BottomPrivate)

//刷新封底视图
- (void)refreshTableBottomView
{
    if (!_enableTableBottomView //禁用封底
        || !_cardControllersArray.count) { //无数据源
        
        if (_tableView.tableFooterView.tag == kTagTableBottomView) {
            _tableView.tableFooterView = nil;
        }
        return;
    }
    
    if (_refreshType & LLCardsRefreshTypeInfiniteScrolling) { //显示加载更多控件，移除封底
        _tableView.tableFooterView = nil;
    } else { //显示封底
        if (_tableBottomCustomView) { //自定义封底
            _tableView.tableFooterView = _tableBottomCustomView;
        } else { //默认封底
            if (![_tableView.tableFooterView isKindOfClass:[LLCardTableFooterView class]]) {
                _tableView.tableFooterView = [[LLCardTableFooterView alloc] init];
            }
        }
        _tableView.tableFooterView.tag = kTagTableBottomView;
    }
}


@end
