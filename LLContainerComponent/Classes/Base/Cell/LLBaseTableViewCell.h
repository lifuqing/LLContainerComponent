//
//  LLBaseTableViewCell.h
//  LLContainerComponent
//
//  Created by lifuqing on 2018/12/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLBaseTableViewCell : UITableViewCell

@property (nonatomic, strong) id model;

///子类重写
+ (CGFloat)cellHeightWithModel:(nullable id)model;

@end

NS_ASSUME_NONNULL_END
