//
//  LLCardController.h
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/5.
//

#import <Foundation/Foundation.h>
#import "LLContainerCardsControllerProtocol.h"
#import <LLHttpEngine/LLHttpEngine.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LLCardControllerDelegate <NSObject>
///刷新指定类型的卡片
- (void)refreshCardWithType:(ELLCardType)type;
@end



@protocol LLCardControllerDelegate, LLContainerCardsController;

///卡片，可继承
@interface LLCardController : NSObject <LLContainerCardsControllerDelegate>

@property (nonatomic, weak  ) id<LLCardControllerDelegate> delegate;
///卡片列表控制器
@property (nonatomic, weak  ) LLContainerCardsController *cardsController;
///卡片数据源
@property (nonatomic, strong) LLCardContext *cardContext;
///是否完成准备，会自动渲染执行refreshCard,异步请求的需要回调后设置此属性来达到卡片刷新，默认NO
@property (nonatomic, assign) BOOL isPrepared;

/**
 卡片是否无数据,如果卡片数据为空不需要占位，则不需要设置此属性（请求成功，但是结果为0个，内部已针对cardContext.error有无进行判断，无需再多判断一层error）,默认 NO，
 */
@property (nonatomic, assign) BOOL isNoData;

///渲染刷新该卡片
- (void)refreshCard;
///请求错误卡片数据
- (void)requestErrorCardData;

@end

/**
 *  配置卡片的数据源方式之一,子类设置，可代替delegate
 */
@interface LLCardController (DataSource)
///内容类
@property (nonatomic, assign) Class cardContentClass;
///悬停header高度，默认0.0，不建议用高度来控制悬停头部卡片显示隐藏，如果数据拿不到不显示卡片，请通过cardHasForeverSuspendHeader属性配合isPrepared实现
@property (nonatomic, assign) CGFloat cardSuspendHeaderHeight;
///卡片头行高，默认0.0，不建议用高度来控制头部卡片显示隐藏，如果数据拿不到不显示卡片，请通过shouldShowCardHeaderInTableView:代理配合isPrepared实现
@property (nonatomic, assign) CGFloat cardHeaderHeight;
///卡片底部间距高度，默认10,当大于0的时候显示间距
@property (nonatomic, assign) CGFloat cardSpacingHeight;
///卡片头类
@property (nonatomic, assign) Class cardHeaderClass;
///是否显示卡片头，默认NO
@property (nonatomic, assign) BOOL cardShowHeader;
///是否显示卡片底部，默认NO
@property (nonatomic, assign) BOOL cardShowFooter;
///是否显示错误卡片，默认NO
@property (nonatomic, assign) BOOL cardShowErrorCard;
///扩展是否有永久性悬停header，默认NO
@property (nonatomic, assign) BOOL cardHasForeverSuspendHeader;

@end

/**
 *  缓存参数，用于优化表视图性能
 */
@interface LLCardController (Cache)
///是否显示错误视图
@property (nonatomic, assign) BOOL        showCardError;
///是否显示头部视图
@property (nonatomic, assign) BOOL        showCardHeader;
///是否显示尾部视图
@property (nonatomic, assign) BOOL        showCardFooter;
///是否显示卡片间距
@property (nonatomic, assign) BOOL        showCardSpacing;
///行数缓存
@property (nonatomic, assign) NSInteger   rowCountCache;
///行高缓存
@property (nonatomic, copy  ) NSArray     *rowHeightsCache;

@end


/**
 *  加载更多
 */
@interface LLCardController (RequestMore)
///是否可加载更多。默认为NO。开启后可响应-didTriggerRequestMoreDataActionInCardsController:协议。
@property (nonatomic, assign) BOOL canRequestMoreData;

@end

/**
 * 曝光统计,扩展备用
 */
@interface LLCardController (Expose)
///头部是否已经曝光
@property (nonatomic, assign) BOOL headerExposed;
///尾部是否已经曝光,尾部数据更新了,需要设置为NO,下次展示会重新曝光
@property (nonatomic, assign) BOOL footerExposed;
///已经曝光过的数据,不包含header和footer
@property (nonatomic, strong) NSMutableArray<NSObject *> *exposedArray;

@end
NS_ASSUME_NONNULL_END
