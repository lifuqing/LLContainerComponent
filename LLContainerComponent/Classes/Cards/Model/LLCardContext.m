//
//  LLCardContext.m
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/5.
//

#import "LLCardContext.h"

@implementation LLCardHeaderContext
@end

@implementation LLCardFooterContext
@end
@interface LLCardContext ()
///卡片控制器Class 继承自LLCardController的
@property (nonatomic, copy, readwrite) NSString *clazz;
@end
@implementation LLCardContext

+ (instancetype)cardContextWithCardType:(NSInteger)cardType headerTitle:(nullable NSString *)headerTitle headerDesc:(nullable NSString *)headerDesc contextModel:(nullable id)model {
    LLCardContext *cardContext = [[[self class] alloc] init];
    cardContext.type = cardType;
    cardContext.model = model;
    
    LLCardHeaderContext *headerContext = [[LLCardHeaderContext alloc] init];
    headerContext.title = headerTitle;
    headerContext.desc = headerDesc;
    
    cardContext.headerContext = headerContext;
    return cardContext;
}

#pragma mark - Property

- (void)setType:(ELLCardType)type
{
    if (_type != type) {
        _type = type;
        
        self.clazz = [self parseClassName:type];
    }
}

- (void)setModel:(id)model
{
    if (_model != model) {
        _model = model;
        self.error = nil;
    }
}

- (void)setError:(nullable NSError *)error
{
    if (_error != error) {
        _error = error;
        
        _state = error ? ELLCardStateError : ELLCardStateNormal;
    }
}

- (void)setHeaderContext:(LLCardHeaderContext *)headerContext {
    if (_headerContext != headerContext) {
        _headerContext = headerContext;
        _headerContext.cardContext = self;
    }
}

#pragma mark - Parse

- (NSString *)parseClassName:(NSInteger)type
{
    NSString *className = nil;
    switch (type) {
        case ELLCardTypeNone:
            className = @"LLHomeTestCard";
            break;
        default:
            break;
    }
    return className;
}
@end
