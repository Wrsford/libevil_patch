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
//  PureEvil.m
//  libevil
//
//  Created by Will Stafford on 4/12/16.
//  Copyright © 2016 Will Stafford. All rights reserved.
//

#import "PureEvil.h"
#import "PEManager.h"
#import "PEPatch.h"

#ifdef EVIL_INTEL64
void page_mapper (int signo, siginfo_t *info, void *uapVoid) {
	PEManager *evil = [PEManager sharedEvil];
	NSUInteger patch_count = evil.patches.count;
	NSArray *patches = evil.patches;
	
	ucontext_t *uap = uapVoid;
	typeof(uap->uc_mcontext) ctx = uap->uc_mcontext;
	
	
	__uint64_t	*rax = &ctx->__ss.__rax;
	__uint64_t	*rip = &ctx->__ss.__rip;
	
	uintptr_t pc = *rip;
	
	
	
	if (pc == (uintptr_t) info->si_addr) {
		for (PEPatch *patch in evil.patches) {
			if (patch.originalFunctionPointer_nthumb == pc) {
				*rip = (uintptr_t) patch.newFunctionPointer;
				return;
			}
		}
		
		for (PEPatch *patch in evil.patches) {
			if (pc >= patch.originalAddress && pc < (patch.originalAddress + patch.mappedSize)) {
				*rip = patch.newAddress + (pc - patch.originalAddress);
				return;
			}
		}
	}
	
	BOOL didMatchPatch = false;
	
	
	// This is six kinds of wrong; we're just rewriting any registers that match the si_addr, and
	// are pointed into now-dead pages. The danger here ought to be obvious.
	for (PEPatch *patch in evil.patches) {
		if ((uintptr_t) info->si_addr < patch.originalAddress)
			continue;
		
		if ((uintptr_t) info->si_addr >= patch.originalAddress + patch.mappedSize)
			continue;
		
		// XXX we abuse the r[] array here.
		for (int i = 0; i < 15; i++) {
			uintptr_t rv = (rax)[i];
			
			if (rv == (uintptr_t) info->si_addr) {
				if (patch.newAddress > patch.originalAddress)
					(rax)[i] -= patch.newAddress - patch.originalAddress;
				else
					(rax)[i] += patch.originalAddress - patch.newAddress;
				didMatchPatch = true;
			}
		}
		
		//		uintptr_t rv = uap->uc_mcontext->__ss.__lr;
		//		if (rv == (uintptr_t) info->si_addr) {
		//			uap->uc_mcontext->__ss.__lr += p->new_addr - p->orig_addr;
		//			if (p->new_addr > p->orig_addr)
		//				uap->uc_mcontext->__ss.__lr -= p->new_addr - p->orig_addr;
		//			else
		//				uap->uc_mcontext->__ss.__lr += p->orig_addr - p->new_addr;
		//		}
	}
	
//	if (!didMatchPatch && fallbackHandler)
//	{
//		fallbackHandler(signo);
//	}
	
	return;
}
#endif

#ifdef EVIL_INTEL32
void page_mapper (int signo, siginfo_t *info, void *uapVoid) {
	PEManager *evil = [PEManager sharedEvil];
	
	ucontext_t *uap = uapVoid;
	typeof(uap->uc_mcontext) ctx = uap->uc_mcontext;
	
	unsigned int	*eax = &ctx->__ss.__eax;
	unsigned int	*eip = &ctx->__ss.__eip;
	
	unsigned int pc = *eip;
	if (pc == (uintptr_t) info->si_addr) {
		for (PEPatch *patch in evil.patches) {
			if (patch.originalFunctionPointer_nthumb == pc) {
				*eip = (uintptr_t) patch.newFunctionPointer;
				return;
			}
		}
		
		for (PEPatch *patch in evil.patches) {
			if (pc >= patch.originalAddress && pc < (patch.originalAddress + patch.mappedSize)) {
				*eip = (typeof(pc))patch.newAddress + (pc - (typeof(pc))patch.originalAddress);
				return;
			}
		}
	}
	
	BOOL didMatchPatch = false;
	
	
	// This is six kinds of wrong; we're just rewriting any registers that match the si_addr, and
	// are pointed into now-dead pages. The danger here ought to be obvious.
	for (PEPatch *patch in evil.patches) {
		if ((uintptr_t) info->si_addr < patch.originalAddress)
			continue;
		
		if ((uintptr_t) info->si_addr >= patch.originalAddress + patch.mappedSize)
			continue;
		
		// XXX we abuse the r[] array here.
		for (int i = 0; i < 15; i++) {
			uintptr_t rv = (eax)[i];
			
			if (rv == (uintptr_t) info->si_addr) {
				if (patch.newAddress > patch.originalAddress)
					(eax)[i] -= patch.newAddress - patch.originalAddress;
				else
					(eax)[i] += patch.originalAddress - patch.newAddress;
				didMatchPatch = true;
			}
		}
	}
	
	if (!didMatchPatch)
	{
		fallbackSignalHandler(signo);
	}
	
	return;
}
#endif

#ifdef EVIL_ARMV7
void page_mapper (int signo, siginfo_t *info, void *uapVoid) {
	ucontext_t *uap = uapVoid;
	typeof(uap->uc_mcontext) ctx = uap->uc_mcontext;
	
	typeof(ctx->__ss.__pc)	*r = (typeof(ctx->__ss.__pc) *) &ctx->__ss.__r;
	typeof(ctx->__ss.__pc)	*pcPtr = &ctx->__ss.__pc;
	
	unsigned int pc = *pcPtr;
	
	ctx->__es.__far = 0x0;
	ctx->__es.__fsr = 0x02000000;
	ctx->__es.__exception = 0x0;
	
	if (pc == (typeof(pc)) info->si_addr) {
		for (int i = 0; i < patch_count; i++) {
			if (patches[i].orig_fptr_nthumb == pc) {
				*pcPtr = (typeof(pc)) patches[i].new_fptr;
				return;
			}
		}
		
		for (int i = 0; i < patch_count; i++) {
			struct patch *p = &patches[i];
			if (pc >= p->orig_addr && pc < (p->orig_addr + p->mapped_size)) {
				*pcPtr = p->new_addr + (pc - p->orig_addr);
				return;
			}
		}
	}
	
	BOOL didMatchPatch = false;
	
	// This is six kinds of wrong; we're just rewriting any registers that match the si_addr, and
	// are pointed into now-dead pages. The danger here ought to be obvious.
	for (int i = 0; i < patch_count; i++) {
		struct patch *p = &patches[i];
		
		if ((typeof(pc)) info->si_addr < p->orig_addr)
			continue;
		
		if ((typeof(pc)) info->si_addr >= p->orig_addr + p->mapped_size)
			continue;
		
		// XXX we abuse the r[] array here.
		for (int i = 0; i < 15; i++) {
			uintptr_t rv = (r)[i];
			if (rv == (uintptr_t) info->si_addr) {
				if (p->new_addr > p->orig_addr)
					(r)[i] -= p->new_addr - p->orig_addr;
				else
					(r)[i] += p->orig_addr - p->new_addr;
				didMatchPatch = true;
			}
		}
		
		for (int i = 1; i <= 1; i++) {
			typeof(pc) rv = (pcPtr)[i];
			if (rv == (typeof(rv)) info->si_addr) {
				if (p->new_addr > p->orig_addr)
					(pcPtr)[i] -= p->new_addr - p->orig_addr;
				else
					(pcPtr)[i] += p->orig_addr - p->new_addr;
				didMatchPatch = true;
			}
		}
		
		uintptr_t rv = uap->uc_mcontext->__ss.__lr;
		if (rv == (uintptr_t) info->si_addr) {
			uap->uc_mcontext->__ss.__lr += p->new_addr - p->orig_addr;
			if (p->new_addr > p->orig_addr)
				uap->uc_mcontext->__ss.__lr -= p->new_addr - p->orig_addr;
			else
				uap->uc_mcontext->__ss.__lr += p->orig_addr - p->new_addr;
		}
	}
	
	if (!didMatchPatch)
	{
		fallbackSignalHandler(signo);
	}
	else
	{
		ctx->__es.__far = 0x0;
		ctx->__es.__fsr = 0x02000000;
		ctx->__es.__exception = 0x0;
	}
	
	return;
}
#endif

#ifdef EVIL_ARM64
void page_mapper (int signo, siginfo_t *info, void *uapVoid) {
	ucontext_t *uap = uapVoid;
	typeof(uap->uc_mcontext) ctx = uap->uc_mcontext;
	
	typeof(ctx->__ss.__pc)	*x = ctx->__ss.__x;
	typeof(ctx->__ss.__pc)	pc = ctx->__ss.__pc;
	
	if (pc == (typeof(pc)) info->si_addr) {
		for (int i = 0; i < patch_count; i++) {
			if (patches[i].orig_fptr_nthumb == pc) {
				pc = (typeof(pc)) patches[i].new_fptr;
				return;
			}
		}
		
		for (int i = 0; i < patch_count; i++) {
			struct patch *p = &patches[i];
			if (pc >= p->orig_addr && pc < (p->orig_addr + p->mapped_size)) {
				pc = p->new_addr + (pc - p->orig_addr);
				return;
			}
		}
	}
	
	BOOL didMatchPatch = false;
	
	// This is six kinds of wrong; we're just rewriting any registers that match the si_addr, and
	// are pointed into now-dead pages. The danger here ought to be obvious.
	for (int i = 0; i < patch_count; i++) {
		struct patch *p = &patches[i];
		
		if ((typeof(pc)) info->si_addr < p->orig_addr)
			continue;
		
		if ((typeof(pc)) info->si_addr >= p->orig_addr + p->mapped_size)
			continue;
		
		// XXX we abuse the r[] array here.
		for (int i = 0; i < 32; i++) {
			typeof(pc) rv = (x)[i];
			if (rv == (uintptr_t) info->si_addr) {
				if (p->new_addr > p->orig_addr)
					(x)[i] -= p->new_addr - p->orig_addr;
				else
					(x)[i] += p->orig_addr - p->new_addr;
				didMatchPatch = true;
			}
		}
		
	}
	
	if (!didMatchPatch && fallbackHandler)
	{
		fallbackHandler(signo);
	}
	else
	{
		ctx->__es.__far = 0x0;
		ctx->__es.__esr = 0x02000000;
		ctx->__es.__exception = 0x0;
	}
	
	return;
}
#endif

PureEvil* sharedDarkness;

@implementation PureEvil

- (id)init {
	self = [super init];
	
	self.mappedImages = [NSMutableArray new];
	
	return self;
}

+ (instancetype)sharedEvil
{
	if (!sharedDarkness) {
		sharedDarkness = [self new];
	}
	
	return sharedDarkness;
}

void baseFallback(int signo) {
	raise(signo);
}

void (*fallbackSignalHandler)(int signo) = baseFallback;

+ (void)setFallbackHandler:(void (*)(int signo))fallback
{
	fallbackSignalHandler = fallback;
}


+ (kern_return_t)overrideFunction:(void*)targetFunction
					  newFunction:(const void*)newFunction
		 originalFunctionCallable:(void**)originalRentry
{
	extern void *_sigtramp;
	/// Return value
	__block kern_return_t returnValue;
	
	/// The page for the target function
	vm_address_t page = trunc_page((vm_address_t) targetFunction);
	
	/// Not sure what this assertion is doing
	assert(page != trunc_page((vm_address_t) _sigtramp));
	
	/* Determine the Mach-O image and size. */
	
	/// Will be filled with the target function's page info.
	Dl_info dlinfo;
	
	/// Fill and check for error
	if (dladdr(targetFunction, &dlinfo) == 0) {
		EVILog(@"dladdr() failed: %s", dlerror());
		return KERN_FAILURE;
	}
	
	__block uint64_t image_addr = (vm_address_t) dlinfo.dli_fbase;
	__block uint64_t image_end = image_addr;
	__block uint64_t image_slide = 0x0;
	
	bool ret = [PureEvil iterateMachOSegmentsWithHeader:dlinfo.dli_fbase block:^(const char segname[16], uint64_t vmaddr, uint64_t vmsize, BOOL *cont) {
		if (vmaddr + vmsize > image_end)
			image_end = vmaddr + vmsize;
		
		if (image_addr == image_end) {
			image_end += vmsize;
		}
		
		// compute the slide. we could also get this iterating the images via dyld, but whatever.
		if (strcmp(segname, SEG_TEXT) == 0) {
			if (vmaddr < image_addr)
				image_slide = image_addr - vmaddr;
			else
				image_slide = vmaddr - image_addr;
		}
		
	}];
	
	uint64_t image_size = image_end - image_addr;
	
	if (!ret) {
		EVILog(@"Failed parsing Mach-O header");
		return KERN_FAILURE;
	}
	
	/* Allocate a single contigious block large enough for our purposes */
	vm_address_t target = 0x0;
	returnValue = vm_allocate(mach_task_self(), &target, (vm_size_t) image_size, VM_FLAGS_ANYWHERE);
	
	// Check for failure
	if (returnValue != KERN_SUCCESS) {
		EVILog(@"Failed reserving sufficient space");
		return KERN_FAILURE;
	}
	
	/* Remap the segments into place */
	[PureEvil iterateMachOSegmentsWithHeader:dlinfo.dli_fbase block:^(const char *segname, uint64_t vmaddr, uint64_t vmsize, BOOL *cont) {
		EVILog(@"Iterating segs. vmsize: %llu", vmsize);
		if (vmsize == 0)
			return;
		
		uint64_t seg_source = vmaddr + image_slide;
		uint64_t seg_target = target + (seg_source - image_addr);
		
		vm_prot_t cprot, mprot;
		EVILog(@"Remapping...");
		returnValue = vm_remap(mach_task_self(),
							   (vm_address_t *) &seg_target,
							   (vm_size_t) vmsize,
							   0x0,
							   VM_FLAGS_FIXED|VM_FLAGS_OVERWRITE,
							   mach_task_self(),
							   (vm_address_t) seg_source,
							   false,
							   &cprot,
							   &mprot,
							   VM_INHERIT_SHARE);
		EVILog(@"Done remapping.");
		if (returnValue != KERN_SUCCESS) {
			*cont = false;
			return;
		}
	}];
	
	
	
	if (returnValue != KERN_SUCCESS) {
		EVILog(@"Failed to remap pages: 0x%x", returnValue);
		return returnValue;
	}
	
	EVILog(@"Creating patch...");
	PEPatch *patch = [PEPatch new];
	patch.originalAddress = image_addr;
	patch.newAddress = target;
	patch.mappedSize = image_size;
	
	patch.originalFunctionPointer = (uintptr_t) targetFunction;
	patch.originalFunctionPointer_nthumb = ((uintptr_t) targetFunction) & ~1;
	patch.newFunctionPointer = (vm_address_t) newFunction;
	EVILog(@"Patch created.");
	
	EVILog(@"Adding patch.");
	[PEManager addPatch:patch];
	EVILog(@"Patch added.");
	
	// For whatever reason we can't just remove PROT_WRITE with mprotect. It
	// succeeds, but then doesn't do anything. So instead, we overwrite the
	// target with a dead page.
	// There's a race condition between the vm_allocate and vm_protect. One could
	// probably fix that by allocating elsewhere, setting permissions, and remapping in,
	// or by mapping in the NULL page.
#if 0
	//vm_deallocate(mach_task_self(), page, PAGE_SIZE);
	EVILog(@"Reserving space...");
	returnValue = vm_allocate(mach_task_self(), &page, PAGE_SIZE, VM_FLAGS_FIXED|VM_FLAGS_OVERWRITE);
	if (returnValue != KERN_SUCCESS) {
		EVILog(@"Failed reserving sufficient space");
		return KERN_FAILURE;
	}
	EVILog(@"Space reserved");
	
	EVILog(@"Setting protections...");
	vm_protect(mach_task_self(), page, PAGE_SIZE, true, VM_PROT_NONE);
	EVILog(@"Protections changed.");
#else
	// Not sure, but this seems to work now.
	if (mprotect((void *)page, PAGE_SIZE, PROT_NONE) != 0) {
		perror("mprotect");
		return KERN_FAILURE;
	}
#endif
	
	if (originalRentry) {
		*originalRentry = (void *) (patch.newAddress + (patch.originalFunctionPointer - patch.originalAddress));
	}
	
	
	return KERN_SUCCESS;
}

+ (BOOL)iterateMachOSegmentsWithHeader:(const void *)header block:(void (^)(const char segname[16], uint64_t vmaddr, uint64_t vmsize, BOOL *cont))block
{
	const struct mach_header *header32 = (const struct mach_header *) header;
	const struct mach_header_64 *header64 = (const struct mach_header_64 *) header;
	struct load_command *cmd;
	uint32_t ncmds;
	
	/* Check for 32-bit/64-bit header and extract required values */
	switch (header32->magic) {
			/* 32-bit */
		case MH_MAGIC:
		case MH_CIGAM:
			ncmds = header32->ncmds;
			cmd = (struct load_command *) (header32 + 1);
			break;
			
			/* 64-bit */
		case MH_MAGIC_64:
		case MH_CIGAM_64:
			ncmds = header64->ncmds;
			cmd = (struct load_command *) (header64 + 1);
			break;
			
		default:
			//NSLog(@"Invalid Mach-O header magic value: %x", header32->magic);
			return false;
	}
	
	for (uint32_t i = 0; cmd != NULL && i < ncmds; i++) {
		BOOL cont = true;
		
		/* 32-bit text segment */
		if (cmd->cmd == LC_SEGMENT) {
			struct segment_command *segment = (struct segment_command *) cmd;
			block(segment->segname, segment->vmaddr, segment->vmsize, &cont);
		}
		
		/* 64-bit text segment */
		else if (cmd->cmd == LC_SEGMENT_64) {
			struct segment_command_64 *segment = (struct segment_command_64 *) cmd;
			block(segment->segname, segment->vmaddr, segment->vmsize, &cont);
		}
		
		cmd = (struct load_command *) ((uint8_t *) cmd + cmd->cmdsize);
		
		if (!cont)
			break;
	}
	
	return true;
}

@end
