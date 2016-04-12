//
//  PEPatch.h
//  libevil
//
//  Created by Will Stafford on 4/12/16.
//  Copyright © 2016 Landon Fuller. All rights reserved.
//

#import <signal.h>
#import <unistd.h>
#import <dlfcn.h>

#import <sys/mman.h>

#import <sys/ucontext.h>

#import <mach/mach.h>
#import <mach-o/loader.h>


#import <Foundation/Foundation.h>

/// Object representing a patch.
@interface PEPatch : NSObject

/*
 Original structure:
 struct patch {
 vm_address_t orig_addr;
 vm_address_t new_addr;
 
 vm_size_t mapped_size;
 
 vm_address_t orig_fptr;
 vm_address_t orig_fptr_nthumb; // low-order bit masked
 vm_address_t new_fptr;
 };
 */

@property (nonatomic) vm_address_t	originalAddress;
@property (nonatomic) vm_address_t	newAddress;

@property (nonatomic) vm_size_t		mappedSize;

@property (nonatomic) vm_address_t originalFunctionPointer;
@property (nonatomic) vm_address_t originalFunctionPointer_nthumb; // low-order bit masked
@property (nonatomic) vm_address_t newFunctionPointer;


@end
