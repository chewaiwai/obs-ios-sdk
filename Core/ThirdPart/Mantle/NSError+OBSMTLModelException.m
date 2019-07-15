//
//  NSError+OBSMTLModelException.m
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "OBSMTLModel.h"

#import "NSError+OBSMTLModelException.h"

// The domain for errors originating from OBSMTLModel.
static NSString  *const OBSMTLModelErrorDomain = @"OBSMTLModelErrorDomain";

// An exception was thrown and caught.
static const NSInteger OBSMTLModelErrorExceptionThrown = 1;

// Associated with the NSException that was caught.
static NSString  *const OBSMTLModelThrownExceptionErrorKey = @"OBSMTLModelThrownException";

@implementation NSError (OBSMTLModelException)

+ (instancetype)obs_mtl_modelErrorWithException:(NSException *)exception {
	NSParameterAssert(exception != nil);

	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey: exception.description,
		NSLocalizedFailureReasonErrorKey: exception.reason,
		OBSMTLModelThrownExceptionErrorKey: exception
	};

	return [NSError errorWithDomain:OBSMTLModelErrorDomain code:OBSMTLModelErrorExceptionThrown userInfo:userInfo];
}

@end
