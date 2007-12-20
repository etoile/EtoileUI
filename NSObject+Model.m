/*
	NSObject+Model.m
	
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

#import <EtoileUI/NSObject+Model.h>
#import <EtoileUI/ETCompatibility.h>

//#define DEBUG_PVC 1


@implementation NSObject (EtoileModel)

+ (id) objectWithObjectValue: (id)object
{
	if ([object isString])
	{
		return [self objectWithStringValue: object];
	}
	else if ([object isCommonObjectValue])
	{
		return object;
	}
	else if ([object isKindOfClass: [NSValue class]])
	{
		return nil;
	}
	
	return nil;
}

+ (id) objectWithStringValue: (id)string
{
	id object = nil;
	Class class = NSClassFromString(string);
	
	if (class != nil)
		object = AUTORELEASE([[class alloc] init]);
		
	return object;
}

	// returning the value
	// as is if it is declared as a common object value or
- (id) objectValue
{
	if ([self isCommonObjectValue])
	{
		return self;
	}
	else
	{
		return [self stringValue];
	}
}

/** Returns the description of the receiver by default.
	Subclasses can override this method to return a string representation that 
	encodes some basic infos about the receiver. This string representation can
	then be edited, validated by -validateValue:forKey:error: and used to 
	instantiate another object by passing it to +objectWithStringValue:. */
- (id) stringValue
{
	return [self description];
}

/** Returns YES if the receiver is an NSString instance, otherwise, returns NO. */
- (BOOL) isString
{
	return [self isKindOfClass: [NSString class]];
}

/** Returns YES if the receiver is an NSNumber instance, otherwise, returns NO. */
- (BOOL) isNumber
{
	return [self isKindOfClass: [NSNumber class]];
}

- (BOOL) validateValue: (id *)value forKey: (NSString *)key error: (NSError **)err
{
	id val = *value;
	BOOL validated = YES;
	
	if ([val isCommonObjectValue])
		return YES;
	
	/* Validate non common value objects */
		
	NSString *type = [self typeForKey: key];
	
	return validated;
}

- (NSString *) typeForKey: (NSString *)key
{
/*	NSMethodSignature *sig = [self methodSignatureForSelector: NSSelectorFromString(key)];
	
	if (sig == nil)
		sig [self methodSignatureForSelector: NSSelectorFromString()];
		
	[*/
	return nil;
}

/* Property Value Coding */

- (NSArray *) properties
{
	return [NSArray arrayWithObjects: @"icon", @"displayName", nil];
}

- (id) valueForProperty: (NSString *)key
{
	id value = nil;
	
	if ([[self properties] containsObject: key])
	{
		value = [self valueForKey: key];
	}
	else
	{
		// TODO: Turn into an ETDebugLog which takes an object (or a class) to
		// to limit the logging to a particular object or set of instances.
		#ifdef DEBUG_PVC
		ETLog(@"WARNING: Found no value for property %@ in %@", key, self);
		#endif
	}
	
	return value;
}

- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	BOOL result = NO;
	
	if ([[self properties] containsObject: key])
	{
		[self setValue: value forKey: key];
		result = YES;
	}
	else
	{
		// TODO: Turn into an ETDebugLog which takes an object (or a class) to
		// to limit the logging to a particular object or set of instances.
		#ifdef DEBUG_PVC
		ETLog(@"WARNING: Trying to set value %@ for property %@ missing in "
			@"immutable property collection of %@", value, key, self);
		#endif
	}
	
	return result;
}

/* Basic Properties */

/** Returns the receiver description.
	Subclasses can override this method to return a more appropriate display
	name. */
- (NSString *) displayName
{
	return [self description];
}

/** Returns the icon used to represent unknown object.
	Subclasses can override this method to return an icon that suits and 
	describes better their own objects. */
- (NSImage *) icon
{
	// FIXME: Asks Jesse to create an icon representing an unknown object
	return nil;
}

/** Returns YES when the receiver is an object which can be passed to 
	-setObjectValue: or returned by -objectValue. Some common object values
	like string and number can be displayed and edited transparently (in an 
	NSCell instance to take an example). If you define additional common object
	values, you usually have to write related formatters.
	Returns NO by default.
	Subclasses can override this method to specify an object can be accepted
	and used a common object value. */
- (BOOL) isCommonObjectValue
{
	return NO;
}

@end

/* Basic Common Value Classes */

@implementation NSString (EtoileModel)
- (BOOL) isCommonObjectValue { return YES; }
@end

@implementation NSNumber (EtoileModel)
- (BOOL) isCommonObjectValue { return YES; }
@end

@implementation NSImage (EtoileModel)
- (BOOL) isCommonObjectValue { return YES; }
@end


@implementation ETProperty

+ (id) propertyWithName: (NSString *)key representedObject: (id)object
{
	return AUTORELEASE([[ETProperty alloc] initWithName: key representedObject: object]);
}

- (id) initWithName: (NSString *)key representedObject: (id)object
{
	self = [super init];
	
	if (self != nil)
	{
		ASSIGN(_propertyName, key);
		[self setRepresentedObject: object];
	}
	
	return self;
}

- (void) dealloc
{
	DESTROY(_propertyName);
	DESTROY(_propertyOwner);
	
	[super dealloc];
}

- (id) representedObject
{
	return _propertyOwner;
}

- (void) setRepresentedObject: (id)object
{
	ASSIGN(_propertyOwner, object);
}

- (NSString *) name
{
	return _propertyName;
}

/*- (NSString *) string
{
	[[self objectValue] stringValue];
}*/

- (NSString *) type
{
	// NOTE: May be necessary to cache this value...
	// or [[self representedObject] typeForKey: [self name]]
	return [[self objectValue] type];
}

- (id) objectValue
{
	return [[self representedObject] valueForProperty: [self name]];
}

- (void) setObjectValue: (id)objectValue
{
	[[self representedObject] setValue: objectValue forProperty: [self name]];
}

/* Property Value Coding */

- (NSArray *) properties
{
	return [NSArray arrayWithObjects: @"property", @"name", @"value", nil];
}

- (id) valueForProperty: (NSString *)key
{
	id value = nil;
	
	if ([[self properties] containsObject: key])
	{
		if ([key isEqual: @"value"])
		{
			value = [self objectValue];
		}
		else if ([key isEqual: @"property"])
		{
			value = [self name];
		}
		else /* name, type properties */
		{
			value = [self valueForKey: key];
		}
	}
	
	return value;
}

- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	BOOL result = NO;
	
	if ([[self properties] containsObject: key])
	{
		// NOTE: name, type are read-only properties
		if ([key isEqual: @"value"])
		{
			[self setObjectValue: value];
			result = YES;
		}
	}
	
	return result;
}

@end
