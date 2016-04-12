//
//  PureEvil.h
//  libevil
//
//  Created by Will Stafford on 4/12/16.
//  Copyright © 2016 Landon Fuller. All rights reserved.
//

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
extern void page_mapper (int signo, siginfo_t *info, void *uapVoid);

/// There are no words to describe the darkness that is contained(?) here.
@interface PureEvil : NSObject


@end
