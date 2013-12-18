/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETPaintBucketTool.h"
#import "ETPaintActionHandler.h"
#import "ETApplication.h"
#import "ETLayoutItem.h"
#import "ETCompatibility.h"


@implementation ETPaintBucketTool

/** Initializes and returns a new paint bucket tool which is set up with orange 
as stroke color and brown as fill color. */
- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	ASSIGN(_strokeColor, [NSColor orangeColor]);
	ASSIGN(_fillColor, [NSColor brownColor]);
	return self;
}

- (void) dealloc
{
    DESTROY(_fillColor);
    DESTROY(_strokeColor);
    [super dealloc];
}

- (id) copyWithCopier: (ETCopier *)aCopier
{
	ETPaintBucketTool *newTool = [super copyWithCopier: aCopier];

	if ([aCopier isAliasedCopy])
		return newTool;

	[aCopier beginCopyFromObject: self toObject: newTool];

	newTool->_fillColor = [_fillColor copyWithZone: [aCopier zone]];
	newTool->_strokeColor = [_strokeColor copyWithZone: [aCopier zone]];
	newTool->_paintMode = _paintMode;

	[aCopier endCopy];
	return newTool;
}

/** Returns the fill color associated with the receiver. */
- (NSColor *) fillColor
{
    return AUTORELEASE([_fillColor copy]); 
}

/** Sets the fill color associated with the receiver. */
- (void) setFillColor: (NSColor *)color
{
	[self willChangeValueForProperty: @"fillColor"];
	ASSIGNCOPY(_fillColor, color);
	[self didChangeValueForProperty: @"fillColor"];
}

/** Returns the stroke color associated with the receiver. */
- (NSColor *) strokeColor
{
    return AUTORELEASE([_strokeColor copy]); 
}

/** Sets the stroke color associated with the receiver. */
- (void) setStrokeColor: (NSColor *)color
{
	[self willChangeValueForProperty: @"strokeColor"];
	ASSIGNCOPY(_strokeColor, color);
	[self didChangeValueForProperty: @"strokeColor"];
}

/** Returns the paint action produced by the receiver, either stroke or fill. */
- (ETPaintMode) paintMode
{
	return _paintMode;
}

/** Sets the paint action produced by the receiver, either stroke or fill. */
- (void) setPaintMode: (ETPaintMode)aMode
{
	[self willChangeValueForProperty: @"paintMode"];
	_paintMode = aMode;
	[self didChangeValueForProperty: @"paintMode"];
}

/* Outside of the boundaries doesn't count because the parent tool will 
be reactivated when we exit our owner layout. */
- (void) mouseUp: (ETEvent *)anEvent
{	
	ETLayoutItem *item = [self hitTestWithEvent: anEvent];
	ETActionHandler *actionHandler = [item actionHandler];

	ETDebugLog(@"Mouse up with %@ on item %@", self, item);

	if ([self paintMode] == ETPaintModeFill && [actionHandler canFillItem: item])
	{
		[actionHandler handleFillItem: item withColor: [self fillColor]];
	}
	else if ([self paintMode] == ETPaintModeStroke && [actionHandler canStrokeItem: item])
	{
		[actionHandler handleStrokeItem: item withColor: [self strokeColor]];
	}
}

- (NSMenu *) menuRepresentation
{
	NSMenu *menu = AUTORELEASE([[NSMenu alloc] initWithTitle: _(@"Bucket Tool Options")]);
	NSMenu *modeSubmenu = AUTORELEASE([[NSMenu alloc] initWithTitle: _(@"Bucket Tool Paint Mode")]);

	[menu addItemWithSubmenu: modeSubmenu];

	[modeSubmenu addItemWithTitle: _(@"Fill")
                     state: ([self paintMode] == ETPaintModeFill)
	                target: self
	                action: @selector(changePaintMode:)
	         keyEquivalent: @""];

	[modeSubmenu addItemWithTitle: _(@"Stroke")
	                 state: ([self paintMode] == ETPaintModeStroke)
	                target: self
	                action: @selector(changePaintMode:)
	         keyEquivalent: @""];

	[menu addItemWithTitle:  _(@"Choose Colors…")
	                target: self
	                action: @selector(chooseColors:)
	         keyEquivalent: @""];

	return menu;
}

- (void) changePaintMode: (id)sender
{
	 // TODO: Implement
}

- (void) changeColor: (id)sender
{
	NSColor *newColor = nil; // TODO: Finish to implement

	if ([self paintMode] == ETPaintModeFill)
	{
		[self setFillColor: newColor];
	}
	else if ([self paintMode] == ETPaintModeStroke)
	{
		[self setStrokeColor: newColor];
	}
}

@end
