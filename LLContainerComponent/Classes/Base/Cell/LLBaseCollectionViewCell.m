//
//  LLBaseCollectionViewCell.m
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/8.
//

#import "LLBaseCollectionViewCell.h"

@implementation LLBaseCollectionViewCell

+ (CGFloat)cellHeightWithModel:(nullable id)model {
    return 0;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];//默认无背景
    }
    return self;
}

- (void)setModel:(id)model {
    _model = model;
}
@end
