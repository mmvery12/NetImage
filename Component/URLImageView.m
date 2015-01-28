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

@interface URLImageView ()
@property (nonatomic,assign)Class objIsa;
@property (nonatomic,assign) NSOperation *operation;
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
    [self urlImage:url largeUrl:url defaultIMG:img];
}

-(void)urlImage:(NSString *)url largeUrl:(NSString *)large defaultIMG:(NSString *)img
{
    [self cancelOperation];
    self.backgroundColor = [UIColor whiteColor];
    __weak URLImageView *imageView = self;
    NSOperation *opertation = [URLImageQueue setOperationUrl:[url copy] defaultImageName:[img copy] netImageBlock:^(UIImage *image,BOOL isMemory) {
        [imageView imageDone:image memory:isMemory];
    }];
    self.operation = opertation;
}


-(void)setOperation:(NSOperation *)operation
{
    _operation = operation;
    _objIsa = object_getClass(_operation);
}

-(void)imageDone:(UIImage *)image memory:(BOOL)memory
{
    self.image = image;
    if (!memory) {
        self.alpha = 0;
        __weak URLImageView *imageView = self;
        [UIView animateWithDuration:0.5 animations:^{
            imageView.alpha = 1;
        }];
    }
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
    [_indexPath release];_indexPath = nil;
    [super dealloc];
#endif
}
@end
