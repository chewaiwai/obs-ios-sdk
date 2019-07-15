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
#import "OBSServiceCredentialProvider.h"
#import "OBSBaseCategory.h"
#import "OBSServiceUtils.h"
#import "OBSBaseNetworking.h"
#import "OBSBaseModel.h"
#import "CommonCrypto/CommonHMAC.h"
#import "OBSLogging.h"
#import "OBSServiceConstDefinition.h"
#import "OBSServiceBaseModel.h"
#import "OBSServiceCredentialProvider.h"

NSArray *GetCanonicalHeadersKey(NSDictionary *headers, NSArray *additionalKeys,BOOL isOBSProtocol){
    NSPredicate *predicate = NULL;
    if (isOBSProtocol){
         predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@%@%@",@"SELF beginswith[c] '",OBSCanonicalPrefix_OBS,@"'"]];
    }else{
        predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@%@%@",@"SELF beginswith[c] '",OBSCanonicalPrefix,@"'"]];
    }
    
    
    NSMutableArray *canonicalHeaders= [[[headers allKeys] filteredArrayUsingPredicate:predicate] mutableCopy];
    if(additionalKeys){
        [canonicalHeaders addObjectsFromArray:additionalKeys];
    }
    return [canonicalHeaders sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

NSString *GetCanonicalHeaderString(NSDictionary *headers ,NSArray *keyArray){
    NSRegularExpression *regExp = [[NSRegularExpression alloc] initWithPattern:@"[^\\S\r\n]+" options:0 error:nil];
    NSMutableString *headerString = [NSMutableString new];
    for(NSString *key in keyArray){
        NSString *value =  [[headers valueForKey:key] obs_trim];
        [headerString appendString:[key lowercaseString]];
        [headerString appendString:@":"];
        if([value canBeConvertedToEncoding:NSASCIIStringEncoding]){
            [headerString appendString:value];
        }else{
            [headerString appendString:[[value dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
        }
        [headerString appendString:@"\n"];
    }
    headerString =  [[regExp stringByReplacingMatchesInString:headerString options:0 range:NSMakeRange(0, [headerString length]) withTemplate:@" "] copy];
    return headerString;
}

NSString *V4GetCanonicalQueryString(NSDictionary *queries){
    NSMutableString *queryString = [NSMutableString new];
    BOOL firstTag=YES;
    for(NSString *key in [[queries allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]){
        if(firstTag){
            [queryString appendFormat:@"%@=%@",key,queries[key]];
            firstTag = NO;
        }else{
            [queryString appendFormat:@"&%@=%@",key,queries[key]];
        }
    }
    return queryString;
}
NSString *V4GetSignedHeaderString(NSDictionary *headers, NSArray *keyArray){
    NSMutableString *signedHeaderString = [NSMutableString new];
    BOOL firstTag=YES;
    for(NSString*key in keyArray){
        if(firstTag){
            [signedHeaderString appendString:[key lowercaseString]];
            firstTag=NO;
        }else{
            [signedHeaderString appendFormat:@";%@", [key lowercaseString]];
        }
    }
    return signedHeaderString;
}

NSString *V4GenerateQueryString(NSDictionary* queryParameters){
    NSMutableString *queryString = [NSMutableString new];
    if(![queryParameters count]){
        return queryString;
    }
    BOOL firstTag=YES;
    for(NSString *key in [[queryParameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]){
        NSString *value = queryParameters[key];
        if(firstTag){
            [queryString appendFormat:@"%@=",[key obs_stringWithURLEncodingAllowedSet]];
            if([value length]){
                [queryString appendFormat:@"%@",[value obs_stringWithURLEncodingAllowedSet]];
            }
            firstTag = NO;
        }else{
            [queryString appendFormat:@"&%@=",[key obs_stringWithURLEncodingAllowedSet]];
            if([value length]){
                [queryString appendFormat:@"%@",[value obs_stringWithURLEncodingAllowedSet]];
            }
        }
    }
    return [queryString copy];
}

NSString *V2GenerateQueryString(NSDictionary* queryParameters){
    MakeDispatchOnceArrayBEGIN
    array = @[OBSSubResourceACLKey,OBSSubResourceLifecycleKey,OBSSubResourceLocationKey,
              OBSSubResourceLoggingKey,OBSSubResourceNotificationKey,OBSSubResourcePartNumberKey,OBSSubResourcePolicyKey,OBSSubResourceUploadIDKey,OBSSubResourceUploadsKey,OBSSubResourceAppendKey,OBSSubResourceVersionIDKey,OBSSubResourceVersioningKey,OBSSubResourceVersionsKey,OBSSubResourcePositionKey,OBSSubResourceImageProcessKey,
              OBSSubResourceWebsiteKey,OBSSubResourceQuotaKey,OBSSubResourceStoragePolicyKey,OBSSubResourceStoragePolicyKey_OBS,OBSSubResourceReplicateBucketKey,
              OBSSubResourceStorageInfoKey,OBSSubResourceDeleteKey,OBSSubResourceCORSKey,
              OBSSubResourceRestoreKey,OBSSubResourceTaggingKey,
              OBSSubResourceResponseContentTypeKey,OBSSubResourceResponseContentLanguageKey,
              OBSSubResourceResponseExpiresKey,OBSSubResourceResponseCacheControlKey,
              OBSSubResourceResponseContentDispositionKey,OBSSubResourceResponseContentEncodingKey
              ];
    MakeDispatchOnceArrayEND
    NSMutableString *queryString = [NSMutableString new];
    if(![queryParameters count]){
        return queryString;
    }
    BOOL firstTag=YES;
    for(NSString *key in [[queryParameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]){
        NSString *value = queryParameters[key];
        if([array containsObject:key]){
            if(firstTag){
                [queryString appendFormat:@"?%@",[key obs_stringWithURLEncodingAllowedSet]];
                if([value length]){
                    [queryString appendFormat:@"=%@",[value obs_stringWithURLEncodingAllowedSet]];
                }
                firstTag = NO;
            }else{
                [queryString appendFormat:@"&%@",[key obs_stringWithURLEncodingAllowedSet]];
                if([value length]){
                    [queryString appendFormat:@"=%@",[value obs_stringWithURLEncodingAllowedSet]];
                }
            }
        }
    }
    return [queryString copy];
}

@implementation OBSStaticCredentialProvider
-(instancetype)init{
    if(self = [super init]){
        _authVersion = OBSAuthVersionV2;
        _protocolType = OBSProtocolTypeOBS;
        _isGetProtocol = YES;
        
    }
    return self;
}



- (instancetype)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey {
    return [self initWithAccessKey:accessKey secretKey:secretKey authVersion:OBSAuthVersionV2];
}



- (instancetype)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey authVersion:(OBSAuthVersion)authVersion{
    self = [self init];
    self.accessKey = [accessKey obs_trim];
    self.secretKey = [secretKey obs_trim];
    self.authVersion = authVersion;
    return self;
}

//- (instancetype)copyWithZone:(NSZone *)zone{
//    OBSStaticCredentialProvider *copy = [[[self class] allocWithZone:zone] initWithAccessKey:[_accessKey copy] secretKey:[_secretKey copy] authVersion:_authVersion];
//    return copy;
//}

+(void)processRequest:(OBSBaseNetworkingRequest*) request configuration:(OBSServiceConfiguration *const) configuration error:(NSError**)  error{
    [configuration.credentialProvider processRequest:request configuration:configuration error:error];
}

-(void)processRequest:(OBSBaseNetworkingRequest*) request configuration:(OBSServiceConfiguration *const) configuration error:(NSError**)  error{
    switch(_authVersion){
        case OBSAuthVersionV2:
            [self V2Sign:(OBSServiceNetworkingRequest*)request configuration:configuration error:error];
            break;
        case OBSAuthVersionV4:
            [self V4Sign:(OBSServiceNetworkingRequest*)request configuration:configuration error:error];
            break;
        default:
            break;
    }
}

#pragma mark - V2 sign

-(void) V2Sign:(OBSServiceNetworkingRequest*) request configuration:(OBSServiceConfiguration *const) configuration error:(NSError**) error{
    @autoreleasepool {
        NSString *canonicalResource = request.requestResourceString;
        //virtual host
        if(configuration.useVirtualhost){
            NSArray *resourceArray = [request.requestOriginalResourceString componentsSeparatedByString:@"/"];
            if([resourceArray count]>1 && [resourceArray[1] hasPrefix:@"${"]){
                NSString *bucketNameVariable = resourceArray[1];
                NSString *bucketNameKey = [bucketNameVariable componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"${}"]][2];
                NSString *bucketName = request.requestResourceParameters[bucketNameKey];
                NSMutableArray *urlStringArray = [[request.requestBaseURLString componentsSeparatedByString:@"//"] mutableCopy];
                if(!configuration.useCustomDomain){
                    urlStringArray[1] = [NSString stringWithFormat:@"%@.%@",bucketName,urlStringArray[1]];
                }
                request.requestBaseURLString = [urlStringArray componentsJoinedByString:@"//"];
                request.requestResourceString = [[request.requestOriginalResourceString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/%@",bucketNameVariable] withString:@""] obs_stringSubstituteWithDict:request.requestResourceParameters];
                if([request.requestResourceString isEqualToString:@""]){
                    request.requestResourceString = @"/";
                }
                if(!configuration.useCustomDomain){
                    request.requestHeadersParameters[OBSHeadersHostKey] = [NSString stringWithFormat:@"%@.%@",bucketName,configuration.url.host];
                }
                
                canonicalResource = [NSString stringWithFormat:@"/%@%@",bucketName, request.requestResourceString];
            }
        }
        
            // set xamzdate
        NSDate *date = [NSDate new];
        
        NSString *xamzDate = [OBSUtils getDateStringWithFormatString:date format:OBSDateRFC1123Format];
        
        switch (_protocolType) {
            case OBSProtocolTypeOBS:{
                [request.requestHeadersParameters setValue:xamzDate forKey:@"x-obs-date"];
                if(_securityToken){
                   [request.requestHeadersParameters setValue:_securityToken forKey:@"x-obs-security-token"];
                }
            }
                break;
            default:
                [request.requestHeadersParameters setValue:xamzDate forKey:@"x-amz-date"];
                if(_securityToken){
                    [request.requestHeadersParameters setValue:_securityToken forKey:@"x-amz-security-token"];
                }
                break;
        }
        
        
        NSString *httpVerb = [NSString obs_initWithOBSHTTPMethod:request.requestMethod];
        NSString *contentMD5 = [request.requestHeadersParameters valueForKey:OBSHeaderContentMD5Key];
        if(!contentMD5){
            if(request.calcBodyHash && request.requestBodyData){
                contentMD5 = [OBSUtils calBase64md5FromData:request.requestBodyData];
                [request.requestHeadersParameters setValue:contentMD5 forKey:OBSHeaderContentMD5Key];
            }else{
                contentMD5 = @"";
            }
        }
        NSString *contentType = [request.requestHeadersParameters objectForKey:OBSHeadersContentTypeKey] ? request.requestHeadersParameters[OBSHeadersContentTypeKey] : @"";
        NSString *dateString = @"";
        NSArray *canonicalHeadersKeys = GetCanonicalHeadersKey(request.requestHeadersParameters, nil,NO);
        switch (_protocolType) {
            case OBSProtocolTypeOBS:
                canonicalHeadersKeys = GetCanonicalHeadersKey(request.requestHeadersParameters, nil,YES);
                break;
                
            default:
                break;
        }
        NSString *canonicalHeadersString = GetCanonicalHeaderString(request.requestHeadersParameters, canonicalHeadersKeys);
       
        
        NSString *canonicalQueryString = V2GenerateQueryString(request.requestQueryParameters);
    canonicalQueryString = [canonicalQueryString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if(![canonicalQueryString isEqualToString:@""]){
            canonicalResource = [NSString stringWithFormat:@"%@%@",canonicalResource,canonicalQueryString];
        }
        
        
    
        
        
        NSString *stringToSign = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@%@",httpVerb,contentMD5,contentType,dateString,canonicalHeadersString,canonicalResource];
        
        NSString *signature = [[OBSUtils hmacWithString:stringToSign withKeyString:self.secretKey algorithm:kCCHmacAlgSHA1] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        NSString *prefix = @"AWS";
        switch (_protocolType) {
            case OBSProtocolTypeOBS:
                prefix = @"OBS";
                break;
                
            default: 
                prefix = @"AWS";
                break;
        }
        NSString *authorization = [NSString stringWithFormat:@"%@ %@:%@",prefix,self.accessKey,signature];
        
        [request.requestHeadersParameters setValue:authorization forKey:OBSHeadersAuthorizationKey];
    }
}


#pragma mark - V4 sign
-(void) V4Sign:(OBSServiceNetworkingRequest*) request configuration:(OBSServiceConfiguration *const) configuration error:(NSError**) error{
        //virtual host
    @autoreleasepool {
        if(configuration.useVirtualhost){
            NSArray *resourceArray = [request.requestOriginalResourceString componentsSeparatedByString:@"/"];
            if([resourceArray count]>1 && [resourceArray[1] hasPrefix:@"${"]){
                NSArray *resourceArray = [request.requestOriginalResourceString componentsSeparatedByString:@"/"];
                if([resourceArray count]>1 && [resourceArray[1] hasPrefix:@"${"]){
                    NSString *bucketNameVariable = resourceArray[1];
                    NSString *bucketNameKey = [bucketNameVariable componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"${}"]][2];
                    NSString *bucketName = request.requestResourceParameters[bucketNameKey];
                    NSMutableArray *urlStringArray = [[request.requestBaseURLString componentsSeparatedByString:@"//"] mutableCopy];
                    urlStringArray[1] = [NSString stringWithFormat:@"%@.%@",bucketName,urlStringArray[1]];
                    request.requestBaseURLString = [urlStringArray componentsJoinedByString:@"//"];
                    request.requestResourceString = [[request.requestOriginalResourceString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/%@",bucketNameVariable] withString:@""] obs_stringSubstituteWithDict:request.requestResourceParameters];
                    if([request.requestResourceString isEqualToString:@""]){
                        request.requestResourceString = @"/";
                    }
                    request.requestHeadersParameters[OBSHeadersHostKey] = [NSString stringWithFormat:@"%@.%@",bucketName,configuration.url.host];
                }
                
            }
        }
            // set xamzdate
        NSDate *date = [NSDate new];
            // for test
    //    date = [OBSUtils dateFromString:@"20171115T085952Z" format:OBSDateISO8601Format2];
            //test end
        NSString *xamzDate = [OBSUtils getDateStringWithFormatString:date format:OBSDateISO8601Format2];
        
        switch (_protocolType) {
            case OBSProtocolTypeOBS:{
                [request.requestHeadersParameters setValue:xamzDate forKey:@"x-obs-date"];
            }
                break;
            default:
                [request.requestHeadersParameters setValue:xamzDate forKey:@"x-amz-date"];
                break;
        }
        
        NSString *regionName = configuration.region?configuration.region:OBSDefaultRegion;
        NSString *serviceName = OBSServiceName;
        NSString *shortDate = [OBSUtils getDateStringWithFormatString:date format:OBSDateShortFormat];
        NSString *scope = [NSString stringWithFormat:@"%@/%@/%@/%@",
                           shortDate,
                           regionName,
                           serviceName,
                           OBSSigV4Terminator];
        NSString *authorizationHeaderString = [NSString stringWithFormat:@"%@ Credential=%@/%@,",
                                               OBSSigV4Algorithm,
                                               self.accessKey,
                                               scope];
        
        NSString *hashedPayload;
        if(request.calcBodyHash){
                //hash body
            hashedPayload =  [OBSUtils hexEncode:[[NSString alloc] initWithData:[OBSUtils sha256Hash:request.requestBodyData] encoding:NSASCIIStringEncoding]];
        }else{
                //hash with empty body
            hashedPayload = [OBSUtils hexEncode:[[NSString alloc] initWithData:[OBSUtils sha256Hash:[NSData new]] encoding:NSASCIIStringEncoding]];
        }
        [request.requestHeadersParameters setValue:hashedPayload forKey:OBSCanonicalContentSha256Key];
        
        NSString *httpVerb = [NSString obs_initWithOBSHTTPMethod:request.requestMethod];
        NSString *canonicalResource = request.requestResourceString ;
    
        NSString *canonicalQueryString = V4GenerateQueryString(request.requestQueryParameters);
        NSArray *canonicalHeadersKeys = GetCanonicalHeadersKey(request.requestHeadersParameters, @[OBSHeadersHostKey],NO) ;
        switch (_protocolType) {
            case OBSProtocolTypeOBS:{
                canonicalHeadersKeys = GetCanonicalHeadersKey(request.requestHeadersParameters, @[OBSHeadersHostKey],YES) ;
            }
                break;
            default:
                break;
        }
        canonicalHeadersKeys = [canonicalHeadersKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        NSString *canonicalHeadersString = GetCanonicalHeaderString(request.requestHeadersParameters,canonicalHeadersKeys);
        NSString *signedHeaders = V4GetSignedHeaderString(request.requestHeadersParameters, canonicalHeadersKeys);
        
        NSString *canocicalRequest = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@",httpVerb,canonicalResource,canonicalQueryString,canonicalHeadersString,signedHeaders,hashedPayload];
        NSString *hexedRequest = [OBSUtils hexEncode:[[NSString alloc]initWithData:[OBSUtils sha256HashString:canocicalRequest] encoding: NSASCIIStringEncoding]];
        NSString *stringToSign = [NSString stringWithFormat:@"%@\n%@\n%@\n%@",OBSSigV4Algorithm,xamzDate,scope,hexedRequest];
        OBSLogDebug(@"stringToSign=%@",stringToSign);
        
        NSData *dateKey = [OBSUtils sha256HmacWithString:shortDate withKeyString:[NSString stringWithFormat:@"%@%@",OBSSigV4Marker,self.secretKey]];
        NSData *dateRegionKey = [OBSUtils sha256HmacWithString:regionName withKeyData:dateKey];
        NSData *dateRegionServiceKey = [OBSUtils sha256HmacWithString:serviceName withKeyData:dateRegionKey];
        NSData *sigingKey = [OBSUtils sha256HmacWithString:OBSSigV4Terminator withKeyData:dateRegionServiceKey];
        NSData *signature = [OBSUtils sha256HmacWithString:stringToSign withKeyData:sigingKey];
        NSString *signatureString = [OBSUtils hexEncode:[[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding]];
        NSString *authorization = [NSString stringWithFormat:@"%@SignedHeaders=%@,Signature=%@",authorizationHeaderString,signedHeaders,signatureString];
        // 设置Authorization字段
        [request.requestHeadersParameters setValue:authorization forKey:OBSHeadersAuthorizationKey];
    }
}


@end

@interface OBSSTSCredentialProvider()
@property (nonatomic, strong, nonnull) OBSStaticCredentialProvider *innerStaticProvider;
@end
@implementation OBSSTSCredentialProvider
- (instancetype)initWithAccessKey:(NSString *)accessKey
                        secretKey:(NSString *)secretKey
                         stsToken:(NSString *)stsToken{
    return [self initWithAccessKey:accessKey secretKey:secretKey stsToken:stsToken authVersion:OBSAuthVersionV4];
}
- (instancetype)initWithAccessKey:(NSString *)accessKey
                        secretKey:(NSString *)secretKey
                         stsToken:(NSString *)stsToken
                      authVersion:(OBSAuthVersion) authVersion{
    if (self = [super init]) {
        self.accessKey = [accessKey obs_trim];
        self.secretKey = [secretKey obs_trim];
        self.authVersion = authVersion;
        self.stsToken = stsToken;
    }
    return self;
}
- (instancetype)copyWithZone:(NSZone *)zone{
    OBSSTSCredentialProvider *copy = [[[self class] allocWithZone:zone] initWithAccessKey:[self.accessKey copy]
                                                                                   secretKey:[self.secretKey copy]
                                                                                    stsToken:[self.stsToken copy]
                                                                                 authVersion:self.authVersion];
    return copy;
}
+(void)processRequest:(OBSBaseNetworkingRequest*) request
        configuration:(OBSServiceConfiguration *const) configuration
                error:(NSError**)  error{
    [request.requestHeadersParameters setValue:((OBSSTSCredentialProvider*)configuration.credentialProvider).stsToken forKey:OBSSTSTokenHeaderKey];
    [configuration.credentialProvider processRequest:request configuration:configuration error:error];
}
-(void)processRequest:(OBSBaseNetworkingRequest*) request configuration:(OBSServiceConfiguration *const) configuration error:(NSError**)  error{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.innerStaticProvider = [[OBSStaticCredentialProvider alloc] initWithAccessKey:self.accessKey secretKey:self.secretKey authVersion:self.authVersion];
    });
    switch(_authVersion){
        case OBSAuthVersionV2:
            [self.innerStaticProvider V2Sign:(OBSServiceNetworkingRequest*)request configuration:configuration error:error];
            break;
        case OBSAuthVersionV4:
            [self.innerStaticProvider V4Sign:(OBSServiceNetworkingRequest*)request configuration:configuration error:error];
            break;
        default:
            break;
    }
}
@end
