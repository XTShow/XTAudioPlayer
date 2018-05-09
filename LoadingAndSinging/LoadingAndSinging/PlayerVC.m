//
//  PlayerVC.m
//  LoadingAndSinging
//
//  Created by XTShow on 2018/2/17.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import "PlayerVC.h"
#import "XTAudioPlayer.h"

@interface PlayerVC ()
<
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic,strong) NSArray *urlArray;
@end

@implementation PlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *audioBoundlePath = [[NSBundle mainBundle] pathForResource:@"ForElise" ofType:@"mp3"];
    NSString *audioSandboxPath = [documentPath stringByAppendingPathComponent:@"ForElise.mp3"];
    NSString *videoBoundlePath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];

    NSArray *audioUrlArray = @[
                               @"http://download.lingyongqian.cn/music/ForElise.mp3",
                               @"http://mpge.5nd.com/2018/2018-1-23/74521/1.mp3",
                               @"http://download.lingyongqian.cn/music/AdagioSostenuto.mp3",
                               @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4",
                               audioBoundlePath,
                               audioSandboxPath,
                               videoBoundlePath,
                               ];
    self.urlArray = audioUrlArray;
    
    CGFloat SWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat SHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat statusH = [UIApplication sharedApplication].statusBarFrame.size.height;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SWidth, 44 * audioUrlArray.count + statusH) style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    
    CGFloat btnY = SHeight - 66;
    
    UIButton *pauseBtn = [UIButton new];
    pauseBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    pauseBtn.layer.borderWidth = 2;
    [pauseBtn setTitle:@"Pause" forState:UIControlStateNormal];
    pauseBtn.frame = CGRectMake(0, btnY, SWidth/3, 66);
    [self.view addSubview:pauseBtn];
    [pauseBtn addTarget:self action:@selector(playerPause) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *restartBtn = [UIButton new];
    restartBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    restartBtn.layer.borderWidth = 2;
    [restartBtn setTitle:@"Restart" forState:UIControlStateNormal];
    restartBtn.frame = CGRectMake(SWidth/3, btnY, SWidth/3, 66);
    [self.view addSubview:restartBtn];
    [restartBtn addTarget:self action:@selector(playerRestart) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *dismissBtn = [UIButton new];
    dismissBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    dismissBtn.layer.borderWidth = 2;
    [dismissBtn setTitle:@"Dismiss" forState:UIControlStateNormal];
    dismissBtn.frame = CGRectMake(SWidth/3 * 2, btnY, SWidth/3, 66);
    [self.view addSubview:dismissBtn];
    [dismissBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
}

-(void)dealloc{
    NSLog(@"%@:%s",[self class],__func__);
}

#pragma mark - UITableViewDelegate & UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
    }
    cell.textLabel.text = self.urlArray[indexPath.row];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.urlArray.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    //Configure properties for XTAudioPlayer and playback a video.
//    [XTAudioPlayer sharePlayer].config.playerLayerRotateAngle = M_PI_2;
//    [XTAudioPlayer sharePlayer].config.playerLayerVideoGravity = AVLayerVideoGravityResizeAspectFill;
//    [XTAudioPlayer sharePlayer].config.audioSessionCategory = AVAudioSessionCategoryPlayback;
//
//    [[XTAudioPlayer sharePlayer] playWithUrlStr:self.urlArray[indexPath.row] cachePath:nil videoFrame:[UIScreen mainScreen].bounds inView:self.view completion:nil];
    
    //======
    
    //Playback a audio.
    [[XTAudioPlayer sharePlayer] playWithUrlStr:self.urlArray[indexPath.row] cachePath:nil completion:nil];
}

#pragma mark - Assistant Selector
- (void)playerPause {
    [[XTAudioPlayer sharePlayer] pause];
}

- (void)playerRestart {
    [[XTAudioPlayer sharePlayer] restart];
}

- (void)dismiss {
    [[XTAudioPlayer sharePlayer] cancel];
    //[XTAudioPlayer completeDealloc];// Completely destroy the Player, free up all the memory occupied by the XTAudioPlayer. If not special needs, it is not recommended.(完全销毁，释放掉XTAudioPlayer所占用的全部内存，如非特殊需要，不建议使用。)
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
