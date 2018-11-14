//
//  XTDataManager.m
//  LoadingAndSinging
//
//  Created by XTShow on 2018/2/13.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import "XTDataManager.h"

static NSString *playerDirectory = @"XTAudioPlayer";
static NSString *currentUrlStr;

@interface XTDataManager ()

@property (nonatomic,copy) NSString *tmpPath;
@property (nonatomic,copy) NSString *cachePath;
@property (nonatomic,strong) NSFileHandle *writeFileHandle;
@property (nonatomic,strong) NSFileHandle *readFileHandle;
@property (nonatomic,assign) BOOL closeFile;
@property (nonatomic,assign) NSUInteger cachedDataLength;
@end

@implementation XTDataManager

#pragma mark - 初始化

- (instancetype)initWithUrlStr:(nonnull NSString *)urlStr cachePath:(nullable NSString *)cachePath {

    self = [super init];
    if (self) {
        BOOL isCreateSuccess = [self createTmpPathWithUrlStr:urlStr CachePath:cachePath];
        
        if (!isCreateSuccess) {
            NSLog(@"[XTAudioPlayer]%s:create File Path Fail",__func__);
            return nil;
        }
    }
    return self;
}

-(void)dealloc{
    [self.writeFileHandle closeFile];
    [self.readFileHandle closeFile];
}

#pragma mark - Public API

+ (NSString *)checkCachedWithUrl:(NSString *)urlStr {
    
    if ([urlStr hasPrefix:@"/var"] || [urlStr hasPrefix:@"/Users"]) {
        return urlStr;
    }
    
    NSURL *url = [NSURL URLWithString:urlStr];
    NSString *fileType = url.pathExtension;
    NSString *urlHash = [NSString stringWithFormat:@"%lu",(unsigned long)urlStr.hash];
    
    NSString *cachePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:playerDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",urlHash,fileType]];

    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        return cachePath;
    }else{
        return nil;
    }

}

+ (NSString *)checkCachedWithFilePath:(NSString *)filePath {

    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return filePath;
    }else{
        return nil;
    }
    
}

- (void)addCacheData:(NSData *)data ForRange:(NSRange)range{
    @synchronized(self.writeFileHandle){
        @try{
            if (!self.closeFile) {
                [self.writeFileHandle seekToFileOffset:range.location];
                [self.writeFileHandle writeData:data];
                [self.writeFileHandle synchronizeFile];
                self.cachedDataLength += data.length;
                if (self.cachedDataLength >= self.contentLength) {
                    [self copyFileToCachePath];
                }
            }
        }@catch(NSException *exception){
            NSLog(@"[XTAudioPlayer]%s:%@",__func__,exception);
        }
    }
}

- (NSData *)readCacheDataInRange:(NSRange)range{
    @synchronized(self.readFileHandle){
            [self.readFileHandle seekToFileOffset:range.location];
            return [self.readFileHandle readDataOfLength:range.length];
    }
}

#pragma mark - 辅助方法
- (BOOL)createTmpPathWithUrlStr:(NSString *)urlStr CachePath:(NSString *)cachePath {
    
    //临时缓存文件地址
    NSString *playerTmpDire = [NSTemporaryDirectory() stringByAppendingPathComponent:playerDirectory];
    
    if (![self checkDirectoryPath:playerTmpDire]) return NO;

    NSURL *url = [NSURL URLWithString:urlStr];
    NSString *fileType = url.pathExtension;
    NSString *urlHash = [NSString stringWithFormat:@"%lu",(unsigned long)urlStr.hash];

    self.tmpPath = [playerTmpDire stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",urlHash,fileType]];
    
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.tmpPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.tmpPath error:&error];
        if (error) {
            NSLog(@"[XTAudioPlayer]%s:%@",__func__,error);
        }
    }

    if (![[NSFileManager defaultManager] createFileAtPath:self.tmpPath contents:nil attributes:nil]) return NO;
    
    //缓存文件地址
    if (cachePath) {
        
        NSString *userCustomCacheDire = cachePath.stringByDeletingLastPathComponent;
        
        if (![self checkDirectoryPath:userCustomCacheDire]) return NO;
        
        self.cachePath = cachePath;

    }else{
        
        NSString *playerCacheDire =  [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:playerDirectory];
        
        if (![self checkDirectoryPath:playerCacheDire]) return NO;
        
        self.cachePath = [playerCacheDire stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",urlHash,fileType]];
    }
    
    self.writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:self.tmpPath];
    self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:self.tmpPath];
    return YES;
}

/**
 校验文件夹路径是否存在，如果不存在则创建该文件夹
 */
- (BOOL)checkDirectoryPath:(NSString *)direPath {
    
    BOOL isDire = NO;
    if (!([[NSFileManager defaultManager] fileExistsAtPath:direPath isDirectory:&isDire] && isDire)) {
        NSError *error;
        BOOL isCreateSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:direPath withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error || !isCreateSuccess) {
            NSLog(@"[XTAudioPlayer]%s:%@",__func__,error);
            return NO;
        }
    }
    
    return YES;
}

- (void)copyFileToCachePath{
    
    [self.writeFileHandle closeFile];
    self.closeFile = YES;
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:self.tmpPath toPath:self.cachePath error:&error];
    if (error) {
        NSLog(@"[XTAudioPlayer]%s:%@",__func__,error);
    }else{
        self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:self.cachePath];
        if ([self.delegate respondsToSelector:@selector(fileDownloadAndSaveSuccess)]) {
            [self.delegate fileDownloadAndSaveSuccess];
        }
    }
    
}
@end
