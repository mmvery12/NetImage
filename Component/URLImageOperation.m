//
//  URLImageOperation.m
//  XF9H-HD
//
//  Created by liyuchang on 14-11-21.
//  Copyright (c) 2014年 com.Vacn. All rights reserved.
//

#import "URLImageOperation.h"
#import <objc/runtime.h>
#import "ImageDataPool.h"

@implementation URLImageOperation
@synthesize url = _url;
@synthesize sblock = _sblock;
@synthesize pblock = _pblock;
@synthesize fblock = _fblock;
@synthesize path = _path;
-(void)start
{
    [self getImage];
}

-(void)getImage
{
    isFinish = YES;
    if ([self isCancelled]) return;
    NSString *url = self.url;
    NSString *path = self.path;
    isFinish = YES;
    if ([self isCancelled]) return;
    revdata = [NSMutableData data];
    [self loadFromUrl:url savePath:path];
}


-(void)loadFromUrl:(id)url savePath:(NSString *)path
{
    isFinish = NO;
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
    [revdata appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    isFinish = YES;
    [layer judgeData:revdata];
    [ImageDataPool addImageURL:self.url data:layer];
    __weak URLImageOperation *oper = self;
    if (![self isCancelled]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [oper done:layer];
        });
    }
}

-(void)done:(URLImageLayer *)responseDatas
{
    [revdata writeToFile:self.path atomically:YES];
    if (self.sblock && responseDatas) _sblock(responseDatas,NO);
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
