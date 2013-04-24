/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import "ETResponder.h"

@implementation ETResponderTrait

/** <override-dummy />
Returns the next responder in the responder chain.
 
By default, returns nil. */
- (id) nextResponder
{
	return nil;
}

/** Returns the first responder sharing area in the responder chain.

The returned object coordinates the field editor use to ensure the first
responder status is given to a single object in this area.

By default, returns the receiver in case it conforms to ETFirstResponderSharingArea,
or just  calls -firstResponderSharingArea on -nextResponder. */
- (id <ETFirstResponderSharingArea>) firstResponderSharingArea
{
	if ([self conformsToProtocol: @protocol(ETFirstResponderSharingArea)])
	{
		return (id)self;
	}
	return [[self nextResponder] firstResponderSharingArea];
}

/** Returns the edition coordinator in the responder chain.
 
By default, returns the receiver in case it conforms to ETEditionCoordinator, 
or just  calls -editionCoordinator on -nextResponder. */
- (id <ETEditionCoordinator>) editionCoordinator
{
	if ([self conformsToProtocol: @protocol(ETEditionCoordinator)])
	{
		return (id)self;
	}
	return [[self nextResponder] editionCoordinator];
}

@end

// TODO: Move into AppKitWidgetBackend
@interface NSResponder (ETResponderTrait) <ETResponder>
@end

@implementation  NSResponder (ETResponderTrait)

- (id <ETFirstResponderSharingArea>) firstResponderSharingArea
{
	return nil;
}

- (id <ETEditionCoordinator>) editionCoordinator
{
	return nil;
}

- (ETLayoutItem *) focusedItem
{
	return nil;
}

@end

// TODO: Move into AppKitWidgetBackend
@interface NSText (ETResponder)
@end

@implementation  NSText

- (ETLayoutItem *) focusedItem
{
	if ([self isFieldEditor])
	{
		ETAssert([self delegate] != nil);
		return [[self delegate] focusedItem];
	}
	return [self focusedItem];
}

@end

