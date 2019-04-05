//
//  LLCardErrorCell.h
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class LLCardController;

@interface LLCardErrorCell : UITableViewCell
@property (nonatomic, weak) LLCardController *cardController;
///刷新错误视图
- (void)refreshCardErrorView;
@end

NS_ASSUME_NONNULL_END
