//
//  LLCardErrorCell.m
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/7.
//

#import "LLCardErrorCell.h"
#import "LLCardController.h"
#import "LLLoadingView.h"

#pragma mark - loading view

@interface LLCardLoadingView : UIView

///旋转动画的图片。若未设置，默认加载通用loading动画。
@property (nonatomic, strong) UIImage *loadingImage;
///开始动画
- (void)startAnimating;
///停止动画
- (void)stopAnimating;
@end

@interface LLCardLoadingView ()
@property (nonatomic, strong) UIView *loading;

@end

@implementation LLCardLoadingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //
    }
    return self;
}

///开始动画
- (void)startAnimating{
    if (self.loadingImage) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:self.loadingImage];
        _loading = imageView;
    }
    else {
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleGray)];
        [view startAnimating];
        _loading = view;
    }
    [self addSubview:_loading];
    _loading.center = self.center;
    _loading.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}
///停止动画
- (void)stopAnimating{
    [_loading removeFromSuperview];
}


@end

#pragma mark - error view

@interface LLCardErrorView : UIView
//public
@property (nonatomic, strong) NSMutableAttributedString *errorMessage;
@property (nonatomic, copy) dispatch_block_t clickBlock;
//private
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation LLCardErrorView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:self.titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.frame = CGRectMake(0, (CGRectGetHeight(self.frame) - 16)/2.0, CGRectGetWidth(self.frame), 16);
    
}
- (void)setErrorMessage:(NSMutableAttributedString *)errorMessage {
    self.titleLabel.attributedText = errorMessage;
}

@end

@interface LLCardErrorCell()
@property (nonatomic, strong) LLCardLoadingView *loadingView;
@property (nonatomic, strong) LLCardErrorView *errorView;
@end

@implementation LLCardErrorCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)refreshCardErrorView
{
    ELLCardState state = _cardController.cardContext.state;
    if (state == ELLCardStateError) { //错误状态
        NSMutableAttributedString *errorMessage = nil;
        
        if ([_cardController respondsToSelector:@selector(cardsController:errorBackgroundColorWithCode:)]) {
            self.backgroundColor =[_cardController cardsController:_cardController.cardsController errorBackgroundColorWithCode:_cardController.cardContext.error.code];
        }
        
        //获取自定义错误描述
        if ([_cardController respondsToSelector:@selector(cardsController:errorDescriptionWithCode:)]) {
            NSAttributedString *errorDescription = [_cardController cardsController:_cardController.cardsController errorDescriptionWithCode:_cardController.cardContext.error.code];
            if ([errorDescription isKindOfClass:[NSMutableAttributedString class]]) {
                errorMessage = (NSMutableAttributedString *)errorDescription;
            } else if ([errorDescription isKindOfClass:[NSAttributedString class]]) {
                errorMessage = [[NSMutableAttributedString alloc] initWithAttributedString:errorDescription];
            }
        }
        
        //默认错误描述
        if (!errorMessage) {
            errorMessage = [[NSMutableAttributedString alloc] initWithString:@"获取失败，点击重试"];
            [errorMessage addAttribute:NSForegroundColorAttributeName
                                 value:[UIColor clearColor]
                                 range:NSMakeRange(7, 2)];
        }
        
        //字体
        [errorMessage addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:14.0]
                             range:NSMakeRange(0, errorMessage.length)];
        
        [self showErrorAttributedMessage:errorMessage
                        target:_cardController
                      selector:@selector(requestErrorCardData)];
    } else {
        [self hideErrorView];
    }
    
    if (state == ELLCardStateLoading) { //加载状态
        if (![[self.contentView subviews] containsObject:_loadingView]) {
            [self.contentView addSubview:self.loadingView];
        }
        
        [_loadingView startAnimating];
        [_loadingView setNeedsLayout]; //复用时可能会停止旋转动画，此处强制刷新
    } else {
        [_loadingView stopAnimating];
        [_loadingView removeFromSuperview];
    }
}

- (void)hideErrorView {
    [self.errorView removeFromSuperview];
}

- (void)showErrorAttributedMessage:(NSMutableAttributedString *)message target:(id)target selector:(SEL)selector {
    if (![[self.contentView subviews] containsObject:_errorView]) {
        [self.contentView addSubview:self.errorView];
    }
    self.errorView.errorMessage = message;
    
    if ([target respondsToSelector:selector] && self.cardController.cardContext.error.code != ELLCardErrorCodeNoData) {
        self.errorView.clickBlock = ^{
            IMP imp = [target methodForSelector:selector];
            void (*func)(id, SEL) = (void *)imp;
            func(target, selector);
        };
    }
    else {
        self.errorView.clickBlock = nil;
    }
}

- (LLCardLoadingView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[LLCardLoadingView alloc] initWithFrame:self.bounds]; //给定足够大的尺寸
        _loadingView.center = self.contentView.center;
        _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _loadingView;
}

- (LLCardErrorView *)errorView {
    if (!_errorView) {
        _errorView =[[LLCardErrorView alloc] initWithFrame:self.bounds];
        _errorView.center = self.contentView.center;
        _errorView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    return _errorView;
}
@end
