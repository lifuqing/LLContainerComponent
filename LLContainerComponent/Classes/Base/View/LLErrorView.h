//
//  LLErrorView.h
//  LLContainerComponent
//
//  Created by lifuqing on 2019/4/5.
//  Copyright © 2019 lifuqing. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    LLErrorTypeFailed,
    LLErrorTypeNoNetwork,
    LLErrorTypeNoData,
} LLErrorType;

@interface LLErrorView : UIView

+ (void)showErrorViewInView:(nullable UIView *)view withErrorType:(LLErrorType)errorType withClickBlock:(dispatch_block_t)clickBlock;
+ (void)hideErrorViewInView:(nullable UIView *)view;
+ (BOOL)errorViewIsShowInView:(nullable UIView *)view;
@end

NS_ASSUME_NONNULL_END
