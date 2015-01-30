//
//  URLImageLayer.h
//  FrameWork
//
//  Created by liyuchang on 15-1-30.
//  Copyright (c) 2015年 com.Vacn. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>
@interface URLImageLayer : CALayer

-(void)judgeData:(NSData *)data;

- (void)load:(UIImageView *)imageView;
- (void)pause;
@end

