/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: November 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETHandle.h"
#import "ETCompatibility.h"
#import "ETGeometry.h"
#import "NSView+Etoile.h"

NSString *kETMediatedInstrumentProperty = @"mediatedInstrument";
NSString *kETManipulatedObjectProperty = @"manipulatedObject";

@implementation ETHandle

- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
{
	return nil;
}

- (id) initWithActionHandler: (ETActionHandler *)anHandler 
           manipulatedObject: (id)aTarget
{
	self = [super initWithView: nil value: nil representedObject: nil];
	if (self == nil)
		return nil;

	[self setActionHandler: anHandler];
	[self setStyle: [ETBasicHandleStyle sharedInstance]];
	[self setManipulatedObject: aTarget];
	[self setFlipped: YES];
	//[super setFrame: NSMakeRect(-5, -5, 10, 10)];
	[super setFrame: NSMakeRect(0, 0, 10, 10)];
	[self setAnchorPoint: NSMakePoint(5, 5)];
	return self;
}

- (ETInstrument *) mediatedInstrument
{
	return GET_PROPERTY(kETMediatedInstrumentProperty);
}

- (void) setMediatedInstrument: (ETInstrument *)anInstrument
{
	SET_PROPERTY(anInstrument, kETMediatedInstrumentProperty);
}

/** Returns the object on which the receiver acts upon. */
- (id) manipulatedObject
{
	return GET_PROPERTY(kETManipulatedObjectProperty);
}

/** Sets the object on which the receiver acts upon. */
- (void) setManipulatedObject: (id)anObject
{
	SET_PROPERTY(anObject, kETManipulatedObjectProperty);
}

@end

@implementation ETHandleActionHandler

/** Handles are not selectable. */
- (BOOL) canSelect: (ETHandle *)handle
{
	return NO;
}

@end

@implementation ETBottomLeftHandleActionHandler

- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
	ETHandleGroup *handleGroup = [handle manipulatedObject];
	NSRect manipulatedFrame = [handleGroup frame];
	float deltaHeight = delta.height;
	
	[handleGroup setNeedsDisplay: YES]; /* Invalid existing rect */

	/* We receive delta in the handle group coordinates, however we resize 
	   both handle group and its manipulated object in their parent item 
	   coordinates, which means we can have to convert the delta height to 
	   the parent coordinate space.

	   Root item in the layout and layout context are expected to have 
	   identical -isFlipped value... we could potentially eliminate this 
	   restriction by checking whether the layout context is flipped or not in 
	   -[ETHandleGroup setFrame:]. */
	NSParameterAssert([[handleGroup parentItem] isFlipped] 
		== [[[handleGroup manipulatedObject] parentItem] isFlipped]);
	if ([[handleGroup parentItem] isFlipped] != [handleGroup isFlipped])
		deltaHeight = -deltaHeight;

	manipulatedFrame.origin.x += delta.width;
	manipulatedFrame.size.width -= delta.width;

	if ([[handleGroup parentItem] isFlipped])
	{
		manipulatedFrame.size.height += deltaHeight;
	}
	else
	{
		manipulatedFrame.origin.y += deltaHeight;
		manipulatedFrame.size.height -= deltaHeight;
	}

	/* We let -[ETHandleGroup setFrame:] updates the manipulated object frame */
	[handleGroup setFrame: manipulatedFrame];
	[handleGroup setNeedsDisplay: YES]; /* Invalid new resized rect */
}

@end

/* Explanations in ETBottomLeftHandleActionHandler comments. */
@implementation ETBottomRightHandleActionHandler

- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
	ETHandleGroup *handleGroup = [handle manipulatedObject];
	NSRect manipulatedFrame = [handleGroup frame];
	float deltaHeight = delta.height;

	[handleGroup setNeedsDisplay: YES];

	if ([[handleGroup parentItem] isFlipped] != [handleGroup isFlipped])
		deltaHeight = -deltaHeight;

	manipulatedFrame.size.width += delta.width;

	if ([[handleGroup parentItem] isFlipped])
	{
		manipulatedFrame.size.height += deltaHeight;
	}
	else
	{
		manipulatedFrame.origin.y += deltaHeight;
		manipulatedFrame.size.height -= deltaHeight;
	}

	[handleGroup setFrame: manipulatedFrame];
	[handleGroup setNeedsDisplay: YES];
}

@end

/* Explanations in ETBottomLeftHandleActionHandler comments. */
@implementation ETTopLeftHandleActionHandler

- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
	ETHandleGroup *handleGroup = [handle manipulatedObject];
	NSRect manipulatedFrame = [handleGroup frame];
	float deltaHeight = delta.height;
	
	[handleGroup setNeedsDisplay: YES];

	if ([[handleGroup parentItem] isFlipped] != [handleGroup isFlipped])
		deltaHeight = -deltaHeight;

	manipulatedFrame.origin.x += delta.width;
	manipulatedFrame.size.width -= delta.width;

	if ([[handleGroup parentItem] isFlipped])
	{
		manipulatedFrame.origin.y += deltaHeight;
		manipulatedFrame.size.height -= deltaHeight;
	}
	else
	{
		manipulatedFrame.size.height += deltaHeight;	
	}

	[handleGroup setFrame: manipulatedFrame];
	[handleGroup setNeedsDisplay: YES];
}

@end

/* Explanations in ETBottomLeftHandleActionHandler comments. */
@implementation ETTopRightHandleActionHandler

- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
	ETHandleGroup *handleGroup = [handle manipulatedObject];
	NSRect manipulatedFrame = [handleGroup frame];
	float deltaHeight = delta.height;

	[handleGroup setNeedsDisplay: YES];

	if ([[handleGroup parentItem] isFlipped] != [handleGroup isFlipped])
		deltaHeight = -deltaHeight;

	manipulatedFrame.size.width += delta.width;

	if ([[handleGroup parentItem] isFlipped])
	{
		manipulatedFrame.origin.y += deltaHeight;
		manipulatedFrame.size.height -= deltaHeight;
	}
	else
	{
		manipulatedFrame.size.height += deltaHeight;	
	}

	[handleGroup setFrame: manipulatedFrame];
	[handleGroup setNeedsDisplay: YES];
}

@end

@implementation ETBasicHandleStyle

static ETBasicHandleStyle *sharedBasicHandleStyle = nil;

+ (id) sharedInstance
{
	if (sharedBasicHandleStyle == nil)
		sharedBasicHandleStyle = [[ETBasicHandleStyle alloc] init];
		
	return sharedBasicHandleStyle;
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
{
	// FIXME: May be we should better support dirtyRect. The next drawing 
	// methods don't take in account it and simply redraw all their content.
	
	[self drawHandleInRect: [item drawingFrame]];

	if ([item isSelected])
		[self drawSelectionIndicatorInRect: [item drawingFrame]];
	
	[super render: inputValues layoutItem: item dirtyRect: dirtyRect];
}

/** Draws the interior of the handle. */
- (void) drawHandleInRect: (NSRect)rect
{
	[[[NSColor purpleColor] colorWithAlphaComponent: 0.80] set];
	NSRectFillUsingOperation(rect, NSCompositeSourceOver);
}

- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect
{
	//ETLog(@"--- Drawing selection %@ in view %@", NSStringFromRect([item drawingFrame]), [NSView focusView]);
	
	// TODO: We disable the antialiasing for the stroked rect with direct 
	// drawing, but this code may be better moved in 
	// -[ETLayoutItem render:dirtyRect:inContext:] to limit the performance impact.
	BOOL gstateAntialias = [[NSGraphicsContext currentContext] shouldAntialias];
	[[NSGraphicsContext currentContext] setShouldAntialias: NO];
	
	/* Align on pixel boundaries for fractional pixel margin and frame. 
	   Fractional item frame results from the item scaling. 
	   NOTE: May be we should adjust pixel boundaries per edge and only if 
	   needed to get a perfect drawing... */
	NSRect normalizedIndicatorRect = NSInsetRect(NSIntegralRect(indicatorRect), 0.5, 0.5);

	/* Draw the outline
	   FIXME: Cannot get the outline precisely aligned on pixel boundaries for 
	   GNUstep. With the current code which works well on Cocoa, the top border 
	   of the outline isn't drawn most of the time and the image drawn 
	   underneath seems to wrongly extend beyond the border. */
#ifdef USE_BEZIER_PATH
	// FIXME: NSFrameRectWithWidthUsingOperation() seems to be broken. It 
	// doesn't work even with no alpha in the color, NSCompositeCopy and a width 
	// of 1.0
	[[[NSColor darkGrayColor] colorWithAlphaComponent: 0.55] set];
	NSFrameRectWithWidthUsingOperation(normalizedIndicatorRect, 0.0, NSCompositeSourceOver);
#else
	// FIXME: -setStroke doesn't work on GNUstep
	[[[NSColor darkGrayColor] colorWithAlphaComponent: 0.55] set];
	[NSBezierPath strokeRect: normalizedIndicatorRect];
#endif

	[[NSGraphicsContext currentContext] setShouldAntialias: gstateAntialias];
}

@end


@interface ETHandleGroup (Private)
- (void) updateHandleLocations;
@end

@implementation ETHandleGroup

- (id) initWithItems: (NSArray *)layoutItems view: (NSView *)view value: (id)value representedObject: (id)repObject
{
	return nil;
}

#define HANDLE(x) \
	AUTORELEASE([[ETHandle alloc] initWithActionHandler: [x sharedInstance] \
	                                  manipulatedObject: self])

- (id) initWithActionHandler: (ETActionHandler *)anHandler 
           manipulatedObject: (id)aTarget
{
	NSArray *handles = A(HANDLE(ETTopLeftHandleActionHandler), 
                         HANDLE(ETTopRightHandleActionHandler),
                         HANDLE(ETBottomRightHandleActionHandler),
                         HANDLE(ETBottomLeftHandleActionHandler));
	//NSArray *handles = A(HANDLE(ETTopLeftHandleActionHandler));

	// NOTE: -setManipulatedObject: will set aTarget as a representedObject
	self = [super initWithItems: handles view: nil value: nil representedObject: nil];
	if (self == nil)
		return nil;

	// NOTE: Must be called before -setManipulatedObject: that sets the handle
	// locations.
	[self setFlipped: YES];
	[self setStyle: nil]; /* Suppress the default ETLayoutItem style */
	[self setActionHandler: anHandler];
	[self setManipulatedObject: aTarget];

	return self;
}

// TODO: Would be nice to share the method implementations with ETHandle.

#if 0
// NOTE: The next two methods don't seem to be useful in ETHandleGroup but only 
// in ETHandle
- (ETInstrument *) mediatedInstrument
{
	return GET_PROPERTY(kETMediatedInstrumentProperty);
}

- (void) setMediatedInstrument: (ETInstrument *)anInstrument
{
	SET_PROPERTY(anInstrument, kETMediatedInstrumentProperty);
}
#endif

- (id) manipulatedObject
{
	return GET_PROPERTY(kETManipulatedObjectProperty);
}

- (void) setManipulatedObject: (id)anObject
{
	SET_PROPERTY(anObject, kETManipulatedObjectProperty);
	/* Better to avoid -setFrame: which would update the represented object frame. */
	// FIXME: Ugly duplication with -setFrame:... 
	//[self setFrame: [anObject frame]];
	[self setRepresentedObject: anObject];
	[self updateHandleLocations];
}

- (NSPoint) anchorPoint
{
	return [GET_PROPERTY(kETManipulatedObjectProperty) anchorPoint];
}

- (void) setAnchorPoint: (NSPoint)anchor
{
	return [GET_PROPERTY(kETManipulatedObjectProperty) setAnchorPoint: anchor];
}

- (NSPoint) position
{
	return [(ETLayoutItem *)GET_PROPERTY(kETManipulatedObjectProperty) position];
}

- (void) setPosition: (NSPoint)aPosition
{
	[GET_PROPERTY(kETManipulatedObjectProperty) setPosition: aPosition];
	[self updateHandleLocations];
}

/** Returns the content bounds associated with the receiver. */
- (NSRect) contentBounds
{
	NSRect manipulatedFrame = [GET_PROPERTY(kETManipulatedObjectProperty) frame];
	return ETMakeRect(NSZeroPoint, manipulatedFrame.size);
}

- (void) setContentBounds: (NSRect)rect
{
	NSRect manipulatedFrame = ETMakeRect([GET_PROPERTY(kETManipulatedObjectProperty) origin], rect.size);
	[GET_PROPERTY(kETManipulatedObjectProperty) setFrame: manipulatedFrame];
	[self updateHandleLocations];
}

- (NSRect) frame
{
	return [GET_PROPERTY(kETManipulatedObjectProperty) frame];
}

// NOTE: We need to figure out what we really needs. For example,
// -setBoundingBox: could be called when a handle group is inserted, or the 
// layout and/or the style could have a hook -boundingBoxForItem:. We 
// probably want to cache the bounding box value in an ivar too.
- (void) setFrame: (NSRect)frame
{
	[GET_PROPERTY(kETManipulatedObjectProperty) setFrame: frame];
	[self updateHandleLocations];
}

- (void) setBoundingBox: (NSRect)extent
{
	[super setBoundingBox: extent];
	[GET_PROPERTY(kETManipulatedObjectProperty) setBoundingBox: extent];
}

/** Marks both the receiver and its manipulated object as invalidated area 
or not. */
- (void) setNeedsDisplay: (BOOL)flag
{
	[super setNeedsDisplay: flag];
	[[self manipulatedObject] setNeedsDisplay: flag];
}

- (void) updateHandleLocations
{ 
	[self setBoundingBox: NSInsetRect([self contentBounds], -10.0, -10.0)];
	//NSRect localBoundingBox = ETUnionRectWithObjectsAndSelector([self items], @selector(frame));
	
	//[self setBoundingBox: [self convertRectToParent: localBoundingBox]];
}

@end


@implementation ETResizeRectangle

- (id) initWithManipulatedObject: (id)aTarget
{
	return [super initWithActionHandler: nil manipulatedObject: aTarget];
}

- (void) updateHandleLocations
{
	NSRect frame = [self frame];
	
	if ([self isFlipped])
	{
		[[self topLeftHandle] setPosition: NSZeroPoint];
		[[self topRightHandle] setPosition: NSMakePoint(frame.size.width, 0)];
		[[self bottomRightHandle] setPosition: NSMakePoint(frame.size.width, frame.size.height)];
		[[self bottomLeftHandle] setPosition: NSMakePoint(0, frame.size.height)];
	}
	else
	{
		[[self topLeftHandle] setPosition: NSMakePoint(0, frame.size.height)];
		[[self topRightHandle] setPosition: NSMakePoint(frame.size.width, frame.size.height)];
		[[self bottomRightHandle] setPosition: NSMakePoint(frame.size.width, 0)];
		[[self bottomLeftHandle] setPosition: NSZeroPoint];
	}

	[super updateHandleLocations];
}

/** Returns the handle item located in the top left corner. */
- (ETHandle *) topLeftHandle
{
	return (ETHandle *)[self itemAtIndex: 0];
}

/** Returns the handle item located in the top right corner. */
- (ETHandle *) topRightHandle
{
	return (ETHandle *)[self itemAtIndex: 1];
}

/** Returns the handle item located in the bottom right corner. */
- (ETHandle *) bottomRightHandle
{
	return (ETHandle *)[self itemAtIndex: 2];
}

/** Returns the handle item located in the bottom left corner. */
- (ETHandle *) bottomLeftHandle
{
	return (ETHandle *)[self itemAtIndex: 3];
}

/** Draws the receiver style. See ETStyle. */
- (void) render: (NSMutableDictionary *)inputValues 
	  dirtyRect: (NSRect)dirtyRect
      inContext: (id)ctxt
{
	[self drawOutlineInRect: [self drawingFrame]];
	/* Now draw the handles that are our children */
	[super render: inputValues dirtyRect: dirtyRect inContext: ctxt];
}

/** Draws a rectangular outline. */
- (void) drawOutlineInRect: (NSRect)rect
{
	[[[NSColor blackColor] colorWithAlphaComponent: 0.90] set];
	[NSBezierPath setDefaultLineWidth: 0.0];
	[NSBezierPath strokeRect: rect];
}

@end
