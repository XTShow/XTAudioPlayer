//
//  XTRangeManager.m
//  LoadingAndSinging
//
//  Created by XTShow on 2018/2/13.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import "XTRangeManager.h"
#import "XTRangeModel.h"

static XTRangeManager *rangeManger;
static dispatch_once_t onceToken;

@interface XTRangeManager ()
/**
 已缓存的data的range的数组
 */
@property (nonatomic,strong) NSMutableArray *cachedRangeArray;
@property (nonatomic,copy) NSString *url;
@end

@implementation XTRangeManager

#pragma mark - 初始化
+ (instancetype)shareRangeManager {
    
    dispatch_once(&onceToken, ^{
        rangeManger = [[XTRangeManager alloc] init];
    });
    
    return rangeManger;
}

+ (void)completeDealloc{
    onceToken = 0;
    rangeManger = nil;
}

/**
 将loadingRequest拆分成 已缓存的部分 和 需要网络请求的部分
 */
- (NSMutableArray *)calculateRangeModelArrayForLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    
    if (![self.url isEqualToString:loadingRequest.request.URL.absoluteString]) {
        self.cachedRangeArray = [NSMutableArray array];
        self.url = loadingRequest.request.URL.absoluteString;
    }
    
    NSUInteger requestOffset = (NSUInteger)loadingRequest.dataRequest.requestedOffset;
    NSUInteger requestLength = (NSUInteger)loadingRequest.dataRequest.requestedLength;
    
    NSRange requestRange = NSMakeRange(requestOffset, requestLength);
    
    NSMutableArray *rangModelArray = [NSMutableArray array];
    
    if (self.cachedRangeArray.count == 0) {
        XTRangeModel *model = [[XTRangeModel alloc] initWithRequestType:XTRequestFromNet RequestRange:requestRange];
        [rangModelArray addObject:model];
    }else{
        
        //先处理loadingRequest和本地缓存有交集的部分
        NSMutableArray *cachedModelArray = [NSMutableArray array];
        
        [self.cachedRangeArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSRange cacheRange = [obj rangeValue];
            
            NSRange intersectionRange = NSIntersectionRange(cacheRange, requestRange);
            
            if (intersectionRange.length > 0) {
                XTRangeModel *model = [[XTRangeModel alloc] initWithRequestType:XTRequestFromCache RequestRange:intersectionRange];
                [cachedModelArray addObject:model];
            }
            
        }];
        
        //围绕交集，进行需要网络请求的range的拆解
        if (cachedModelArray.count == 0) {
            XTRangeModel *model = [[XTRangeModel alloc] initWithRequestType:XTRequestFromNet RequestRange:requestRange];
            [rangModelArray addObject:model];
        }else{
            
            [cachedModelArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if (idx == 0) {
                    
                    XTRangeModel *firstRangeModel = cachedModelArray[0];
                    if (firstRangeModel.requestRange.location > requestRange.location) {//在第一个cacheRange前还有一部分需要net请求
                        
                        XTRangeModel *model = [[XTRangeModel alloc] initWithRequestType:XTRequestFromNet RequestRange:NSMakeRange(requestRange.location, firstRangeModel.requestRange.location - requestRange.location)];
                        
                        [rangModelArray addObject:model];
                    }
                    [rangModelArray addObject:firstRangeModel];//注意此处的rangModelArray是最终的包含该loadingRequest的全部rangeModel的数组，因此不要忘记将刚才cachedModelArray中的model也添加进来，而且要注意顺序，依次添加
                    
                }else{
                    //除了首尾可能存在的两个（小于首个cachedModel 和 大于最后一个cachedModel）range，其他range都应该是夹在两个cachedModel之间的range，在此处处理
                    XTRangeModel *lastCachedRangeModel = cachedModelArray[idx - 1];
                    XTRangeModel *currentCachedRangeModel = cachedModelArray[idx];
                    
                    NSUInteger startOffst = lastCachedRangeModel.requestRange.location + lastCachedRangeModel.requestRange.length;
                    
                    XTRangeModel *model = [[XTRangeModel alloc] initWithRequestType:XTRequestFromNet RequestRange:NSMakeRange(startOffst, currentCachedRangeModel.requestRange.location - startOffst)];
                    
                    [rangModelArray addObject:model];
                    [rangModelArray addObject:currentCachedRangeModel];
                }
                
                if (idx == cachedModelArray.count - 1) {//最后一个cachedRange后面可能还有一段需要网络请求
                    
                    XTRangeModel *lastRangeModel = cachedModelArray.lastObject;
                    if (requestRange.location + requestRange.length > lastRangeModel.requestRange.location + lastRangeModel.requestRange.length) {

                        NSUInteger lastCacheRangeModelEndOffset = lastRangeModel.requestRange.location + lastRangeModel.requestRange.length;
                        
                        XTRangeModel *model = [[XTRangeModel alloc] initWithRequestType:XTRequestFromNet RequestRange:NSMakeRange(lastCacheRangeModelEndOffset, requestRange.location + requestRange.length - lastCacheRangeModelEndOffset)];
                        [rangModelArray addObject:model];
                    }
                }
            }];
        }
    }

    return [rangModelArray mutableCopy];
    
}


/**
 记录已缓存的data的range并进行range合并
 */
-(void)addCacheRange:(NSRange)newRange{
    
    @synchronized(self.cachedRangeArray){
        
        if (self.cachedRangeArray.count > 0) {
            
            NSMutableArray *shouldRemoveArray = [NSMutableArray array];
            
            __block BOOL hasIntersection = NO;
            __block NSInteger firstMergeIndex = 0;
            //一、先处理有交集的range
            [self.cachedRangeArray enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSRange cacheRange = [obj rangeValue];
                
                NSRange intersectionRange = NSIntersectionRange(cacheRange, newRange);
                
                if (intersectionRange.length > 0) {//如果和已缓存range有交集的话，必能与其融为一体，融合后代替其位置
                    if (!hasIntersection) {//第一次出现有交集的，直接融合替换即可
                        hasIntersection = YES;
                        firstMergeIndex = idx;
                        NSUInteger startOffset = MIN(newRange.location, cacheRange.location);
                        NSUInteger mergeLength = MAX(newRange.location + newRange.length, cacheRange.location + cacheRange.length) - startOffset;
                        NSRange mergeRange = NSMakeRange(startOffset, mergeLength);
                        [self.cachedRangeArray replaceObjectAtIndex:idx withObject:[NSValue valueWithRange:mergeRange]];
                    }else{
                        //有时newRange可能和多个cacheRange有交集，那就都合到一起
                        NSRange lastMergedRange = [self.cachedRangeArray[firstMergeIndex] rangeValue];//提出第一个被merge的range
                        
                        NSUInteger startOffset = lastMergedRange.location;
                        NSUInteger mergeLength = MAX(lastMergedRange.location + lastMergedRange.length, cacheRange.location + cacheRange.length) - startOffset;
                        
                        NSRange mergeRange = NSMakeRange(startOffset, mergeLength);
                        [self.cachedRangeArray replaceObjectAtIndex:firstMergeIndex withObject:[NSValue valueWithRange:mergeRange]];
                        
                        [shouldRemoveArray addObject:[self.cachedRangeArray objectAtIndex:idx]];
                    }
                }
                
            }];
            
            
            for (id obj in shouldRemoveArray) {
                [self.cachedRangeArray removeObject:obj];
            }
            shouldRemoveArray = [NSMutableArray array];
            
            //二、处理没有任何交集的range（注意首尾相接的情况）
            [self.cachedRangeArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if (![shouldRemoveArray containsObject:obj]) {//此时shouldRemoveArray中包含的是已经合并过的，就不再做处理
                    
                    NSRange cacheRange = [obj rangeValue];
                    
                    if (newRange.location < cacheRange.location) {//newRange比cacheRange小（此处的小为range.location的大小，下文一致）
                        if (newRange.location + newRange.length == cacheRange.location) {//new与cache首尾相接
                            [self.cachedRangeArray replaceObjectAtIndex:idx withObject:[NSValue valueWithRange:NSMakeRange(newRange.location, newRange.length + cacheRange.length)]];
                        }else{
                            [self.cachedRangeArray insertObject:[NSValue valueWithRange:newRange] atIndex:idx];
                        }
                        
                        *stop = YES;//被合并或加入cachedRangeArray就不需要继续遍历其他cacheRange与其比较了
                    }else{//newRange比cacheRange大
                        
                        if (cacheRange.location + cacheRange.length == newRange.location) {//当new在cache之后时，有一种特殊情况就是首尾相接，那么此时仍要做合并处理

                            BOOL hasHandle = NO;
                            
                            if (idx + 1 < self.cachedRangeArray.count) {//如果当前cacheRange不是self.cachedRangeArray中的最后一个元素时（保证cachedRangeArray中有下一位）
                                NSRange nextRange = [self.cachedRangeArray[idx + 1] rangeValue];
                                if (newRange.location + newRange.length == nextRange.location) {//正好newRange的尾又与下一个的头相接（最多只能与两个cachedRange首尾相接，因为newRange和此时的所有cacheRange都没有交集，第一个循环处理已经把有交集的都合并了）

                                    hasHandle = YES;
                                    [self.cachedRangeArray replaceObjectAtIndex:idx withObject:[NSValue valueWithRange:NSMakeRange(cacheRange.location, cacheRange.length + newRange.length + nextRange.length)]];
                                    [shouldRemoveArray addObject:self.cachedRangeArray[idx + 1]];
                                }
                            }
                            
                            if (!hasHandle) {//如果只是单纯的一个首尾相接，则执行此处
                                [self.cachedRangeArray replaceObjectAtIndex:idx withObject:[NSValue valueWithRange:NSMakeRange(cacheRange.location, cacheRange.length + newRange.length)]];
                            }
                            
                            *stop = YES;
                        }else{//首尾不相接
                            if (idx == self.cachedRangeArray.count - 1) {//在cachedRange后且不首尾相接的newRange，正常是交给下一个cachedRange处理的，但如果是最后一个cachedRange，则没有下一个，直接在此做判断

                                [self.cachedRangeArray addObject:[NSValue valueWithRange:newRange]];
                                *stop = YES;
                            }
                        }
                    }
                }
                
            }];
            
            for (id obj in shouldRemoveArray) {
                [self.cachedRangeArray removeObject:obj];
            }
            
        }else{
            [self.cachedRangeArray addObject:[NSValue valueWithRange:newRange]];
        }
    }
    
}
@end
