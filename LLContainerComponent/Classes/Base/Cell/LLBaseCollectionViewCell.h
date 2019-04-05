//
//  LLBaseCollectionViewCell.h
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLBaseCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) id model;

///子类重写
+ (CGFloat)cellHeightWithModel:(nullable id)model;
@end

NS_ASSUME_NONNULL_END
