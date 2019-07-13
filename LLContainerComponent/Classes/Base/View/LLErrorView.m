//
//  LLErrorView.m
//  LLContainerComponent
//
//  Created by lifuqing on 2019/4/5.
//  Copyright © 2019 lifuqing. All rights reserved.
//

#import "LLErrorView.h"
@interface LLErrorView ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, copy) dispatch_block_t tapBlock;
@end

@implementation LLErrorView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textColor = [UIColor grayColor];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        [self addSubview:_titleLabel];
        [self addSubview:_iconView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapActionClick:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

#pragma mark - public

+ (void)showErrorViewInView:(nullable UIView *)view withErrorType:(LLErrorType)errorType withClickBlock:(dispatch_block_t)clickBlock {
    UIView *destView = [UIApplication sharedApplication].keyWindow;
    if (view) {
        destView = view;
    }
    [self hideErrorViewInView:destView];
    LLErrorView *errorView = [[LLErrorView alloc] initWithFrame:destView.bounds];
    errorView.center = CGPointMake(destView.bounds.size.width/2.0, destView.bounds.size.height/2.0);
    errorView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [destView addSubview:errorView];
    
    [errorView configErrorInfoWithType:errorType];
    errorView.tapBlock = clickBlock;
    
}

+ (void)hideErrorViewInView:(nullable UIView *)view {
    [view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[LLErrorView class]]) {
            [obj removeFromSuperview];
        }
    }];
}

+ (BOOL)errorViewIsShowInView:(nullable UIView *)view {
    __block LLErrorView *errorView = nil;
    [view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[LLErrorView class]]) {
            errorView = obj;
            *stop = YES;
        }
    }];
    return errorView && !errorView.isHidden;
}

#pragma mark - private

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), 20);
    self.titleLabel.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
}

- (void)configErrorInfoWithType:(LLErrorType)errorType {
    NSString *errorStr = @"";
    if (errorType == LLErrorTypeFailed) {
        errorStr = @"数据加载失败、点击重试";
    }
    else if (errorType == LLErrorTypeNoNetwork) {
        errorStr = @"数据加载失败、点击重试";
    }
    else if (errorType == LLErrorTypeNoData) {
        errorStr = @"暂无数据";
    }
    else {
        errorStr = @"数据加载失败、点击重试";
    }
    self.titleLabel.text = errorStr;
    [self setNeedsLayout];
}

#pragma mark - action
- (void)tapActionClick:(UITapGestureRecognizer *)tap {
    if (self.tapBlock) {
        self.tapBlock();
    }
}
@end
