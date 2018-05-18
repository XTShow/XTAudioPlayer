//
//  XTDownloader.h
//  LoadingAndSinging
//
//  Created by XTShow on 2018/2/13.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "XTDataManager.h"

@interface XTDownloader : NSObject

@property (nonatomic,strong) AVAssetResourceLoadingRequest *loadingRequest;

- (instancetype)initWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest RangeModelArray:(NSMutableArray *)rangeModelArray UrlScheme:(NSString *)urlScheme InDataManager:(XTDataManager *)dataManager;
- (void)cancel;
@end
