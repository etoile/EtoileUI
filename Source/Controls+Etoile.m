/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import "Controls+Etoile.h"
#import "NSView+Etoile.h"
#import "NSImage+Etoile.h"
#import "ETCompatibility.h"


@implementation NSControl (Etoile)

/** Returns YES to indicate that the receiver is a widget (or control in AppKit 
terminology) on which actions should be dispatched. */
- (BOOL) isWidget
{
	return YES;
}

/* Copying */

/** Returns a view copy of the receiver. The superview of the resulting copy is
	always nil. The whole subview tree is also copied, in other words the new
	object is a deep copy of the receiver.
    Also updates the copy for NSControl specific properties such target and 
    action. */
- (id) copyWithZone: (NSZone *)zone
{
	NSControl *viewCopy = (NSControl *)[super copyWithZone: zone];

	/* Access and updates target and action properties of the enclosed cell */
	[viewCopy setTarget: [self target]];
	[viewCopy setAction: [self action]];

	return viewCopy;
}

/* Property Value Coding */

- (NSArray *) properties
{
	// NOTE: objectValue property is exposed by NSObject+Model
	// TODO: selectedTag, selectedCell and currentEditor are read only. 
	// Eventually expose cellClass as class property.
	NSArray *properties = [NSArray arrayWithObjects: @"cell", @"enabled", 
		@"selectedTag", @"selectedCell", @"alignement", @"font", @"formatter", 
		@"baseWritingDirection", @"currentEditor", @"target", @"action", 
		@"continuous", @"tag",@"refusesFirstResponder", @"ignoresMultiClick", nil]; 
	
	return [[super properties] arrayByAddingObjectsFromArray: properties];
}
@end

		
@implementation NSTextField (Etoile)

/** Returns 96 for width and 22 for height, the current values used by default 
    in IB on Mac OS X. */
+ (NSRect) defaultFrame
{
	return NSMakeRect(0, 0, 96, 22);
}

- (NSArray *) properties
{
	// TODO: Declare properties.
	NSArray *properties = [NSArray array]; 
	
	return [[super properties] arrayByAddingObjectsFromArray: properties];
}

@end


@implementation NSImageView (Etoile)

/** Returns YES when the receiver is editable, otherwise returns NO. */
- (BOOL) isWidget
{
	return [self isEditable];
}

@end


@interface NSPopUpButton (Etoile)
- (id) copyWithZone: (NSZone *)aZone;
@end

@implementation NSPopUpButton (Etoile)

- (id) copyWithZone: (NSZone *)aZone
{
	NSPopUpButton *popUpCopy = [super copyWithZone: aZone];
	unsigned int nbOfItems = [self numberOfItems];

	for (int i = 0; i < nbOfItems; i++)
	{
		id repObject = [[self itemAtIndex: i] representedObject];
		[[popUpCopy itemAtIndex: i] setRepresentedObject: repObject];
	}

	return popUpCopy;
}

@end

#ifndef GNUSTEP

// NOTE: We might need to make the same changes to NSControl.
@interface NSCell (Etoile)
- (void) willChangeValueForKey: (NSString *)aKey;
- (void) didChangeValueForKey: (NSString *)aKey;
@end

@implementation NSCell (Etoile)

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

@end

#endif
