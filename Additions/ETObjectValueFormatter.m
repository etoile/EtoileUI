/*
	Copyright (C) 2013 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import "ETObjectValueFormatter.h"

@implementation ETObjectValueFormatter

@synthesize delegate = _delegate, name = _name;

- (void) dealloc
{
	DESTROY(_name);
	[super dealloc];
}

- (NSString *) stringForObjectValue: (id)aValue
{
	/* If a text field presents an entity object, no empty strings must be 
	   passed to NSStringFromClass(), otherwise the text field shows a NSString 
	   subclass as the entity type. */
	if (aValue == nil || [aValue isString])
		return aValue;

	id string = [[(id)[self delegate] ifResponds] formatter: self stringForObjectValue: aValue];
	ETAssert(string == nil || [string isKindOfClass: [NSString class]]);

	if (string == nil)
	{
		string = NSStringFromClass([aValue class]);
	}
	return string;
}

/** This method is called on each key press, if the string represents a valid value 
value, it returns YES to indicate the user can stop the editing, otherwise it 
returns NO to indicate the user must continue the editing (hitting the return key 
doesn't abort the editing). */
- (BOOL) getObjectValue: (id *)anObject forString: (NSString *)aString errorDescription: (NSString **)error
{
	NSString *string = AUTORELEASE([aString copy]);

	if (string == nil)
		return NO;

	NSString *validatedString = [[self delegate] formatter: self stringValueForString: string];
	ETAssert(validatedString == nil || [validatedString isKindOfClass: [NSString class]]);

	if (validatedString == nil && NSClassFromString(string) != Nil)
	{
		validatedString = string;
	}
	
	if (validatedString == nil)
	{
		//*error = [NSString stringWithFormat: _(@"Found no aspect or class for %@"), string];
		//error = &string;
		return NO;
	}
	else
	{
		*anObject = validatedString;
		return YES;
	}
}

@end

