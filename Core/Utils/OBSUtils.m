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
#import "OBSUtils.h"
#import "CommonCrypto/CommonHMAC.h"
#import "OBSLogging.h"
#import "OBSBaseCategory.h"
#import "OBSXMLDictionary.h"

#import "OBSBaseModel.h"
#import "OBSBaseNetworking.h"
#import "OBSBolts.h"

@implementation OBSUtils
//+ (NSDictionary*) convertXMLStringToDict:(NSString*) xmlString error:(NSError**) error{
//    return [self convertXMLDataToDict:[xmlString dataUsingEncoding:NSUTF8StringEncoding] error:error];
//}

+ (NSDictionary*) convertXMLDataToDict:(NSData*) xmlData error:(NSError**) error{
    OBSXMLDictionaryParserWithFormat *parser = [OBSXMLDictionaryParserWithFormat new];
    parser.attributesMode = OBSXMLDictionaryAttributesModeDictionary;
    return [parser dictionaryWithData:xmlData];
}

+ (NSString*) convertDictToXMLString:(NSDictionary*) dict error:(NSError**) error{
    return [dict obs_XMLString];
}

+(NSMutableDictionary*) getDataDict:(OBSBaseRequest*) obsRequest
                      configuration:(OBSBaseConfiguration*) configuration
                        targetClazz:(Class) targetClazz
                              error:(NSError**) error{
    NSMutableDictionary *requestDataDict = [[OBSMTLJSONAdapterCustomized JSONDictionaryFromModel:obsRequest error:error] mutableCopy];
    if(*error){
        return nil;
    }
        //add networkingrequest additional data
    if([targetClazz conformsToProtocol:@protocol(OBSNetworkingRequestJSONDataProtocol) ]){
        [requestDataDict addEntriesFromDictionary:[targetClazz getAdditionalJSONDataIncludeParents]];
    }else{
        *error = [NSError errorWithDomain:OBSClientErrorDomain
                                    code:OBSErrorCodeClientErrorStatus
                                userInfo:@{
                                           @"reason": @"targetClazz not conforms OBSNetworkingRequestJSONDataProtocol"
                                           }
                 ];
    }
    return requestDataDict;
}

+(OBSBaseNetworkingRequest*) getNetworkingRequestFromDict:(Class) networkingClazz
                                                 dataDict:(NSDictionary*) dataDict
                                            configuration:(OBSBaseConfiguration*) configuration
                                                    error:(NSError**) error{
    
    OBSBaseNetworkingRequest *networkingRequest = [OBSMTLJSONAdapterCustomized modelOfClass:networkingClazz
                                                                         fromJSONDictionary:dataDict
                                                                                      error:error];
    if(*error){
        return nil;
    }
        //add default post processors
    for(Class clazz in [configuration getDefaultPostProcessors]){
        [networkingRequest.postProcessors addObject:clazz];
    }
        //add addon post processors
    for(Class clazz in networkingRequest.addonRequestPostProcessorsParameters){
        [networkingRequest.postProcessors addObject:clazz];
    }
        //add custom post processors
    for(NSString *clazzName in configuration.customProcessors){
        [networkingRequest.postProcessors addObject:NSClassFromString(clazzName)];
    }
        //add addon pre processors
    for(Class clazz in networkingRequest.addonResponsePreProcessorsParameters){
        [networkingRequest.preProcessors addObject:clazz];
    }
    
        //fill body data
    switch(networkingRequest.requestType){
        case OBSRequestTypeCommandRequest:{
            OBSNetworkingCommandRequest *request = (OBSNetworkingCommandRequest*) networkingRequest;
            if([request.requestBodyParameters count]){
                switch([[request class]GetBodyType]){
                    case OBSBodyTypeXML:
                        request.requestBodyData = [[OBSUtils convertDictToXMLString:request.requestBodyParameters error:error] dataUsingEncoding:NSUTF8StringEncoding];
                            //                        request.requestBodyData = [[request.requestBodyParameters OBSXMLString] dataUsingEncoding:NSUTF8StringEncoding];
                        break;
                    case OBSBodyTypeJSON:
                        request.requestBodyData = [NSJSONSerialization dataWithJSONObject:request.requestBodyParameters
                                                                                  options:NSJSONWritingPrettyPrinted
                                                                                    error:error];
                        break;
                    case OBSBodyTypeStringData:{
                        [request.requestBodyParameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                            request.requestBodyData = [obj dataUsingEncoding:NSUTF8StringEncoding];
                        }];
                    }
                        break;
                    default:
                        break;
                }
                if(*error){
                    [request.completionSource trySetError:*error];
                }
            }
            return request;
        }
            break;
        case OBSRequestTypeUploadDataRequest:{
            OBSNetworkingUploadDataRequest *request = (OBSNetworkingUploadDataRequest*) networkingRequest;
            request.requestBodyData = request.uploadData;
            return request;
        }
        default:
            break;
    }
    return networkingRequest;
    
}
+(__kindof OBSBaseNetworkingRequest*) convertOBSRequestToNetworkingRequestWithMTL:(OBSBaseRequest*) obsRequest
                                                                    configuration:(OBSBaseConfiguration*) configuration
                                                                      targetClazz:(Class) targetClazz
                                                                            error:(NSError**) error{
        //get input request data dict data
    NSMutableDictionary *requestDataDict = [self getDataDict:obsRequest
                                               configuration:configuration
                                                 targetClazz:targetClazz
                                                       error:error];

    OBSBaseNetworkingRequest *request = [self getNetworkingRequestFromDict:targetClazz
                                                                  dataDict:requestDataDict
                                                             configuration:configuration
                                                                     error:error];
    request.obsRequest = obsRequest;
    return request;
}
+(NSString*)generateQueryString:(NSDictionary*) queryParameters{
    NSMutableString *longQueryString = [NSMutableString new];
    NSMutableString *shortQueryString = [NSMutableString new];
    if(![queryParameters count]){
        return longQueryString;
    }
    for(NSString *key in [[queryParameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]){
        NSString *value = queryParameters[key];
        if([value length]){
            [longQueryString appendFormat:@"&%@=",[key obs_stringWithURLEncodingAllowedSet]];
            [longQueryString appendFormat:@"%@",[value obs_stringWithURLEncodingAllowedSet]];
        }else{
            [shortQueryString appendFormat:@"&%@",[key obs_stringWithURLEncodingAllowedSet]];
        }
    }
    return [NSString stringWithFormat:@"?%@", [[NSString stringWithFormat:@"%@%@",shortQueryString,longQueryString] substringFromIndex:1] ];
}
+ (NSDateFormatter *)getDateFormatterRFC1123{
    static NSDateFormatter *dateFormatter ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = [ NSTimeZone timeZoneWithName:@"GMT"];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = OBSDateRFC1123Format;
    });
    return dateFormatter;
}
+ (NSDateFormatter *)getDateFormatterISO8601Format3{
    static NSDateFormatter *dateFormatter ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = [ NSTimeZone timeZoneWithName:@"GMT"];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = OBSDateISO8601Format3;
    });
    return dateFormatter;
}
+ (NSString *)getDateStringWithFormatString:(NSDate*) date format:(NSString*) dateFormat{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.timeZone = [ NSTimeZone timeZoneWithName:@"GMT"];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = dateFormat;
    return [dateFormatter stringFromDate:date];
}
@end
