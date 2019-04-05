//
//  LLCardHeaderTableViewCell.h
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/18.
//

#import <UIKit/UIKit.h>
#import "LLCardContext.h"

NS_ASSUME_NONNULL_BEGIN
@class LLCardHeaderTableViewCell;

typedef void(^LLCardHeaderDescClickBlock)(UIButton *button, LLCardHeaderTableViewCell *cell);

@interface LLCardHeaderTableViewCell : UITableViewCell

@property (nonatomic, strong) LLCardHeaderContext *headerContext;
///点击右侧描述按钮
@property (nonatomic, copy) LLCardHeaderDescClickBlock descClickBlock;

///线
@property (nonatomic, strong) UIView *line;
@end

NS_ASSUME_NONNULL_END
