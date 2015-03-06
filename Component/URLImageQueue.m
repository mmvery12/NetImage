//
//  URLImageQueue.m
//  NiuBXiChe
//
//  Created by liyuchang on 14-8-1.
//  Copyright (c) 2014年 Mac. All rights reserved.
//

#import "URLImageQueue.h"
#import "ImageDataPool.h"

#define KmaxConcurrentOperationCount 10
@implementation URLImageQueue

+(id)SingleURLImageQueue
{
    @synchronized(self)
    {
        static URLImageQueue *queue;
        if (!queue) {
            queue = [[URLImageQueue alloc] init];
        }
        return queue;
    }
}

+(void)viewWillDismissPauseGif:(UIImageView *)imageView url:(NSString *)url
{
    URLImageObjc *memoryData = (id)[ImageDataPool getImageData:url];
    [memoryData pause];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.maxConcurrentOperationCount = KmaxConcurrentOperationCount;
    }
    return self;
}

+(NSOperation *)setOperation:(UIImageView *)imageView Url:(NSString *)url defaultImageName:(NSString *)defaultName data:(NSData *)data netImageBlock:(URLImageBlock)block
{
    return [[URLImageQueue SingleURLImageQueue] queue:imageView url:url defaultImageName:defaultName data:data netImageBlock:block];
}

-(NSOperation *)queue:(UIImageView *)imageView url:(NSString *)url defaultImageName:(NSString *)defaultName data:(NSData *)hdata netImageBlock:(URLImageBlock)block
{
    if (!url||url.length==0) return nil;
#if !__has_feature(objc_arc)
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
#endif
    URLImageOperation *fileOpertation = nil;
    URLImageObjc *memoryData = (id)[ImageDataPool getImageData:url];
    if (memoryData) {
        block(memoryData,YES);
    }else
    {
        memoryData = [[URLImageObjc alloc] initDefaultObjc:defaultName];
        block(memoryData,YES);
#if !__has_feature(objc_arc)
        [memoryData release];
#endif
        fileOpertation = [self loadFromurl:url block:block];
    }
#if !__has_feature(objc_arc)
    Block_release(block);
    [pool drain];
#endif
    return fileOpertation;
}

-(URLImageOperation *)loadFromurl:(NSString *)url block:(URLImageBlock)block
{
    URLImageOperation *fileOpertation = nil;
    fileOpertation = [[URLImageOperation alloc] init];
    fileOpertation.url = url;
    fileOpertation.sblock = block;
    [self addOperation:fileOpertation];
#if !__has_feature(objc_arc)
    [fileOpertation release];
    [imageData release];
#endif
    return fileOpertation;
}



-(void)dealloc
{
#if !__has_feature(objc_arc)
    [cachePath release];cachePath = nil;
    [super dealloc];
#endif
    
}
@end
