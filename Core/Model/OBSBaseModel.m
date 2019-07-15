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
#import "OBSBaseModel.h"
#import "OBSBaseNetworking.h"
#import "OBSUtils.h"
#import <objc/runtime.h>
#import "OBSMTLReflection.h"
#import "OBSEXTRuntimeExtensions.h"
#import "OBSEXTScope.h"
#import "NSDictionary+OBSMTLJSONKeyPath.h"
#import "OBSLogging.h"
#import "OBSBFTaskCompletionSource.h"

//#pragma mark - SafeMutableDictionary
//
//@interface OBSSafeMutableDictionary()
//{
//    NSMutableDictionary *_dict;
//}
//@end
//@implementation OBSSafeMutableDictionary
//- (id) objectForKey:(id)aKey{
//    return [_dict objectForKey:aKey];
//}
//-(instancetype)init{
//    if(self = [super init]){
//        _dict = [NSMutableDictionary dictionary];
//        return self;
//    }
//    return nil;
//}
//-(void)setObject:(id)anObject forKey:(id<NSCopying>)aKey{
//    @synchronized (self) {
//        [_dict setObject:anObject forKey:aKey];
//    }
//}
//-(void)removeObjectForKey:(id)aKey{
//    @synchronized (self) {
//        [_dict removeObjectForKey:aKey];
//    }
//}
//
//@end
//
//#pragma mark - OBSOrderedMutableDictionary
//@interface OBSOrderedMutableDictionary()
//{
//    NSMutableDictionary *_dict;
//    NSMutableArray *_array;
//}
//@end
//@implementation OBSOrderedMutableDictionary
//-(instancetype)init{
//    if(self = [super init]){
//        _dict = [NSMutableDictionary dictionary];
//        _array = [NSMutableArray array];
//        return self;
//    }
//    return nil;
//}
//- (id) objectForKey:(id)aKey{
//    return [_dict objectForKey:aKey];
//}
//-(void)setObject:(id)anObject forKey:(id<NSCopying>)aKey{
//    if(![_array containsObject:aKey]){
//        [_array addObject:aKey];
//    }
//    [_dict setObject:anObject forKey:aKey];
//}
//-(void)removeObjectForKey:(id)aKey{
//    [_dict removeObjectForKey:aKey];
//    [_array removeObject:aKey];
//}
//- (NSUInteger)count{
//    return [_dict count];
//}
//- (NSEnumerator*)keyEnumerator{
//    return [_array objectEnumerator];
//}
//@end

#pragma mark - OBSWeakMutableArray
@interface OBSWeakMutableArray()
{
    NSMutableArray *_array;
}
@end
@implementation OBSWeakMutableArray
-(OBSWeakMutableArray*)initWithCapacity:(NSUInteger)numItems{
    if(self = [super init]){
        _array = [NSMutableArray array];
    }
    return self;
}
-(NSUInteger)count{
    return [_array count];
}
-(void)addObject:(id)anObject{
    __weak id weakRef = anObject;
    [_array addObject:weakRef];
}
-(void)removeObject:(id)anObject{
    [_array removeObject:anObject];
}
-(void)removeObjectAtIndex:(NSUInteger)index{
    [_array removeObjectAtIndex:index];
}
-(id)objectAtIndex:(NSUInteger)index{
    return [_array objectAtIndex:index];
}
@end




#pragma mark configuration
@implementation OBSHTTPProxyConfiguration : NSObject

-(instancetype)initWithType:(OBSHTTPProxyType) proxyType proxyHost:(NSString*) host proxyPort:(NSUInteger) port{
    if(self = [super init]){
        _proxyType = proxyType;
        _proxyHost = host;
        _proxyPort = [NSNumber numberWithUnsignedInteger:port];
    }
    return self;
}
-(NSDictionary*) getProxyDict{
    NSMutableDictionary *proxyDict = [NSMutableDictionary dictionary];
    
    switch (_proxyType) {
        case OBSHTTPRroxyTypeHTTP:
            [proxyDict setValue:@YES forKey:@"HTTPEnable"];
            [proxyDict setValue:_proxyHost forKey:(__bridge_transfer NSString *)kCFStreamPropertyHTTPProxyHost];
            [proxyDict setValue:_proxyPort forKey:(__bridge_transfer NSString *)kCFStreamPropertyHTTPProxyPort];
            break;
        case OBSHTTPRroxyTypeHTTPS:
            [proxyDict setValue:@YES forKey:@"HTTPSEnable"];
            [proxyDict setValue:_proxyHost forKey:(__bridge_transfer NSString *)kCFStreamPropertyHTTPSProxyHost];
            [proxyDict setValue:_proxyPort forKey:(__bridge_transfer NSString *)kCFStreamPropertyHTTPSProxyPort];
            break;
        case OBSHTTPRroxyTypeHTTPAndHTTPS:
            [proxyDict setValue:@YES forKey:@"HTTPEnable"];
            [proxyDict setValue:_proxyHost forKey:(__bridge_transfer NSString *)kCFStreamPropertyHTTPProxyHost];
            [proxyDict setValue:_proxyPort forKey:(__bridge_transfer NSString *)kCFStreamPropertyHTTPProxyPort];
            [proxyDict setValue:@YES forKey:@"HTTPSEnable"];
            [proxyDict setValue:_proxyHost forKey:(__bridge_transfer NSString *)kCFStreamPropertyHTTPSProxyHost];
            [proxyDict setValue:_proxyPort forKey:(__bridge_transfer NSString *)kCFStreamPropertyHTTPSProxyPort];
            break;
        default:
            break;
    }
    if(self.username && self.password){
        [proxyDict setValue:_username forKey:(__bridge_transfer NSString *) kCFProxyUsernameKey];
        [proxyDict setValue:_password forKey:(__bridge_transfer NSString *) kCFProxyPasswordKey];
    }

    return proxyDict;
}
//-(instancetype)copyWithZone:(NSZone*)zone{
//    OBSHTTPProxyConfiguration *copy = [[[self class] allocWithZone:zone]initWithType:self.proxyType proxyHost:[self.proxyHost copy] proxyPort:[self.proxyPort intValue]];
//    return copy;
//}
@end

@interface OBSBaseConfiguration()
@property (nonatomic, readonly, nonnull) NSArray *defaultPostProcessors;
@end
@implementation OBSBaseConfiguration
-(instancetype)init{
    if(self = [super init]){
        self.enableURLEncoding = YES;
        
        self.maxConcurrentCommandRequestCount = maxConcurrentRequestCountDefault;
        self.maxConcurrentUploadRequestCount = maxConcurrentRequestCountDefault;
        self.maxConcurrentDownloadRequestCount = maxConcurrentRequestCountDefault;
        self.commandSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.commandSessionConfiguration.URLCache = nil;
        self.commandSessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        self.uploadSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.uploadSessionConfiguration.URLCache = nil;
        self.uploadSessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        self.downloadSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.downloadSessionConfiguration.URLCache = nil;
        self.downloadSessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        self.backgroundUploadSessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:OBSUploadBackgroundIdentifierDefault];
        self.backgroundUploadSessionConfiguration.URLCache = nil;
        self.backgroundUploadSessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        self.backgroundDownloadSessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:OBSDownloadBackgroundIdentifierDefault];
        self.backgroundDownloadSessionConfiguration.URLCache = nil;
        self.backgroundDownloadSessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        _defaultPostProcessors =   @[OBSRequestURLStringPostProcessor.class,
                                     OBSURLEncodingPostProcessor.class,\
                                     OBSResouceParameterPostProcessor.class,\
                                     OBSHeaderUAPostProcessor.class, \
                                     OBSHeaderContentLengthPostProcessor.class,\
                                     OBSHeaderContentTypePostProcessor.class,\
                                     OBSHeaderHostPostProcessor.class,\
                                     ];
    }
    return self;
}
-(instancetype) initWithURL:(NSURL*) url {
    self = [self init];
    _url = url;
    return self;
}
-(NSArray*)getDefaultPostProcessors{
    return _defaultPostProcessors;
}
-(OBSHTTPProxyConfiguration*)getProxyConfig{
    return _proxyConfig;
}
-(void)setProxyConfig:(OBSHTTPProxyConfiguration *)proxyConfig{
    _proxyConfig = proxyConfig;
    if (proxyConfig) {
        NSDictionary *proxyDict = [proxyConfig getProxyDict];
        self.commandSessionConfiguration.connectionProxyDictionary = proxyDict;
        self.uploadSessionConfiguration.connectionProxyDictionary = proxyDict;
        self.downloadSessionConfiguration.connectionProxyDictionary = proxyDict;
        self.backgroundUploadSessionConfiguration.connectionProxyDictionary = proxyDict;
        self.backgroundDownloadSessionConfiguration.connectionProxyDictionary = proxyDict;
    }
}

@end

#pragma mark MTLJSONAdaptor and XML Parser
SuppressMethodDefinitionNotFoundWarning(
@implementation OBSMTLJSONAdapterCustomized: OBSMTLJSONAdapter
                                        )
-(NSDictionary*)JSONKeyPathsByPropertyKeyWithParents:(Class)modelClass{
    Class parentClass = class_getSuperclass(modelClass);
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if([parentClass conformsToProtocol:@protocol(OBSMTLJSONSerializing) ]){
        [dict addEntriesFromDictionary:[self JSONKeyPathsByPropertyKeyWithParents:parentClass]];
    }
    [dict addEntriesFromDictionary:[modelClass JSONKeyPathsByPropertyKey]];
    return dict;
}
- (NSArray*)serializablePropertyKeysArray:(NSArray *)propertyKeys forModel:(id<OBSMTLJSONSerializing>)model {
    NSMutableArray *nonnilArray = [NSMutableArray array];
    for(NSString *propertyKey in propertyKeys){
        id value = model.dictionaryValue[propertyKey];
        if(value == nil || value == [NSNull null]){
            continue;
        }
        [nonnilArray addObject:propertyKey];
    }
    return nonnilArray;
}
-(void)setModelClass:(Class)clazz{
    [self setValue:clazz forKey:@"_modelClass"];
}
-(void)setJSONKeyPathsByPropertyKey:(NSDictionary*)dict{
    [self setValue:dict forKey:@"_JSONKeyPathsByPropertyKey"];
}
-(void)setValueTransformersByPropertyKey:(NSDictionary*)dict{
    [self setValue:dict forKey:@"_valueTransformersByPropertyKey"];
}
-(void)setJSONAdaptersByModelClass:(NSMapTable*)dict{
    [self setValue:dict forKey:@"_JSONAdaptersByModelClass"];
}
- (id)initWithModelClass:(Class)modelClass {
    NSParameterAssert(modelClass != nil);
    NSParameterAssert([modelClass conformsToProtocol:@protocol(OBSMTLJSONSerializing)]);
    
    self = [super initWithModelClass:modelClass];
    if (self == nil) return nil;
    
    self.modelClass = modelClass;
    
        //keypath with parents
    self.JSONKeyPathsByPropertyKey = [self JSONKeyPathsByPropertyKeyWithParents:modelClass];
    
    NSSet *propertyKeys = [self.modelClass propertyKeys];
    
    for (NSString *mappedPropertyKey in self.JSONKeyPathsByPropertyKey) {
        if (![propertyKeys containsObject:mappedPropertyKey]) {
            NSAssert(NO, @"%@ is not a property of %@.", mappedPropertyKey, modelClass);
            return nil;
        }
        
        id value = self.JSONKeyPathsByPropertyKey[mappedPropertyKey];
        
        if ([value isKindOfClass:NSArray.class]) {
            for (NSString *keyPath in value) {
                if ([keyPath isKindOfClass:NSString.class]) continue;
                
                NSAssert(NO, @"%@ must either map to a JSON key path or a JSON array of key paths, got: %@.", mappedPropertyKey, value);
                return nil;
            }
        } else if (![value isKindOfClass:NSString.class]) {
            NSAssert(NO, @"%@ must either map to a JSON key path or a JSON array of key paths, got: %@.",mappedPropertyKey, value);
            return nil;
        }
    }
    
    self.valueTransformersByPropertyKey = [self.class valueTransformersForModelClass:modelClass];
    
    self.JSONAdaptersByModelClass = [NSMapTable strongToStrongObjectsMapTable];
    
    return self;
}
+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass {
    NSParameterAssert(modelClass != nil);
    NSParameterAssert([modelClass conformsToProtocol:@protocol(OBSMTLJSONSerializing)]);
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    for (NSString *key in [modelClass propertyKeys]) {
        SEL selector = OBSMTLSelectorWithKeyPattern(key, "JSONTransformer");
        if ([modelClass respondsToSelector:selector]) {
            IMP imp = [modelClass methodForSelector:selector];
            NSValueTransformer  *(*function)(id, SEL) = (__typeof__(function))imp;
            NSValueTransformer *transformer = function(modelClass, selector);
            
            if (transformer != nil) result[key] = transformer;
            
            continue;
        }
        
        if ([modelClass respondsToSelector:@selector(JSONTransformerForKey:)]) {
            NSValueTransformer *transformer = [modelClass JSONTransformerForKey:key];
            
            if (transformer != nil) {
                result[key] = transformer;
                continue;
            }
        }
        
        objc_property_t property = class_getProperty(modelClass, key.UTF8String);
        
        if (property == NULL) continue;
        
        obs_mtl_propertyAttributes *attributes = obs_mtl_copyPropertyAttributes(property);
        @obs_onExit {
            free(attributes);
        };
        
        NSValueTransformer *transformer = nil;
        
        if (*(attributes->type) == *(@encode(id))) {
            Class propertyClass = attributes->objectClass;
            
            if (propertyClass != nil) {
                transformer = [self transformerForModelPropertiesOfClass:propertyClass];
            }
            
            
                // For user-defined OBSMTLModel, try parse it with dictionaryTransformer.
            if (nil == transformer && [propertyClass conformsToProtocol:@protocol(OBSMTLJSONSerializing)]) {
                transformer = [self dictionaryTransformerWithModelClass:propertyClass];
            }
            
            if (transformer == nil) transformer = [self obs_mtl_validatingTransformerForClass:propertyClass ?: NSObject.class];
        } else {
            transformer = [self transformerForModelPropertiesOfObjCType:attributes->type] ?: [NSValueTransformer obs_mtl_validatingTransformerForClass:NSValue.class];
        }
        
        if (transformer != nil) result[key] = transformer;
    }
    
    return result;
}

+ (NSValueTransformer<OBSMTLTransformerErrorHandling> *)obs_mtl_validatingTransformerForClass:(Class)modelClass {
    NSParameterAssert(modelClass != nil);
    
    return [OBSMTLValueTransformer transformerUsingForwardBlock:^ id (id value, BOOL *success, NSError **error) {
        if (value !=nil && [modelClass isSubclassOfClass:NSArray.class]){
            return @[value];
        }
        if (value != nil && ![value isKindOfClass:modelClass]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Value did not match expected type", @""),
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected %1$@ to be of class %2$@ but got %3$@", @""), value, modelClass, [value class]],
                                           OBSMTLTransformerErrorHandlingInputValueErrorKey : value
                                           };
                
                *error = [NSError errorWithDomain:OBSMTLTransformerErrorHandlingErrorDomain code:OBSMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;
        }
        
        return value;
    }];
}

+ (NSValueTransformer<OBSMTLTransformerErrorHandling> *)arrayTransformerWithModelClass:(Class)modelClass {
    id<OBSMTLTransformerErrorHandling> dictionaryTransformer = [self dictionaryTransformerWithModelClass:modelClass];
    
    return [OBSMTLValueTransformer
            transformerUsingForwardBlock:^ id (NSArray *dictionaries, BOOL *success, NSError **error) {
                if (dictionaries == nil) return nil;
                if (![dictionaries isKindOfClass:NSArray.class]) {
                    if([dictionaries isKindOfClass:NSDictionary.class]){
                            //item array with encapsulation
                        NSDictionary* keyDict = [modelClass JSONKeyPathsByPropertyKey];
                        NSDictionary* dict = (NSDictionary*)dictionaries;
                        __block BOOL isEncapsulatedDictItem = NO;
                        __block NSString *encapsulateHeader;
                        [keyDict enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, NSString* _Nonnull obj, BOOL * _Nonnull stop) {
                            NSRange range = [obj rangeOfString:@"."];
                            if(range.location != NSNotFound ){
                                encapsulateHeader = [obj substringToIndex:range.location];
                                isEncapsulatedDictItem = YES;
                                *stop = YES;
                                return;
                            }
                        }];
                        if(isEncapsulatedDictItem){
                            id valueArrayorDict = dict[encapsulateHeader];
                                //when multiple items , the valueArrayorDict is an array
                            if([valueArrayorDict isKindOfClass:NSArray.class]){
                                NSMutableArray *newArray = [NSMutableArray array];
                                for(id value in valueArrayorDict){
                                    [newArray addObject:@{encapsulateHeader:value}];
                                }
                                dictionaries =  newArray;
                            }else{
                                    //when single item , the valueArrayorDict is a dict
                                dictionaries = @[dictionaries];
                            }
                            
                        }else{
                            dictionaries = @[dictionaries];
                        }
                        
                    }
                }
                
                if (![dictionaries isKindOfClass:NSArray.class]) {
                    if (error != NULL) {
                        NSDictionary *userInfo = @{
                                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
                                                   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), dictionaries],
                                                   OBSMTLTransformerErrorHandlingInputValueErrorKey : dictionaries
                                                   };
                        
                        *error = [NSError errorWithDomain:OBSMTLTransformerErrorHandlingErrorDomain code:OBSMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                    }
                    *success = NO;
                    return nil;
                }
                
                NSMutableArray *models = [NSMutableArray arrayWithCapacity:dictionaries.count];
                for (id JSONDictionary in dictionaries) {
                    if (JSONDictionary == NSNull.null) {
                        [models addObject:NSNull.null];
                        continue;
                    }
                    
                    if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
                        if (error != NULL) {
                            NSDictionary *userInfo = @{
                                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
                                                       NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary or an NSNull, got: %@.", @""), JSONDictionary],
                                                       OBSMTLTransformerErrorHandlingInputValueErrorKey : JSONDictionary
                                                       };
                            
                            *error = [NSError errorWithDomain:OBSMTLTransformerErrorHandlingErrorDomain code:OBSMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                        }
                        *success = NO;
                        return nil;
                    }
                    
                    id model = [dictionaryTransformer transformedValue:JSONDictionary success:success error:error];
                    
                    if (*success == NO) return nil;
                    
                    if (model == nil) continue;
                    
                    [models addObject:model];
                }
                
                return models;
            }
            reverseBlock:^ id (NSArray *models, BOOL *success, NSError **error) {
                if (models == nil) return nil;
                
                if (![models isKindOfClass:NSArray.class]) {
                    if (error != NULL) {
                        NSDictionary *userInfo = @{
                                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert model array to JSON array", @""),
                                                   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), models],
                                                   OBSMTLTransformerErrorHandlingInputValueErrorKey : models
                                                   };
                        
                        *error = [NSError errorWithDomain:OBSMTLTransformerErrorHandlingErrorDomain code:OBSMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                    }
                    *success = NO;
                    return nil;
                }
                
                NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:models.count];
                for (id model in models) {
                    if (model == NSNull.null) {
                        [dictionaries addObject:NSNull.null];
                        continue;
                    }
                    
                    if (![model isKindOfClass:OBSMTLModel.class]) {
                        if (error != NULL) {
                            NSDictionary *userInfo = @{
                                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
                                                       NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected a OBSMTLModel or an NSNull, got: %@.", @""), model],
                                                       OBSMTLTransformerErrorHandlingInputValueErrorKey : model
                                                       };
                            
                            *error = [NSError errorWithDomain:OBSMTLTransformerErrorHandlingErrorDomain code:OBSMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                        }
                        *success = NO;
                        return nil;
                    }
                    
                    NSDictionary *dict;

                    dict = [dictionaryTransformer reverseTransformedValue:model success:success error:error];
                    if (*success == NO) return nil;
                    
                    if (dict == nil) continue;
                    
                    [dictionaries addObject:dict];
                }
                
                return dictionaries;
            }];
}

- (NSDictionary *)JSONDictionaryFromModel:(id<OBSMTLJSONSerializing>)model error:(NSError **)error {
    NSParameterAssert(model != nil);
    NSParameterAssert([model isKindOfClass:self.modelClass]);
    
    if (self.modelClass != model.class) {
        OBSMTLJSONAdapter *otherAdapter = [self JSONAdapterForModelClass:model.class error:error];
        
        return [otherAdapter JSONDictionaryFromModel:model error:error];
    }
    
    NSArray *propertyKeysToSerialize = [self serializablePropertyKeysArray:self.JSONKeyPathsByPropertyKey.allKeys forModel:model];
    
    NSDictionary *dictionaryValue = [model.dictionaryValue dictionaryWithValuesForKeys:propertyKeysToSerialize];
    NSMutableDictionary *JSONDictionary = [[NSMutableDictionary alloc] initWithCapacity:dictionaryValue.count];
    
    __block BOOL success = YES;
    __block NSError *tmpError = nil;

    [dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
        id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];
        
        if (JSONKeyPaths == nil) return;
        
        NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
        if ([transformer.class allowsReverseTransformation]) {
                // Map NSNull -> nil for the transformer, and then back for the
                // dictionaryValue we're going to insert into.
            if ([value isEqual:NSNull.null]) value = nil;
            
            if ([transformer respondsToSelector:@selector(reverseTransformedValue:success:error:)]) {
                id<OBSMTLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;
                
                value = [errorHandlingTransformer reverseTransformedValue:value success:&success error:&tmpError];
                
                if (!success) {
                    *stop = YES;
                    return;
                }
            } else {
                value = [transformer reverseTransformedValue:value] ?: NSNull.null;
            }
        }
        
        void (^createComponents)(id, NSString *) = ^(id obj, NSString *keyPath) {
            
            NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
            
                // Set up dictionaries at each step of the key path.
            for (NSString *component in keyPathComponents) {
                if ([obj valueForKey:component] == nil) {
                        // Insert an empty mutable dictionary at this spot so that we
                        // can set the whole key path afterward.
                    [obj setValue:[NSMutableDictionary dictionary] forKey:component];
                }
                
                obj = [obj valueForKey:component];
            }
        };
        
        if ([JSONKeyPaths isKindOfClass:NSString.class]) {
            createComponents(JSONDictionary, JSONKeyPaths);
            
            [JSONDictionary setValue:value forKeyPath:JSONKeyPaths];
        }
        
        if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
            for (NSString *JSONKeyPath in JSONKeyPaths) {
                createComponents(JSONDictionary, JSONKeyPath);
                
                [JSONDictionary setValue:value[JSONKeyPath] forKeyPath:JSONKeyPath];
            }
        }
    }];
    
    
    if (success) {
        if([model.class conformsToProtocol:@protocol(OBSMTLDictionaryItemOrderProtocol)]){
            [JSONDictionary setValue:[model.class DictionaryOrderList] forKey:OBSXMLDictionaryNodeOrderKey];
        }
        return JSONDictionary;
    } else {
        if (error != NULL) *error = tmpError;
        
        return nil;
    }
}

- (id)modelFromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error {
    if ([self.modelClass respondsToSelector:@selector(classForParsingJSONDictionary:)]) {
        Class class = [self.modelClass classForParsingJSONDictionary:JSONDictionary];
        if (class == nil) {
//            if (error != NULL) {
//                NSDictionary *userInfo = @{
//                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Could not parse JSON", @""),
//                                           NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No model class could be found to parse the JSON dictionary.", @""),
//                                           @"ClassName":NSStringFromClass(self.modelClass)
//                                           };
//                
//                *error = [NSError errorWithDomain:OBSMTLJSONAdapterErrorDomain code:OBSMTLJSONAdapterErrorNoClassFound userInfo:userInfo];
//            }
            
            return nil;
        }
        
        if (class != self.modelClass) {
            NSAssert([class conformsToProtocol:@protocol(OBSMTLJSONSerializing)], @"Class %@ returned from +classForParsingJSONDictionary: does not conform to <OBSMTLJSONSerializing>", class);
            
            OBSMTLJSONAdapter *otherAdapter = [self JSONAdapterForModelClass:class error:error];
            
            return [otherAdapter modelFromJSONDictionary:JSONDictionary error:error];
        }
    }
    
    NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:JSONDictionary.count];
    
    for (NSString *propertyKey in [self.modelClass propertyKeys]) {
        
        id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];
        
        if (JSONKeyPaths == nil) continue;
        
        id value;
        
        if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            
            for (NSString *keyPath in JSONKeyPaths) {
                BOOL success = NO;
                id value = [JSONDictionary obs_mtl_valueForJSONKeyPath:keyPath success:&success error:error];
                
                if (!success) return nil;
                
                if (value != nil) dictionary[keyPath] = value;
            }
            
            value = dictionary;
        } else {
            BOOL success = NO;
            
            value = [JSONDictionary obs_mtl_valueForJSONKeyPath:JSONKeyPaths success:&success error:error];
            
            if (!success) return nil;
        }
        
        if (value == nil) continue;
        
        @try {
           
            NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
            if (transformer != nil) {
                    // Map NSNull -> nil for the transformer, and then back for the
                    // dictionary we're going to insert into.
                if ([value isEqual:NSNull.null]) value = nil;
                
                if ([transformer respondsToSelector:@selector(transformedValue:success:error:)]) {
                    id<OBSMTLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;
                    
                    BOOL success = YES;
                    
                    value = [errorHandlingTransformer transformedValue:value success:&success error:error];
                    
                    
                    
                    if (!success) return nil;
                } else {
                    value = [transformer transformedValue:value];
                }
                
                if (value == nil) value = NSNull.null;
            }
            
            dictionaryValue[propertyKey] = value;
        } @catch (NSException *ex) {
            NSLog(@"** *Caught exception %@ parsing JSON key path \"%@\" from: %@", ex, JSONKeyPaths, JSONDictionary);
            
                // Fail fast in Debug builds.
#if DEBUG
            @throw ex;
#else
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Caught exception parsing JSON key path \"%@\" for model class: %@", JSONKeyPaths, self.modelClass],
                                           NSLocalizedRecoverySuggestionErrorKey: ex.description,
                                           NSLocalizedFailureReasonErrorKey: ex.reason,
                                           OBSMTLJSONAdapterThrownExceptionErrorKey: ex
                                           };
                
                *error = [NSError errorWithDomain:OBSMTLJSONAdapterErrorDomain code:OBSMTLJSONAdapterErrorExceptionThrown userInfo:userInfo];
            }
            
            return nil;
#endif
        }
    }
    
    id model = [self.modelClass modelWithDictionary:dictionaryValue error:error];
    
    return [model validate:error] ? model : nil;
}

+ (NSValueTransformer<OBSMTLTransformerErrorHandling> *)dictionaryTransformerWithModelClass:(Class)modelClass {
    NSParameterAssert([modelClass conformsToProtocol:@protocol(OBSMTLModel)]);
    NSParameterAssert([modelClass conformsToProtocol:@protocol(OBSMTLJSONSerializing)]);
    __block OBSMTLJSONAdapter *adapter;
    
    return [OBSMTLValueTransformer
            transformerUsingForwardBlock:^ id (id JSONDictionary, BOOL *success, NSError **error) {
                if (JSONDictionary == nil) return nil;
                
                if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
                    if (error != NULL) {
                        NSDictionary *userInfo = @{
                                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON dictionary to model object", @""),
                                                   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary, got: %@", @""), JSONDictionary],
                                                   OBSMTLTransformerErrorHandlingInputValueErrorKey : JSONDictionary
                                                   };
                        
                        *error = [NSError errorWithDomain:OBSMTLTransformerErrorHandlingErrorDomain code:OBSMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                    }
                    *success = NO;
                    return nil;
                }
                
                if (!adapter) {
                    adapter = [[self alloc] initWithModelClass:modelClass];
                }
                id model = [adapter modelFromJSONDictionary:JSONDictionary error:error];
//                if (model == nil) {
//                    *success = NO;
//                }
                
                return model;
            }
            reverseBlock:^ NSDictionary  *(id model, BOOL *success, NSError **error) {
                if (model == nil) return nil;
                
                if (![model conformsToProtocol:@protocol(OBSMTLModel)] || ![model conformsToProtocol:@protocol(OBSMTLJSONSerializing)]) {
                    if (error != NULL) {
                        NSDictionary *userInfo = @{
                                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert model object to JSON dictionary", @""),
                                                   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected a OBSMTLModel object conforming to <OBSMTLJSONSerializing>, got: %@.", @""), model],
                                                   OBSMTLTransformerErrorHandlingInputValueErrorKey : model
                                                   };
                        
                        *error = [NSError errorWithDomain:OBSMTLTransformerErrorHandlingErrorDomain code:OBSMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                    }
                    *success = NO;
                    return nil;
                }
                
                if (!adapter) {
                    adapter = [[self alloc] initWithModelClass:modelClass];
                }
                NSDictionary *result = [adapter JSONDictionaryFromModel:model error:error];
                if (result == nil) {
                    *success = NO;
                }
                
                return result;
            }];
}

@end
SuppressMethodDefinitionNotFoundWarning(
@implementation OBSXMLDictionaryParserWithFormat
                                        )
+ (NSString *)OBSXMLStringForNode:(id)node withNodeName:(NSString *)nodeName ident:(NSInteger)ident{
    NSString *identString = [@" " stringWithRepeatTimes:ident*4];
    NSString *xmlNS = @"";
    if(ident == 0){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL isOBSProtocol = [[defaults objectForKey:@"OBSProtocol"] integerValue];
        if(isOBSProtocol){
//            xmlNS = OBSXMLDefaultNS_OBS;
        }else{
            xmlNS = OBSXMLDefaultNS;
        }
        
    }
    if ([node isKindOfClass:[NSArray class]]){
        NSMutableArray<NSString *> *nodes = [NSMutableArray arrayWithCapacity:[node count]];
        for (id individualNode in node) {
            [nodes addObject:[individualNode obs_innerXML:ident+1]];
        }
        NSString *innerOBSXML = [nodes componentsJoinedByString:@"\n"];
        if (innerOBSXML.length) {
            return [NSString stringWithFormat:@"%2$@<%1$@%3$@>\n%4$@\n%2$@</%1$@>", nodeName, identString,xmlNS,innerOBSXML];
        }else{
            return [NSString stringWithFormat:@"%2$@<%1$@%3$@/>", nodeName, identString,xmlNS];
        }
    } else if ([node isKindOfClass:[NSDictionary class]]) {
        NSDictionary<NSString *, NSString *> *attributes = [(NSDictionary *)node obs_attributes];
        NSMutableString *attributeString = [NSMutableString string];
        if([attributes count]){
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            BOOL isOBSProtocol = [[defaults objectForKey:@"OBSProtocol"] integerValue];
            if(!isOBSProtocol){
               [attributeString appendString:@" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\""];
            }
            
        }
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, __unused BOOL *stop) {
            [attributeString appendFormat:@" %@=\"%@\"", key.description, value.description];
        }];
        
        NSString *innerOBSXML = [node obs_innerXML:ident+1];
        if (innerOBSXML.length) {
            return [NSString stringWithFormat:@"%2$@<%1$@%5$@%3$@>\n%4$@\n%2$@</%1$@>", nodeName, identString, xmlNS, innerOBSXML, attributeString];
        }else{
            return [NSString stringWithFormat:@"%2$@<%1$@%5$@%3$@%4$@/>", nodeName, identString, xmlNS, innerOBSXML ,attributeString];
        }
    } else {
        return [NSString stringWithFormat:@"%2$@<%1$@%3$@>%4$@</%1$@>", nodeName, identString, xmlNS, [node description]];
    }
}
- (void)parser:(__unused NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(__unused NSString *)namespaceURI qualifiedName:(__unused NSString *)qName attributes:(NSDictionary *)attributeDict
{
    [self endText];
    
    NSMutableDictionary<NSString *, id> *node = [NSMutableDictionary dictionary];
    switch (self.nodeNameMode)
    {
        case OBSXMLDictionaryNodeNameModeRootOnly:
        {
        if (!self.root)
            {
            node[OBSXMLDictionaryNodeNameKey] = elementName;
            }
        break;
        }
        case OBSXMLDictionaryNodeNameModeAlways:
        {
        node[OBSXMLDictionaryNodeNameKey] = elementName;
        break;
        }
        case OBSXMLDictionaryNodeNameModeNever:
        {
        break;
        }
    }
    
    if (attributeDict.count)
        {
        switch (self.attributesMode)
            {
                case OBSXMLDictionaryAttributesModePrefixed:
                {
                for (NSString *key in attributeDict)
                    {
                    node[[OBSXMLDictionaryAttributePrefix stringByAppendingString:key]] = attributeDict[key];
                    }
                break;
                }
                case OBSXMLDictionaryAttributesModeDictionary:
                {
                node[OBSXMLDictionaryAttributesKey] = attributeDict;
                break;
                }
                case OBSXMLDictionaryAttributesModeUnprefixed:
                {
                [node addEntriesFromDictionary:attributeDict];
                break;
                }
                case OBSXMLDictionaryAttributesModeDiscard:
                {
                break;
                }
            }
        }
    
    if (!self.root)
        {
        self.root = node;
        self.stack = [NSMutableArray arrayWithObject:node];
        if (self.wrapRootNode)
            {
            self.root = [NSMutableDictionary dictionaryWithObject:self.root forKey:elementName];
            [self.stack insertObject:self.root atIndex:0];
            }
        }
    else
        {
        NSMutableDictionary<NSString *, id> *top = self.stack.lastObject;
        id existing = top[elementName];
        if ([existing isKindOfClass:[NSArray class]])
            {
            [(NSMutableArray *)existing addObject:node];
            }
        else if (existing)
            {
            top[elementName] = [@[existing, node] mutableCopy];
            }
        else if (self.alwaysUseArrays)
            {
            top[elementName] = [NSMutableArray arrayWithObject:node];
            }
        else
            {
            top[elementName] = node;
            }
        [self.stack addObject:node];
        }
}
@end

#pragma mark - Base Model

@implementation OBSAbstractModel
    //<OBSMTLJSONSerializing>
    // Should implement in sub classes
-(instancetype)init{
    if(self=[super init]){
        NSString *clazzName = NSStringFromClass([self class]) ;
        if([clazzName hasPrefix:OBSAbstractClassPrefix]){
            NSException *ex = [NSException exceptionWithName:@"Abstract class initialization" reason:@"Abstract class is not supposed to be used." userInfo:@{@"className":clazzName}];
            @throw ex;
        }
    }
    return self;
}
+(NSDictionary*) JSONKeyPathsByPropertyKey{
    return nil;
}
@end

@implementation OBSBaseEntity: OBSAbstractModel
@end

#pragma mark - Base Requests

@interface OBSBaseRequest()
@property (nonatomic, strong, nullable) OBSWeakMutableArray  *networkingRequestList;
@end
@implementation OBSBaseRequest: OBSAbstractModel
@synthesize isCancelled = _cancelled;
-(instancetype)init{
    if(self=[super init]){
        self.requestID = [[NSUUID UUID]UUIDString];
    }
    return self;
}


+(NSDictionary*) JSONKeyPathsByPropertyKey{
    MakeDispatchOnceDictBEGIN
    dict = @{
             OBSRequestIDKey:OBSRequestIDKey,
             };
    MakeDispatchOnceDictEND
    return dict;
}

-(OBSBaseNetworkingRequest*)convertToNetworkingRequest:(OBSBaseConfiguration*) configuration error:(NSError**) error{
    return [OBSUtils convertOBSRequestToNetworkingRequestWithMTL:self configuration:configuration targetClazz:[OBSBaseNetworkingRequest class] error:error];
}
-(void)cancel{
    @synchronized (self) {
        OBSLogDebug(@"Base cancelled %@ start", self.requestID);
        if(!self.isCancelled){
            for(OBSBaseNetworkingRequest *request in self.networkingRequestList){
                [request cancel];
            }
            _cancelled = YES;
        }
        OBSLogDebug(@"Base cancelled %@ end", self.requestID);
    }
}
-(BOOL)validateRequest:(NSError**)error{
    return YES;
}

@end

#pragma mark - Base Response

@implementation OBSBaseResponse: OBSAbstractModel
+(NSDictionary*) JSONKeyPathsByPropertyKey{
    MakeDispatchOnceDictBEGIN
    dict= @{
             OBSRequestIDKey:OBSRequestIDKey,
             OBSOutputHeadersKey:OBSOutputHeadersKey,
             OBSOutputCodeKey:OBSOutputCodeKey,
             };
    MakeDispatchOnceDictEND
    return dict;
}
+(OBSBodyType)GetBodyType{
        //default response body type XML
    return OBSBodyTypeXML;
}

@end



