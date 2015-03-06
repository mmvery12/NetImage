//
//  URLImageOperation.h
//  XF9H-HD
//
//  Created by liyuchang on 14-11-21.
//  Copyright (c) 2014年 com.Vacn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "URLImageObjc.h"
typedef void (^URLImageBlock)(URLImageObjc *image,BOOL isMemory);
typedef void (^URLImagePercent)(CGFloat percent);
typedef void (^FaileBlock)();
@interface URLImageOperation : NSOperation<NSURLConnectionDataDelegate>
{
    Class objc;
    NSURLConnection *conn;
    NSMutableData *revdata;
    CFRunLoopRef loop;
    long long totalSize;
    URLImageObjc *layer;
}
@property (nonatomic,copy)NSString *url;
@property (nonatomic,copy)URLImageBlock sblock;
@property (nonatomic,copy)URLImagePercent pblock;
@property (nonatomic,copy)FaileBlock fblock;
@end
