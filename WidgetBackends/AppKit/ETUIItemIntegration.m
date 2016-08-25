/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import "ETUIItemIntegration.h"
#import "ETUIItemCellIntegration.h"
#import "ETView.h"
#import "NSImage+Etoile.h"
#import "NSView+EtoileUI.h"
#import "ETCompatibility.h"


@implementation  NSView (ETUIItemSupportAdditions)

+ (NSRect) defaultFrame
{
	return NSMakeRect(0, 0, 100, 50);
}

- (instancetype) init
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


@implementation NSControl (ETUIItemSupportAdditions)

/** Returns YES to indicate that the receiver is a widget (or control in AppKit 
terminology) on which actions should be dispatched. */
- (BOOL) isWidget
{
	return YES;
}

/** Returns a view copy of the receiver. The superview of the resulting copy is
always nil. The whole subview tree is also copied, in other words the new object 
is a deep copy of the receiver.

Also updates the copy for NSControl specific properties such target and  action. */
- (id) copyWithZone: (NSZone *)zone
{
	NSControl *viewCopy = (NSControl *)[super copyWithZone: zone];

	/* Access and updates target and action properties of the enclosed cell */
	[viewCopy setTarget: [self target]];
	[viewCopy setAction: [self action]];

	return viewCopy;
}

- (id) objectValueForCurrentValue: (id)aValue
{
		if ([self cell] == nil)
			return aValue;
		
		return [[self cell] objectValueForCurrentValue: aValue];
}

- (id) currentValueForObjectValue: (id)aValue
{
	if ([self cell] == nil)
		return aValue;

	return [[self cell] currentValueForObjectValue: aValue];
}

@end


@implementation NSPopUpButton (ETUIItemSupportAdditions)

- (id) copyWithZone: (NSZone *)aZone
{
	unsigned int nbOfItems = [self numberOfItems];
	NSArray *repObjects = [[[self itemArray] mappedCollection] representedObject];

	/* Since -[NSPopUpButton setMenu: nil] doesn't work, we remove all represented 
	   objects to prevent their encoding in -[NSView(Etoile) copyWithZone:] */
	[[[self itemArray] mappedCollection] setRepresentedObject: nil];

	NSPopUpButton *popUpCopy = [super copyWithZone: aZone];

	for (int i = 0; i < nbOfItems; i++)
	{
		id repObject = [repObjects objectAtIndex: i];

		if ([repObject isEqual: [NSNull null]])
			continue;

		[[self itemAtIndex: i] setRepresentedObject: repObject];
		[[popUpCopy itemAtIndex: i] setRepresentedObject: repObject];
	}

	return popUpCopy;
}

@end


@implementation NSTextField (ETUIItemSupportAdditions)

/** Returns 96 for width and 22 for height, the current values used by default 
    in IB on Mac OS X. */
+ (NSRect) defaultFrame
{
	return NSMakeRect(0, 0, 96, 22);
}

@end


@implementation NSImageView (ETUIItemSupportAdditions)

/** Returns YES when the receiver is editable, otherwise returns NO. */
- (BOOL) isWidget
{
	return [self isEditable];
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
