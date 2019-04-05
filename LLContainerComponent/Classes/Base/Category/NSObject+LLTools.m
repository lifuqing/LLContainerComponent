//
//  NSObject+LLTools.m
//  LLContainerComponent
//
//  Created by lifuqing on 2019/4/5.
//  Copyright © 2019 lifuqing. All rights reserved.
//

#import "NSObject+LLTools.h"
#import <objc/runtime.h>

@implementation NSObject (LLTools)

@end

@implementation NSObject (LLExposeModel)

@dynamic ll_exposed;

- (BOOL)ll_exposed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setLl_exposed:(BOOL)ll_exposed
{
    objc_setAssociatedObject(self, @selector(ll_exposed), @(ll_exposed), OBJC_ASSOCIATION_ASSIGN);
}

@end
