//
//  NSObject+LLTools.h
//  LLContainerComponent
//
//  Created by lifuqing on 2019/4/5.
//  Copyright © 2019 lifuqing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (LLTools)

@end

@interface NSObject (LLExposeModel)
///是否曝光
@property (nonatomic, assign) BOOL ll_exposed;

@end

NS_ASSUME_NONNULL_END
