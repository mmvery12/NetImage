//
//  URLImage.m
//  FrameWork
//
//  Created by liyuchang on 15-1-30.
//  Copyright (c) 2015年 com.Vacn. All rights reserved.
//

#import "URLImage.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>


#ifndef FLT_EPSILON
#define FLT_EPSILON __FLT_EPSILON__
#endif

void getFrameInfo(CFDataRef url, NSMutableArray *frames, NSTimeInterval *delayTimes, NSTimeInterval *totalTime,CGFloat *gifWidth, CGFloat *gifHeight)
{
    CGImageSourceRef gifSource = CGImageSourceCreateWithData(url, NULL);
    size_t frameCount = CGImageSourceGetCount(gifSource);
    for (size_t i = 0; i < frameCount; ++i) {
        CGImageRef frame = CGImageSourceCreateImageAtIndex(gifSource, i, NULL);
        [frames addObject:(__bridge id)frame];
        
        CFDictionaryRef sourceDict = CGImageSourceCopyPropertiesAtIndex(gifSource, i, NULL);
        NSDictionary *dict = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)(sourceDict)];
        if (gifWidth != NULL && gifHeight != NULL) {
            *gifWidth = [[dict valueForKey:(NSString*)kCGImagePropertyPixelWidth] floatValue];
            *gifHeight = [[dict valueForKey:(NSString*)kCGImagePropertyPixelHeight] floatValue];
        }
        NSDictionary *gifDict = [dict valueForKey:(NSString*)kCGImagePropertyGIFDictionary];
        delayTimes[i] = [[gifDict valueForKey:(NSString*)kCGImagePropertyGIFDelayTime] floatValue];
        if (totalTime) {
            *totalTime = *totalTime + [[gifDict valueForKey:(NSString*)kCGImagePropertyGIFDelayTime] floatValue];
        }
        CFRelease(sourceDict);
        CGImageRelease(frame);
    }
    CFRelease(gifSource);
}

inline static NSTimeInterval CGImageSourceGetGifFrameDelay(CGImageSourceRef imageSource, NSUInteger index)
{
    NSTimeInterval frameDuration = 0;
    CFDictionaryRef theImageProperties;
    if ((theImageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, NULL))) {
        CFDictionaryRef gifProperties;
        if (CFDictionaryGetValueIfPresent(theImageProperties, kCGImagePropertyGIFDictionary, (const void **)&gifProperties)) {
            const void *frameDurationValue;
            if (CFDictionaryGetValueIfPresent(gifProperties, kCGImagePropertyGIFUnclampedDelayTime, &frameDurationValue)) {
                frameDuration = [(__bridge NSNumber *)frameDurationValue doubleValue];
                if (frameDuration <= 0) {
                    if (CFDictionaryGetValueIfPresent(gifProperties, kCGImagePropertyGIFDelayTime, &frameDurationValue)) {
                        frameDuration = [(__bridge NSNumber *)frameDurationValue doubleValue];
                    }
                }
            }
        }
        CFRelease(theImageProperties);
    }
    
#ifndef OLExactGIFRepresentation
    //Implement as Browsers do.
    //See:  http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser-compatibility
    //Also: http://blogs.msdn.com/b/ieinternals/archive/2010/06/08/animated-gifs-slow-down-to-under-20-frames-per-second.aspx
    
    if (frameDuration < 0.02 - FLT_EPSILON) {
        frameDuration = 0.1;
    }
#endif
    return frameDuration;
}

inline static BOOL CGImageSourceContainsAnimatedGif(CGImageSourceRef imageSource)
{
    return imageSource && UTTypeConformsTo(CGImageSourceGetType(imageSource), kUTTypeGIF) && CGImageSourceGetCount(imageSource) > 1;
}

@interface URLImage ()

@property (nonatomic, readwrite) NSMutableArray *images;
@property (nonatomic, readwrite) NSTimeInterval *frameDurations;
@property (nonatomic, readwrite) NSTimeInterval *totalDuration;
@property (nonatomic, readwrite) NSUInteger loopCount;
@property (nonatomic, readwrite) CGImageSourceRef incrementalSource;

@end

static NSUInteger _prefetchedNum = 10;

@implementation URLImage
{
    dispatch_queue_t readFrameQueue;
    CGImageSourceRef _imageSourceRef;
    CGFloat _scale;
}

@synthesize images;
- (id)initWithData:(NSData *)data
{
    if (!data) {
        return nil;
    }
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)(data), NULL);
    if (CGImageSourceContainsAnimatedGif(imageSource)) {
        self = [self initWithCGImageSource:imageSource scale:NO :data];
        _imageSourceRef = imageSource;
        CFRetain(imageSource);
    } else {
        CGImageRef ref = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        CGFloat percent = 100./data.length;
        self = [super initWithCGImage:ref scale:percent>1?1:percent orientation:UIImageOrientationUp];
        CFRelease(ref);
    }
    if (imageSource) {
        CFRelease(imageSource);
    }
    return self;
}


- (id)initWithCGImageSource:(CGImageSourceRef)imageSource scale:(CGFloat)scale :(NSData *)data
{
    self = [super init];
    if (!imageSource || !self) {
        return nil;
    }
    NSUInteger numberOfFrames = CGImageSourceGetCount(imageSource);
    
    NSDictionary *imageProperties = CFBridgingRelease(CGImageSourceCopyProperties(imageSource, NULL));
    NSDictionary *gifProperties = [imageProperties objectForKey:(NSString *)kCGImagePropertyGIFDictionary];
    
    self.frameDurations = (NSTimeInterval *)malloc(numberOfFrames  * sizeof(NSTimeInterval));
    self.loopCount = [gifProperties[(NSString *)kCGImagePropertyGIFLoopCount] unsignedIntegerValue];
    self.images = [NSMutableArray arrayWithCapacity:numberOfFrames];
    
    CFDataRef dataref = CFDataCreate(CFAllocatorGetDefault(), [data bytes], data.length);
    CGFloat gifWidth;
    CGFloat gifHeight;
    getFrameInfo(dataref, self.images, self.frameDurations, _totalDuration, &gifWidth, &gifHeight);
    CFRelease(dataref);
    //CFTimeInterval start = CFAbsoluteTimeGetCurrent();
    // Load first frame
    NSUInteger num = MIN(_prefetchedNum, numberOfFrames);
    for (NSUInteger i=0; i<num; i++) {
        CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
        [self.images replaceObjectAtIndex:i withObject:[UIImage imageWithCGImage:image scale:scale orientation:UIImageOrientationUp]];
        CFRelease(image);
    }
    
    _scale = scale;
    readFrameQueue = dispatch_queue_create("com.ronnie.gifreadframe", DISPATCH_QUEUE_SERIAL);
    
    return self;
}

- (UIImage*)getFrameWithIndex:(NSUInteger)idx
{
    UIImage* frame = nil;
    @synchronized(self.images) {
        frame = self.images[idx];
    }
    if(!frame) {
        CGImageRef image = CGImageSourceCreateImageAtIndex(_imageSourceRef, idx, NULL);
        frame = [UIImage imageWithCGImage:image scale:_scale orientation:UIImageOrientationUp];
        CFRelease(image);
    }
    if(self.images.count > _prefetchedNum) {
        if(idx != 0) {
            [self.images replaceObjectAtIndex:idx withObject:[NSNull null]];
        }
        NSUInteger nextReadIdx = (idx + _prefetchedNum);
        for(NSUInteger i=idx+1; i<=nextReadIdx; i++) {
            NSUInteger _idx = i%self.images.count;
            if([self.images[_idx] isKindOfClass:[NSNull class]]) {
                dispatch_async(readFrameQueue, ^{
                    CGImageRef image = CGImageSourceCreateImageAtIndex(_imageSourceRef, _idx, NULL);
                    @synchronized(self.images) {
                        [self.images replaceObjectAtIndex:_idx withObject:[UIImage imageWithCGImage:image scale:_scale orientation:UIImageOrientationUp]];
                    }
                    CFRelease(image);
                });
            }
        }
    }
    return frame;
}

#pragma mark - Compatibility methods

- (CGSize)size
{
    if (self.images.count) {
        return [[self.images objectAtIndex:0] size];
    }
    return [super size];
}

- (CGImageRef)CGImage
{
    if (self.images.count) {
        return [[self.images objectAtIndex:0] CGImage];
    } else {
        return [super CGImage];
    }
}

- (UIImageOrientation)imageOrientation
{
    if (self.images.count) {
        return [[self.images objectAtIndex:0] imageOrientation];
    } else {
        return [super imageOrientation];
    }
}

- (CGFloat)scale
{
    if (self.images.count) {
        return [(UIImage *)[self.images objectAtIndex:0] scale];
    } else {
        return [super scale];
    }
}

- (NSTimeInterval)duration
{
    return self.images ? *self.totalDuration : [super duration];
}

- (void)dealloc {
    if(_imageSourceRef) {
        CFRelease(_imageSourceRef);
    }
    free(_frameDurations);
    free(_totalDuration);
    if (_incrementalSource) {
        CFRelease(_incrementalSource);
    }
}

@end