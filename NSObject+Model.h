/*
	NSObject+Model.h
	
	NSObject additions providing basic management of model objects.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
 
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
#import <EtoileUI/ETPropertyValueCoding.h>


@interface NSObject (EtoileModel)

+ (id) objectWithObjectValue: (id)object;
+ (id) objectWithStringValue: (NSString *)string;

- (id) objectValue;
- (NSString *) stringValue;
- (NSString *) stringValueWithOptions: (NSDictionary *)outputOptions;

- (BOOL) isCommonObjectValue;
- (BOOL) isString;
- (BOOL) isNumber;

- (NSString *) typeForKey: (NSString *)key;

/* Property Value Coding */

- (NSArray *) properties;
- (id) valueForProperty: (NSString *)key;
- (BOOL) setValue: (id)value forProperty: (NSString *)key;

/* Basic Properties */

- (NSString *) displayName;
- (NSImage *) icon;

- (NSString *) primitiveDescription;

/* Collection & Mutability */

- (BOOL) isMutable;
- (BOOL) isCollection;
- (BOOL) isMutableCollection;
- (BOOL) isGroup;

- (id) keyForCollection: (id)collection;

@end

/* Basic Common Value Classes */

@interface NSString (EtoileModel)
- (BOOL) isCommonObjectValue;
@end

@interface NSNumber (EtoileModel)
- (BOOL) isCommonObjectValue;
@end

@interface NSImage (EtoileModel)
- (BOOL) isCommonObjectValue;
@end


/** Property Representation */
@interface ETProperty : NSObject <ETPropertyValueCoding>
{
	id _propertyOwner;
	id _propertyName;
}

+ (id) propertyWithName: (NSString *)key representedObject: (id)object;

- (id) initWithName: (NSString *)key representedObject: (id)objet;

- (NSString *) name;

- (id) representedObject;
- (void) setRepresentedObject: (id)object;

//- (NSString *) stringValue;
- (NSString *) type;

- (id) objectValue;
- (void) setObjectValue: (id)objectValue;

/* Property Value Coding */

- (NSArray *) properties;
- (id) valueForProperty: (NSString *)key;
- (BOOL) setValue: (id)value forProperty: (NSString *)key;

@end
