/*
 * Author: Landon Fuller <landonf@bikemonkey.org>
 *
 * Copyright (c) 2013 Landon Fuller <landonf@bikemonkey.org>.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

//
//  PEManager.h
//  libevil
//
//  Created by Will Stafford on 4/12/16.
//  Copyright © 2016 Will Stafford. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEPatch;
/// Class for managing patches
@interface PEManager : NSObject

/// Array of patches
@property (nonatomic, retain) NSMutableArray *patches;

/// @returns Shared instance of this object.
+ (instancetype)sharedEvil;

/**
 Overrides a function and points it to a new function.
 @param victimFunction The function to override.
 @param newFunction The function to point to.
 @returns A pointer to the original function.
 */
+ (void *)overrideFunction:(void *)victimFunction newFunction:(void *)newFunction;

/// Adds a single patch.
+ (void)addPatch:(PEPatch *)patch;

@end
