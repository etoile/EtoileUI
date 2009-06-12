/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD  (see COPYING)
 */

#import "ETSelectionAreaItem.h"
#import "ETGeometry.h"
#import "ETShape.h"
#import "ETCompatibility.h"

@implementation ETSelectionAreaItem

/** <init />
Intializes and returns a selection area item based on a rectangle shape with a 
dark gray outline, a light gray interior and an overall alpha value of 0.5. */
- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
{
	self = [super initWithView: view value: value representedObject: repObject];
	if (self == nil)
		return nil;
	
	ETShape *shape = [ETShape rectangleShapeWithRect: NSMakeRect(0, 0, 100, 50)];

	[shape setStrokeColor: [NSColor darkGrayColor]];
	[shape setFillColor: [NSColor lightGrayColor]];
	[shape setAlphaValue: 0.5];
	[self setRepresentedObject: shape];
	[self setStyle: shape];

    return self;
}

- (void) setFrame: (NSRect)rect
{
	[super setFrame: rect];
	NSRect bounds = ETMakeRect(NSZeroPoint, rect.size);
	[[self representedObject] setBounds: bounds];
	 // FIXME: We create an outset rect to take in account the shape outline 
	 // thickness and ensure the redisplay won't ignore the shape border part  
	 // that lies outside of the frame.
	 // This should be handled in ETShape and in a better way.
	[self setBoundingBox: NSInsetRect(bounds, -5, -5)];

	// TODO: We should also resize in a way that truly supports any shape. May 
	// be something like... 
	//[[self representedObject] setPath: [NSBezierPath bezierPathWithRect: rect]];
}

@end
