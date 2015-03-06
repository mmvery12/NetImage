//
//  UIImageView+LoadImage.h
//  NiuBXiChe
//
//  Created by liyuchang on 14-8-1.
//  Copyright (c) 2014年 Mac. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface URLImageView : UIImageView
@property (nonatomic,assign,readonly) CGFloat percent;
-(void)urlImage:(NSString *)url;
-(void)urlImage:(NSString *)url defaultIMG:(NSString *)img;
@property (nonatomic,retain) NSIndexPath *indexPath;
@end

@interface URLImageView (GIFImage)
- (void)viewWillDismissPauseGif;
@end

@interface URLImageView (Adapter)
-(void)urlImage:(NSString *)url scale:(BOOL)scale;
-(void)urlImage:(NSString *)url defaultIMG:(NSString *)img scale:(BOOL)scale;
-(void)urlImage:(NSString *)url largeUrl:(NSString *)large defaultIMG:(NSString *)img scale:(BOOL)scale;
@end
