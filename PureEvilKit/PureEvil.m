//
//  PureEvil.m
//  libevil
//
//  Created by Will Stafford on 4/12/16.
//  Copyright © 2016 Landon Fuller. All rights reserved.
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
	//	__uint64_t	*rbx = &ctx->__ss.__rbx;
	//	__uint64_t	*rcx = &ctx->__ss.__rcx;
	//	__uint64_t	*rdx = &ctx->__ss.__rdx;
	//	__uint64_t	*rdi = &ctx->__ss.__rdi;
	//	__uint64_t	*rsi = &ctx->__ss.__rsi;
	//	__uint64_t	*rbp = &ctx->__ss.__rbp;
	//	__uint64_t	*rsp = &ctx->__ss.__rsp;
	//	__uint64_t	*r8 = &ctx->__ss.__r8;
	//	__uint64_t	*r9 = &ctx->__ss.__r9;
	//	__uint64_t	*r10 = &ctx->__ss.__r10;
	//	__uint64_t	*r11 = &ctx->__ss.__r11;
	//	__uint64_t	*r12 = &ctx->__ss.__r12;
	//	__uint64_t	*r13 = &ctx->__ss.__r13;
	//	__uint64_t	*r14 = &ctx->__ss.__r14;
	//	__uint64_t	*r15 = &ctx->__ss.__r15;
	__uint64_t	*rip = &ctx->__ss.__rip;
	//	__uint64_t	*rflags = &ctx->__ss.__rflags;
	//	__uint64_t	*cs = &ctx->__ss.__cs;
	//	__uint64_t	*fs = &ctx->__ss.__fs;
	//	__uint64_t	*gs = &ctx->__ss.__gs;
	
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
static void page_mapper (int signo, siginfo_t *info, void *uapVoid) {
	ucontext_t *uap = uapVoid;
	typeof(uap->uc_mcontext) ctx = uap->uc_mcontext;
	
	unsigned int	*eax = &ctx->__ss.__eax;
	unsigned int	*eip = &ctx->__ss.__eip;
	
	unsigned int pc = *eip;
	
	if (pc == (typeof(pc)) info->si_addr) {
		for (int i = 0; i < patch_count; i++) {
			if (patches[i].orig_fptr_nthumb == pc) {
				*eip = (uintptr_t) patches[i].new_fptr;
				return;
			}
		}
		
		for (int i = 0; i < patch_count; i++) {
			struct patch *p = &patches[i];
			if (pc >= p->orig_addr && pc < (p->orig_addr + p->mapped_size)) {
				*eip = p->new_addr + (pc - p->orig_addr);
				return;
			}
		}
	}
	
	BOOL didMatchPatch = false;
	
	// This is six kinds of wrong; we're just rewriting any registers that match the si_addr, and
	// are pointed into now-dead pages. The danger here ought to be obvious.
	for (int i = 0; i < patch_count; i++) {
		struct patch *p = &patches[i];
		
		if ((uintptr_t) info->si_addr < p->orig_addr)
			continue;
		
		if ((uintptr_t) info->si_addr >= p->orig_addr + p->mapped_size)
			continue;
		
		// XXX we abuse the r[] array here.
		for (int i = 0; i < 9; i++) {
			uintptr_t rv = (eax)[i];
			if (rv == (uintptr_t) info->si_addr) {
				if (p->new_addr > p->orig_addr)
					(eax)[i] -= p->new_addr - p->orig_addr;
				else
					(eax)[i] += p->orig_addr - p->new_addr;
				didMatchPatch = true;
			}
		}
		
		for (int i = 1; i <= 5; i++) {
			uintptr_t rv = (eax)[i];
			if (rv == (uintptr_t) info->si_addr) {
				if (p->new_addr > p->orig_addr)
					(eip)[i] -= p->new_addr - p->orig_addr;
				else
					(eip)[i] += p->orig_addr - p->new_addr;
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
	
	if (!didMatchPatch && fallbackHandler)
	{
		fallbackHandler(signo);
	}
	
	return;
}
#endif

#ifdef EVIL_ARMV7
static void page_mapper (int signo, siginfo_t *info, void *uapVoid) {
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
	
	if (!didMatchPatch && fallbackHandler)
	{
		fallbackHandler(signo);
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
static void page_mapper (int signo, siginfo_t *info, void *uapVoid) {
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


BOOL macho_iterate_segments (const void *header, void (^block)(const char segname[16], vm_address_t vmaddr, vm_size_t vmsize, BOOL *cont)) {
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
			NSLog(@"Invalid Mach-O header magic value: %x", header32->magic);
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

extern void *_sigtramp;

// Replace 'function' with 'newImp', and return an address at 'originalRentry' that
// may be used to call the original function.
kern_return_t evil_override_ptr (void *function, const void *newFunction, void **originalRentry) {
	__block kern_return_t kt;
	
	vm_address_t page = trunc_page((vm_address_t) function);
	assert(page != trunc_page((vm_address_t) _sigtramp));
	
	/* Determine the Mach-O image and size. */
	Dl_info dlinfo;
	if (dladdr(function, &dlinfo) == 0) {
		NSLog(@"dladdr() failed: %s", dlerror());
		return KERN_FAILURE;
	}
	
	__block vm_address_t image_addr = (vm_address_t) dlinfo.dli_fbase;
	__block vm_address_t image_end = image_addr;
	__block intptr_t image_slide = 0x0;
	
	bool ret = macho_iterate_segments(dlinfo.dli_fbase, ^(const char segname[16], vm_address_t vmaddr, vm_size_t vmsize, BOOL *cont) {
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
		
	});
	vm_address_t image_size = image_end - image_addr;
	
	if (!ret) {
		NSLog(@"Failed parsing Mach-O header");
		return KERN_FAILURE;
	}
	
	/* Allocate a single contigious block large enough for our purposes */
	vm_address_t target = 0x0;
	kt = vm_allocate(mach_task_self(), &target, image_size, VM_FLAGS_ANYWHERE);
	if (kt != KERN_SUCCESS) {
		NSLog(@"Failed reserving sufficient space");
		return KERN_FAILURE;
	}
	
	/* Remap the segments into place */
	macho_iterate_segments(dlinfo.dli_fbase, ^(const char segname[16], vm_address_t vmaddr, vm_size_t vmsize, BOOL *cont) {
		if (vmsize == 0)
			return;
		
		vm_address_t seg_source = vmaddr + image_slide;
		vm_address_t seg_target = target + (seg_source - image_addr);
		
		vm_prot_t cprot, mprot;
		kt = vm_remap(mach_task_self(),
					  &seg_target,
					  vmsize,
					  0x0,
					  VM_FLAGS_FIXED|VM_FLAGS_OVERWRITE,
					  mach_task_self(),
					  seg_source,
					  false,
					  &cprot,
					  &mprot,
					  VM_INHERIT_SHARE);
		if (kt != KERN_SUCCESS) {
			*cont = false;
			return;
		}
	});
	
	if (kt != KERN_SUCCESS) {
		NSLog(@"Failed to remap pages: %x", kt);
		return kt;
	}
	
	PEPatch *patch = [PEPatch new];
	patch.originalAddress = image_addr;
	patch.newAddress = target;
	patch.mappedSize = image_size;
	
	patch.originalFunctionPointer = (uintptr_t) function;
	patch.originalFunctionPointer_nthumb = ((uintptr_t) function) & ~1;
	patch.newFunctionPointer = (vm_address_t) newFunction;
	
	[[PEManager sharedEvil].patches addObject:patch];
	
	// For whatever reason we can't just remove PROT_WRITE with mprotect. It
	// succeeds, but then doesn't do anything. So instead, we overwrite the
	// target with a dead page.
	// There's a race condition between the vm_allocate and vm_protect. One could
	// probably fix that by allocating elsewhere, setting permissions, and remapping in,
	// or by mapping in the NULL page.
#if 1
	// vm_deallocate(mach_task_self(), page, PAGE_SIZE);
	
	kt = vm_allocate(mach_task_self(), &page, PAGE_SIZE, VM_FLAGS_FIXED|VM_FLAGS_OVERWRITE);
	if (kt != KERN_SUCCESS) {
		NSLog(@"Failed reserving sufficient space");
		return KERN_FAILURE;
	}
	vm_protect(mach_task_self(), page, PAGE_SIZE, true, VM_PROT_NONE);
	
#else
	if (mprotect(page, PAGE_SIZE, PROT_NONE) != 0) {
		perror("mprotect");
		return KERN_FAILURE;
	}
#endif
	
	if (originalRentry)
		*originalRentry = (void *) (patch.newAddress + (patch.originalFunctionPointer - patch.originalAddress));
	
	return KERN_SUCCESS;
}



@implementation PureEvil

@end


