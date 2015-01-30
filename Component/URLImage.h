//
//  URLImage.h
//  FrameWork
//
//  Created by liyuchang on 15-1-30.
//  Copyright (c) 2015年 com.Vacn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface URLImage : UIImage
@property (nonatomic, readonly) NSTimeInterval *frameDurations;
@property (nonatomic, readonly) NSTimeInterval totalDuration;
@property (nonatomic, readonly) NSUInteger loopCount;
@end
