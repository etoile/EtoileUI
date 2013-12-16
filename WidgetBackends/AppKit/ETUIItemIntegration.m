/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETUIItemIntegration.h"
#import "ETView.h"
#import "NSView+Etoile.h"


@implementation  NSView (ETUIItemSupportAdditions)

+ (NSRect) defaultFrame
{
	return NSMakeRect(0, 0, 100, 50);
}

- (id) init
{
	return [self initWithFrame: [[self class] defaultFrame]];
}

/** Returns whether the receiver is a widget (or control in AppKit terminology) 
on which actions should be dispatched.

If you override this method to return YES, your subclass must implement the 
methods listed in the ETWidget protocol.

By default, returns NO. */
- (BOOL) isWidget
{
	return NO;
}

/** Returns YES when the receiver is an ETView class or subclass instance, 
otherwise returns NO. */
- (BOOL) isSupervisorView
{
	return [self isKindOfClass: [ETView class]];
}

/** Returns the item bound to the first supervisor view found in the view 
ancestor hierarchy.

The returned object is an ETUIItem or subclass instance. */
- (id) owningItem
{
	return [[self superview] owningItem];
}

@end


@implementation NSScrollView (ETUIItemSupportAdditions)

/** Returns YES to indicate that the receiver is a widget on which actions 
should be dispatched. */
- (BOOL) isWidget
{
	return YES;
}

// FIXME: Quick hack to let us use a text view as an item view. 
// See -setView:autoresizingMask:
- (id) cell
{
	return nil;
}

@end
