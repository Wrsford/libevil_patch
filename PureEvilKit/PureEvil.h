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
//  PureEvil.h
//  libevil
//
//  Created by Will Stafford on 4/12/16.
//  Copyright © 2016 Will Stafford. All rights reserved.
//

#import <signal.h>
#import <unistd.h>
#import <dlfcn.h>

#import <sys/mman.h>

#import <sys/ucontext.h>

#import <mach/mach.h>
#import <mach-o/loader.h>
#include <mach-o/dyld.h>

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#if TARGET_CPU_ARM64
// arm64
#ifndef EVIL_ARM64
#define EVIL_ARM64
#endif
#else
#if TARGET_CPU_ARM
// armv7
#ifndef EVIL_ARMV7
#define EVIL_ARMV7
#endif

#endif
#endif

#if TARGET_CPU_X86_64
// Simulator 64bit (5s and up)
#ifndef EVIL_INTEL64
#define EVIL_INTEL64
#endif

#endif

#if TARGET_CPU_X86
// Simulator 32bit
#ifndef EVIL_INTEL32
#define EVIL_INTEL32
#endif

#endif

#ifndef SHOULD_LOG_EVIL_ERRORS
/// Determine if errors should be logged in the evil
#define SHOULD_LOG_EVIL_ERRORS 0
#endif

#ifndef EVILog
/// Log via NSLog if errors should be logged in the evil
#define EVILog(...) if (SHOULD_LOG_EVIL_ERRORS) { NSLog(__VA_ARGS__); }
#endif

#ifndef cEVILog
/// Log via printf if errors should be logged in the evil
#define cEVILog(...) if (SHOULD_LOG_EVIL_ERRORS) { printf(__VA_ARGS__); }
#endif

/// The signal handler
extern void page_mapper (int signo, siginfo_t *info, void *uapVoid);

/// Fallback Handler
extern void (*fallbackSignalHandler)(int signo);

/// There are no words to describe the darkness that is contained(?) here.
@interface PureEvil : NSObject

@property (nonatomic, retain) NSMutableArray *mappedImages;

/// @returns A shared darkness.
+ (instancetype)sharedEvil;

/// @param fallback The signal handler to use if no patch is matched.
+ (void)setFallbackHandler:(void (*)(int signo))fallback;

/**
 Overrides a function
 @param targetFunction The function to override.
 @param newFunction The function to replace the target.
 @param originalRentry Pointer will be filled with a pointer to the original function.
 @returns Success or failure as a kern_return_t.
 */
+ (kern_return_t)overrideFunction:(void*)targetFunction
					  newFunction:(const void*)newFunction
		 originalFunctionCallable:(void**)originalRentry;

/**
 Iterates through a Mach-O image.
 @param header The header to parse.
 @param block The callback for each segment.
 */
+ (BOOL)iterateMachOSegmentsWithHeader:(const void *)header block:(void (^)(const char segname[16], uint64_t vmaddr, uint64_t vmsize, BOOL *cont))block;

@end
