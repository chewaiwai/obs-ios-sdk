//
//  EXTScope.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "OBSEXTScope.h"

void obs_mtl_executeCleanupBlock (__strong obs_mtl_cleanupBlock_t *block) {
    (*block)();
}
