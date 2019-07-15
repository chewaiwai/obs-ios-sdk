//
//  NSArray+OBSMTLManipulationAdditions.m
//  Mantle
//
//  Created by Josh Abernathy on 9/19/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSArray+OBSMTLManipulationAdditions.h"

@interface NSArray (OBSMTLDeclarations)

// This declaration is needed so Mantle can be compiled with SDK 6 / 10.8.
- (id)firstObject;

@end

@implementation NSArray (OBSMTLManipulationAdditions)

- (id)obs_mtl_firstObject {
	return self.firstObject;
}

- (instancetype)obs_mtl_arrayByRemovingObject:(id)object {
	NSMutableArray *result = [self mutableCopy];
	[result removeObject:object];
	return result;
}

- (instancetype)obs_mtl_arrayByRemovingFirstObject {
	if (self.count == 0) return self;

	return [self subarrayWithRange:NSMakeRange(1, self.count - 1)];
}

- (instancetype)obs_mtl_arrayByRemovingLastObject {
	if (self.count == 0) return self;

	return [self subarrayWithRange:NSMakeRange(0, self.count - 1)];
}

@end
