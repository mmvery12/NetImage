//
//  UIImageView+LoadImage.m
//  NiuBXiChe
//
//  Created by liyuchang on 14-8-1.
//  Copyright (c) 2014年 Mac. All rights reserved.
//

  
#import "URLImageView.h"
#import "URLImageQueue.h"
#import <objc/runtime.h>
#import "SysAsseist.h"
#import "URLImageObjc.h"
@interface URLImageView ()
@property (nonatomic,assign)Class objIsa;
@property (nonatomic,assign) NSOperation *operation;
@property (nonatomic,copy)NSString *url;
@property (nonatomic,assign)URLImageObjc *imageObjc;
@end

@implementation URLImageView
@synthesize indexPath = _indexPath;
@synthesize operation = _operation;
-(void)urlImage:(NSString *)url
{
    
    [self urlImage:url defaultIMG:@"defaultImage"];
}

-(void)urlImage:(NSString *)url defaultIMG:(NSString *)img
{
    [self loadAction:url defaultIMG:img data:nil];
}

-(void)loadAction:(NSString *)url defaultIMG:(NSString *)img data:(NSData *)data
{
    [self cancelOperation];
    self.url = url;
    __weak URLImageView *imageView = self;
    NSOperation *opertation = [URLImageQueue setOperation:self Url:[url copy] defaultImageName:[img copy] data:data netImageBlock:^(URLImageObjc *imageData,BOOL isMemory) {
        [imageView imageDone:imageData memory:isMemory];
    }];
    self.operation = opertation;
}

-(void)setOperation:(NSOperation *)operation
{
    _operation = operation;
    _objIsa = object_getClass(_operation);
}

-(void)imageDone:(URLImageObjc *)imageData memory:(BOOL)memory
{
    if ([imageData isEqual:self.imageObjc]) {
        return;
    }
    [imageData showImage:self];
}

-(void)cancelOperation
{
    if (_objIsa == object_getClass(_operation) && self.operation) {
        [self.operation cancel];
    }else
    {
    
    }
}

- (void)dealloc
{
    [self cancelOperation];
#if !__has_feature(objc_arc)
    [_url release];_url = nil;
    [_indexPath release];_indexPath = nil;
    [super dealloc];
#endif
}
@end

@implementation URLImageView (GIFImage)
- (void)viewWillDismissPauseGif
{
    [URLImageQueue viewWillDismissPauseGif:self url:self.url];
}
@end

@implementation URLImageView (Adapter)

-(void)urlImage:(NSString *)url scale:(BOOL)scale
{
    [self urlImage:url];
}
-(void)urlImage:(NSString *)url defaultIMG:(NSString *)img scale:(BOOL)scale
{
    [self urlImage:url defaultIMG:img];
}
-(void)urlImage:(NSString *)url largeUrl:(NSString *)large defaultIMG:(NSString *)img scale:(BOOL)scale
{
    [self urlImage:url defaultIMG:img];
}
@end
