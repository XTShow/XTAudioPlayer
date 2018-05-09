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
    
    //Prepare the file in sandbox
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *itemPath = [documentPath stringByAppendingPathComponent:@"ForElise.mp3"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:itemPath]) {
        NSString *mp3Path = [[NSBundle mainBundle] pathForResource:@"ForElise" ofType:@"mp3"];
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:mp3Path toPath:[documentPath stringByAppendingPathComponent:@"ForElise.mp3"] error:&error];
        if (error) {
            NSLog(@"%@",error);
        }
    }
}

- (void)pushToPlayerVC {
    [self presentViewController:[PlayerVC new] animated:YES completion:nil];
}

@end
