//
//  LLLoadingView.h
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface LLLoadingView : UIView

///旋转动画的图片。若未设置，默认加载通用loading动画。
@property (nonatomic, strong) UIImage *loadingImage;
///开始动画
- (void)startAnimating;
///停止动画
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
