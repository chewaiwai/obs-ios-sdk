/*
  * Copyright (c) 2014, Facebook, Inc.
  * All rights reserved.
 *
  * This source code is licensed under the BSD-style license found in the
  * LICENSE file in the root directory of this source tree. An additional grant
  * of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "OBSBFCancellationTokenRegistration.h"

#import "OBSBFCancellationToken.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBSBFCancellationTokenRegistration ()

@property (nonatomic, weak) OBSBFCancellationToken *token;
@property (nullable, nonatomic, strong) OBSBFCancellationBlock cancellationObserverBlock;
@property (nonatomic, strong) NSObject *lock;
@property (nonatomic) BOOL disposed;

@end

@interface OBSBFCancellationToken (OBSBFCancellationTokenRegistration)

- (void)unregisterRegistration:(OBSBFCancellationTokenRegistration *)registration;

@end

@implementation OBSBFCancellationTokenRegistration

+ (instancetype)registrationWithToken:(OBSBFCancellationToken *)token delegate:(OBSBFCancellationBlock)delegate {
    OBSBFCancellationTokenRegistration *registration = [OBSBFCancellationTokenRegistration new];
    registration.token = token;
    registration.cancellationObserverBlock = delegate;
    return registration;
}

- (instancetype)init {
    self = [super init];
    if (!self) return self;

    _lock = [NSObject new];
    
    return self;
}

- (void)dispose {
    @synchronized(self.lock) {
        if (self.disposed) {
            return;
        }
        self.disposed = YES;
    }

    OBSBFCancellationToken *token = self.token;
    if (token != nil) {
        [token unregisterRegistration:self];
        self.token = nil;
    }
    self.cancellationObserverBlock = nil;
}

- (void)notifyDelegate {
    @synchronized(self.lock) {
        [self throwIfDisposed];
        self.cancellationObserverBlock();
    }
}

- (void)throwIfDisposed {
    NSAssert(!self.disposed, @"Object already disposed");
}

@end

NS_ASSUME_NONNULL_END
