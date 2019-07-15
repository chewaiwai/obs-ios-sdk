//
//  NSDictionary+OBSMTLMappingAdditions.m
//  Mantle
//
//  Created by Robert Böhnke on 10/31/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "OBSMTLModel.h"

#import "NSDictionary+OBSMTLMappingAdditions.h"

@implementation NSDictionary (OBSMTLMappingAdditions)

+ (NSDictionary *)obs_mtl_identityPropertyMapWithModel:(Class)modelClass {
	NSCParameterAssert([modelClass conformsToProtocol:@protocol(OBSMTLModel)]);

	NSArray *propertyKeys = [modelClass propertyKeys].allObjects;

	return [NSDictionary dictionaryWithObjects:propertyKeys forKeys:propertyKeys];
}

@end
