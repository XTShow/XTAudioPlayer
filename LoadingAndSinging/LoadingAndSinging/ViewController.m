//
//  ViewController.m
//  LoadingAndSinging
//
//  Created by XTShow on 2018/2/9.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import "ViewController.h"
#import "PlayerVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [btn setCenter:self.view.center];
    [btn setTitle:@"GO" forState:UIControlStateNormal];
    [btn setBackgroundColor:[UIColor lightGrayColor]];
    btn.layer.masksToBounds = YES;
    btn.layer.cornerRadius = 5;
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(pushToPlayerVC) forControlEvents:UIControlEventTouchUpInside];
}

- (void)pushToPlayerVC {
    [self presentViewController:[PlayerVC new] animated:YES completion:nil];
}

@end
