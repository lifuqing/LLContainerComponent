//
//  LLCardTableFooterView.m
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/7.
//

#import "LLCardTableFooterView.h"

@interface LLCardTableFooterView ()
@property (nonatomic, strong) UILabel *label;
@end

@implementation LLCardTableFooterView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.backgroundColor = [UIColor clearColor];
        _label.font = [UIFont systemFontOfSize:12];
        _label.textColor = [UIColor grayColor];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.text = @"没有更多了";
        [self addSubview:_label];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = CGRectMake(0, (self.frame.size.height - 17)/2.0, self.frame.size.width, 17);
}

@end
