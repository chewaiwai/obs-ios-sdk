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

#import "OBSProtocol.h"
#ifdef __IPHONE_10_0
os_unfair_lock lock0 = OS_UNFAIR_LOCK_INIT;
os_unfair_lock lock1 = OS_UNFAIR_LOCK_INIT;
os_unfair_lock lock2 = OS_UNFAIR_LOCK_INIT;
os_unfair_lock lock3 = OS_UNFAIR_LOCK_INIT;
os_unfair_lock lock4 = OS_UNFAIR_LOCK_INIT;
os_unfair_lock lock5 = OS_UNFAIR_LOCK_INIT;
os_unfair_lock lock6 = OS_UNFAIR_LOCK_INIT;
os_unfair_lock lock7 = OS_UNFAIR_LOCK_INIT;
os_unfair_lock lock8 = OS_UNFAIR_LOCK_INIT;
os_unfair_lock lock9 = OS_UNFAIR_LOCK_INIT;
#endif
static OBSProtocol *__OBSProtocol = nil;
@implementation OBSProtocol
+(OBSProtocol *)sharedOBSProtocol
{
    static dispatch_once_t oneToken;
    
    dispatch_once(&oneToken, ^{
        if(__OBSProtocol==nil){
            __OBSProtocol = [[super allocWithZone:NULL] init];
            if (@available(iOS 10.0, *)) {

            }else{
                __OBSProtocol.nslock0 = [NSLock new];
                __OBSProtocol.nslock1 = [NSLock new];
                __OBSProtocol.nslock2 = [NSLock new];
                __OBSProtocol.nslock3 = [NSLock new];
                __OBSProtocol.nslock4 = [NSLock new];
                __OBSProtocol.nslock5 = [NSLock new];
                __OBSProtocol.nslock6 = [NSLock new];
                __OBSProtocol.nslock7 = [NSLock new];
                __OBSProtocol.nslock8 = [NSLock new];
                __OBSProtocol.nslock9 = [NSLock new];

            }
            
            
        }
    });
    
    return __OBSProtocol;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [OBSProtocol sharedOBSProtocol];
}
- (id)copyWithZone:(nullable NSZone *)zone {
    return [OBSProtocol sharedOBSProtocol];
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    return [OBSProtocol sharedOBSProtocol];
}

//协议协商功能
//列举桶
-(BOOL)getObsProtocolListBucket:(int)times endPoint:(NSURL*)endPoint baseRequest:(OBSBaseRequest *) baseRequest{
    __block BOOL isSuccess;
    __block int retryTimes;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    
    //确定请求路径
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?apiversion",endPoint]];
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"HEAD";
    
    //获得会话对象
    NSURLSession *session = [NSURLSession sharedSession];
    
    //根据会话对象创建一个Task(发送请求）
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //拿到响应头信息
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        
        if(res.statusCode >= 500){
            // 出错重试
            if(times>0){
                retryTimes = times;
                retryTimes -= 1;
                [self getObsProtocolListBucket:retryTimes endPoint:endPoint baseRequest:baseRequest];
            }else{
                isSuccess = NO;
            }
            
            
        }else if(res.statusCode == 200){
            if([[res.allHeaderFields objectForKey:@"x-obs-api"] floatValue] >= 3.0){
                //采用自研协议
                
                baseRequest.protocolType = OBSProtocolTypeOBS;
                
                [defaults setBool:YES forKey:@"OBSProtocol"];
                [defaults synchronize];
                
            }else{
                //采用v2协议
                baseRequest.protocolType = OBSProtocolTypeOld;
                [defaults setBool:NO forKey:@"OBSProtocol"];
                [defaults synchronize];
            }
            isSuccess = YES;
        }else{
            //采用v2协议
            baseRequest.protocolType = OBSProtocolTypeOld;
            [defaults setBool:NO forKey:@"OBSProtocol"];
            [defaults synchronize];
            isSuccess = YES;
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    //5.执行任务
    [dataTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return isSuccess;
    
}

//创建桶
-(BOOL)getObsProtocolCreatBucket:(int)times bucketName:(NSString*)bucketName endPoint:(NSURL*)endPoint baseRequest:(OBSBaseRequest *) baseRequest{
    __block BOOL isSuccess;
    __block int retryTimes;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 查找缓存是否存在
    NSString *cache = [self defaultsManagement:bucketName value:@"" type:@"read"];
    NSDate *datenow = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];
    if(cache){
        NSArray<NSString*> *cacheArray = [cache componentsSeparatedByString:@"+"];
        
        
        if([timeSp intValue]-[cacheArray[1] intValue]<900){
            if([cacheArray[0] isEqualToString:@"OBSProtocolTypeOBS"]){
                //采用自研协议
                baseRequest.protocolType = OBSProtocolTypeOBS;
                [defaults setBool:YES forKey:@"OBSProtocol"];
                [defaults synchronize];
            }else{
                //采用v2协议
                baseRequest.protocolType = OBSProtocolTypeOld;
                [defaults setBool:NO forKey:@"OBSProtocol"];
                [defaults synchronize];
            }
            
            return YES;
        }
        
    }
    
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    //确定请求路径
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?apiversion",endPoint]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"HEAD";
    
    //获得会话对象
    NSURLSession *session = [NSURLSession sharedSession];
    
    //根据会话对象创建一个Task(发送请求）
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //拿到响应头信息
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        
        if(res.statusCode >= 500){
            // 出错重试
            if(times>0){
                retryTimes = times;
                retryTimes -= 1;
                [self getObsProtocolCreatBucket:retryTimes bucketName:bucketName endPoint:endPoint baseRequest:baseRequest];
            }else{
                isSuccess = NO;
            }
            
            
        }else if(res.statusCode == 200){
            if([[res.allHeaderFields objectForKey:@"x-obs-api"] floatValue] >= 3.0){
                //采用自研协议
                
                baseRequest.protocolType = OBSProtocolTypeOBS;
                NSString *cacheValue = [NSString stringWithFormat:@"OBSProtocolTypeOBS+%@",timeSp];
                
                [self defaultsManagement:bucketName value:cacheValue type:@"write"];
                [defaults setBool:YES forKey:@"OBSProtocol"];
                [defaults synchronize];
                
                
            }else{
                //采用v2协议
                baseRequest.protocolType = OBSProtocolTypeOld;
                NSString *cacheValue = [NSString stringWithFormat:@"OBSProtocolTypeOld+%@",timeSp];
                
                [self defaultsManagement:bucketName value:cacheValue type:@"write"];
                [defaults setBool:NO forKey:@"OBSProtocol"];
                [defaults synchronize];
            }
            isSuccess = YES;
        }else{
            //采用v2协议
            baseRequest.protocolType = OBSProtocolTypeOld;
            NSString *cacheValue = [NSString stringWithFormat:@"OBSProtocolTypeOld+%@",timeSp];
            
            [self defaultsManagement:bucketName value:cacheValue type:@"write"];
            [defaults setBool:NO forKey:@"OBSProtocol"];
            [defaults synchronize];
            isSuccess = YES;
        }
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    //5.执行任务
    [dataTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return isSuccess;
    
}

//其他接口
-(BOOL)getObsProtocolOthers:(int)times bucketName:(NSString*)bucketName endPoint:(NSURL*)endPoint baseRequest:(OBSBaseRequest *) baseRequest{
    __block BOOL isSuccess;
    __block int retryTimes;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 查找缓存是否存在
    NSString *cache = [self defaultsManagement:bucketName value:@"" type:@"read"];
    NSDate *datenow = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];
    if(cache){
        NSArray<NSString*> *cacheArray = [cache componentsSeparatedByString:@"+"];
        
        
        if([timeSp intValue]-[cacheArray[1] intValue]<900){
            if([cacheArray[0] isEqualToString:@"OBSProtocolTypeOBS"]){
                //采用自研协议
                baseRequest.protocolType = OBSProtocolTypeOBS;
                [defaults setBool:YES forKey:@"OBSProtocol"];
                [defaults synchronize];
            }else{
                //采用v2协议
                baseRequest.protocolType = OBSProtocolTypeOld;
                [defaults setBool:NO forKey:@"OBSProtocol"];
                [defaults synchronize];
            }
            
            return YES;
        }
        
    }
    
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    //确定请求路径
    NSURL *obsURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?apiversion",endPoint]];
    NSArray *listItems = [[obsURL absoluteString] componentsSeparatedByString:@"//"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@//%@.%@",listItems[0],bucketName,listItems[1]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"HEAD";
    
    //获得会话对象
    NSURLSession *session = [NSURLSession sharedSession];
    
    //根据会话对象创建一个Task(发送请求）
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //拿到响应头信息
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        if(res.statusCode == 404){
            isSuccess = NO;
            
        }else if(res.statusCode >= 500){
            // 出错重试
            if(times>0){
                retryTimes = times;
                retryTimes -= 1;
                [self getObsProtocolOthers:retryTimes bucketName:bucketName endPoint:endPoint baseRequest:baseRequest];
            }else{
                isSuccess = NO;
            }
            
            
        }else if(res.statusCode == 200){
            if([[res.allHeaderFields objectForKey:@"x-obs-api"] floatValue] >= 3.0){
                //采用自研协议
                
                baseRequest.protocolType = OBSProtocolTypeOBS;
                NSString *cacheValue = [NSString stringWithFormat:@"OBSProtocolTypeOBS+%@",timeSp];
                
                [self defaultsManagement:bucketName value:cacheValue type:@"write"];
                [defaults setBool:YES forKey:@"OBSProtocol"];
                [defaults synchronize];
                
            }else{
                //采用v2协议
                baseRequest.protocolType = OBSProtocolTypeOld;
                NSString *cacheValue = [NSString stringWithFormat:@"OBSProtocolTypeOld+%@",timeSp];
                
                [self defaultsManagement:bucketName value:cacheValue type:@"write"];
                [defaults setBool:NO forKey:@"OBSProtocol"];
                [defaults synchronize];
            }
            isSuccess = YES;
        }else{
            //采用v2协议
            baseRequest.protocolType = OBSProtocolTypeOld;
            NSString *cacheValue = [NSString stringWithFormat:@"OBSProtocolTypeOld+%@",timeSp];
            
            [self defaultsManagement:bucketName value:cacheValue type:@"write"];
            [defaults setBool:NO forKey:@"OBSProtocol"];
            [defaults synchronize];
            isSuccess = YES;
        }
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    //5.执行任务
    [dataTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return isSuccess;
    
}

// 用来读取缓存
-(NSString*)defaultsManagement:(NSString*)key value:(NSString*)value type:(NSString*)type{
    //从缓存中取出来的值
    NSString *valueStr;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 根据key的值分段锁
    int num = [self getnumber:key];
    if (@available(iOS 10.0, *)) {
        switch (num) {
            case 0:
                os_unfair_lock_lock(&lock0);
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                os_unfair_lock_unlock(&lock0);
                break;
            case 1:
                os_unfair_lock_lock(&lock1);
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                os_unfair_lock_unlock(&lock1);
                break;
            case 2:
                os_unfair_lock_lock(&lock2);
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                os_unfair_lock_unlock(&lock2);
                break;
            case 3:
                os_unfair_lock_lock(&lock3);
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                os_unfair_lock_unlock(&lock3);
                break;
            case 4:
                os_unfair_lock_lock(&lock4);
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                os_unfair_lock_unlock(&lock4);
                break;
            case 5:
                os_unfair_lock_lock(&lock5);
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                
                os_unfair_lock_unlock(&lock5);
                
                break;
            case 6:
                os_unfair_lock_lock(&lock6);
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                os_unfair_lock_unlock(&lock6);
                break;
            case 7:
                os_unfair_lock_lock(&lock7);
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                os_unfair_lock_unlock(&lock7);
                break;
            case 8:
                os_unfair_lock_lock(&lock8);
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                os_unfair_lock_unlock(&lock8);
                break;
            case 9:
                os_unfair_lock_lock(&lock9);
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                os_unfair_lock_unlock(&lock9);
                break;
                
            default:
                break;
        }
    }else{
        switch (num) {
            case 0:
                [_nslock0 lock];
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                [_nslock0 unlock];
                break;
            case 1:
                [_nslock1 lock];
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                [_nslock1 unlock];
                break;
            case 2:
                [_nslock2 lock];
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                [_nslock2 unlock];
                break;
            case 3:
                [_nslock3 lock];
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                [_nslock3 unlock];
                break;
            case 4:
                [_nslock4 lock];
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                [_nslock4 unlock];
                break;
            case 5:
                [_nslock5 lock];
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                
                [_nslock5 unlock];
                
                break;
            case 6:
                [_nslock6 lock];
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                [_nslock6 unlock];
                break;
            case 7:
                [_nslock7 lock];
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                [_nslock7 unlock];
                break;
            case 8:
                [_nslock8 lock];
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                [_nslock8 unlock];
                break;
            case 9:
                [_nslock9 lock];
                
                if([type isEqualToString:@"read"]){
                    valueStr = [defaults valueForKey:key];
                }else{
                    [defaults setObject:value forKey:key];
                }
                [defaults synchronize];
                [_nslock9 unlock];
                break;
                
            default:
                break;
        }
    }
    
    
    
    
    
    return valueStr;
}
//获取分段锁的值
-(int)getnumber:(NSString *)str{
    int temp = 0;
    for(int i=0;i<str.length;i++){
        int asciiCode = [str characterAtIndex:i];
        temp += asciiCode;
    }
    return temp % 10;
}
//sha算法
- (NSString *)sha1:(NSString *)inputString{
    NSData *data = [inputString dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes,(unsigned int)data.length,digest);
    NSMutableString *outputString = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [outputString appendFormat:@"%02x",digest[i]];
    }
    return [outputString lowercaseString];
}
@end
