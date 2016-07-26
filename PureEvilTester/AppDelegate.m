//
//  AppDelegate.m
//  PureEvilTester
//
//  Created by Will Stafford on 5/12/16.
//  Copyright © 2016 Landon Fuller. All rights reserved.
//

#import "AppDelegate.h"
#import <PureEvilKit/PureEvilKit.h>
@interface AppDelegate ()

@end

double (*orig_pow)(double, double) = NULL;

void (*orig_NSLog)(NSString *fmt, ...) = NULL;


void myFallbackHandler(int signo) {
	printf("1. Fallback hit with signal: %d\n", signo);
	while (true)
	{
		sleep(0);
	}
	abort();
}

void my_NSLog (NSString *fmt, ...) {
	orig_NSLog(@"I'm in your computers, patching your strings ...");
	
	NSString *newFmt = [NSString stringWithFormat: @"[PATCHED]: %@", fmt];
	
	va_list ap;
	va_start(ap, fmt);
	NSLogv(newFmt, ap);
	va_end(ap);
}

double my_pow(double baseNum, double exp)
{
	NSLog(@"pow called");
	return powf(baseNum, exp);
}

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	// Override point for customization after application launch.
	NSLog(@"Please print this sir prepatch");
	NSLog(@"pow(2, 5) = %f", pow(2, 5));
	printf("NSLog (prepatch): %p\n", NSLog);
	//evil_fallback_signal_handler(&myFallbackHandler);
	orig_NSLog = [PEManager overrideFunction:NSLog newFunction:my_NSLog];
	orig_pow = [PEManager overrideFunction:pow newFunction:my_pow];
	printf("NSLog: %p\n", NSLog);
	printf("my_NSLog: %p\n", my_NSLog);
	printf("orig_NSLog: %p\n", orig_NSLog);
	
	//evil_override_ptr(, , (void **) &orig_NSLog);
	NSLog(@"Please print this sir postpatch");
	
	NSLog(@"pow(2, 5) = %f", pow(2, 5));
	//double z = orig_pow(2, 5);
	
	//NSLog(@"pow(2, 5) = %f", pow(2, 5));
	
	NSLog(@"pow(2, 5) = %f", pow(2, 5));
	
	
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
