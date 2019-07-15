//
//  OBSMTLValueTransformer.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "OBSMTLValueTransformer.h"

//
// Any OBSMTLValueTransformer supporting reverse transformation. Necessary because
// +allowsReverseTransformation is a class method.
//
@interface OBSMTLReversibleValueTransformer : OBSMTLValueTransformer
@end

@interface OBSMTLValueTransformer ()

@property (nonatomic, copy, readonly) OBSMTLValueTransformerBlock forwardBlock;
@property (nonatomic, copy, readonly) OBSMTLValueTransformerBlock reverseBlock;

@end

@implementation OBSMTLValueTransformer

#pragma mark Lifecycle

+ (instancetype)transformerUsingForwardBlock:(OBSMTLValueTransformerBlock)forwardBlock {
	return [[self alloc] initWithForwardBlock:forwardBlock reverseBlock:nil];
}

+ (instancetype)transformerUsingReversibleBlock:(OBSMTLValueTransformerBlock)reversibleBlock {
	return [self transformerUsingForwardBlock:reversibleBlock reverseBlock:reversibleBlock];
}

+ (instancetype)transformerUsingForwardBlock:(OBSMTLValueTransformerBlock)forwardBlock reverseBlock:(OBSMTLValueTransformerBlock)reverseBlock {
	return [[OBSMTLReversibleValueTransformer alloc] initWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
}

- (id)initWithForwardBlock:(OBSMTLValueTransformerBlock)forwardBlock reverseBlock:(OBSMTLValueTransformerBlock)reverseBlock {
	NSParameterAssert(forwardBlock != nil);

	self = [super init];
	if (self == nil) return nil;

	_forwardBlock = [forwardBlock copy];
	_reverseBlock = [reverseBlock copy];

	return self;
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation {
	return NO;
}

+ (Class)transformedValueClass {
	return NSObject.class;
}

- (id)transformedValue:(id)value {
	NSError *error = nil;
	BOOL success = YES;

	return self.forwardBlock(value, &success, &error);
}

- (id)transformedValue:(id)value success:(BOOL *)outerSuccess error:(NSError **)outerError {
	NSError *error = nil;
	BOOL success = YES;

	id transformedValue = self.forwardBlock(value, &success, &error);

	if (outerSuccess != NULL) *outerSuccess = success;
	if (outerError != NULL) *outerError = error;

	return transformedValue;
}

@end

@implementation OBSMTLReversibleValueTransformer

#pragma mark Lifecycle

- (id)initWithForwardBlock:(OBSMTLValueTransformerBlock)forwardBlock reverseBlock:(OBSMTLValueTransformerBlock)reverseBlock {
	NSParameterAssert(reverseBlock != nil);
	return [super initWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (id)reverseTransformedValue:(id)value {
	NSError *error = nil;
	BOOL success = YES;

	return self.reverseBlock(value, &success, &error);
}

- (id)reverseTransformedValue:(id)value success:(BOOL *)outerSuccess error:(NSError **)outerError {
	NSError *error = nil;
	BOOL success = YES;

	id transformedValue = self.reverseBlock(value, &success, &error);

	if (outerSuccess != NULL) *outerSuccess = success;
	if (outerError != NULL) *outerError = error;

	return transformedValue;
}

@end


@implementation OBSMTLValueTransformer (Deprecated)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (instancetype)transformerWithBlock:(id (^)(id))transformationBlock {
	return [self transformerUsingForwardBlock:^(id value, BOOL *success, NSError **error) {
		return transformationBlock(value);
	}];
}

+ (instancetype)reversibleTransformerWithBlock:(id (^)(id))transformationBlock {
	return [self transformerUsingReversibleBlock:^(id value, BOOL *success, NSError **error) {
		return transformationBlock(value);
	}];
}

+ (instancetype)reversibleTransformerWithForwardBlock:(id (^)(id))forwardBlock reverseBlock:(id (^)(id))reverseBlock {
	return [self
		transformerUsingForwardBlock:^(id value, BOOL *success, NSError **error) {
			return forwardBlock(value);
		}
		reverseBlock:^(id value, BOOL *success, NSError **error) {
			return reverseBlock(value);
		}];
}

#pragma clang diagnostic pop

@end
