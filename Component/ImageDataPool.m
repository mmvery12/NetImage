//
//  ImageDataPool.m
//  XF9H-HD
//
//  Created by liyuchang on 13-11-10.
//  Copyright (c) 2014年 com.Vacn. All rights reserved.
//

#import "ImageDataPool.h"

@implementation ImageDataPool
+(ImageDataPool *)Share
{
    @synchronized(self)
    {
        static ImageDataPool *queue;
        if (!queue) {
            queue = [[ImageDataPool alloc] init];
        }
        return queue;
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dict = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ApplicationDidReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

+(void)addImageURL:(NSString *)url data:(URLImageLayer *)data
{
    [[ImageDataPool Share] imageurl:url data:data];
}

+(URLImageLayer *)getImageData:(NSString *)url
{
    return [[ImageDataPool Share] getData:url];
}

-(void)imageurl:(NSString *)url data:(URLImageLayer *)data
{
    @synchronized(_dict)
    {
        [_dict setObject:data forKey:url];
    }
}

-(URLImageLayer *)getData:(NSString *)url
{
    @synchronized(_dict)
    {
        return [_dict objectForKey:url];
    }
}

-(void)ApplicationDidReceiveMemoryWarningNotification
{
    @synchronized(_dict)
    {
        [_dict removeAllObjects];
    }
}
-(void)dealloc
{
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
}
@end
