//
//  LLLoadingView.m
//  LLContainerComponent
//
//  Created by lifuqing on 2019/1/7.
//

#import "LLLoadingView.h"
#import <MBProgressHUD/MBProgressHUD.h>

@implementation LLLoadingView


///开始动画
- (void)startAnimating{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
    if (self.loadingImage) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:self.loadingImage];
        imageView.center = self.center;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        hud.mode = MBProgressHUDModeCustomView;
        hud.customView = imageView;
    }
    else {
        hud.mode = MBProgressHUDModeAnnularDeterminate;
        hud.label.text = @"正在加载";
    }
}
///停止动画
- (void)stopAnimating{
    [MBProgressHUD hideHUDForView:self animated:YES];
}

@end
