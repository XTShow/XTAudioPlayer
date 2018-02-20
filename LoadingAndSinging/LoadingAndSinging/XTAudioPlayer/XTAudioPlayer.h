//
//  XTAudioPlayer.h
//  LoadingAndSinging
//
//  Created by XTShow on 2018/2/9.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XTAudioPlayer : NSObject

/**
 AVAudioSession的Category，直接传入系统原始值即可（默认为AVAudioSessionCategoryPlayback）
 */
@property (nonatomic,copy) NSString * _Nonnull audioSessionCategory;

/**
 初始化
 */
+ (instancetype _Nonnull )sharePlayer;

/**
 播放音频并设置沙盒缓存路径
 @param urlStr :资源url字符串
 @param cachePath :资源文件的沙盒缓存路径
 */
- (void)playWithUrlStr:(nonnull NSString *)urlStr cachePath:(nullable NSString *)cachePath;

- (void)restart;
- (void)pause;
- (void)cancel;
/**
 完全销毁，释放掉XTAudioPlayer所占用的全部内存，如非特殊需要，不建议使用。
 */
+ (void)completeDealloc;
@end
