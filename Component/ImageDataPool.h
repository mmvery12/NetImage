//
//  ImageDataPool.h
//  XF9H-HD
//
//  Created by liyuchang on 13-11-10.
//  Copyright (c) 2014年 com.Vacn. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "URLImageLayer.h"
@interface ImageDataPool : NSObject
{
    NSMutableDictionary *_dict;
}
+(void)addImageURL:(NSString *)url data:(URLImageLayer *)data;
+(URLImageLayer *)getImageData:(NSString *)url;
@end
