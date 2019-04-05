//
//  LLCardTableView.m
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/7.
//

#import "LLCardTableView.h"
#import <WebKit/WebKit.h>
#import "LLCardController.h"
#import "LLContainerCardsController.h"

#define HEIGHT_ERROR        100.0   //错误提示高度

@interface LLCardTableView () <UIGestureRecognizerDelegate>
@property (nonatomic, assign) CGFloat foreverOriginY;
@end

@implementation LLCardTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.backgroundView = nil;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.canCancelContentTouches = YES;
        [self setDelaysContentTouches:NO];
        
        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))];
    
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))] && _foreverSuspendHeader) {
        CGFloat y = self.foreverOriginY > self.contentOffset.y ? self.foreverOriginY : self.contentOffset.y;
        self.foreverSuspendHeader.frame = CGRectMake(CGRectGetMinX(self.foreverSuspendHeader.frame), y, CGRectGetWidth(self.foreverSuspendHeader.frame), CGRectGetHeight(self.foreverSuspendHeader.frame));

        [self bringSubviewToFront:self.foreverSuspendHeader];
        [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UITableViewHeaderFooterView class]] && !obj.isHidden) {
                [self insertSubview:self.foreverSuspendHeader aboveSubview:obj];
            }
        }];
        
    }
}

//解决详情页互动卡片不能上下滑动问题,卡片结构中所有的webView都不会覆盖原有滑动手势
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return ([otherGestureRecognizer.view isKindOfClass:[UIWebView class]]
            || [otherGestureRecognizer.view.superview isKindOfClass:[UIWebView class]]
            || [otherGestureRecognizer.view.superview.superview isKindOfClass:[UIWebView class]]
            || [otherGestureRecognizer.view isKindOfClass:[WKWebView class]]
            || [otherGestureRecognizer.view.superview isKindOfClass:[WKWebView class]]
            || [otherGestureRecognizer.view.superview.superview isKindOfClass:[WKWebView class]]);
}

#pragma mark - Reload

- (void)reloadData
{
    for (int i = 0; i < _cardControllersArray.count; i++) {
        [self setupCacheDataWithSection:i];
    }
    
    [super reloadData];
    
    [self layoutForeverSuspendHeader];
    
    [self sendExposeStatistics];
}

- (void)reloadSections:(NSIndexSet *)sections
{
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [self setupCacheDataWithSection:idx];
    }];
    
    [super reloadData];
    [self layoutForeverSuspendHeader];
    [self sendExposeStatistics];
}

- (void)reloadSection:(NSInteger)section
{
    [self setupCacheDataWithSection:section];
    
    [super reloadData];
    [self layoutForeverSuspendHeader];
    [self sendExposeStatistics];
}

#pragma mark - 重写

- (void)reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self setupCacheDataWithSection:idx];
    }];
    
    [super reloadSections:sections withRowAnimation:animation];
    [self layoutForeverSuspendHeader];
}

- (void)insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    NSMutableIndexSet *sections = [NSMutableIndexSet indexSet];
    for (NSIndexPath *indexPath in indexPaths) {
        [sections addIndex:indexPath.section];
    }
    
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self setupCacheDataWithSection:idx];
    }];
    
    [super insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self layoutForeverSuspendHeader];
}

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self setupCacheDataWithSection:idx];
    }];
    
    [super insertSections:sections withRowAnimation:animation];
    [self layoutForeverSuspendHeader];
}

- (NSArray<NSIndexPath *> *)indexPathsForVisibleRows {
    if (_foreverSuspendHeader) {
        NSArray<NSIndexPath *> *indexPaths = [super indexPathsForVisibleRows];
        
        NSMutableArray <NSIndexPath *> *realArray = [NSMutableArray arrayWithArray:indexPaths];
        //找到第一个section 里面对应的所有row
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray<NSIndexPath *> *indexPathsForSection = [self visibleRowsInVisibleSection:obj.section fromIndexPaths:indexPaths];
            //遍历section里面的row来计算当row visible但是被悬停header完全覆盖的也算是消失了
            [indexPathsForSection enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                //偏移悬停header的高度来计算相对位置
                CGRect cellRect = [self rectForRowAtIndexPath:obj];
                CGRect cellRealRect = [self convertRect:CGRectOffset(cellRect, 0, -CGRectGetHeight(self.foreverSuspendHeader.frame)) toView:self.foreverSuspendHeader];
                //悬停header下面的cell才进行计算
                if (cellRect.origin.y >= self.foreverOriginY &&
                    cellRealRect.origin.y + cellRealRect.size.height <= 0) {
                    [realArray removeObject:obj];
                }
            }];
            *stop = YES;
        }];
        
        return [realArray copy];
    }
    else {
        return [super indexPathsForVisibleRows];
    }
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated {
    if (_foreverSuspendHeader && scrollPosition == UITableViewScrollPositionTop) {
        CGRect originRect = [self rectForRowAtIndexPath:indexPath];
        [self setContentOffset:CGPointMake(originRect.origin.x, MIN(originRect.origin.y - CGRectGetHeight(self.foreverSuspendHeader.frame), self.contentSize.height - self.bounds.size.height)) animated:animated];
    }
    else {
        [super scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
    }
}
#pragma mark - Cache

//重置指定section的缓存数据
- (void)setupCacheDataWithSection:(NSInteger)section
{
    if (section < 0 || section >= _cardControllersArray.count) return;
    
    LLContainerCardsController *cardsController = (LLContainerCardsController *)self.delegate;
    LLCardController *cardController = _cardControllersArray[section];
    
    //是否显示错误视图
    cardController.showCardError = NO;
    if (cardController.cardContext.error) { //数据错误
        cardController.showCardError = cardController.cardShowErrorCard;
        if ([cardController respondsToSelector:@selector(cardsController:shouldShowCardErrorWithCode:)]) {
            cardController.showCardError = [cardController cardsController:cardsController shouldShowCardErrorWithCode:cardController.cardContext.error.code];
        }
    }
    
    //是否显示头部视图
    cardController.showCardHeader = cardController.cardShowHeader;
    
    if ([cardController respondsToSelector:@selector(cardsController:shouldShowCardHeaderInTableView:)]) {
        cardController.showCardHeader = [cardController cardsController:cardsController shouldShowCardHeaderInTableView:self];
    }
//    if (cardController.showCardError) { //显示错误视图时隐藏头部视图,暂时改为显示错误视图不隐藏
//        cardController.showCardHeader = NO;
//    }
    
    //是否显示尾部视图
    cardController.showCardFooter = cardController.cardShowFooter;
    
    if ([cardController respondsToSelector:@selector(cardsController:shouldShowCardFooterInTableView:)]) {
        cardController.showCardFooter = [cardController cardsController:cardsController shouldShowCardFooterInTableView:self];
    }
//    if (cardController.showCardError) { //显示错误视图时隐藏尾部视图,暂时改为显示错误视图不隐藏
//        cardController.showCardFooter = NO;
//    }
    
    //是否显示卡片间距
    CGFloat cardSpacing = cardController.cardSpacingHeight;
    if ([cardController respondsToSelector:@selector(cardsController:heightForCardSpacingInTableView:)]) {
        cardSpacing = [cardController cardsController:cardsController heightForCardSpacingInTableView:self];
        if (cardSpacing <= 0.1) {
            cardSpacing = 0.0;
        }
    }
    if (cardSpacing > 0.0) {
        cardController.showCardSpacing = YES;
    }
    
    //行数缓存
    NSInteger rowCount = 0;
    if (cardController.cardContext.error) { //数据错误
        if (cardController.showCardError) rowCount++; //显示错误视图
    } else { //数据正常
        //内容行数
        NSInteger count = [cardController cardsController:cardsController rowCountForCardContentInTableView:self];
        if (count > 0) {
            rowCount += count;
        }
    }
    
    if (rowCount > 0) { //有可显示的数据
        if (cardController.showCardHeader)  rowCount++; //显示头部视图
        if (cardController.showCardFooter)  rowCount++; //显示尾部视图
        if (cardController.showCardSpacing) rowCount++; //显示卡片间距
    }
    else {
        BOOL alwaysShow = NO;
        if ([cardController respondsToSelector:@selector(cardsController:alwaysShouldShowCardHeaderInTableView:)]) {
            alwaysShow = [cardController cardsController:cardsController alwaysShouldShowCardHeaderInTableView:self];
        }
        if (alwaysShow) {
            if (cardController.showCardHeader)  rowCount++; //显示头部视图
            if (cardController.showCardSpacing) rowCount++; //显示卡片间距
        }
    }
    cardController.rowCountCache = rowCount;
    
    //行高缓存
    NSMutableArray *rowHeights = [NSMutableArray array];
    for (int row = 0; row < rowCount; row++) {
        CGFloat rowHeight = 0.0;
        
        BOOL isCardSpacing = (cardController.showCardSpacing && row == rowCount - 1); //卡片间距
        BOOL isCardHeader = (cardController.showCardHeader && row == 0); //头部视图
        BOOL isCardFooter = NO; //尾部视图
        if (cardController.showCardFooter) {
            if (cardController.showCardSpacing && row == rowCount - 2) {
                isCardFooter = YES;
            }
            if (!cardController.showCardSpacing && row == rowCount - 1) {
                isCardFooter = YES;
            }
        }
        
        if (isCardSpacing) { //卡片间距
            rowHeight = cardSpacing;
        } else if (isCardHeader) { //头部视图
            rowHeight = cardController.cardHeaderHeight;
            if ([cardController respondsToSelector:@selector(cardsController:heightForCardHeaderInTableView:)]) {
                rowHeight = [cardController cardsController:cardsController heightForCardHeaderInTableView:self];
            }
        } else if (isCardFooter) { //尾部视图
            if ([cardController respondsToSelector:@selector(cardsController:heightForCardFooterInTableView:)]) {
                rowHeight = [cardController cardsController:cardsController heightForCardFooterInTableView:self];
            }
        } else {
            if (cardController.showCardError) { //错误视图
                rowHeight = HEIGHT_ERROR;
            } else { //数据源
                NSInteger rowIndex = cardController.showCardHeader ? row - 1 : row; //数据源对应的index
                rowHeight = [cardController cardsController:cardsController rowHeightForCardContentAtIndex:rowIndex];
            }
        }
        [rowHeights addObject:@(rowHeight)];
    }
    cardController.rowHeightsCache = rowHeights;
}

#pragma mark - Expose

- (void)sendExposeStatistics
{
    if (!(self.dragging || self.tracking)) {//停止滚动,刷新了数据,发送曝光
        if (self.cardsController && [self.cardsController isKindOfClass:[LLContainerCardsController class]]) {
            LLContainerCardsController *cardsController = (LLContainerCardsController *)self.cardsController;
            [cardsController exposeStatistics];
        }
    }
}

#pragma mark - private method - 永久悬停

- (UIView *)foreverSuspendHeader {
    if (!_foreverSuspendHeader) {
        _foreverSuspendHeader = [[UIView alloc] initWithFrame:CGRectZero];
    }
    return _foreverSuspendHeader;
}


- (void)layoutForeverSuspendHeader {
    [self.cardsController.cardControllersArray enumerateObjectsUsingBlock:^(LLCardController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.cardHasForeverSuspendHeader) {
            CGFloat originY = [self rectForHeaderInSection:idx].origin.y;
            self.foreverOriginY = originY;
            CGFloat y = self.foreverOriginY > self.contentOffset.y ? self.foreverOriginY : self.contentOffset.y;
            self.foreverSuspendHeader.frame = CGRectMake(CGRectGetMinX(self.foreverSuspendHeader.frame), y, CGRectGetWidth(self.foreverSuspendHeader.frame), CGRectGetHeight(self.foreverSuspendHeader.frame));
            *stop = YES;
        }
    }];
    
}

/// 可见的section里面可见的rows
- (NSArray<NSIndexPath *> *)visibleRowsInVisibleSection:(NSUInteger)section fromIndexPaths:(NSArray<NSIndexPath *> *)indexPaths{
    NSMutableArray *rows = [NSMutableArray array];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (section == obj.section) {
            [rows addObject:obj];
        }
    }];
    return rows;
}

@end
