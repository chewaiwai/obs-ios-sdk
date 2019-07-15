// Copyright 2019 Huawei Technologies Co.,Ltd.
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License.  You may obtain a copy of the
// License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.


#import <Foundation/Foundation.h>
#import "OBSBaseNetworking.h"
#import "OBSBolts.h"
#import "OBSBaseConstDefinition.h"
#import "OBSBaseCategory.h"
#import "OBSBaseModel.h"
#import "OBSUtils.h"
#import "OBSServiceCredentialProvider.h"
#import "OBSLogging.h"
#import "OBSServiceBaseModel.h"
#import "objc/runtime.h"
#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#elif TARTGET_OS_MAC
    #import <AppKit/AppKit.h>
#endif

#pragma mark - Networking post processors

@implementation OBSRequestURLStringPostProcessor
+(void) processRequest:(OBSBaseNetworkingRequest *)request configuration:(OBSBaseConfiguration *const) configuration error:(NSError**) error{
    request.requestBaseURLString = configuration.url.absoluteString;
}
@end
@implementation OBSResouceParameterPostProcessor
+(void) processRequest:(OBSBaseNetworkingRequest *)request configuration:(OBSBaseConfiguration *const) configuration error:(NSError**) error{
    request.requestOriginalResourceString = request.requestResourceString;
    request.requestResourceString = [request.requestResourceString obs_stringSubstituteWithDict:request.requestResourceParameters];
}
@end

@implementation OBSHeaderUAPostProcessor

// 添加User-Agent字段
+(void) processRequest:(OBSBaseNetworkingRequest *)request configuration:(OBSBaseConfiguration *const) configuration error:(NSError**) error{
    [request.requestHeadersParameters setValue:[self getUserAgent] forKey:OBSHeadersUAKey];
}

+(NSString*) getUserAgent{
    return [[NSString alloc]initWithFormat:@"%@/%@",@"obs-sdk-iOS",OBSSDKVersion];
}
@end

@implementation OBSHeaderContentLengthPostProcessor
+(void)processRequest:(OBSBaseNetworkingRequest*) request configuration:(OBSBaseConfiguration *const) configuration error:(NSError**)  error{
    if([request.requestBodyData length] != 0){
        [request.requestHeadersParameters setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[request.requestBodyData length]] forKey:OBSHeadersContentLengthKey];
    }
}
@end

@implementation OBSHeaderContentTypePostProcessor
+(void) processRequest:(OBSBaseNetworkingRequest *)request configuration:(OBSBaseConfiguration *const) configuration error:(NSError**) error{
    if(request.requestMethod == OBSHTTPMethodPUT || request.requestMethod == OBSHTTPMethodPOST){
        if(![request.requestHeadersParameters objectForKey:OBSHeadersContentTypeKey]){
            [request.requestHeadersParameters setValue:OBSDefaultContentType forKey:OBSHeadersContentTypeKey];
        }
    }
}
@end

@implementation OBSHeaderHostPostProcessor
// 设置Host
+(void) processRequest:(OBSBaseNetworkingRequest *)request configuration:(OBSBaseConfiguration *const) configuration error:(NSError**) error{
    [request.requestHeadersParameters setValue:configuration.url.host forKey:OBSHeadersHostKey];
}
@end

@implementation OBSURLEncodingPostProcessor
+(void) processRequest:(OBSBaseNetworkingRequest *)request configuration:(OBSBaseConfiguration *const) configuration error:(NSError**) error{
    if(configuration.enableURLEncoding){
        [request.requestResourceParameters enumerateKeysAndObjectsUsingBlock:^(NSString *  key, NSString *  obj, BOOL  * stop) {
            [request.requestResourceParameters setValue:[obj obs_stringWithURLEncodingAllowedSet] forKey:key];
        }];
    }
}
@end
#pragma mark - Networking Manager
@interface OBSNetworkingManager ()
@property (nonatomic, strong) NSURLSession *commandURLSession;
@property (nonatomic, strong) NSURLSession *uploadURLSession;
@property (nonatomic, strong) NSURLSession *downloadURLSession;
@property (nonatomic, strong) NSURLSession *backgroundUploadURLSession;
@property (nonatomic, strong) NSURLSession *backgroundDownloadURLSession;
@property (nonatomic, strong) NSOperationQueue *commandURLTaskQueue;
@property (nonatomic, strong) NSOperationQueue *uploadURLTaskQueue;
@property (nonatomic, strong) NSOperationQueue *downloadURLTaskQueue;
@end


@implementation OBSNetworkingManager

-(instancetype) initWithConfiguration:(OBSBaseConfiguration*) configuration{
    if(self = [super init]){
            //set configuration
        _configuration = configuration;
        
        self.commandURLTaskQueue= [NSOperationQueue new];
        self.uploadURLTaskQueue= [NSOperationQueue new];
        self.downloadURLTaskQueue= [NSOperationQueue new];
        
        self.commandURLTaskQueue.maxConcurrentOperationCount = self.configuration.maxConcurrentCommandRequestCount;
        [self.configuration addObserver:self forKeyPath:OBSMaxConcurrentCommandRequestCountKey
                                options:NSKeyValueObservingOptionNew context:nil];
        
        self.uploadURLTaskQueue.maxConcurrentOperationCount = self.configuration.maxConcurrentUploadRequestCount;
        [self.configuration addObserver:self forKeyPath:OBSMaxConcurrentUploadRequestCountKey
                                options:NSKeyValueObservingOptionNew context:nil];
        
        self.downloadURLTaskQueue.maxConcurrentOperationCount = self.configuration.maxConcurrentDownloadRequestCount;
        [self.configuration addObserver:self forKeyPath:OBSMaxConcurrentDownloadRequestCountKey
                                options:NSKeyValueObservingOptionNew context:nil];
        
        self.commandURLSession = [NSURLSession sessionWithConfiguration:configuration.commandSessionConfiguration
                                                     delegate:self
                                                delegateQueue:self.commandURLTaskQueue];
        self.uploadURLSession = [NSURLSession sessionWithConfiguration:configuration.uploadSessionConfiguration
                                                     delegate:self
                                                delegateQueue:self.uploadURLTaskQueue];
        self.downloadURLSession = [NSURLSession sessionWithConfiguration:configuration.downloadSessionConfiguration
                                                     delegate:self
                                                delegateQueue:self.downloadURLTaskQueue];
        self.backgroundUploadURLSession = [NSURLSession sessionWithConfiguration:configuration.backgroundUploadSessionConfiguration
                                                     delegate:self
                                                delegateQueue:self.uploadURLTaskQueue];
        self.backgroundDownloadURLSession = [NSURLSession sessionWithConfiguration:configuration.backgroundDownloadSessionConfiguration
                                                     delegate:self
                                                delegateQueue:self.downloadURLTaskQueue];
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSNumber* newValue = [change objectForKey:@"new"];
    if([keyPath isEqualToString:OBSMaxConcurrentCommandRequestCountKey]){
        self.commandURLTaskQueue.maxConcurrentOperationCount = [newValue integerValue];
    }
    if([keyPath isEqualToString:OBSMaxConcurrentUploadRequestCountKey]){
        self.uploadURLTaskQueue.maxConcurrentOperationCount = [newValue integerValue];
    }
    if([keyPath isEqualToString:OBSMaxConcurrentDownloadRequestCountKey]){
        self.downloadURLTaskQueue.maxConcurrentOperationCount = [newValue integerValue];
    }
}

-(OBSBFTask*) sendRequest: (OBSBaseNetworkingRequest*) request{
    
    
    
    if(request.isCancelled){
        NSError *error = [NSError errorWithDomain:OBSClientErrorDomain
                                             code:OBSErrorCodeClientErrorStatus
                                         userInfo:@{
                                                    @"reason": @"request is cancelled1"
                                                    }];
        [request.completionSource trySetError:error];
        return nil;
    }
    dispatch_queue_t processQueue = dispatch_queue_create(OBSProcessorsQueueName, DISPATCH_QUEUE_CONCURRENT);
    return [OBSBFTask taskFromExecutor:[OBSBFExecutor executorWithDispatchQueue:processQueue] withBlock:^id {
        OBSLogInfo(@"Sending Request %@",request.requestID);
        NSError *error = nil;
            //isCancelled
        if(request.obsRequest.isCancelled){
            error = [NSError errorWithDomain:OBSClientErrorDomain
                                        code:OBSErrorCodeClientErrorStatus
                                    userInfo:@{
                                               @"reason": @"request is cancelled2"
                                               }];
            return [OBSBFTask taskWithError:error];
        }

            //run processors
        for(id<OBSNetworkingRequestPostProcessor> processor in request.postProcessors){
            [processor processRequest:request configuration:self.configuration error:&error];
            if(error){
                OBSLogError(@"%@.",error);
                return [OBSBFTask taskWithError:error];
            }
        }
        
            //generate mutablerequest
        NSMutableString *urlString = [request.requestBaseURLString mutableCopy];
        NSMutableString  *urlSuffix = [request.requestResourceString mutableCopy];
        [urlSuffix appendString:[OBSUtils generateQueryString:request.requestQueryParameters]];
        [urlString appendString:urlSuffix];
        NSMutableURLRequest  *mutableRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        mutableRequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        mutableRequest.HTTPMethod = [NSString obs_initWithOBSHTTPMethod:request.requestMethod];
        [mutableRequest setAllHTTPHeaderFields:request.requestHeadersParameters];
        
        
            //create sessiontask
        NSURLSessionTask *sessionTask = nil;
        switch(request.requestType){
            case OBSRequestTypeCommandRequest:{
                mutableRequest.HTTPBody = request.requestBodyData;
                sessionTask = [self.commandURLSession dataTaskWithRequest:mutableRequest];
            }
                break;
            case OBSRequestTypeUploadDataRequest:{
                mutableRequest.HTTPBodyStream = [NSInputStream inputStreamWithData:request.requestBodyData];
                sessionTask = [self.uploadURLSession dataTaskWithRequest:mutableRequest];
            }
                break;
            case OBSRequestTypeUploadFileRequest:{
                OBSNetworkingUploadFileRequest *upRequest = (OBSNetworkingUploadFileRequest*) request;
                if(upRequest.background){
                    sessionTask = [self.backgroundUploadURLSession uploadTaskWithRequest:mutableRequest fromFile:[NSURL fileURLWithPath:upRequest.uploadFilePath]];
                }else{
                    sessionTask = [self.uploadURLSession uploadTaskWithRequest:mutableRequest fromFile:[NSURL fileURLWithPath:upRequest.uploadFilePath]];
                }
            }
                break;
            case OBSRequestTypeDownloadDataRequest:{
                sessionTask = [self.downloadURLSession dataTaskWithRequest:mutableRequest];
            }
                break;
            case OBSRequestTypeDownloadFileRequest:{
                OBSNetworkingDownloadFileRequest *downRequest = (OBSNetworkingDownloadFileRequest*) request;
                if(downRequest.background){
                    sessionTask = [self.backgroundDownloadURLSession downloadTaskWithRequest:mutableRequest];
                }else{
                    sessionTask = [self.downloadURLSession downloadTaskWithRequest:mutableRequest];
                }
            }
                break;
            default:
                break;
        }
        sessionTask.obsNetworkingRequest = request;
        [request.sessionTaskList addObject:sessionTask];
        
        [sessionTask resume];
        return request.completionSource.task;
    }];
}
-(void)releaseSessions{
    // 移除kvo
    [self.configuration removeObserver:self forKeyPath:OBSMaxConcurrentCommandRequestCountKey];
    [self.configuration removeObserver:self forKeyPath:OBSMaxConcurrentUploadRequestCountKey];
    [self.configuration removeObserver:self forKeyPath:OBSMaxConcurrentDownloadRequestCountKey];
    
    [self.commandURLSession finishTasksAndInvalidate];
    [self.uploadURLSession finishTasksAndInvalidate];
    [self.downloadURLSession finishTasksAndInvalidate];
    [self.backgroundUploadURLSession finishTasksAndInvalidate];
    [self.backgroundDownloadURLSession finishTasksAndInvalidate];
}
-(BOOL) isErrorResponse:(NSURLSessionTask*) task{
    @autoreleasepool {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) task.response;
        NSInteger statusCode = httpResponse.statusCode;
        if(statusCode >0 && (statusCode < 200 || statusCode >= 300)){
            return YES;
        }else{
            return NO;
        }
    }
}

#pragma  mark - URLSessionTaskDelegate

#pragma  mark - Delegate 1 send request : initial handshake
#pragma  mark - Delegate 5 got resposne : authentication is required
-(void) URLSession:(NSURLSession *)session task:(NSURLSessionTask*) task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
    if(task.obsNetworkingRequest.isCancelled){
        NSError *error = [NSError errorWithDomain:OBSClientErrorDomain
                                             code:OBSErrorCodeClientErrorStatus
                                         userInfo:@{
                                                    @"reason": @"request is cancelled1"
                                                    }];
        [task cancel];
        [task.obsNetworkingRequest.completionSource trySetError:error];
        return;
    }
    if(!challenge){
        return;
    }
    if(self.configuration.trustUnsafeCert){
        completionHandler(NSURLSessionAuthChallengeUseCredential,[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
        return;
    }
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    NSString *host = [[task.currentRequest allHTTPHeaderFields] objectForKey:OBSHeadersHostKey];
    if(!host){
        host = task.currentRequest.URL.host;
    }
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        NSMutableArray *policies = [NSMutableArray array];
        if(host){
            [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge  CFStringRef)host)];
        }else{
            [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
        }
        SecTrustSetPolicies(challenge.protectionSpace.serverTrust, (__bridge CFArrayRef)policies);
        SecTrustResultType result;
        SecTrustEvaluate(challenge.protectionSpace.serverTrust, &result);
        if(result == kSecTrustResultUnspecified|| result == kSecTrustResultProceed){
            disposition = NSURLSessionAuthChallengeUseCredential;
            credential = [ NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        }else{
            OBSLogError(@"Certificat verification failed with Server %@.",host);
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
        completionHandler(disposition,credential);
    }
}

//#pragma  mark - Delegate 2 send request : if data provided from stream
//-(void)URLSession:(NSURLSession*)session task:(nonnull NSURLSessionTask *)task needNewBodyStream:(nonnull void (^)(NSInputStream *))completionHandler{
//    if(task.obsNetworkingRequest.isCancelled){
//        NSError *error = [NSError errorWithDomain:OBSClientErrorDomain
//                                             code:OBSErrorCodeClientErrorStatus
//                                         userInfo:@{
//                                                    @"reason": @"request is cancelled1"
//                                                    }];
//        [task cancel];
//        [task.obsNetworkingRequest.completionSource trySetError:error];
//        return;
//    }
//}

#pragma  mark - Delegate 3 send request : initialing upload body content to server
-(void)URLSession:(NSURLSession*)session task:(nonnull NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    if(task.obsNetworkingRequest.isCancelled){
        NSError *error = [NSError errorWithDomain:OBSClientErrorDomain
                                             code:OBSErrorCodeClientErrorStatus
                                         userInfo:@{
                                                    @"reason": @"request is cancelled1"
                                                    }];
        [task cancel];
        [task.obsNetworkingRequest.completionSource trySetError:error];
        return;
    }
    OBSBaseNetworkingRequest *networkingRequest = task.obsNetworkingRequest;
    if([self isErrorResponse:task]){
            //if error code, just return.
        return;
    }
    
    switch(networkingRequest.requestType){
        case OBSRequestTypeUploadDataRequest:
        case OBSRequestTypeUploadFileRequest:
            if([networkingRequest respondsToSelector:NSSelectorFromString(OBSRequestUploadProgressBlockKey)]){
                OBSNetworkingUploadProgressBlock block = [networkingRequest valueForKey:OBSRequestUploadProgressBlockKey];
                if(block){
                    block(bytesSent,totalBytesSent,totalBytesExpectedToSend);
                }
            }
            break;
        default:
            break;
    }
    return;
}

#pragma  mark - Delegate 13 Got response : any task
-(void)URLSession:(NSURLSession*)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    if(task.obsNetworkingRequest.isCancelled){
        NSError *error = [NSError errorWithDomain:OBSClientErrorDomain
                                             code:OBSErrorCodeClientErrorStatus
                                         userInfo:@{
                                                    @"reason": @"request is cancelled1"
                                                    }];
        [task cancel];
        [task.obsNetworkingRequest.completionSource trySetError:error];
        return;
    }
    OBSBaseNetworkingRequest *networkingRequest = task.obsNetworkingRequest;
        //session error
    if(error){
        OBSLogError(@"%@.",error);
        [networkingRequest.completionSource trySetError:error];
        return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) task.response;
    NSInteger statusCode = httpResponse.statusCode;
    NSDictionary *headers = [httpResponse allHeaderFields];

    if([self isErrorResponse:task]){
        NSDictionary *xmlErrorDict = nil;
        if([networkingRequest.responseData length]){
            xmlErrorDict = [OBSUtils convertXMLDataToDict:networkingRequest.responseData error:nil];
        }
        NSMutableDictionary *userInfoDict = [@{
                                              @"statusCode":@(statusCode),
                                              @"requestID":networkingRequest.requestID,
                                              @"headers":headers,
                                              @"responseBody":[NSString obs_initWithDataUTF8:networkingRequest.responseData],
                                              } mutableCopy];
        if([headers objectForKey:@"x-amz-request-id"]){
            [userInfoDict setObject:headers[@"x-amz-request-id"] forKey:@"xRequestID"];
        }else{
            [userInfoDict setObject:headers[@"x-obs-request-id"] forKey:@"xRequestID"];
        }
        
        if(xmlErrorDict){
            [userInfoDict setObject:xmlErrorDict forKey:@"responseXMLBodyDict"];
        }
        error = [NSError errorWithDomain:OBSServerErrorDomain
                                    code:OBSErrorCodeServerErrorStatus
                                userInfo:userInfoDict
                 ];
        OBSLogError(@"%@.",error);
        [networkingRequest.completionSource trySetError:error];
        return;
    }
    NSMutableDictionary *responseDict = [NSMutableDictionary dictionary];
    [responseDict setValue:[NSString stringWithFormat:@"%d",(int)statusCode] forKey:OBSOutputCodeKey];
    [responseDict setValue:networkingRequest.requestID forKey:OBSRequestIDKey];
    [responseDict setValue:headers forKey:OBSOutputHeadersKey];
    [responseDict setValue:networkingRequest.responseData forKey:OBSOutputBodyKey];
        //run pre processors
    for(id<OBSNetworkingResponsePreProcessor> processor in networkingRequest.preProcessors){
        [processor processResponse:responseDict configuration:self.configuration error:&error];
        if(error){
            OBSLogError(@"%@.",error);
            [networkingRequest.completionSource trySetError:error];
        }
    }
    OBSBaseResponse *response ;
    
    switch(networkingRequest.requestType){
        case OBSRequestTypeUploadDataRequest:
        case OBSRequestTypeUploadFileRequest:
        case OBSRequestTypeCommandRequest:{
            OBSBodyType bodyType;
            Class outputClazz = [networkingRequest getResponseClazz];
            NSAssert(outputClazz != nil, @"outputClazz is not correct");
            if(outputClazz == nil){
                NSString *errorMsg = [NSString stringWithFormat:@"outputClazz for networkingRequest %@ is nil", NSStringFromClass(networkingRequest.class)];
                error = [NSError errorWithDomain:OBSClientErrorDomain
                                            code:OBSErrorCodeClientErrorStatus
                                        userInfo:@{
                                                   @"reason": errorMsg
                                                   }
                         ];
                [networkingRequest.completionSource trySetError:error];
            }
                //ToDo: check responds
            bodyType = [outputClazz GetBodyType];
            if([networkingRequest.responseData length]){
                switch(bodyType){
                    case OBSBodyTypeXML:
                        [responseDict setValue:[OBSUtils convertXMLDataToDict:[responseDict valueForKey:OBSOutputBodyKey] error:&error]
                                        forKey:OBSOutputBodyKey];
                        break;
                    case OBSBodyTypeJSON:
                        [responseDict setValue:[NSJSONSerialization JSONObjectWithData:networkingRequest.responseData options:kNilOptions error:&error]
                                        forKey:OBSOutputBodyKey];
                        break;
                    default:
                        break;
                }
            }else{
                [responseDict setValue:@{} forKey:OBSOutputBodyKey];
            }
            if(error){
                OBSLogError(@"%@.",error);
                [networkingRequest.completionSource trySetError:error];
                return;
            }
            response = [OBSMTLJSONAdapterCustomized modelOfClass:outputClazz fromJSONDictionary:responseDict  error:&error];
            
        }
            break;
        case OBSRequestTypeDownloadDataRequest:{
            OBSNetworkingDownloadDataRequest *request = (OBSNetworkingDownloadDataRequest*)networkingRequest;
            [responseDict setValue:request.responseData forKey:OBSOutputBodyKey];
            response = [OBSMTLJSONAdapterCustomized modelOfClass:[request getResponseClazz] fromJSONDictionary:responseDict  error:&error];
        }
            break;
        case OBSRequestTypeDownloadFileRequest:{
            OBSNetworkingDownloadFileRequest *request = (OBSNetworkingDownloadFileRequest*)networkingRequest;
            response = [OBSMTLJSONAdapterCustomized modelOfClass:[request getResponseClazz] fromJSONDictionary:responseDict  error:&error];
        }
            break;
        default:
            break;
    }
    if(error){
        OBSLogError(@"%@.",error);
        [networkingRequest.completionSource trySetError:error];
        return;
    }
    [networkingRequest.completionSource trySetResult:response];
}


#pragma  mark - URLSessionDataTaskDelegate
#pragma  mark - Delegate 8 Got response : only data task
-(void)URLSession:(NSURLSession*)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler{
    completionHandler(NSURLSessionResponseAllow);
}

#pragma  mark - Delegate 9 Got response : only data task
-(void)URLSession:(NSURLSession*)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data{
    if(dataTask.obsNetworkingRequest.isCancelled){
        NSError *error = [NSError errorWithDomain:OBSClientErrorDomain
                                             code:OBSErrorCodeClientErrorStatus
                                         userInfo:@{
                                                    @"reason": @"request is cancelled1"
                                                    }];
        [dataTask cancel];
        [dataTask.obsNetworkingRequest.completionSource trySetError:error];
        return;
    }
    OBSBaseNetworkingRequest *networkingRequest = dataTask.obsNetworkingRequest;
    
    if([self isErrorResponse:dataTask]){
            //if error code, just append response data and return.
        [networkingRequest.responseData appendData:data];
        return;
    }
    
    switch(networkingRequest.requestType){
        case OBSRequestTypeUploadDataRequest:
        case OBSRequestTypeUploadFileRequest:
        case OBSRequestTypeCommandRequest:
            [networkingRequest.responseData appendData:data];
            break;
        case OBSRequestTypeDownloadDataRequest:{
            OBSNetworkingDownloadDataRequest *request = (OBSNetworkingDownloadDataRequest*) networkingRequest;
            if(request.downloadProgressBlock){
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) dataTask.response;
                int64_t bytes_expected = httpResponse.expectedContentLength;
                int64_t bytes_got = [data length];
                request.bytes_totalGot += bytes_got;
                request.downloadProgressBlock(bytes_got,request.bytes_totalGot , bytes_expected);
            }
            
            if(request.onReceiveDataBlock){
                request.onReceiveDataBlock(data);
            }else{
                [request.responseData appendData:data];
            }
        }
            break;
        default:
            break;
    }
 }
#pragma  mark - URLSessionDownloadTaskDelegate
#pragma  mark - Delegate 9 Got response : only download task
-(void)URLSession:(NSURLSession*) session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    if(downloadTask.obsNetworkingRequest.isCancelled){
        NSError *error = [NSError errorWithDomain:OBSClientErrorDomain
                                             code:OBSErrorCodeClientErrorStatus
                                         userInfo:@{
                                                    @"reason": @"request is cancelled"
                                                    }];
        [downloadTask cancel];
        [downloadTask.obsNetworkingRequest.completionSource trySetError:error];
        return;
    }
    if([self isErrorResponse:downloadTask]){
            //if error code, just return.
        return;
    }
    switch(downloadTask.obsNetworkingRequest.requestType){
        case OBSRequestTypeDownloadFileRequest:{
            OBSNetworkingDownloadFileRequest *request = (OBSNetworkingDownloadFileRequest*)downloadTask.obsNetworkingRequest;
            if(request.downloadProgressBlock){
                request.downloadProgressBlock(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
            }
        }
            break;
        default:
            break;
    }
}
#pragma  mark - Delegate 12 Got response : only download task
-(void)URLSession:(NSURLSession*) session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location{
    
    if(downloadTask.obsNetworkingRequest.isCancelled){
        NSError *error = [NSError errorWithDomain:OBSClientErrorDomain
                                             code:OBSErrorCodeClientErrorStatus
                                         userInfo:@{
                                                    @"reason": @"request is cancelled1"
                                                    }];
        [downloadTask cancel];
        [downloadTask.obsNetworkingRequest.completionSource trySetError:error];
        return;
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error;
    
    OBSNetworkingDownloadFileRequest *request = (OBSNetworkingDownloadFileRequest*) downloadTask.obsNetworkingRequest;
    if([self isErrorResponse:downloadTask]){
        [request.responseData appendData:[NSData dataWithContentsOfURL:location]];
        [manager removeItemAtURL:location error:&error];
        if(error){
            OBSLogError(@"%@",error);
            [request.completionSource trySetError:error];
        }
        return;
    }
    
    NSString *filePath = request.downloadFilePath;
    if([manager fileExistsAtPath:filePath]){
        OBSLogWarn(@"download destination file exists, about to overwrite it.");
        [manager removeItemAtPath:filePath error:&error];
        if(error){
            OBSLogError(@"%@",error);
            [request.completionSource trySetError:error];
        }
    }
    [manager moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:&error];
    if(error){
        OBSLogError(@"%@",error);
        [request.completionSource trySetError:error];
    }
}


@end
#pragma mark - networking base requests

@interface OBSBaseNetworkingRequest()
@end
@implementation OBSBaseNetworkingRequest
@synthesize isCancelled = _cancelled;
-(instancetype)init{
    if(self = [super init]){
        self.completionSource = [OBSBFTaskCompletionSource new];
        self.responseData = [NSMutableData new];
        self.postProcessors = [NSMutableArray array];
        self.preProcessors = [NSMutableArray array];
        self.requestResourceParameters = [NSMutableDictionary dictionary];
        self.requestQueryParameters = [NSMutableDictionary dictionary];
        self.requestHeadersParameters = [NSMutableDictionary dictionary];
        self.addonRequestPostProcessorsParameters= [NSMutableArray array];
        self.addonRequestPostProcessorsParameters= [NSMutableArray array];
        self.sessionTaskList = [OBSWeakMutableArray array];
    }
    return self;
}
-(void)cancel{
    @synchronized (self) {
        OBSLogDebug(@"Networking cancelled %@ start", self.requestID);
        if(!self.isCancelled){
            for(NSURLSessionTask *task in self.sessionTaskList){
                [task cancel];
            }
            if(!self.completionSource.task.isCompleted){
                _cancelled = YES;
                
            }
        }
        OBSLogDebug(@"Networking cancelled %@ end", self.requestID);
    }
}
+(NSDictionary*) JSONKeyPathsByPropertyKey{
    MakeDispatchOnceDictBEGIN
    dict= @{
              OBSRequestTypeKey:OBSRequestTypeKey,
              OBSRequestIDKey:OBSRequestIDKey,
              OBSRequestHTTPMethodKey:OBSRequestHTTPMethodKey,
              OBSRequestResourceStringKey:OBSRequestResourceStringKey,
              OBSRequestAddonRequestPostProcessorsKey:OBSRequestAddonRequestPostProcessorsKey,
              OBSRequestAddonResponsePreProcessorsKey:OBSRequestAddonResponsePreProcessorsKey,
             } ;
    MakeDispatchOnceDictEND
    return dict;
}

+(NSValueTransformer*) JSONTransformerForKey:(NSString *)key{
    if([key isEqualToString:OBSRequestHTTPMethodKey]){
        return [OBSMTLValueTransformer obs_mtl_valueMappingTransformerWithDictionary:@{
                                                                                   @"OBSHTTPMethodGET":@(OBSHTTPMethodGET),
                                                                                   @"OBSHTTPMethodHEAD":@(OBSHTTPMethodHEAD),
                                                                                   @"OBSHTTPMethodPUT":@(OBSHTTPMethodPUT),
                                                                                   @"OBSHTTPMethodPOST":@(OBSHTTPMethodPOST),
                                                                                   @"OBSHTTPMethodTRACE":@(OBSHTTPMethodTRACE),
                                                                                   @"OBSHTTPMethodOPTIONS":@(OBSHTTPMethodOPTIONS),
                                                                                   @"OBSHTTPMethodDELETE":@(OBSHTTPMethodDELETE),
                                                                                   @"OBSHTTPMethodLOCK":@(OBSHTTPMethodLOCK),
                                                                                   @"OBSHTTPMethodMKCOL":@(OBSHTTPMethodMKCOL),
                                                                                   @"OBSHTTPMethodMOVE":@(OBSHTTPMethodMOVE),
                                                                                   }];
    }else if([key isEqualToString:OBSRequestAuthRequiredKey]){
        return [OBSMTLValueTransformer obs_mtl_valueMappingTransformerWithDictionary:@{
                                                                                   @"YES":@(YES),
                                                                                   @"NO":@(NO),
                                                                                   }];
    }
    return [OBSMTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    }];
}
@end

@implementation OBSNetworkingCommandRequest
-(instancetype)init{
    if(self=[super init]){
        self.requestType = OBSRequestTypeCommandRequest;
    }
    return self;
}
+(NSDictionary*) JSONKeyPathsByPropertyKey{
    MakeDispatchOnceDictBEGIN
    dict= @{
             OBSRequestBodyParameterKey:OBSRequestBodyParameterKey,
             };
    MakeDispatchOnceDictEND
    return dict;
}
+(NSDictionary*) getAdditionalJSONDataIncludeParents{
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    Class parentClass = class_getSuperclass(self);
    if([parentClass conformsToProtocol:@protocol(OBSNetworkingRequestJSONDataProtocol) ]){
        [dataDict addEntriesFromDictionary:[parentClass getAdditionalJSONDataIncludeParents]];
    }
    [dataDict addEntriesFromDictionary:[self AdditionalJSONData]];
    return dataDict;
}
+(OBSBodyType)GetBodyType{
        //default command request body type XML
    return OBSBodyTypeXML;
}
+(NSDictionary*) AdditionalJSONData{
    return nil;
}
@end

@implementation OBSNetworkingUploadDataRequest
-(instancetype)init{
    if(self=[super init]){
        self.requestType = OBSRequestTypeUploadDataRequest;
    }
    return self;
}
+(NSDictionary*) JSONKeyPathsByPropertyKey{
    MakeDispatchOnceDictBEGIN
    dict= @{
             OBSRequestUploadProgressBlockKey:OBSRequestUploadProgressBlockKey,
             OBSRequestUploadDataKey:OBSRequestUploadDataKey,
             };
    MakeDispatchOnceDictEND
    return dict;
}
+(NSDictionary*) AdditionalJSONData{
    return nil;
}
+(NSDictionary*) getAdditionalJSONDataIncludeParents{
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    Class parentClass = class_getSuperclass(self);
    if([parentClass conformsToProtocol:@protocol(OBSNetworkingRequestJSONDataProtocol) ]){
        [dataDict addEntriesFromDictionary:[parentClass getAdditionalJSONDataIncludeParents]];
    }
    [dataDict addEntriesFromDictionary:[self AdditionalJSONData]];
    return dataDict;
}
@end

@implementation OBSNetworkingUploadFileRequest
-(instancetype)init{
    if(self=[super init]){
        self.requestType = OBSRequestTypeUploadFileRequest;
    }
    return self;
}
+(NSDictionary*) JSONKeyPathsByPropertyKey{
    MakeDispatchOnceDictBEGIN
    dict= @{
             OBSRequestUploadProgressBlockKey:OBSRequestUploadProgressBlockKey,
             OBSRequestUploadFilePathKey:OBSRequestUploadFilePathKey,
             OBSRequestBackgroundKey:OBSRequestBackgroundKey,
             };
    MakeDispatchOnceDictEND
    return dict;
}
+(NSDictionary*) AdditionalJSONData{
    return nil;
}
+(NSDictionary*) getAdditionalJSONDataIncludeParents{
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    Class parentClass = class_getSuperclass(self);
    if([parentClass conformsToProtocol:@protocol(OBSNetworkingRequestJSONDataProtocol) ]){
        [dataDict addEntriesFromDictionary:[parentClass getAdditionalJSONDataIncludeParents]];
    }
    [dataDict addEntriesFromDictionary:[self AdditionalJSONData]];
    return dataDict;
}
@end



@implementation OBSNetworkingDownloadDataRequest
-(instancetype)init{
    if(self=[super init]){
        self.requestType = OBSRequestTypeDownloadDataRequest;
    }
    return self;
}
+(NSDictionary*) JSONKeyPathsByPropertyKey{
    MakeDispatchOnceDictBEGIN
    dict= @{
             OBSRequestOnReceiveDataBlockKey:OBSRequestOnReceiveDataBlockKey,
             OBSRequestDownloadProgressBlockKey:OBSRequestDownloadProgressBlockKey,
             };
    MakeDispatchOnceDictEND
    return dict;
}
+(NSDictionary*) AdditionalJSONData{
    return nil;
}
+(NSDictionary*) getAdditionalJSONDataIncludeParents{
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    Class parentClass = class_getSuperclass(self);
    if([parentClass conformsToProtocol:@protocol(OBSNetworkingRequestJSONDataProtocol) ]){
        [dataDict addEntriesFromDictionary:[parentClass getAdditionalJSONDataIncludeParents]];
    }
    [dataDict addEntriesFromDictionary:[self AdditionalJSONData]];
    return dataDict;
}
@end

@implementation OBSNetworkingDownloadFileRequest
-(instancetype)init{
    if(self=[super init]){
        self.requestType = OBSRequestTypeDownloadFileRequest;
    }
    return self;
}
+(NSDictionary*) JSONKeyPathsByPropertyKey{
    MakeDispatchOnceDictBEGIN
    dict= @{
             OBSRequestDownloadProgressBlockKey:OBSRequestDownloadProgressBlockKey,
             OBSRequestDownloadFilePathKey:OBSRequestDownloadFilePathKey,
             OBSRequestBackgroundKey:OBSRequestBackgroundKey,
             };
    MakeDispatchOnceDictEND
    return dict;
}
+(NSDictionary*) AdditionalJSONData{
    return nil;
}
+(NSDictionary*) getAdditionalJSONDataIncludeParents{
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    Class parentClass = class_getSuperclass(self);
    if([parentClass conformsToProtocol:@protocol(OBSNetworkingRequestJSONDataProtocol) ]){
        [dataDict addEntriesFromDictionary:[parentClass getAdditionalJSONDataIncludeParents]];
    }
    [dataDict addEntriesFromDictionary:[self AdditionalJSONData]];
    return dataDict;
}
@end


