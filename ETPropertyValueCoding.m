/*
	ETPropertyValueCoding.m
	
	Property Value Coding protocol used by CoreObject and EtoileUI provides a
	unified API to implement access, mutation, delegation and late-binding of 
	properties.
 
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


#import <EtoileUI/ETPropertyValueCoding.h>
#import <EtoileUI/ETCompatibility.h>


@implementation NSDictionary (ETPropertyValueCoding)

- (NSArray *) properties
{
	return [self allKeys];
}

- (id) valueForProperty: (NSString *)key
{
	return [self objectForKey: key];
}

- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	return NO;
}

@end

@implementation NSMutableDictionary (ETPropertyValueCoding)

- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	BOOL result = YES;
	id object = value;
	
	// NOTE: Note sure we should really insert a null object when value is nil
	if (object == nil)
		object = [NSNull null];
	
	NS_DURING
		[self setObject: object forKey: key];
	NS_HANDLER
		result = NO;
		ETLog(@"Failed to set value %@ for property %@ in %@", value, key, self);
	NS_ENDHANDLER
	
	return result;
}

@end

#if 0

/* To extend NSClassDescription and NSManagedObject */
- (NSArray *) properties
{
	else if ([_modelObject respondsToSelector: @selector(entity)]
	 && [[(id)_modelObject entity] respondsToSelector: @selector(properties)])
	{
		/* Managed Objects have an entity which describes them */
		properties = (NSArray *)[[_modelObject entity] properties];
	}
	else if ([_modelObject respondsToSelector: @selector(classDescription)])
	{
		/* Any objects can declare a class description, so we try to use it */
		NSClassDescription *desc = [_modelObject classDescription];
		
		properties = [NSMutableArray arrayWithArray: [desc attributeKeys]];
		// NOTE: Not really sure we should include relationship keys
		[(NSMutableArray *)properties addObjectsFromArray: (NSArray *)[desc toManyRelationshipKeys]];
		[(NSMutableArray *)properties addObjectsFromArray: (NSArray *)[desc toOneRelationshipKeys]];
	}
}

#endif
