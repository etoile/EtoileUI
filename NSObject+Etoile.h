/*
	NSObject+etoile.h
	
	NSObject additions like basic metamodel.
 
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@protocol ETInspectableObject
- (id) valueForProperty: (NSString *)key;
- (void) setValue: (id)value forProperty: (NSString *)key;
@end

/** Utility metamodel for GNUstep/Cocoa Objective-C */

@interface NSObject (Etoile)
{

}

/** Returns both methods and instance variables for the receiver by default */
- (NSArray *) properties;
- (id) valueForProperty: (NSString *)key;
- (void) setValue: (id)value forProperty: (NSString *)key;

- (NSArray *) instanceVariables;
- (NSArray *) instanceVariableNames;
- (NSDictionary *) instancesVariableValues;
- (NSDictionary *) instancesVariableTypes;
- (id) valueForInstanceVariable: (NSString *)ivar;
- (id) typeForInstanceVariable: (NSString *)ivar;

- (NSArray *) methods;
- (NSArray *) methodNames;
- (NSArray *) instanceMethods;
- (NSArray *) instanceMethodNames;
- (NSArray *) classMethods;
- (NSArray *) classMethodNames;

- (void) addMethod: (ETMethod *)method;
- (void) removeMethod: (ETMethod *)method;
/** Method swizzling */
- (void) replaceMethod: (ETMethod *)method byMethod: (ETMethod *)method;

/** Low level methods used to implement method list edition */
- (void) bindMethod: (ETMethod *) toSelector: (SEL)selector;
- (void) bindSelector: (SEL) toMethod: (ETMethod *)method;

@end

@interface ETInstanceVariable : NSObject 
{

}

- (NSString *) name;
// FIXME: Replace by ETUTI class later
- (NSString *) type;
- (id) value;
/** Pass NSValue to set primitive types */
- (void) setValue: (id)value;

@end

@interface ETMethod : NSObject 
{

}

- (BOOL) isInstanceMethod;
- (BOOL) isClassMethod;

- (NSString *) name;
- (SEL) selector;
- (NSMethodSignature *) methodSignature;

@end
