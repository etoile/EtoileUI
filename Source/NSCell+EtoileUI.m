/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2010
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import "NSCell+EtoileUI.h"
#import "ETCompatibility.h"


@implementation NSCell (EtoileUI)

/** Returns an object value representation compatible with the cell.

Nil can be returned. */
- (id) objectValueForObject: (id)anObject
{
	if ([self type] ==  NSImageCellType)
	{
		return ([anObject isKindOfClass: [NSImage class]] ? anObject: nil);
	}
	else
	{
		return ([anObject isCommonObjectValue] ? anObject : [anObject objectValue]);
	}
}

@end


@implementation NSImageCell (EtoileUI)

/** Returns nil when the given object is not an NSImage instance. */
- (id) objectValueForObject: (id)anObject
{
	// NOTE: We override NSCell implementation because NSImageCell type is 
	// NSNullCellType on Mac OS X
	return ([anObject isKindOfClass: [NSImage class]] ? anObject: nil);
}

@end
