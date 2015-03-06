//
//  URLimageObjc.m
//  FrameWork
//
//  Created by liyuchang on 15-1-30.
//  Copyright (c) 2015年 com.Vacn. All rights reserved.
//

#import "URLImageObjc.h"
#import <objc/runtime.h>
#import "URLImage.h"
#import <QuartzCore/QuartzCore.h>

@interface URLImageObjc ()
@property (nonatomic, assign) UIImageView *imageView;
@property (nonatomic, strong) URLImage *animatedImage;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic) NSTimeInterval accumulator;
@property (nonatomic) NSUInteger currentFrameIndex;
@property (nonatomic, assign) UIImage* currentFrame;
@property (nonatomic) NSUInteger loopCountdown;
@property (nonatomic,assign)BOOL loaded;
@end

@implementation URLImageObjc
@synthesize animatedImage = _animatedImage;
const NSTimeInterval kMaxTimeStep = 1; // note: To avoid spiral-o-death
@synthesize displayLink = _displayLink;

- (instancetype)initImageObjc:(NSData *)data
{
    self = [super init];
    if (self) {
        [self parseData:data];
    }
    return self;
}

- (instancetype)initDefaultObjc:(NSString *)img
{
    self = [super init];
    if (self) {
        [self parseData2:img];
    }
    return self;
}


-(void)parseData:(NSData *)data
{
    URLImage *image = [[URLImage alloc] initWithData:data];
    self.animatedImage = image;
    self.currentFrameIndex = 0;
#if !__has_feature(objc_arc)
    [image release];
#endif
}

-(void)parseData2:(NSString *)data
{
    URLImage *image =(id) [URLImage imageNamed:data];
    self.animatedImage = image;
    self.currentFrameIndex = 0;
}

- (CADisplayLink *)displayLink
{
    if (self.imageView) {
        if (!_displayLink && self.animatedImage.images.count>1) {
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(changeKeyframe:)];
            [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        }else
        {
            [_displayLink invalidate];
            _displayLink = nil;
        }
    } else {
        [_displayLink invalidate];
        _displayLink = nil;
    }
    return _displayLink;
}

- (void)showImage:(UIImageView *)imageView
{
    self.imageView = imageView;
    if (!_loaded) {
        _loaded = YES;
        self.currentFrameIndex = 0;
        self.loopCountdown = 0;
        self.accumulator = 0;
    }
    [self stopAnimating];
    if (self.animatedImage.images && self.animatedImage.images.count>1) {
        self.currentFrame = self.animatedImage.images[self.currentFrameIndex];
        self.loopCountdown = self.animatedImage.loopCount ?: NSUIntegerMax;
        [self startAnimating];
    }else
    {
        self.currentFrame = self.animatedImage;
    }
    [self displayLayer];
}


- (BOOL)isAnimating
{
    return [self.imageView isAnimating] || (self.displayLink && !self.displayLink.isPaused);
}

-(void)pause
{
    [self stopAnimating];
}

- (void)stopAnimating
{
    if (!self.animatedImage) {
        [self.imageView stopAnimating];
        return;
    }
    
    self.loopCountdown = 0;
    self.displayLink.paused = YES;
}

- (void)startAnimating
{
    if (!self.animatedImage) {
        [self.imageView startAnimating];
        return;
    }
    if (self.isAnimating) {
        return;
    }
    self.loopCountdown = self.animatedImage.loopCount ?: NSUIntegerMax;
    self.displayLink.paused = NO;
}

- (void)changeKeyframe:(CADisplayLink *)displayLink
{
    if (self.currentFrameIndex >= [self.animatedImage.images count]) {
        return;
    }
    self.accumulator += fmin(displayLink.duration, kMaxTimeStep);
    
    while (self.accumulator >= self.animatedImage.frameDurations[self.currentFrameIndex]) {
        self.accumulator -= self.animatedImage.frameDurations[self.currentFrameIndex];
        if (++self.currentFrameIndex >= [self.animatedImage.images count]) {
            if (--self.loopCountdown == 0) {
                [self stopAnimating];
                return;
            }
            self.currentFrameIndex = 0;
        }
        self.currentFrameIndex = MIN(self.currentFrameIndex, [self.animatedImage.images count] - 1);
        self.currentFrame = self.animatedImage.images[self.currentFrameIndex];
        [self displayLayer];
    }
}

-(void)displayLayer
{
    self.imageView.image = [self.currentFrame copy];
}

- (void)dealloc
{
    if (_animatedImage==nil) {
        
    }else
        _animatedImage = nil;
}

@end
