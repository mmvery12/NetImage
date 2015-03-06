//
//  URLimageObjc.h
//  FrameWork
//
//  Created by liyuchang on 15-1-30.
//  Copyright (c) 2015年 com.Vacn. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>
@interface URLImageObjc : NSObject
- (instancetype)initImageObjc:(NSData *)data;
- (instancetype)initDefaultObjc:(NSString *)img;
-(void)parseData:(NSData *)data;
- (void)showImage:(UIImageView *)imageView;
- (void)pause;
@end

