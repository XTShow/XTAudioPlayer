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
UITableViewDataSource,
XTAudioPlayerDelegate
>

@property (nonatomic,strong) NSArray *urlArray;
@property (nonatomic,assign) NSTimeInterval lastSuspendTime;
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
                               @"http://vfx.mtime.cn/Video/2018/05/15/mp4/180515210431224977.mp4",
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

//1.===Playback a audio.
//    [[XTAudioPlayer sharePlayer] playWithUrlStr:self.urlArray[indexPath.row] cachePath:nil completion:nil];
    
    
//2.===Configure properties for XTAudioPlayer and playback a video.
//    [XTAudioPlayer sharePlayer].config.playerLayerRotateAngle = M_PI_2;
//    [XTAudioPlayer sharePlayer].config.playerLayerVideoGravity = AVLayerVideoGravityResizeAspectFill;
//    [XTAudioPlayer sharePlayer].config.audioSessionCategory = AVAudioSessionCategoryPlayback;
//
//    [[XTAudioPlayer sharePlayer] playWithUrlStr:self.urlArray[indexPath.row] cachePath:nil videoFrame:[UIScreen mainScreen].bounds inView:self.view completion:nil];
    
    
//3.===Playback a video by AVPlayerViewController
    [XTAudioPlayer sharePlayer].delegate = self;
    AVPlayerViewController *playerVC = [[XTAudioPlayer sharePlayer] playByPlayerVCWithUrlStr:self.urlArray[indexPath.row] cachePath:nil completion:nil];

    [self presentViewController:playerVC animated:NO completion:nil];
    
}

#pragma mark - XTAudioPlayerDelegate
-(void)suspendForLoadingDataWithPlayer:(AVPlayer *)player{
    //Do something when the player is suspended for loading data...
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSinceNow];
    self.lastSuspendTime = currentTime;
}

-(void)activeToContinueWithPlayer:(AVPlayer *)player{
    //The player is ready to continue...
    /**
     It is not recommended to continue play the player immediately, because this selector will be called when the player only buffer a little data, so this selector will be called very frequently.
     Therefore it is recommended to play the player after buffering several seconds.
     */
    dispatch_after(dispatch_time(self.lastSuspendTime, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [player play];
    });
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
    //[[XTAudioPlayer sharePlayer] completeDealloc];// Completely destroy the Player, free up all the memory occupied by the XTAudioPlayer. If not special needs, it is not recommended.(完全销毁，释放掉XTAudioPlayer所占用的全部内存，如非特殊需要，不建议使用。)
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
