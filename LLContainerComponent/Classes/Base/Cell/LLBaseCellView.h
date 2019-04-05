//
//  LLBaseCellView.h
//  LLContainerComponent
//
//  Created by lifuqing on 2018/12/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLBaseCellView : UIView

@property (nonatomic, strong) id model;

///子类重写
+ (CGFloat)cellHeightWithModel:(nullable id)model;

@end

NS_ASSUME_NONNULL_END
