//
//  ViewController.m
//  NetImage
//
//  Created by liyuchang on 15-1-28.
//  Copyright (c) 2015年 com.Vacn. All rights reserved.
//

#import "ViewController.h"
#import "URLImageView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    URLImageView *image = [[URLImageView alloc] initWithFrame:self.view.bounds];
    [image urlImage:@"http://e.hiphotos.baidu.com/image/w%3D310/sign=f72912cfb0119313c743f9b155390c10/a6efce1b9d16fdfa0b3b1ae3b68f8c5494ee7b6c.jpg"];
    [self.view addSubview:image];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
