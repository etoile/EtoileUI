/*
	ETCompatibility.h
	
	Implementation compatibility (Cocoa, GNUstep etc.) and other utilities like 
	widely used macros
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
 
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
 
/* CoreObject (aka ObjectMerging) Support */
 
#define OBJECTMERGING

#ifdef OBJECTMERGING
#  define BASEOBJECT COObject
#else
#  define BASEOBJECT NSObject
#endif

/* How we get GNUstep.h */

#ifndef GNUSTEP
#import <EtoileFoundation/GNUstep.h>
#else
// NOTE: Temporary hack until GNUstep Base includes KVO header in Foundation.h
#import <Foundation/NSKeyValueObserving.h>
#endif

/* Logging Additions */

// TODO: Should be improved to rely on a logging class. Probably move to EtoileFoundation too.
#ifdef DEBUG_LOG
#define ETDebugLog ETLog
#else
#define ETDebugLog(format, args...)
#endif
#define ETLog NSLog

/* Properties Read and Write Macros */

/* Macros to read and write the local properties that belongs the given object 
without exposing how the properties are stored. */
#define SET_OBJECT_PROPERTY(object, value, property) \
	if (value != nil) \
	{ \
		[object->_variableProperties setObject: value forKey: property]; \
	} \
	else \
	{ \
		[object->_variableProperties removeObjectForKey: property]; \
	}
#define GET_OBJECT_PROPERTY(object, property) \
	[object->_variableProperties objectForKey: property]
#define HAS_OBJECT_PROPERTY(object, property) \
	([object->_variableProperties objectForKey: property] != nil)

#define SET_OBJECT_PROPERTY_AND_RELEASE(object, value, property) \
do { \
	id __val = value; \
	SET_OBJECT_PROPERTY(object, __val, property); \
	RELEASE(__val); \
} while (0)


/* Macros to read and write the receiver local properties without exposing 
how the properties are stored. The implicit property owner is self. */
#define SET_PROPERTY(value, property) \
	SET_OBJECT_PROPERTY(self, value, property)
#define GET_PROPERTY(property) \
	GET_OBJECT_PROPERTY(self, property)
#define HAS_PROPERTY(property) \
	HAS_OBJECT_PROPERTY(self, property)
	
/* Assertions */

// TODO: Move to EtoileFoundation as ETAssertFail()
#define ASSERT_FAIL(msg) NSAssert(NO, msg)
// TODO: Use ETAssertUnreachable() instead
#define ASSERT_INVALID_CASE ASSERT_FAIL(@"Reached invalid branch statement. e.g. the default case in a switch statement")

/* For debugging */

//#define DEBUG_DRAWING

#define TRACE_RELEASE_RETAIN(className) \
@interface className (TraceReleaseRetain) \
- (oneway void) release; \
- (id) retain; \
@end \
@implementation className (TraceReleaseRetain) \
- (oneway void) release \
{ \
	ETLog(@"TRACE -- Release %@", self); \
	[super release]; \
} \
- (id) retain \
{ \
	ETLog(@"TRACE -- Retain %@", self); \
	return [super retain]; \
} \
@end
