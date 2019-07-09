//
//  XTRangeManager.h
//  LoadingAndSinging
//
//  Created by XTShow on 2018/2/13.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface XTRangeManager : NSObject

/**
 初始化方法
 */
+ (instancetype)shareRangeManager;
+ (void)completeDealloc;
/**
 将loadingRequest拆分成 已缓存的部分 和 需要网络请求 的部分,封装成rangeModel数组返回
 @param loadingRequest 需要处理的loadingRequest
 @return 处理后的rangeModel数组
 */
-(NSMutableArray *)calculateRangeModelArrayForLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest;

-(void)addCacheRange:(NSRange)newRange;
@end
