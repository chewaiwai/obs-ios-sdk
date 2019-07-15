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
#import "OBSClient.h"
#import "OBSBaseModel.h"
#import "OBSBolts.h"
#import "OBSBaseNetworking.h"
#import "OBSLogging.h"
#import "OBSServiceBaseModel.h"
#import "OBSServiceCredentialProvider.h"
#import "OBSListBucketsModel.h"
#import "OBSCreateBucketModel.h"
#import "OBSCopyObjectModel.h"
#import "OBSCopyPartModel.h"
#import "OBSProtocol.h"


#import <objc/runtime.h>

@interface OBSClient()
@property (nonatomic,strong) OBSNetworkingManager *networkingManager;
@property (nonatomic,strong) NSString *uuid;
@end

@implementation OBSClient

#pragma mark - init
- (void)dealloc{
    OBSLogInfo(@"Dealloc %@",self);
    [self.networkingManager releaseSessions];
}

-(instancetype) initWithConfiguration:(__kindof OBSBaseConfiguration*) configuration{
    if (self = [super init]) {
        _configuration = configuration;
        
        self.networkingManager = [[OBSNetworkingManager alloc] initWithConfiguration:configuration];
        [OBSDDLog addLogger:[OBSDDTTYLogger sharedInstance]];
    }
    return self;
}

#pragma mark - set logger
-(void) setLogLevel:(OBSDDLogLevel)logLevel{
    @synchronized (self) {
        obsddLogLevel = logLevel;
    }
}

-(void) addLogger: (id<OBSDDLogger>) logger{
    @synchronized (self) {
        [OBSDDLog addLogger: logger];
    }
}

-(void) setASLogOn{
    @synchronized (self) {
        [OBSDDLog addLogger:[OBSDDASLLogger sharedInstance]];
    }
}

#pragma mark - Invoke Methods
- (BOOL) getOBSProtocol:(OBSBaseRequest *)request{
    NSURL* endPoint = ((OBSServiceConfiguration*)self.configuration).url;
    // 单例构建一个对象
    OBSProtocol *obsProtocol = [OBSProtocol sharedOBSProtocol];
    if (((OBSStaticCredentialProvider*)((OBSServiceConfiguration *)self.configuration).credentialProvider).isGetProtocol){
        //列举桶
        if([request conformsToProtocol:@protocol(OBSListBucketsProtocol)]){
            BOOL isSuccess = [obsProtocol getObsProtocolListBucket:3 endPoint:endPoint baseRequest:request];
            
            return isSuccess;
            
            
        }
        //创建桶
        else if([request conformsToProtocol:@protocol(OBSCreateBucketProtocol)]){
            BOOL isSuccess = [obsProtocol getObsProtocolCreatBucket:3 bucketName:((OBSCreateBucketRequest*)request).bucketName endPoint:endPoint baseRequest:request];
            return isSuccess;
        }
        //其他
        else{
            BOOL isSuccess = YES;
            if([request conformsToProtocol:@protocol(OBSCopyObjectProtocol)]){
                isSuccess = [obsProtocol getObsProtocolOthers:3 bucketName:((OBSCopyObjectRequest*)request).srcBucketName endPoint:endPoint baseRequest:request];
            }else if([request conformsToProtocol:@protocol(OBSCopyPartProtocol)]){
                isSuccess = [obsProtocol getObsProtocolOthers:3 bucketName:((OBSCopyPartRequest*)request).srcBucketName endPoint:endPoint baseRequest:request];
            }else{
                
                isSuccess = [obsProtocol getObsProtocolOthers:3 bucketName:((OBSCreateBucketRequest*)request).bucketName endPoint:endPoint baseRequest:request];
            }
            
            return isSuccess;
        }
    }else{
        return YES;
    }
    
}
- (OBSBFTask*)invokeRequest:(OBSBaseRequest *) request{
    @autoreleasepool {
        
        NSError *error=nil;
            //request is nil
        if (!request) {
            error = [NSError errorWithDomain:OBSClientErrorDomain
                                        code:OBSErrorCodeClientErrorStatus
                                    userInfo:@{
                                               @"reason": @"request is nil"
                                               }];
            return [OBSBFTask taskWithError:error];
        }
            //validateRequest
       
        
        [request validateRequest:&error];
        if(error){
            return [OBSBFTask taskWithError:error];
        }
            //isCancelled
        if(request.isCancelled){
            error = [NSError errorWithDomain:OBSClientErrorDomain
                                        code:OBSErrorCodeClientErrorStatus
                                    userInfo:@{
                                               @"reason": @"request is cancelled"
                                               }];
            return [OBSBFTask taskWithError:error];
        }
        
    
        
        OBSBaseNetworkingRequest *networkingRequest = nil;
        networkingRequest = [request convertToNetworkingRequest:_configuration error:&error];
        [request setValue:[OBSWeakMutableArray array] forKey:@"networkingRequestList"];
        [[request valueForKey:@"networkingRequestList"] addObject:networkingRequest];
        if (error){
            return [OBSBFTask taskWithError:error];
        }else{
            return [self.networkingManager sendRequest:networkingRequest];
        }
    }
}



@end
