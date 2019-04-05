//
//  LLCardHeaderTableViewCell.m
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/18.
//

#import "LLCardHeaderTableViewCell.h"

@interface LLCardHeaderTableViewCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *descButton;
@property (nonatomic, strong) UIImageView *arrow;

@end

@implementation LLCardHeaderTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.arrow = [[UIImageView alloc] initWithImage:nil];
        
        self.line = [[UIView alloc] initWithFrame:CGRectZero];
        self.line.backgroundColor = [UIColor lightGrayColor];
        
        [self addSubview:self.titleLabel];
        [self addSubview:self.descButton];
        [self addSubview:self.arrow];
        [self addSubview:self.line];
    }
    return self;
}

- (void)dealloc {
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat leftPadding = 20, rightPadding = 15, titleH = [self.titleLabel.text sizeWithAttributes:@{NSFontAttributeName : self.titleLabel.font}].height;
    CGFloat arrowW = (self.headerContext.hasMoreExtend ? 15 : 0);
    
    CGFloat titleLeft = leftPadding;
    
    self.titleLabel.frame = CGRectMake(titleLeft, (CGRectGetHeight(self.bounds) - titleH)/2.0, CGRectGetWidth(self.bounds)/2.0, titleH);
    self.arrow.frame = CGRectMake(CGRectGetWidth(self.bounds) - rightPadding - arrowW, (CGRectGetHeight(self.bounds) - arrowW)/2.0, arrowW, arrowW);
    CGFloat descW = [self.headerContext.desc sizeWithAttributes:@{NSFontAttributeName : self.descButton.titleLabel.font}].width;
    self.descButton.frame = CGRectMake(self.arrow.frame.origin.x - descW, self.titleLabel.frame.origin.y, descW, self.titleLabel.bounds.size.height);
    self.line.frame = CGRectMake(20, self.bounds.size.height - 0.5, self.bounds.size.width - 20, 0.5);
}

#pragma mark - public

#pragma mark - private

#pragma mark - action

- (void)descButtonActionClick:(UIButton *)sender {
    if (self.descClickBlock) {
        self.descClickBlock(sender, self);
    }
}
#pragma mark - setter

- (void)setHeaderContext:(LLCardHeaderContext *)headerContext {
    _headerContext = headerContext;
    self.titleLabel.text = headerContext.title;
    
    self.arrow.hidden = !self.headerContext.hasMoreExtend;
    
    if (headerContext.desc) {
        [self.descButton setTitle:headerContext.desc forState:UIControlStateNormal];
    }
    
    [self setNeedsLayout];
}

- (void)setDescClickBlock:(LLCardHeaderDescClickBlock)descClickBlock {
    _descClickBlock = descClickBlock;
    self.descButton.enabled = !!descClickBlock;
}

#pragma mark - lazyloading

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

- (UIButton *)descButton {
    if (!_descButton) {
        _descButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _descButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_descButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [_descButton addTarget:self action:@selector(descButtonActionClick:) forControlEvents:UIControlEventTouchUpInside];
        _descButton.adjustsImageWhenDisabled = NO;
        _descButton.enabled = NO;
        
    }
    return _descButton;
}
@end
