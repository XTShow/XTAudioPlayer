//
//  XTAudioPlayer.m
//  LoadingAndSinging
//
//  Created by XTShow on 2018/2/9.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import "XTAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "XTDataManager.h"
#import "XTRangeManager.h"
#import "XTDownloader.h"

static XTAudioPlayer *audioPlayer = nil;
static dispatch_once_t onceToken;
static NSString *XTCustomScheme = @"XTShow";

@interface XTAudioPlayer ()
<
AVAssetResourceLoaderDelegate
>

@property (nonatomic,copy) NSString *originalUrlStr;
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
@property (nonatomic,strong) XTDataManager *dataManager;
@property (nonatomic,strong) XTDownloader *lastToEndDownloader;
@property (nonatomic,strong) NSMutableArray *nonToEndDownloaderArray;
@property (nonatomic,copy) PlayCompleteBlock playCompleteBlock;
@end

@implementation XTAudioPlayer

-(XTPlayerConfiguration *)config{
    if (!_config) {
        _config = [XTPlayerConfiguration new];
    }
    return _config;
}

#pragma mark - 生命周期
+ (instancetype)sharePlayer {
    
    dispatch_once(&onceToken, ^{
        audioPlayer = [XTAudioPlayer new];
    });
    return audioPlayer;
}

-(void)dealloc{
    NSLog(@"[XTAudioPlayer]%@:%s",self,__func__);
}

- (void)playWithUrlStr:(nonnull NSString *)urlStr cachePath:(nullable NSString *)cachePath completion:(PlayCompleteBlock)playCompleteBlock{
    
    [self cancel];
    
    self.originalUrlStr = urlStr;
    
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:self.config.audioSessionCategory?self.config.audioSessionCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        NSLog(@"[XTAudioPlayer]%s:%@",__func__,error);
    }
    
    if ([XTDataManager checkCachedWithUrl:urlStr]) {
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[XTDataManager checkCachedWithUrl:urlStr]] options:nil];
        
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];

        self.player = player;
        [player play];
    }else{
        
        XTDataManager *dataManager = [[XTDataManager alloc] initWithUrlStr:urlStr cachePath:cachePath];
        
        if (dataManager) {
            
            self.dataManager = dataManager;
            //此处需要将原始的url的协议头处理成系统无法处理的自定义协议头，此时才会进入AVAssetResourceLoaderDelegate的代理方法中
            NSURL *audioUrl = [self handleUrl:urlStr];
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:audioUrl options:nil];
            //为asset.resourceLoader设置代理对象
            [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
            
            AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
            self.player = player;
            
            //决定音频是否马上开始播放的关键性参数！！！
            if (@available(iOS 10.0, *)) {
                player.automaticallyWaitsToMinimizeStalling = NO;
            }
            
            [player play];
        }
        
    }
    
    if (self.player) {
        self.playCompleteBlock = playCompleteBlock;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playToEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failToEnd:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    }

}

- (void)playWithUrlStr:(nonnull NSString *)urlStr cachePath:(nullable NSString *)cachePath videoFrame:(CGRect)videoFrame inView:(UIView *)bgView completion:(PlayCompleteBlock)playCompleteBlock{
    
    [self playWithUrlStr:urlStr cachePath:cachePath completion:playCompleteBlock];
    
    if ((!CGRectEqualToRect(videoFrame, CGRectZero)) & (bgView != nil)) {
        
        if (self.player) {
            AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
            self.playerLayer = playerLayer;
            playerLayer.transform = CATransform3DRotate(CATransform3DIdentity, self.config.playerLayerRotateAngle?self.config.playerLayerRotateAngle:0, 0, 0, 1);
            playerLayer.videoGravity = self.config.playerLayerVideoGravity?self.config.playerLayerVideoGravity:AVLayerVideoGravityResizeAspect;
            playerLayer.frame = videoFrame;//注意此处三者间的顺序
            [bgView.layer addSublayer:playerLayer];
        }
    }
}

- (void)restart {
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)cancel {
    self.player = nil;
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.dataManager = nil;
    [self.lastToEndDownloader cancel];
    self.lastToEndDownloader = nil;
    for (XTDownloader *downloader in self.nonToEndDownloaderArray) {
        [downloader cancel];
    }
}

+ (void)completeDealloc{
    [XTRangeManager completeDealloc];
    onceToken = 0;
    audioPlayer = nil;
}

#pragma mark - AVAssetResourceLoaderDelegate
-(BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
    [self handleLoadingRequest:loadingRequest];
    return YES;
}

#pragma mark - 播放状态
-(void)playToEnd{
    [self cancel];
    if (self.playCompleteBlock) {
        self.playCompleteBlock(nil);
    }
}

-(void)failToEnd:(NSNotification *)noti{
    [self cancel];
    NSError *error = noti.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
    if (self.playCompleteBlock) {
        self.playCompleteBlock(error);
    }
}

#pragma mark - 逻辑方法
- (void)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    
    //取消上一个requestsAllDataToEndOfResource的请求
    if (loadingRequest.dataRequest.requestsAllDataToEndOfResource) {
        if (self.lastToEndDownloader) {
            [self.lastToEndDownloader cancel];
        }
    }
    
    XTRangeManager *rangeManager = [XTRangeManager shareRangeManager];
    //将当前loadingRequest根据本地是否已缓存拆分成本多个rangeModel
    NSMutableArray *rangeModelArray = [rangeManager calculateRangeModelArrayForLoadingRequest:loadingRequest];
    
    NSString *urlScheme = [NSURL URLWithString:self.originalUrlStr].scheme;
    //根据loadingRequest和rangeModel进行下载和数据回调
    XTDownloader *downloader = [[XTDownloader alloc] initWithLoadingRequest:loadingRequest RangeModelArray:rangeModelArray UrlScheme:urlScheme InDataManager:self.dataManager];
    
    if (loadingRequest.dataRequest.requestsAllDataToEndOfResource) {
        self.lastToEndDownloader = downloader;
    }else{
        if (!self.nonToEndDownloaderArray) {//对于不是requestsAllDataToEndOfResource的请求也要收集，在取消当前请求时要一并取消掉
            self.nonToEndDownloaderArray = [NSMutableArray array];
        }
        [self.nonToEndDownloaderArray addObject:downloader];
    }
    
}

#pragma mark - 工具方法
- (NSURL *)handleUrl:(NSString *)urlStr{
    
    if (!urlStr) {
        return nil;
    }
    
    NSURL *originalUrl = [NSURL URLWithString:urlStr];
    
    NSURL *useUrl = [NSURL URLWithString:[urlStr stringByReplacingOccurrencesOfString:originalUrl.scheme withString:XTCustomScheme]];

    return useUrl;
}

@end
