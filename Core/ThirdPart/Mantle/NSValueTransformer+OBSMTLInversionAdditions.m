//
//  NSValueTransformer+OBSMTLInversionAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-05-18.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "NSValueTransformer+OBSMTLInversionAdditions.h"
#import "OBSMTLTransformerErrorHandling.h"
#import "OBSMTLValueTransformer.h"

@implementation NSValueTransformer (OBSMTLInversionAdditions)

- (NSValueTransformer *)obs_mtl_invertedTransformer {
	NSParameterAssert(self.class.allowsReverseTransformation);

	if ([self conformsToProtocol:@protocol(OBSMTLTransformerErrorHandling)]) {
		NSParameterAssert([self respondsToSelector:@selector(reverseTransformedValue:success:error:)]);

		id<OBSMTLTransformerErrorHandling> errorHandlingSelf = (id)self;

		return [OBSMTLValueTransformer transformerUsingForwardBlock:^(id value, BOOL *success, NSError **error) {
			return [errorHandlingSelf reverseTransformedValue:value success:success error:error];
		} reverseBlock:^(id value, BOOL *success, NSError **error) {
			return [errorHandlingSelf transformedValue:value success:success error:error];
		}];
	} else {
		return [OBSMTLValueTransformer transformerUsingForwardBlock:^(id value, BOOL *success, NSError **error) {
			return [self reverseTransformedValue:value];
		} reverseBlock:^(id value, BOOL *success, NSError **error) {
			return [self transformedValue:value];
		}];
	}
}

@end
