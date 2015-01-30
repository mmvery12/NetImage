//
//  URLImageQueue.m
//  NiuBXiChe
//
//  Created by liyuchang on 14-8-1.
//  Copyright (c) 2014年 Mac. All rights reserved.
//

#import "URLImageQueue.h"
#import "ImageDataPool.h"

#define KmaxConcurrentOperationCount 8
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
+(void)pauseGif:(UIImageView *)imageView url:(NSString *)url
{
    URLImageLayer *memoryData = (id)[ImageDataPool getImageData:url];
    [memoryData pause];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        cachePath = [[NSMutableString alloc] initWithString:[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Caches"]];
        self.maxConcurrentOperationCount = KmaxConcurrentOperationCount;
        myDispatch = dispatch_queue_create("com.myDispatch", NULL);
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
    URLImageLayer *memoryData = (id)[ImageDataPool getImageData:url];
    if (memoryData) {
        block(memoryData,YES);
    }else
    {
        NSString *tempurl = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        NSMutableString *path = [NSMutableString stringWithString:[self getPath:tempurl]];
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        if (data||hdata) {
            [self loadFromSandBox:data?data:hdata url:url block:block];
        }else
        {
            fileOpertation = [self loadFromNet:path url:url block:block];
        }
#if !__has_feature(objc_arc)
        [data release];
#endif
    }
#if !__has_feature(objc_arc)
    Block_release(block);
    [pool drain];
#endif
    return fileOpertation;
}

-(void)loadFromSandBox:(NSData *)data url:(NSString *)url block:(URLImageBlock)block
{
    URLImageLayer *imageData = [URLImageLayer layer];
    [imageData judgeData:data];
    block(imageData,YES);
    [ImageDataPool addImageURL:url data:imageData];
//#if !__has_feature(objc_arc)
//    [imageData release];
//#endif
}

-(URLImageOperation *)loadFromNet:(NSString *)path url:(NSString *)url block:(URLImageBlock)block
{
    URLImageOperation *fileOpertation = nil;
    fileOpertation = [[URLImageOperation alloc] init];
    fileOpertation.url = url;
    fileOpertation.sblock = block;
    fileOpertation.path = path;
    [self addOperation:fileOpertation];
#if !__has_feature(objc_arc)
    [fileOpertation release];
#endif
//    URLImageData *imageData = [URLImageData Default];
//    block(imageData,NO);
#if !__has_feature(objc_arc)
    [imageData release];
#endif
    return fileOpertation;
}

-(UIImage *)OriginImage:(UIImage *)image   scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

-(NSMutableString *)getPath:(NSString *)url
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:url]) {
        return [NSMutableString stringWithString:url];
    }
    NSRange string = [url rangeOfString:@"/" options:NSBackwardsSearch];
    NSString *From = [url substringFromIndex:string.location+1];
    NSString *to = [[url substringToIndex:string.location] stringByReplacingOccurrencesOfString:@"." withString:@"/"];
    NSMutableString *mString = [NSMutableString string];
    [mString appendFormat:@"%@/%@",cachePath,to];
    [mString appendString:@"/"];
    [self createFolder:mString];
    [mString appendFormat:@"%@",From];
    return mString;
}

-(void)createFolder:(NSString *)path
{
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
}

-(void)dealloc
{
#if !__has_feature(objc_arc)
    dispatch_release(myDispatch);
    [cachePath release];cachePath = nil;
    [super dealloc];
#endif
    
}
@end
