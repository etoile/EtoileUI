/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2010
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import "ETUIItemCellIntegration.h"
#import "ETCompatibility.h"


@implementation NSCell (ETUIItemCellSupportAdditions)

/** Returns an object value representation compatible with the cell.

Nil can be returned. */
- (id) objectValueForObject: (id)anObject
{
	id objectValue = nil;

	if ([self type] ==  NSImageCellType)
	{
		objectValue = ([anObject isKindOfClass: [NSImage class]] ? anObject: nil);
	}
	else
	{
		objectValue = ([anObject isCommonObjectValue] ? anObject : [anObject objectValue]);
	}
	ETAssert(objectValue == nil || [objectValue conformsToProtocol: @protocol(NSCopying)]);
	return objectValue;
}

- (id) objectValueForCurrentValue: (id)aValue
{
	return [self objectValueForObject: aValue];
}

- (id) currentValueForObjectValue: (id)aValue
{
	return  aValue;
}

#ifndef GNUSTEP
/* We override this method to make KVO resilient to some recursion issues on 
Mac OS X (GNUstep KVO handles this transparently in a way similar to what we implement)
Such a recursion occurs when -didChangeValueForKey: is invoked by the getter 
that corresponds to this key.
e.g. on Mac OS X, we have roughly:
8 ...
7 -didChangeValueForKey:
6 -validateEditing
5 -[NSCell stringValue]
4 -valueForKey:
3 -didChangeValueForKey:
2 -validateEditing
1 -[NSCell stringValue]

This workaround implies that the getters/setters such as -objectValue and 
-setObjectValue: have to be reentrant. It seems to be the case on GNUstep and 
probably on Cocoa but there is no way to be sure with the latter.

The KVO workaround below is not thread-safe, but the AppKit is generally not, so 
it shouldn't be a problem with NSControl/NSCell class hierarchy.

KVO is thread-safe, except that willChangeXXX/change/didChangeXXX sequence 
is never atomic in either automatic and manual KVO. 
Two threads can enters the same setter simultaneously, then two willChangeXXX 
messages might immediately follow each other unlike what you expect.
See also http://lists.apple.com/archives/cocoa-dev/2007/May/msg00022.html */

static NSString *willChangeUnderway = nil;

- (void) willChangeValueForKey: (NSString *)aKey
{
	if (nil != willChangeUnderway && [willChangeUnderway isEqualToString: aKey])
		return;

	willChangeUnderway = aKey;

	[super willChangeValueForKey: aKey];

	willChangeUnderway = nil;
}

static NSString *didChangeUnderway = nil;

- (void) didChangeValueForKey: (NSString *)aKey
{
	if (nil != didChangeUnderway && [didChangeUnderway isEqualToString: aKey])
		return;

	didChangeUnderway = aKey;

	[super didChangeValueForKey: aKey];

	didChangeUnderway = nil;
}
#endif

@end


@implementation NSImageCell (ETUIItemCellSupportAdditions)

/** Returns nil when the given object is not an NSImage instance. */
- (id) objectValueForObject: (id)anObject
{
	// NOTE: We override NSCell implementation because NSImageCell type is 
	// NSNullCellType on Mac OS X
	return ([anObject isKindOfClass: [NSImage class]] ? anObject: nil);
}

@end


@implementation NSPopUpButtonCell (ETUIItemCellSupportAdditions)

- (id) objectValueForCurrentValue: (id)aValue
{
	return [NSNumber numberWithInteger: [self indexOfItemWithRepresentedObject: aValue]];
}

- (id) currentValueForObjectValue: (id)aValue
{
	return [[self itemAtIndex: [aValue integerValue]] representedObject];
}

@end
