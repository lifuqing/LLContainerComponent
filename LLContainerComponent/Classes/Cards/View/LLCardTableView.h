//
//  LLCardTableView.h
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class LLContainerCardsController, LLCardController;

@interface LLCardTableView : UITableView

@property (nonatomic, weak) NSArray<LLCardController *> *cardControllersArray;

@property (nonatomic, weak) LLContainerCardsController *cardsController;


///更新指定section缓存并刷新
- (void)reloadSection:(NSInteger)section;

///更新指定section组缓存并刷新
- (void)reloadSections:(NSIndexSet *)sections;

#pragma mark - 永久悬停功能

@property (nonatomic, strong) UIView *foreverSuspendHeader;

@end

NS_ASSUME_NONNULL_END
