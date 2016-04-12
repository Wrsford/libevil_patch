//
//  PEManager.m
//  libevil
//
//  Created by Will Stafford on 4/12/16.
//  Copyright © 2016 Landon Fuller. All rights reserved.
//

#import "PEManager.h"
#import "PEPatch.h"
#import "PureEvil.h"
#import <signal.h>
#import <unistd.h>
#import <dlfcn.h>

#import <sys/mman.h>

#import <sys/ucontext.h>

#import <mach/mach.h>
#import <mach-o/loader.h>

PEManager* sharedEvil;

@implementation PEManager

- (id)init
{
	self = [super init];
	
	self.patches = [NSMutableArray new];
	struct sigaction act;
	memset(&act, 0, sizeof(act));
	act.sa_sigaction = page_mapper;
	act.sa_flags = SA_SIGINFO;
	
	if (sigaction(SIGSEGV, &act, NULL) < 0) {
		perror("sigaction");
	}
	
	if (sigaction(SIGBUS, &act, NULL) < 0) {
		perror("sigaction");
	}
	
	return self;
}



+ (instancetype)sharedEvil {
	if (!sharedEvil) {
		sharedEvil = [PEManager new];
	}
	
	return sharedEvil;
}

extern kern_return_t evil_override_ptr (void *function, const void *newFunction, void **originalRentry);
+ (void *)overrideFunction:(void *)victimFunction newFunction:(void *)newFunction {
	void (*original)() = NULL;
	evil_override_ptr(victimFunction, newFunction,(void **) &original);
	//NSLog(@"Returning original pointer...");
	return original;
}

+ (void)addPatch:(PEPatch *)patch {
	[[PEManager sharedEvil].patches addObject:patch];
}



@end
