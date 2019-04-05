//
//  LLCardContext.h
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class LLCardContext;

///卡片类型,仅提供样例，各业务方自行定义枚举
typedef NS_ENUM(NSInteger, ELLCardType) {
    ELLCardTypeNone = 1000,///此处仅添加一些公用的卡片类型
};

///卡片状态
typedef NS_ENUM(NSInteger, ELLCardState) {
    ///默认状态
    ELLCardStateNormal,
    ///加载状态
    ELLCardStateLoading,
    ///错误状态
    ELLCardStateError,
};

///卡片错误类型
typedef NS_ENUM(NSInteger, ELLCardErrorCode) {
    ///无错误
    ELLCardErrorCodeNone       = 0,
    ///网络错误
    ELLCardErrorCodeNetwork    = -9900,
    ///数据错误
    ELLCardErrorCodeFailed     = -9901,
    ///数据为空
    ELLCardErrorCodeNoData     = -9902,
};

///卡片头部
@interface LLCardHeaderContext : NSObject

@property (nonatomic, weak) LLCardContext *cardContext;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *schemeUrl;

///是否有更多，如果YES则有箭头,
@property (nonatomic, assign) BOOL hasMoreExtend;

@end


///卡片底部
@interface LLCardFooterContext : NSObject

@property (nonatomic, weak) LLCardContext *cardContext;
/// 任何形式的模型，可为json或者model
@property (nonatomic, strong) id contentModel;

@end

///卡片信息，可继承
@interface LLCardContext : NSObject

///卡片id
@property (nonatomic, copy) NSString *cardId;
///header
@property (nonatomic, strong) LLCardHeaderContext *headerContext;
///类型,可自定义类型，对应实现parseClassName:解析
@property (nonatomic, assign) ELLCardType type;
///状态
@property (nonatomic, assign) ELLCardState state;
///卡片控制器Class 继承自LLCardController的
@property (nonatomic, copy, readonly) NSString *clazz;
///卡片信息（CMS配置的原始数据）
@property (nonatomic, strong) NSDictionary *cardInfo;
///数据源,可为model
@property (nonatomic, strong) id model;
///错误
@property (nonatomic, strong, nullable) NSError *error;
///接口返回的原始error
@property (nonatomic, strong, nullable) NSError *responseError;
///卡片顺序
@property (nonatomic, assign) NSInteger cardIndex;
///是否支持加载更多
@property (nonatomic, assign) BOOL hasMore;
///是否异步请求，外部设置，默认NO
@property (nonatomic, assign) BOOL asyncLoad;


/**
 工厂方法创建一个cardContext

 @param cardType 自定义的卡片类型，注意最好不要简单的从0开始，
 @param headerTitle 卡片标题
 @param headerDesc 卡片描述
 @param model 卡片内容模型
 @return 卡片cardContext
 */
+ (instancetype)cardContextWithCardType:(NSInteger)cardType headerTitle:(nullable NSString *)headerTitle headerDesc:(nullable NSString *)headerDesc contextModel:(nullable id)model;

///根据不同类型，解析为不同的卡片类
- (NSString *)parseClassName:(NSInteger)type;

@end

NS_ASSUME_NONNULL_END
