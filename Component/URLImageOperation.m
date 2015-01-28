//
//  URLImageOperation.m
//  XF9H-HD
//
//  Created by liyuchang on 14-11-21.
//  Copyright (c) 2014年 com.Vacn. All rights reserved.
//

#import "URLImageOperation.h"
#import <objc/runtime.h>
@implementation URLImageOperation

-(void)start
{
    [self getImage];
}

-(void)getImage
{
    if (![self isCancelled]) {
        NSString *url = self.url;
        NSString *path = self.path;
        if (![self isCancelled]) {
            responseData = [NSMutableData data];
            [self loadFromUrl:url savePath:path];
        }
    }
}


-(void)loadFromUrl:(id)url savePath:(NSString *)path
{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
#if !__has_feature(objc_arc)
    [request release];
#endif
    [conn start];
    loop = CFRunLoopGetCurrent();
    CFRunLoopSourceRef source;
    CFRunLoopSourceContext source_context;
    bzero(&source_context, sizeof(source_context));
    source = CFRunLoopSourceCreate(NULL, 0, &source_context);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
    while(!isFinish) {
        CFRunLoopRun();
    }
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    CFRelease(source);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    totalSize = response.expectedContentLength;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (_pblock) {
        _pblock(data.length/totalSize);
    }
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    isFinish = YES;
    UIImage *image = [self OriginImage:responseData];
    __weak URLImageOperation *oper = self;
    if (![self isCancelled]&&image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [oper done:image];
        });
    }
}

-(void)done:(UIImage *)image
{
    [responseData writeToFile:self.path atomically:YES];
    if (self.sblock && image) _sblock(image,NO);
    isFinish = YES;
    CFRunLoopStop(loop);
}

-(void)faild
{
    if (_fblock) _fblock();
    isFinish = YES;
    CFRunLoopStop(loop);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    __weak URLImageOperation *oper = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [oper faild];
    });
}

-(BOOL)isFinished
{
    return isFinish;
}

-(BOOL)isConcurrent
{
    return YES;
}

-(UIImage *)OriginImage:(NSData *)data
{
    UIImage *image = [UIImage imageWithData:responseData];
    CGSize size = image.size;
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (void)dealloc
{
    [conn cancel];
    loop = nil;
#if !__has_feature(objc_arc)
    [_url release];_url = nil;
    [_path release];_path = nil;
    [conn release];conn = nil;
    Block_release(_sblock);
    Block_release(_fblock);
    Block_release(_pblock);
    [super dealloc];
#endif
}
@end
