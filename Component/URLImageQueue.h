//
//  URLImageQueue.h
//  NiuBXiChe
//
//  Created by liyuchang on 14-8-1.
//  Copyright (c) 2014年 Mac. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "URLImageLayer.h"
#import "URLImageOperation.h"
typedef void (^FileBlock)();
@interface URLImageQueue : NSOperationQueue
{
    NSMutableString *cachePath;
    dispatch_queue_t myDispatch;
}
+(id)SingleURLImageQueue;
+(void)pauseGif:(UIImageView *)imageView url:(NSString *)url;
+(NSOperation *)setOperation:(UIImageView *)imageView Url:(NSString *)url defaultImageName:(NSString *)defaultName data:(NSData *)data netImageBlock:(URLImageBlock)block;
@end
