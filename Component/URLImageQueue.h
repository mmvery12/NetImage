//
//  URLImageQueue.h
//  NiuBXiChe
//
//  Created by liyuchang on 14-8-1.
//  Copyright (c) 2014年 Mac. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
typedef void (^URLImageBlock)(UIImage *image,BOOL isMemory);
typedef void (^FileBlock)();
#import "URLImageOperation.h"
@interface URLImageQueue : NSOperationQueue
{
    NSMutableString *cachePath;
    dispatch_queue_t myDispatch;
}
+(id)SingleURLImageQueue;
+(NSOperation *)setOperationUrl:(NSString *)url defaultImageName:(NSString *)defaultName netImageBlock:(URLImageBlock)block;
@end
