//
//  LLBaseTableViewCell.m
//  LLContainerComponent
//
//  Created by lifuqing on 2018/12/29.
//

#import "LLBaseTableViewCell.h"

@interface LLBaseTableViewCell()
@end

@implementation LLBaseTableViewCell

+ (CGFloat)cellHeightWithModel:(nullable id)model {
    return 0;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];//默认无背景
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setModel:(id)model {
    _model = model;
}
@end

