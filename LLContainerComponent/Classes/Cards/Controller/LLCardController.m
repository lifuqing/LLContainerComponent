//
//  LLCardController.m
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/5.
//

#import "LLCardController.h"
#import "LLContainerCardsController.h"

@interface LLCardController ()
/* DataSource */
///内容类
@property (nonatomic, assign) Class     cardContentClass;
///悬停header高度，默认0.0
@property (nonatomic, assign) CGFloat   cardSuspendHeaderHeight;
///卡片头行高
@property (nonatomic, assign) CGFloat   cardHeaderHeight;
///卡片底部间距高度，默认10,当大于0的时候显示间距
@property (nonatomic, assign) CGFloat   cardSpacingHeight;
///卡片头类
@property (nonatomic, assign) Class     cardHeaderClass;
///是否显示卡片头，默认NO
@property (nonatomic, assign) BOOL      cardShowHeader;
///是否显示卡片底部，默认NO
@property (nonatomic, assign) BOOL      cardShowFooter;
///是否显示错误卡片，默认NO
@property (nonatomic, assign) BOOL      cardShowErrorCard;
///扩展是否有永久性悬停header
@property (nonatomic, assign) BOOL      cardHasForeverSuspendHeader;

/* Cache */
@property (nonatomic, assign) BOOL        showCardError;
@property (nonatomic, assign) BOOL        showCardHeader;
@property (nonatomic, assign) BOOL        showCardFooter;
@property (nonatomic, assign) BOOL        showCardSpacing;
@property (nonatomic, assign) NSInteger   rowCountCache;
@property (nonatomic, strong) NSArray     *rowHeightsCache;

/* RequestMore */
@property (nonatomic, assign) BOOL        canRequestMoreData;

/* Expose */
@property (nonatomic, strong) NSMutableArray<NSObject *> *exposedArray;
@property (nonatomic, assign) BOOL        headerExposed;
@property (nonatomic, assign) BOOL        footerExposed;


@end


@implementation LLCardController

- (void)dealloc
{
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _exposedArray = [NSMutableArray array];
        _cardSuspendHeaderHeight = 0.0;
        _cardHeaderHeight = 0.0;
        _cardSpacingHeight = 10.0;
        _cardShowHeader = NO;
        _cardShowErrorCard = NO;
    }
    return self;
}

- (void)refreshCard {
    if ([_delegate respondsToSelector:@selector(refreshCardWithType:)]) {
        [_delegate refreshCardWithType:_cardContext.type];
    }
}

#pragma mark - Property

- (void)setCardContext:(LLCardContext *)cardContext
{
    _cardContext = cardContext;
}

- (void)setIsPrepared:(BOOL)isPrepared
{
    if (_isPrepared != isPrepared) {
        _isPrepared = isPrepared;
        
        [self refreshCard];
    }
}

- (void)setIsNoData:(BOOL)isNoData {
    //仅当请求成功cardContext无error的时候才可以设置成功
    if (!self.cardContext.error) {
        _isNoData = isNoData;
    }
}
#pragma mark - LLContainerCardsControllerDelegate

#pragma mark Card Content

//内容行数
- (NSInteger)cardsController:(LLContainerCardsController *)cardsController rowCountForCardContentInTableView:(LLCardTableView *)tableView
{
    return 0;
}

//内容行高
- (CGFloat)cardsController:(LLContainerCardsController *)cardsController rowHeightForCardContentAtIndex:(NSInteger)index
{
    return 0.0;
}

//复用内容视图
- (void)cardsController:(LLContainerCardsController *)cardsController reuseCell:(UITableViewCell *)cell forCardContentAtIndex:(NSInteger)index
{
    
}

#pragma mark - Error

//请求错误卡片数据
- (void)requestErrorCardData
{
    ELLCardErrorCode errorCode = _cardContext.error.code;
    if (errorCode == ELLCardErrorCodeNetwork || errorCode == ELLCardErrorCodeFailed) { //卡片请求失败
        //显示加载状态
        _cardContext.state = ELLCardStateLoading;
        [self refreshCard];
        
        //重新请求数据
        [self.cardsController requestCardDataWithController:self];
    }
}

@end
