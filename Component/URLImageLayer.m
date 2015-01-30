//
//  URLImageLayer.m
//  FrameWork
//
//  Created by liyuchang on 15-1-30.
//  Copyright (c) 2015年 com.Vacn. All rights reserved.
//

#import "URLImageLayer.h"
#import <objc/runtime.h>
#import "URLImage.h"
#import <QuartzCore/QuartzCore.h>

@interface URLImageLayer ()
@property (nonatomic, assign) UIImageView *imageView;
@property (nonatomic, strong) URLImage *animatedImage;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic) NSTimeInterval accumulator;
@property (nonatomic) NSUInteger currentFrameIndex;
@property (nonatomic, strong) UIImage* currentFrame;
@property (nonatomic) NSUInteger loopCountdown;
@property (nonatomic,assign)BOOL loaded;
@end

@implementation URLImageLayer
@synthesize animatedImage = _animatedImage;
const NSTimeInterval kMaxTimeStep = 1; // note: To avoid spiral-o-death

@synthesize displayLink = _displayLink;

-(void)judgeData:(NSData *)data
{
    URLImage *image = [[URLImage alloc] initWithData:data];
    self.animatedImage = image;
    self.currentFrameIndex = 0;
#if !__has_feature(objc_arc)
    [image release];
#endif
}

- (CADisplayLink *)displayLink
{
    if (self.superlayer) {
        if (!_displayLink && self.animatedImage) {
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(changeKeyframe:)];
            [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        }
    } else {
        [_displayLink invalidate];
        _displayLink = nil;
    }
    return _displayLink;
}


- (void)load:(UIImageView *)imageView
{
    self.imageView = imageView;
    for (CALayer *layer in self.imageView.layer.sublayers) {
        if ([layer isKindOfClass:object_getClass(self)]) {
            [layer removeFromSuperlayer];
        }
    }
    [self.imageView.layer addSublayer:self];
    if (!_loaded) {
        self.frame = imageView.bounds;
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
    [self displayLayer:self];
}


- (BOOL)isAnimating
{
    return [self.imageView isAnimating] || (self.displayLink && !self.displayLink.isPaused);
}
-(void)pause
{
    [self removeFromSuperlayer];
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
        [self displayLayer:self];
    }
}

-(void)displayLayer:(CALayer *)layer
{
    if(self.currentFrame && [self.currentFrame isKindOfClass:[UIImage class]])
        layer.contents = (__bridge id)([self.currentFrame CGImage]);
}


@end
