//
//  XTDownloader.m
//  LoadingAndSinging
//
//  Created by XTShow on 2018/2/13.
//  Copyright © 2018年 XTShow. All rights reserved.
//

#import "XTDownloader.h"
#import "XTRangeModel.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "XTRangeManager.h"

@interface XTDownloader ()
<
NSURLSessionDelegate
>

@property (nonatomic,strong) NSMutableArray *rangeModelArray;
@property (nonatomic,copy) NSString *urlScheme;
@property (nonatomic,strong) XTRangeModel *currentRangeModel;
@property (nonatomic,strong) XTDataManager *dataManager;
@property (nonatomic,strong) NSURLSession *URLSession;
@property (nonatomic,strong) NSURLSessionDataTask *dataTask;
@property (nonatomic,assign) NSUInteger receivedDataLength;
@end

@implementation XTDownloader

- (instancetype)initWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest RangeModelArray:(NSMutableArray *)rangeModelArray UrlScheme:(NSString *)urlScheme InDataManager:(XTDataManager *)dataManager;
{
    self = [super init];
    if (self) {
        self.loadingRequest = loadingRequest;
        self.rangeModelArray = rangeModelArray;
        self.urlScheme = urlScheme;
        self.dataManager = dataManager;
        [self handleLoadingRequest:loadingRequest ByRangeModelArray:rangeModelArray];
    }
    return self;
}

- (void)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest ByRangeModelArray:(NSMutableArray *)rangeModelArray {

    if (rangeModelArray.count > 0) {
        
        XTRangeModel *rangeModel = rangeModelArray.firstObject;
        self.currentRangeModel = rangeModel;
        self.receivedDataLength = 0;
        [rangeModelArray removeObjectAtIndex:0];
        
        if (rangeModel.requestType == XTRequestFromCache) {//本地已缓存，直接从沙盒中读取
            
            NSRange cacheRange = rangeModel.requestRange;
            NSData *cacheData = [self.dataManager readCacheDataInRange:cacheRange];
            [loadingRequest.dataRequest respondWithData:cacheData];
            
            [self handleLoadingRequest:loadingRequest ByRangeModelArray:rangeModelArray];
            
        }else{
            
            //将私有协议开头的请求处理成真正可用的url
            NSURL *url =[loadingRequest.request URL];
            NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
            urlComponents.scheme = self.urlScheme;
            
            if (!self.URLSession) {
                self.URLSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
            }

            NSMutableURLRequest *requset = [NSMutableURLRequest requestWithURL:[urlComponents URL]];
            requset.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
            
            NSString *requestRange = [NSString stringWithFormat:@"bytes=%lu-%lu",(unsigned long)rangeModel.requestRange.location,(unsigned long)(rangeModel.requestRange.location + rangeModel.requestRange.length - 1)];

            [requset setValue:requestRange forHTTPHeaderField:@"Range"];

            NSURLSessionDataTask *task = [self.URLSession dataTaskWithRequest:requset];
            self.dataTask = task;
            [task resume];
        }
        
    }else{//如果当前rangeModelArray.count <= 0,则说明当前loadingRequest已经处理完成，可做finish处理
        [self cancel];
    }
}

#pragma mark - NSURLSessionDataDelegate

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    //服务器首次响应请求时，返回的响应头，长度为2字节，包含该次网络请求返回的音频文件的内容信息，例如文件长度，类型等
    [self fillContentInfo:response];
    
    completionHandler(NSURLSessionResponseAllow);
}

//下载中，服务器返回数据时，调用该方法，可能会调用多次
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{

    [self handleReceiveData:data];
    
}

//请求完成调用该方法   请求失败则error有值
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (!error) {
        [self handleLoadingRequest:self.loadingRequest ByRangeModelArray:self.rangeModelArray];
    }else{
        NSLog(@"[XTAudioPlayer]%s:%@",__func__,error);
    }
}

#pragma mark - 逻辑方法
- (void)fillContentInfo:(NSURLResponse *)response {

    AVAssetResourceLoadingContentInformationRequest *contentInfoRequest = self.loadingRequest.contentInformationRequest;
    if (contentInfoRequest) {
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        //服务器端是否支持分段传输
        BOOL byteRangeAccessSupported = [httpResponse.allHeaderFields[@"Accept-Ranges"] isEqualToString:@"bytes"];
        
        //获取返回文件的长度
        long long contentLength = [[[httpResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"] lastObject] longLongValue];
        self.dataManager.contentLength = (NSUInteger)contentLength;
        //获取返回文件的类型
        NSString *mimeType = httpResponse.MIMEType;
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)mimeType, NULL);//此处需要引入<MobileCoreServices/MobileCoreServices.h>头文件
        NSString *contentTypeStr = CFBridgingRelease(contentType);

        contentInfoRequest.byteRangeAccessSupported = byteRangeAccessSupported;
        contentInfoRequest.contentLength = contentLength;
        contentInfoRequest.contentType = contentTypeStr;
    }

}

- (void)handleReceiveData:(NSData *)data {
    NSRange cacheRange = NSMakeRange(self.currentRangeModel.requestRange.location + self.receivedDataLength, data.length);
    [self.dataManager addCacheData:data ForRange:cacheRange];
    [[XTRangeManager shareRangeManager] addCacheRange:cacheRange];
    self.receivedDataLength += data.length;
    [self.loadingRequest.dataRequest respondWithData:data];
}

- (void)cancel {
    if (!self.loadingRequest.isFinished) {
        [self.loadingRequest finishLoading];
    }
    
    [self.dataTask cancel];//保证请求被立即取消，不然服务器还会继续返回一段数据，这段数据不会被利用到，浪费流量
    [self.URLSession invalidateAndCancel];
}
@end
