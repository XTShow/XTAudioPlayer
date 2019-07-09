//
//  XTRangeModel.h
//  LoadingAndSinging
//
//  Created by XTShow on 2018/2/13.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,XTRangeModelRequestType) {
    XTRequestFromCache = 0,
    XTRequestFromNet = 1
};

@interface XTRangeModel : NSObject

@property (nonatomic,readonly,assign) XTRangeModelRequestType requestType;
@property (nonatomic,readonly,assign) NSRange requestRange;

- (instancetype)initWithRequestType:(XTRangeModelRequestType)requestType RequestRange:(NSRange)requestRange;

@end
