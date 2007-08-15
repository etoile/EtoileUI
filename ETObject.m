/*
	ETObject.m
	
	Description forthcoming.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ETObject.h"
#import "GNUstep.h" 
#import <objc/objc.h>
#import <objc/objc-api.h>
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>

struct objc_object_header {
	id context;
};
typedef struct objc_object_header * ObjectHeader;

NSObject * ETAllocateObject(Class aClass, unsigned extraBytes, NSZone *zone)
{
	if (extraBytes > 0)
	{
		NSLog(@"WARNING: Trying to allocate extra bytes with class %@", aClass);
	}
	
	id object = NSAllocateObject(aClass, extraBytes + sizeof(struct objc_object_header), zone);
	
	struct objc_object_header *header = (struct objc_object_header *)(((char *)object) + sizeof(struct objc_object) + (unsigned)aClass->instance_size + extraBytes);
	header->context = object;
	
	return object;
}

void ETDeallocateObject(NSObject *anObject)
{
	NSDeallocateObject(anObject);
}

@implementation NSObject (ETObject)

/*+ (id) allocWithZone: (NSZone *)z
{
	return ETAllocateObject (self, 0, z);
}

- (void) dealloc
{
	ETDeallocateObject(self);
}*/

@end

@implementation ETObject

+ (id) allocWithZone: (NSZone *)z
{
	return ETAllocateObject (self, 0, z);
}

- (id) init
{
#ifdef REPLACE_SELF_BY_SELF_MSG
	//[self setSelf: [super init]];
	me = [super init];
#else
	self = [super init];
#endif
#undef self	
	Class selfClass = [self class];
	struct objc_object_header *header = (struct objc_object_header *)(((char *)self) + sizeof(struct objc_object) + selfClass->instance_size);

	NSLog(@"Found context %@", header->context);
	//id oh = (id)&self[-1];
	//id obj = oh.context;
	/*id obj = self;
	
	((obj_header *)&obj[-1])->context = nil;
	((obj_header *)obj)[-1].context = nil;*/
	
	return self;
}

- (void) setPrototype: (id)proto
{
	ASSIGN(_proto_, proto);
}

- (id) prototype
{
	return _proto_;
}

- (BOOL) respondsToSelector: (SEL)selector
{
	if ([self respondsToSelectorIgnoringPrototype: selector]
	 || [_proto_ respondsToSelector: selector])
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

- (BOOL) respondsToSelectorIgnoringPrototype: (SEL)selector
{
	return [super respondsToSelector: selector];
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL)selector
{
	if ([_proto_ respondsToSelector: selector])
	{
		return [_proto_ methodSignatureForSelector: selector];
	}
	else
	{
		return [super methodSignatureForSelector: selector];
	}
}

- (void) forwardInvocation: (NSInvocation *)inv
{
	SEL selector = [inv selector];
	
	//NSLog(@"Forward invocation %@ in %@", inv, self);
	
	if ([_proto_ respondsToSelector: selector])
	{
		[_proto_ handleInvocation: inv inContext: self];
	}
	else
	{
		[self doesNotRecognizeSelector: selector];
	}
}

- (void) handleInvocation: (NSInvocation *)inv inContext: (id)sender
{
	SEL selector = [inv selector];
	
	//NSLog(@"Handle invocation %@ sent by %@ in %@", inv, sender, self);
	
	if ([self respondsToSelectorIgnoringPrototype: selector])
	{
		//IMP methodIMP = [self methodForSelector: selector];
		//[inv invokeWithTarget: sender];
		/* We sent the message known by inv directly to self, even if self is 
		   avoid in favor of _context_ in all current object methods. This trick
		   makes possible to have to usual class inheritance and ivars lookup 
		   to happen. */
		#undef self
		_context_ = sender;
		[inv invokeWithTarget: self];
		_context_ = self;
		#define self _context_
	}
	else if	(_proto_ != nil && [_proto_ respondsToSelector: selector])
	{
		[_proto_ handleInvocation: inv inContext: sender];
	}
	else
	{
		NSLog(@"WARNING: Impossible to handle invocation %@ in %@", inv, self);
	}
}

#undef self

- (id) self
{
	return _context_;
}

- (void) setSelf: (id)context
{
	return ASSIGN(_context_, context);
}

@end

