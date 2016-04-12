//
//  PEManager.h
//  libevil
//
//  Created by Will Stafford on 4/12/16.
//  Copyright © 2016 Landon Fuller. All rights reserved.
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
