//
//  ImageDataPool.h
//  XF9H-HD
//
//  Created by liyuchang on 14-11-10.
//  Copyright (c) 2014年 com.Vacn. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#define MAXBytes 1024000
@interface ImageDataPool : NSObject
{
    NSMutableDictionary *_dict;
}
+(void)addImageURL:(NSString *)url data:(NSData *)data;
+(NSData *)getImageData:(NSString *)url;
@end
