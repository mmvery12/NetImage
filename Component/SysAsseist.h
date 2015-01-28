//
//  SysAsseist.h
//  FrameWork
//
//  Created by liyuchang on 15-1-20.
//  Copyright (c) 2015年 com.Vacn. All rights reserved.
//

#ifndef FrameWork_SysAsseist_h
#define FrameWork_SysAsseist_h
#define ipad [[[UIDevice currentDevice] model] hasPrefix:@"ipad"]
#define iphone [[[UIDevice currentDevice] model] hasPrefix:@"iphone"]
#define ios8 [[[UIDevice currentDevice] systemVersion] floatValue]>=8
#define ios7 [[[UIDevice currentDevice] systemVersion] floatValue]>=7&&[[[UIDevice currentDevice] systemVersion] floatValue]<8
#define ios6 [[[UIDevice currentDevice] systemVersion] floatValue]>=6&&[[[UIDevice currentDevice] systemVersion] floatValue]<7


#ifndef DEF_STRONG

#if __has_feature(objc_arc)

#define DEF_STRONG strong

#else

#define DEF_STRONG retain

#endif

#endif

#ifndef DEF_WEAK

#if __has_feature(objc_arc_weak)

#define DEF_WEAK weak

#elif __has_feature(objc_arc)

#define DEF_WEAK unsafe_unretained

#else

#define DEF_WEAK assign

#endif

#endif


#if __has_feature(objc_arc)

#define DEF_AUTORELEASE(expression)

#define DEF_RELEASE(expression)

#define DEF_RETAIN(expression)

#else

#define DEF_AUTORELEASE(expression) [expression autorelease]

#define DEF_RELEASE(expression) [expression release]

#define DEF_RETAIN(expression) [expression retain]

#endif

#endif


#define DEBUG_Graphic

#define ShowBorder(view,color) [view showBorder:color]
@interface UIView (Border)
-(void)showBorder:(UIColor *)color;
@end

@implementation UIView (Border)
-(void)showBorder:(UIColor *)color
{
#ifdef DEBUG_Graphic
    self.layer.borderColor = color.CGColor;
    self.layer.borderWidth = 1.0f;
#endif
}
@end


