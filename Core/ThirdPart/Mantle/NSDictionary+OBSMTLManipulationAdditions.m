//
//  NSDictionary+OBSMTLManipulationAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-24.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSDictionary+OBSMTLManipulationAdditions.h"

@implementation NSDictionary (OBSMTLManipulationAdditions)

- (NSDictionary *)obs_mtl_dictionaryByAddingEntriesFromDictionary:(NSDictionary *)dictionary {
	NSMutableDictionary *result = [self mutableCopy];
	[result addEntriesFromDictionary:dictionary];
	return result;
}

- (NSDictionary *)obs_mtl_dictionaryByRemovingValuesForKeys:(NSArray *)keys {
	NSMutableDictionary *result = [self mutableCopy];
	[result removeObjectsForKeys:keys];
	return result;
}

@end

@implementation NSDictionary (OBSMTLManipulationAdditions_Deprecated)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

- (NSDictionary *)obs_mtl_dictionaryByRemovingEntriesWithKeys:(NSSet *)keys {
	return [self obs_mtl_dictionaryByRemovingValuesForKeys:keys.allObjects];
}

#pragma clang diagnostic pop

@end
