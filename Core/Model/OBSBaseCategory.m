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
#import "OBSBaseCategory.h"
#import "objc/runtime.h"
#import "OBSUtils.h"
#import "OBSMTLJSONAdapter.h"
#import "OBSMTLModel.h"
#import "OBSXMLDictionary.h"
#import "OBSBaseModel.h"
#import "OBSMTLValueTransformer.h"



@implementation NSString (OBS)

+ (instancetype)obs_initWithDataUTF8:(NSData *)data{
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (instancetype) obs_initWithOBSHTTPMethod:(OBSHTTPMethod)HTTPMethod{
    NSString *string = nil;
    switch(HTTPMethod){
        case OBSHTTPMethodGET:
            string = @"GET";
            break;
        case OBSHTTPMethodPUT:
            string = @"PUT";
            break;
        case OBSHTTPMethodHEAD:
            string = @"HEAD";
            break;
        case OBSHTTPMethodLOCK:
            string = @"LOCK";
            break;
        case OBSHTTPMethodMOVE:
            string = @"MOVE";
            break;
        case OBSHTTPMethodPOST:
            string = @"POST";
            break;
        case OBSHTTPMethodMKCOL:
            string = @"KCOL";
            break;
        case OBSHTTPMethodTRACE:
            string = @"TRACE";
            break;
        case OBSHTTPMethodDELETE:
            string = @"DELETE";
            break;
        case OBSHTTPMethodOPTIONS:
            string = @"OPTIONS";
            break;
        default:
            break;
    }
    return string;
}

- (nullable NSString*)obs_removeTailSlash{
    if ([self hasSuffix:@"/"]) {
        return [self substringToIndex:[self length]-1];
    } else {
        return self;
    }
}

//- (nullable NSString*)obs_stringByAppendingQueryStringForURL:(NSDictionary *)queryDict{
//    __block NSString *target = self;
//    __block BOOL firstTag = YES;
//    [queryDict enumerateKeysAndObjectsUsingBlock:^(id   key, id   obj, BOOL  * stop) {
//        if(firstTag){
//            target = [self stringByAppendingString:@"?"];
//            firstTag = NO;
//        }
//        target = [target stringByAppendingFormat:@"%@=%@",key,obj];
//    }];
//    return target;
//}

- (nullable NSString*)obs_trim {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(nullable NSString*)stringWithRepeatTimes:(NSInteger) times{
    return [@"" stringByPaddingToLength:times*[self length] withString:self  startingAtIndex:0];
}


//-(BOOL) obs_boolWithString{
//    if([self isEqualToString:@"YES"]){
//        return YES;
//    }else if([self isEqualToString:@"NO"]){
//        return NO;
//    }
//    return NO;
//}

//- (OBSHTTPMethod)obs_OBSHTTPMethodWithString{
//    OBSHTTPMethod method = OBSHTTPMethodNull0;
//    if([self isEqualToString:@"OBSHTTPMethodGET"]){
//        method = OBSHTTPMethodGET;
//    }else if([self isEqualToString:@"OBSHTTPMethodPUT"]){
//        method = OBSHTTPMethodPUT;
//    }else if([self isEqualToString:@"OBSHTTPMethodHEAD"]){
//        method = OBSHTTPMethodHEAD;
//    }else if([self isEqualToString:@"OBSHTTPMethodLOCK"]){
//        method = OBSHTTPMethodLOCK;
//    }else if([self isEqualToString:@"OBSHTTPMethodMOVE"]){
//        method = OBSHTTPMethodMOVE;
//    }else if([self isEqualToString:@"OBSHTTPMethodPOST"]){
//        method = OBSHTTPMethodPOST;
//    }else if([self isEqualToString:@"OBSHTTPMethodMKCOL"]){
//        method = OBSHTTPMethodMKCOL;
//    }else if([self isEqualToString:@"OBSHTTPMethodTRACE"]){
//        method = OBSHTTPMethodTRACE;
//    }else if([self isEqualToString:@"OBSHTTPMethodDELETE"]){
//        method = OBSHTTPMethodDELETE;
//    }else if([self isEqualToString:@"OBSHTTPMethodOPTIONS"]){
//        method = OBSHTTPMethodOPTIONS;
//    }else{
//        @throw [NSException exceptionWithName:@"Http method not valid" reason:@"Invalid http method." userInfo:@{@"method":self}];
//    }
//    return method;
//}

//-(OBSBodyType)obs_OBSBodyTypeWithString{
//    OBSBodyType type = OBSBodyTypeNull0;
//    if([self isEqualToString:@"OBSBodyTypeXML"]){
//        type = OBSBodyTypeXML;
//    }else if([self isEqualToString:@"OBSBodyTypeJSON"]){
//        type =  OBSBodyTypeJSON;
//    }
//    return type;
//}

-(nullable NSString*)obs_stringWithURLEncodingAllowedSet{
    NSMutableCharacterSet *allowedSet = [NSMutableCharacterSet characterSetWithCharactersInString:OBSURLAllowedSpecialCharacters];
    [allowedSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    return [self stringByAddingPercentEncodingWithAllowedCharacters:allowedSet];
}

//-(nullable NSString*)obs_stringWithURLEncodingAll{
//    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]];
//}
//-(nullable NSString*)obs_stringWithURLEncodingAllowedAlphanumeric{
//    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
//}

-(nullable NSString*)obs_stringSubstituteWithDict: (NSDictionary*) dict{
    __block NSString *target = [self copy];
    [dict enumerateKeysAndObjectsUsingBlock:^(id   key, id   obj, BOOL  * stop) {
        NSString *searchKey  = [NSString stringWithFormat:@"${%@}",key];
        if([target rangeOfString:searchKey].location != NSNotFound){
            target= [target stringByReplacingOccurrencesOfString:searchKey withString:(NSString*)obj];
        }
    }];
    return target;
}

//-(nullable NSString*)obs_XMLEncodeString{
//    NSDictionary *replaceDict = @{
//                                  @"&":@"&amp;",
//                                  @"<":@"&lt;",
//                                  @">":@"&gt;",
//                                  @"\"":@"&quot",
//                                  @"\'":@"&apos;",
//                                  };
//    for(NSString *k in replaceDict){
//        [self stringByReplacingOccurrencesOfString:k withString:replaceDict[k]];
//    }
//    return self;
//}
@end



@implementation  NSDictionary(OBS)
//- (NSString*)obs_convertDictionaryToXMLWithStartNode:(NSString*)startNode{
//    return [self obs_convertDictionaryToXMLWithStartNode:startNode isRoot:YES ident:0];
//}

- (NSString *)obs_innerXML:(NSInteger) ident{
    NSMutableArray *nodes = [NSMutableArray array];
    
    for (NSString *comment in [self comments]) {
        [nodes addObject:[NSString stringWithFormat:@"<!--%@-->", [comment OBSXMLEncodedString]]];
    }
    
    NSDictionary *childNodes = [self obs_childNodes];
    if([self objectForKey:OBSXMLDictionaryNodeOrderKey]){
        for (NSString *key in self[OBSXMLDictionaryNodeOrderKey]) {
            if([childNodes objectForKey:key]){
                [nodes addObject:[OBSXMLDictionaryParserWithFormat OBSXMLStringForNode:childNodes[key] withNodeName:key ident:ident]];
            }else{
                NSMutableArray *subKeys= [[key componentsSeparatedByString:@"."]mutableCopy];
                NSString *firstKey = [subKeys pop];
                NSMutableArray *remainingOrder =  [NSMutableArray array];
                for(NSString *item in self[OBSXMLDictionaryNodeOrderKey]){
                    NSMutableArray *tempArray = [[item componentsSeparatedByString:@"."]mutableCopy];
                    [tempArray pop];
                    [remainingOrder addObject:[tempArray componentsJoinedByString:@"."]];
                }
                childNodes[firstKey][OBSXMLDictionaryNodeOrderKey] = remainingOrder;
                [nodes addObject:[childNodes obs_innerXML:ident]];
                break;
            }
        }
    }else{
        for (NSString *key in childNodes) {
            [nodes addObject:[OBSXMLDictionaryParserWithFormat OBSXMLStringForNode:childNodes[key] withNodeName:key ident:ident]];
        }
    }
    
    NSString *text = [self innerText];
    if (text) {
        [nodes addObject:[text OBSXMLEncodedString]];
    }
    
    return [nodes componentsJoinedByString:@"\n"];
}

- (nullable NSDictionary<NSString *, NSString *> *)obs_attributes
{
    NSDictionary<NSString *, NSString *> *attributes = self[OBSXMLDictionaryAttributesKey];
    if (attributes)
        {
        return attributes.count? attributes: nil;
        }
    else
        {
        NSMutableDictionary<NSString *, id> *filteredDict = [NSMutableDictionary dictionaryWithDictionary:self];
        [filteredDict removeObjectsForKeys:@[OBSXMLDictionaryCommentsKey, OBSXMLDictionaryTextKey, OBSXMLDictionaryNodeNameKey, OBSXMLDictionaryNodeOrderKey]];
        for (NSString *key in filteredDict.allKeys)
            {
            [filteredDict removeObjectForKey:key];
            if ([key hasPrefix:OBSXMLDictionaryAttributePrefix])
                {
                filteredDict[[key substringFromIndex:OBSXMLDictionaryAttributePrefix.length]] = self[key];
                }
            }
        return filteredDict.count? filteredDict: nil;
        }
    return nil;
}

-(NSString*)obs_XMLString{
    if (self.count == 1 && ![self nodeName]) {
            //ignore outermost dictionary
        return [self obs_innerXML:0];
    } else {
        return [OBSXMLDictionaryParserWithFormat OBSXMLStringForNode:self withNodeName:[self nodeName] ?: @"root" ident:0];
    }
}

- (nullable NSDictionary *)obs_childNodes{
    NSMutableDictionary *filteredDict = [self mutableCopy];
    [filteredDict removeObjectsForKeys:@[OBSXMLDictionaryAttributesKey, OBSXMLDictionaryCommentsKey, OBSXMLDictionaryTextKey, OBSXMLDictionaryNodeNameKey, OBSXMLDictionaryNodeOrderKey]];
    for (NSString *key in filteredDict.allKeys)
        {
        if ([key hasPrefix:OBSXMLDictionaryAttributePrefix])
            {
            [filteredDict removeObjectForKey:key];
            }
        }
    return filteredDict.count? filteredDict: nil;
}

//- (NSString*)obs_convertDictionaryToXMLWithStartNode:(NSString*)startNode isRoot:(BOOL) isRoot ident:(int) ident{
//    NSMutableString *xml = [[NSMutableString alloc] initWithString:@""];
//    NSArray *propertyArray = [self allKeys];
//    if(isRoot){
//        [xml appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
//    }
//    if(startNode){
//        [xml appendString:[@" " stringWithRepeatTimes:ident]];
//        [xml appendString:[NSString stringWithFormat:@"<%@>\n", startNode]];
//    }
//    for(int i=0; i < [propertyArray count]; i++){
//        NSString *nodeName = [propertyArray objectAtIndex:i];
//        id nodeValue = [self objectForKey:nodeName];
//        if([nodeValue isKindOfClass:[NSArray class]]) {
//            [xml appendString:[@" " stringWithRepeatTimes:ident+1]];
//            [xml appendString:[NSString stringWithFormat:@"<%@>\n",nodeName]];
//            if([nodeValue count]>0) {
//                for(int j=0;j<[nodeValue count];j++) {
//                    id value = [nodeValue objectAtIndex:j];
//                    if([value isKindOfClass:[NSDictionary class]]) {
//                        if(startNode){
//                            [xml appendString:[value obs_convertDictionaryToXMLWithStartNode:nil isRoot:NO ident:ident+1]];
//                        }else{
//                            [xml appendString:[value obs_convertDictionaryToXMLWithStartNode:nil isRoot:NO ident:ident]];
//                        }
//                    }
//                }
//            }
//            [xml appendString:[@" " stringWithRepeatTimes:ident+1]];
//            [xml appendString:[NSString stringWithFormat:@"</%@>\n",nodeName]];
//        } else if([nodeValue isKindOfClass:[NSDictionary class]]) {
//            if(startNode){
//                [xml appendString:[nodeValue obs_convertDictionaryToXMLWithStartNode:nodeName isRoot:NO ident:ident+1]];
//            }else{
//                [xml appendString:[nodeValue obs_convertDictionaryToXMLWithStartNode:nodeName isRoot:NO ident:ident]];
//            }
//        } else {
//            if(startNode){
//                [xml appendString:[@" " stringWithRepeatTimes:ident+1]];
//            }
//            [xml appendString:[NSString stringWithFormat:@"<%@>",nodeName]];
//            [xml appendString:[NSString stringWithFormat:@"%@",nodeValue]];
//            [xml appendString:[NSString stringWithFormat:@"</%@>\n",nodeName]];
//        }
//    }
//    if(startNode){
//        [xml appendString:[@" " stringWithRepeatTimes:ident]];
//        [xml appendString:[NSString stringWithFormat:@"</%@>\n",startNode]];
//    }
//    if(isRoot){
//        return [xml obs_XMLEncodeString];
//    }else{
//        return xml;
//    }
//}
@end

@implementation NSMutableArray(OBS)
-(id)pop{
    if([self count] == 0){
        return nil;
    }
    id head = [self objectAtIndex:0];
    if(head != nil){
        [self removeObjectAtIndex:0];
    }
    return head;
}
-(void)push:(id)obj{
    [self addObject:obj];
}
@end

@implementation NSURLSessionTask(OBS)
-(OBSBaseNetworkingRequest*)obsNetworkingRequest{
    return objc_getAssociatedObject(self, _cmd);
}

-(void)setObsNetworkingRequest:(OBSBaseNetworkingRequest*) networkingRequest{
    objc_setAssociatedObject(self,@selector(obsNetworkingRequest), networkingRequest, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end


@implementation OBSMTLValueTransformer(OBS)
//+(NSValueTransformer*)obs_mtl_nsnumberIntegerTransformer{
//        //forward: from json to property
//        //reverse: from property to json
//    MakeDispatchOnceTransformerBEGIN
//    transformer = [OBSMTLValueTransformer transformerUsingForwardBlock:^id(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
//        return [NSNumber numberWithInteger:[value integerValue]];
//    } reverseBlock:^id(NSNumber *value, BOOL *success, NSError *__autoreleasing *error) {
//        return [NSString stringWithFormat:@"%li",(long)[value integerValue]];
//    }];
//    MakeDispatchOnceTransformerEND
//    return transformer;
//}

+(NSValueTransformer*)obs_mtl_nsnumberLongLongTransformer{
        //forward: from json to property
        //reverse: from property to json
    MakeDispatchOnceTransformerBEGIN
    transformer = [OBSMTLValueTransformer transformerUsingForwardBlock:^id(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        return [NSNumber numberWithLongLong:[value longLongValue]];
    } reverseBlock:^id(NSNumber *value, BOOL *success, NSError *__autoreleasing *error) {
        return [NSString stringWithFormat:@"%li",(long)[value longLongValue]];
    }];
    MakeDispatchOnceTransformerEND
    return transformer;
}
+(NSValueTransformer*)obs_mtl_nsnumberUIntegerTransformer{
    MakeDispatchOnceTransformerBEGIN
    transformer = [OBSMTLValueTransformer transformerUsingForwardBlock:^id(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        return [NSNumber numberWithUnsignedInteger:[value longLongValue]];
    } reverseBlock:^id(NSNumber *value, BOOL *success, NSError *__autoreleasing *error) {
        return [NSString stringWithFormat:@"%li",(long)[value unsignedIntegerValue]];
    }];
    MakeDispatchOnceTransformerEND
    return transformer;
}
+(NSValueTransformer*)obs_mtl_nsdateRFC1123Transformer{
    MakeDispatchOnceTransformerBEGIN
    transformer = [OBSMTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return [[OBSUtils getDateFormatterRFC1123] dateFromString:value];
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return [[OBSUtils getDateFormatterRFC1123] stringFromDate:value];
    }];
    MakeDispatchOnceTransformerEND
    return transformer;
}

+(NSValueTransformer*)obs_mtl_nsdateIOS8601Format3Transformer{
    MakeDispatchOnceTransformerBEGIN
    transformer = [OBSMTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return [[OBSUtils getDateFormatterISO8601Format3] dateFromString:value];
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return [[OBSUtils getDateFormatterISO8601Format3] stringFromDate:value];
    }];
    MakeDispatchOnceTransformerEND
    return transformer;
}

//+(NSValueTransformer*)obs_mtl_filterNullStringTransformer{
//    MakeDispatchOnceTransformerBEGIN
//    transformer = [OBSMTLValueTransformer transformerUsingForwardBlock:^id(NSString* value, BOOL *success, NSError *__autoreleasing *error) {
//        if([value isEqualToString:@"null"]){
//            return nil;
//        }
//        return value;
//    } reverseBlock:^id(NSString* value, BOOL *success, NSError *__autoreleasing *error) {
//        if([value isEqualToString:@"null"]){
//            return nil;
//        }
//        return value;
//    }];
//    MakeDispatchOnceTransformerEND
//    return transformer;
//}
@end
