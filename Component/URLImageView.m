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
#import "URLImageLayer.h"
@interface URLImageView ()
@property (nonatomic,assign)Class objIsa;
@property (nonatomic,assign) NSOperation *operation;
@property (nonatomic,copy)NSString *url;
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
    self.backgroundColor = [UIColor whiteColor];
    __weak URLImageView *imageView = self;
    self.url = url;
    NSOperation *opertation = [URLImageQueue setOperation:self Url:[url copy] defaultImageName:[img copy] data:data netImageBlock:^(URLImageLayer *imageData,BOOL isMemory) {
        [imageView imageDone:imageData memory:isMemory];
    }];
    self.operation = opertation;
}

-(void)setOperation:(NSOperation *)operation
{
    _operation = operation;
    _objIsa = object_getClass(_operation);
}

-(void)imageDone:(URLImageLayer *)imageData memory:(BOOL)memory
{
    [imageData load:self];
    //    [imageData load:self animate:memory];
}

-(void)cancelOperation
{
    if (_objIsa == object_getClass(_operation) && self.operation) {
        [self.operation cancel];
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
