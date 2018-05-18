# XTAudioPlayer
### Playback an audio/video while caching the media file.

[中文说明](https://www.jianshu.com/p/c157476474f1)

### Features
- Playback an audio/video with an url or a path for a media file in sandbox or boundle, the file will be cached automatically, you can specified the cache path for the media file, the playCompleteBlock will be executed when complete the play;
- If you playback a video, there are two ways:
        1.you can only create a visible layer which can be specified the frame and super view;
        2.you can playback by AVPlayerViewController;
- Configure properties for player,such as AVAudioSessionCategory, rotate angle for playerLayer etc.;
- The delegate methods will be called when the player is suspended because of the buffer is empty or the player is ready to continue to playback;
- Restart, pause and cancel the player.

### How To Get Started
1. Download the XTAudioPlayer zip and try out the example app;
2. Drag the folder "XTAudioPlayer" which in the project folder "LoadingAndSinging" into your project;

### How To Use

````
#import "XTAudioPlayer.h"

//Configure properties for XTAudioPlayer and playback a video.
[XTAudioPlayer sharePlayer].config.playerLayerRotateAngle = M_PI_2;
[XTAudioPlayer sharePlayer].config.playerLayerVideoGravity = AVLayerVideoGravityResizeAspectFill;
[XTAudioPlayer sharePlayer].config.audioSessionCategory = AVAudioSessionCategoryPlayback;

[[XTAudioPlayer sharePlayer] playWithUrlStr:self.urlArray[indexPath.row] cachePath:nil videoFrame:[UIScreen mainScreen].bounds inView:self.view completion:^(NSError *error) {
        //code what you want to code
}];

//Playback a audio.
[[XTAudioPlayer sharePlayer] playWithUrlStr:self.urlArray[indexPath.row] cachePath:nil completion:^(NSError *error) {
        //code what you want to code
}];

//Playback a video by AVPlayerViewController
[XTAudioPlayer sharePlayer].delegate = self;
AVPlayerViewController *playerVC = [[XTAudioPlayer sharePlayer] playByPlayerVCWithUrlStr:self.urlArray[indexPath.row] cachePath:nil completion:nil];
[self presentViewController:playerVC animated:NO completion:nil];

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
````

#### Api Document
###### Playback an audio
````
/**
 Playback an audio with an url string which can be a url for a media file, or a path for a media file in sandbox or boundle, and set cache path for the media file, the playCompleteBlock will be executed when complete the play.

 @param urlStr Url for a media file, or a path for a media file in sandbox or boundle
 @param cachePath Cache path for the media file, if you set it nil, the file will cache in a default path
 @param playCompleteBlock The block to execute after the play has been end. If the play is fail to end, there is a error in the block
 */
- (void)playWithUrlStr:(nonnull NSString *)urlStr cachePath:(nullable NSString *)cachePath completion:(PlayCompleteBlock)playCompleteBlock;

````

###### Playback a video with an visible layer 
````
/**
 Playback a video with an visible layer.

 @param urlStr Url for a media file, or a path for a media file in sandbox or boundle
 @param cachePath Cache path for the media file, if you set it nil, the file will cache in a default path
 @param videoFrame The frame for the visible layer
 @param bgView The super view for the visible layer
 @param playCompleteBlock The block to execute after the play has been end. If the play is fail to end, there is a error in the block
 */
- (void)playWithUrlStr:(nonnull NSString *)urlStr cachePath:(nullable NSString *)cachePath videoFrame:(CGRect)videoFrame inView:(UIView *)bgView completion:(PlayCompleteBlock)playCompleteBlock;

````

###### Playback a video by AVPlayerViewController 
````
/**
 Playback a video by AVPlayerViewController.

 @param urlStr Url for a media file, or a path for a media file in sandbox or boundle
 @param cachePath Cache path for the media file, if you set it nil, the file will cache in a default path
 @param playCompleteBlock The block to execute after the play has been end. If the play is fail to end, there is a error in the block
 @return An AVPlayerViewController object which playback this video
 */
- (AVPlayerViewController *)playByPlayerVCWithUrlStr:(nonnull NSString *)urlStr cachePath:(nullable NSString *)cachePath completion:(PlayCompleteBlock)playCompleteBlock;
````

###### XTAudioPlayerDelegate
````
@protocol XTAudioPlayerDelegate<NSObject>

@optional

/**
 Tells the delegate the player is suspended because of the buffer is empty.

 @param player The AVPlayer object informing the delegate of this event.
 */
-(void)suspendForLoadingDataWithPlayer:(AVPlayer *)player;


/**
 Tells the delegate the player is ready to continue to playback.

 @param player The AVPlayer object informing the delegate of this event.
 */
-(void)activeToContinueWithPlayer:(AVPlayer *)player;

@end

````
