//
//  XTAudioPlayer.h
//  LoadingAndSinging
//
//  Created by XTShow on 2018/2/9.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "XTPlayerConfiguration.h"

typedef void(^PlayCompleteBlock)(NSError *error);

@interface XTAudioPlayer : NSObject

/**
 Configure properties for player,such as AVAudioSessionCategory, rotate angle for playerLayer etc.
 */
@property (nonatomic,strong) XTPlayerConfiguration *config;


/**
 Initialized a player.

 @return An single instance player.
 */
+ (instancetype _Nonnull )sharePlayer;


/**
 Playback an audio with an url string which can be a url for a media file, or a path for a media file in sandbox or boundle, and set cache path for the media file, the playCompleteBlock will be executed when complete the play.

 @param urlStr Url for a media file, or a path for a media file in sandbox or boundle
 @param cachePath Cache path for the media file, if you set it nil, the file will cache in a default path
 @param playCompleteBlock The block to execute after the play has been end. If the play is fail to end, there is a error in the block
 */
- (void)playWithUrlStr:(nonnull NSString *)urlStr cachePath:(nullable NSString *)cachePath completion:(PlayCompleteBlock)playCompleteBlock;


/**
 Playback a video with an visible layer.

 @param urlStr Url for a media file, or a path for a media file in sandbox or boundle
 @param cachePath Cache path for the media file, if you set it nil, the file will cache in a default path
 @param videoFrame The frame for the visible layer
 @param bgView The super view for the visible layer
 @param playCompleteBlock The block to execute after the play has been end. If the play is fail to end, there is a error in the block
 */
- (void)playWithUrlStr:(nonnull NSString *)urlStr cachePath:(nullable NSString *)cachePath videoFrame:(CGRect)videoFrame inView:(UIView *)bgView completion:(PlayCompleteBlock)playCompleteBlock;


/**
 Cotinue playback of the current item.
 */
- (void)restart;

/**
 Pauses playback of the current item.
 */
- (void)pause;

/**
 Cancel playback of the current item and all the remaining network requests of the current item.
 */
- (void)cancel;

/**
 完全销毁Player，释放掉XTAudioPlayer所占用的全部内存，如非特殊需要，不建议使用。
 */

/**
 Completely destroy the Player, free up all the memory occupied by the XTAudioPlayer. If not special needs, it is not recommended.
 */
+ (void)completeDealloc;
@end
