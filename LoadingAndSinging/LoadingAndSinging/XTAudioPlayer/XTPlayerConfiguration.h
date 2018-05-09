//
//  XTPlayerConfiguration.h
//  LoadingAndSinging
//
//  Created by XTShow on 2018/5/8.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface XTPlayerConfiguration : NSObject

/**
 The Category of AVAudioSession, default is AVAudioSessionCategoryPlayback.
 */
@property (nonatomic,copy) NSString *audioSessionCategory;

/**
 The rotation angle for the playerLayer.
 */
@property (nonatomic,assign) CGFloat playerLayerRotateAngle;

/**
 A value that specifies how the video is displayed within a player layer’s bounds.
 The video gravity determines how the video content is scaled or stretched within the player layer’s bounds. 
 */
@property (nonatomic,copy) AVLayerVideoGravity playerLayerVideoGravity;

@end
