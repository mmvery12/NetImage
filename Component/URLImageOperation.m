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
#import "SysAsseist.h"
@interface URLImageOperation ()
@property (nonatomic,DEF_STRONG) NSString *path;
@end

@implementation URLImageOperation
@synthesize url = _url;
@synthesize sblock = _sblock;
@synthesize pblock = _pblock;
@synthesize fblock = _fblock;
-(void)start
{
    NSString *tempurl = [_url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    _path = [NSMutableString stringWithString:[self getPath:tempurl]];
    BOOL flag = false;
    if ([[NSFileManager defaultManager] fileExistsAtPath:_path isDirectory:&flag]) {
        [self loadFromSandBox:_path url:_url block:_sblock];
    }else
        [self getImage];
}


-(NSMutableString *)getPath:(NSString *)url
{
    NSMutableString *cachePath = [[NSMutableString alloc] initWithString:[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Caches"]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:url]) {
        return [NSMutableString stringWithString:url];
    }
    NSRange string = [url rangeOfString:@"/" options:NSBackwardsSearch];
    NSString *From = [url substringFromIndex:string.location+1];
    NSString *to = [[url substringToIndex:string.location] stringByReplacingOccurrencesOfString:@"." withString:@"/"];
    NSMutableString *mString = [NSMutableString string];
    [mString appendFormat:@"%@/%@",cachePath,to];
    [self createFolder:mString];
    [mString appendString:@"/"];
    [mString appendFormat:@"%@",From];
#if !__has_feature(objc_arc)
    [cachePath release];
#endif
    return mString;
}

-(void)createFolder:(NSString *)path
{
    BOOL is = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&is]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    }
}

-(void)loadFromSandBox:(NSString *)path url:(NSString *)url block:(URLImageBlock)block
{
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    URLImageObjc *templayer = [[URLImageObjc alloc] initImageObjc:data];
    [ImageDataPool addImageURL:url data:templayer];
    if (!self.isCancelled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(templayer,YES);
        });
    }
#if !__has_feature(objc_arc)
    [data release];
    [templayer release];
#endif
}

-(void)getImage
{
    NSString *url = self.url;
    if ([self isCancelled]) return;
    revdata = [NSMutableData data];
    [self loadFromUrl:url savePath:_path];
}


-(void)loadFromUrl:(id)url savePath:(NSString *)path
{
    NSLog(@"on %@",self.url);
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
    conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
#if !__has_feature(objc_arc)
    [request release];
#endif
    [conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [conn start];
    while(conn != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    NSLog(@"");
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self iscancel];
    totalSize = response.expectedContentLength;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self iscancel];
    if (_pblock) {
        _pblock(data.length/totalSize);
    }
    [revdata appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    [self iscancel];
    URLImageObjc *templayer = [[URLImageObjc alloc] initImageObjc:revdata];
    [ImageDataPool addImageURL:self.url data:templayer];
    __weak URLImageOperation *oper = self;
    NSError *error;
    [revdata writeToFile:self.path options:NSDataWritingAtomic error:&error];
    if (![self isCancelled]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [oper done:templayer];
        });
    }
#if !__has_feature(objc_arc)
    [templayer release];
#endif
}

-(void)done:(URLImageObjc *)responseDatas
{
    [self iscancel];
    if (self.sblock && responseDatas) _sblock(responseDatas,NO);
    conn = nil;
}

-(void)faild
{
    [self iscancel];
    if (_fblock) _fblock();
    conn = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self iscancel];
    __weak URLImageOperation *oper = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [oper faild];
    });
}

-(void)iscancel
{
    if (self.cancelled) {
        conn = nil;
        return;
    }
}

-(BOOL)isFinished
{
    return conn==nil;
}
-(BOOL)isExecuting
{
    return conn==nil;
}
-(BOOL)isConcurrent
{
    return YES;
}


- (void)dealloc
{
    [conn cancel];
    loop = nil;
    layer = nil;
    revdata = nil;
#if !__has_feature(objc_arc)
    [layer release];layer = nil;
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
