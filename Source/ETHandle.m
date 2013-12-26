/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: November 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <CoreObject/COObjectGraphContext.h>
#import "ETHandle.h"
#import "EtoileUIProperties.h"
#import "ETCompatibility.h"
#import "ETGeometry.h"

NSString *kETMediatedToolProperty = @"mediatedTool";
NSString *kETManipulatedObjectProperty = @"manipulatedObject";

@implementation ETHandle

- (id) initWithView: (NSView *)view 
         coverStyle: (ETStyle *)aStyle 
      actionHandler: (ETActionHandler *)aHandler
 objectGraphContext:(COObjectGraphContext *)aContext
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}

- (id) initWithActionHandler: (ETActionHandler *)aHandler 
           manipulatedObject: (id)aTarget
          objectGraphContext: (COObjectGraphContext *)aContext
{
	/* Pass a nil cover style to suppress the default item style */
	self = [super initWithView: nil coverStyle: nil actionHandler: aHandler objectGraphContext: aContext];
	if (self == nil)
		return nil;

	[self setStyle: [ETBasicHandleStyle sharedInstanceForObjectGraphContext: aContext]];
	[self setManipulatedObject: aTarget];
	[self setFlipped: YES];
	//[super setFrame: NSMakeRect(-5, -5, 10, 10)];
	[super setFrame: NSMakeRect(0, 0, 10, 10)];
	[self setAnchorPoint: NSMakePoint(5, 5)];
	return self;
}

- (ETTool *) mediatedTool
{
	return [self valueForVariableStorageKey: kETMediatedToolProperty];
}

- (void) setMediatedTool: (ETTool *)anTool
{
	[self setValue: anTool forVariableStorageKey: kETMediatedToolProperty];
}

/** Returns the object on which the receiver acts upon. */
- (id) manipulatedObject
{
	return [self valueForVariableStorageKey: kETManipulatedObjectProperty];
}

/** Sets the object on which the receiver acts upon. */
- (void) setManipulatedObject: (id)anObject
{
	[self setValue: anObject forVariableStorageKey: kETManipulatedObjectProperty];
}

@end

@implementation ETHandleActionHandler

/** Handles are not selectable. */
- (BOOL) canSelect: (ETHandle *)handle
{
	return NO;
}

- (void) endTranslateItem: (ETHandle *)handle
{
	ETHandleGroup *handleGroup = [handle manipulatedObject];
	[[handleGroup manipulatedObject] commitWithIdentifier: kETCommitItemResize];
}

@end

@implementation ETBottomLeftHandleActionHandler

- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
	ETHandleGroup *handleGroup = [handle manipulatedObject];
	NSRect manipulatedFrame = [handleGroup frame];
	CGFloat deltaHeight = delta.height;
	
	[handleGroup setNeedsDisplay: YES]; /* Invalid existing rect */

	/* We receive delta in the handle group coordinates, however we resize 
	   both handle group and its manipulated object in their parent item 
	   coordinates, which means we can have to convert the delta height to 
	   the parent coordinate space.

	   Layer item in the layout and layout context are expected to have 
	   identical -isFlipped value... we could potentially eliminate this 
	   restriction by checking whether the layout context is flipped or not in 
	   -[ETHandleGroup setFrame:]. */
	NSParameterAssert([[handleGroup parentItem] isFlipped] 
		== [[(ETLayoutItem *)[handleGroup manipulatedObject] parentItem] isFlipped]);
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
	CGFloat deltaHeight = delta.height;

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
	CGFloat deltaHeight = delta.height;
	
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
	CGFloat deltaHeight = delta.height;

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

/* Explanations in ETBottomLeftHandleActionHandler comments. */
@implementation ETLeftHandleActionHandler

- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
	ETHandleGroup *handleGroup = [handle manipulatedObject];
	NSRect manipulatedFrame = [handleGroup frame];
	
	[handleGroup setNeedsDisplay: YES];
		
	manipulatedFrame.origin.x += delta.width;
	manipulatedFrame.size.width -= delta.width;
	
	[handleGroup setFrame: manipulatedFrame];
	[handleGroup setNeedsDisplay: YES];
}

@end

/* Explanations in ETBottomLeftHandleActionHandler comments. */
@implementation ETRightHandleActionHandler

- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
	ETHandleGroup *handleGroup = [handle manipulatedObject];
	NSRect manipulatedFrame = [handleGroup frame];
	
	[handleGroup setNeedsDisplay: YES];
	
	manipulatedFrame.size.width += delta.width;
		
	[handleGroup setFrame: manipulatedFrame];
	[handleGroup setNeedsDisplay: YES];
}

@end

/* Explanations in ETBottomLeftHandleActionHandler comments. */
@implementation ETTopHandleActionHandler

- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
	ETHandleGroup *handleGroup = [handle manipulatedObject];
	NSRect manipulatedFrame = [handleGroup frame];
	CGFloat deltaHeight = delta.height;
	
	[handleGroup setNeedsDisplay: YES];
	
	if ([[handleGroup parentItem] isFlipped] != [handleGroup isFlipped])
		deltaHeight = -deltaHeight;
	
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
@implementation ETBottomHandleActionHandler

- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
	ETHandleGroup *handleGroup = [handle manipulatedObject];
	NSRect manipulatedFrame = [handleGroup frame];
	CGFloat deltaHeight = delta.height;
	
	[handleGroup setNeedsDisplay: YES];
	
	if ([[handleGroup parentItem] isFlipped] != [handleGroup isFlipped])
		deltaHeight = -deltaHeight;
	
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


@implementation ETBasicHandleStyle

- (NSImage *) icon
{
	return [NSImage imageNamed: @"layer-select-point"];
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item
      dirtyRect: (NSRect)dirtyRect
{
	NSRect bounds = [item drawingBoundsForStyle: self];

	[self drawHandleInRect: bounds];

	if ([item isSelected])
	{
		[self drawSelectionIndicatorInRect: bounds];
	}
}

/** Draws the interior of the handle. */
- (void) drawHandleInRect: (NSRect)rect
{
	[[[NSColor purpleColor] colorWithAlphaComponent: 0.80] set];
	NSRectFillUsingOperation(NSInsetRect(rect, 2, 2), NSCompositeSourceOver);
	[[[NSColor blackColor] colorWithAlphaComponent: 0.80] set];
	NSFrameRectWithWidth(NSInsetRect(rect, 2, 2), 0.5);	
}

- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect
{
	//ETLog(@"--- Drawing selection %@ in view %@", NSStringFromRect([item drawingBoundsForStyle: self]), [NSView focusView]);
	
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
	
	[[[NSColor darkGrayColor] colorWithAlphaComponent: 0.55] set];
#ifdef USE_BEZIER_PATH
	// FIXME: NSFrameRectWithWidthUsingOperation() seems to be broken. It 
	// doesn't work even with no alpha in the color, NSCompositeCopy and a width 
	// of 1.0
	NSFrameRectWithWidthUsingOperation(normalizedIndicatorRect, 0.0, NSCompositeSourceOver);
#else

	NSBezierPath *indicatorPath = [NSBezierPath bezierPathWithRect: normalizedIndicatorRect];
	[indicatorPath setLineWidth: 1.0];
	[indicatorPath stroke];
#endif

	[[NSGraphicsContext currentContext] setShouldAntialias: gstateAntialias];
}

@end


@interface ETHandleGroup (Private)
- (void) updateHandleLocations;
@end

@implementation ETHandleGroup

- (id) initWithView: (NSView *)view 
         coverStyle: (ETStyle *)aStyle 
      actionHandler: (ETActionHandler *)aHandler
 objectGraphContext:(COObjectGraphContext *)aContext
{
	return nil;
}

#define HANDLE(x) \
	AUTORELEASE([[ETHandle alloc] initWithActionHandler: [x sharedInstanceForObjectGraphContext: aContext] \
	                                  manipulatedObject: self \
                                     objectGraphContext: aContext])

- (id) initWithActionHandler: (ETActionHandler *)aHandler 
           manipulatedObject: (id)aTarget
          objectGraphContext: (COObjectGraphContext *)aContext
{
	NSArray *handles = A(HANDLE(ETTopLeftHandleActionHandler), 
                         HANDLE(ETTopRightHandleActionHandler),
                         HANDLE(ETBottomRightHandleActionHandler),
                         HANDLE(ETBottomLeftHandleActionHandler),
						 HANDLE(ETLeftHandleActionHandler), 
                         HANDLE(ETRightHandleActionHandler),
                         HANDLE(ETTopHandleActionHandler),
                         HANDLE(ETBottomHandleActionHandler));

	/* Pass a nil cover style to suppress the default item style */
	self = [super initWithView: nil coverStyle: nil actionHandler: aHandler objectGraphContext: aContext];
	if (self == nil)
		return nil;

	[self addItems: handles];
	// NOTE: Must be called before -setManipulatedObject: that sets the handle
	// locations.
	[self setFlipped: YES];
	// NOTE: -setManipulatedObject: will set aTarget as a representedObject
	[self setManipulatedObject: aTarget];

	return self;
}

// TODO: Would be nice to share the method implementations with ETHandle.

#if 0
// NOTE: The next two methods don't seem to be useful in ETHandleGroup but only 
// in ETHandle
- (ETTool *) mediatedTool
{
	return [self valueForVariableStorageKey: kETMediatedToolProperty];
}

- (void) setMediatedTool: (ETTool *)anTool
{
	[self setValue: anTool forVariableStorageKey: kETMediatedToolProperty];
}
#endif

- (id) manipulatedObject
{
	return [self valueForVariableStorageKey: kETManipulatedObjectProperty];
}

- (void) setManipulatedObject: (id)anObject
{
	[self setValue: anObject forVariableStorageKey: kETManipulatedObjectProperty];
	/* Better to avoid -setFrame: which would update the represented object frame. */
	// FIXME: Ugly duplication with -setFrame:... 
	//[self setFrame: [anObject frame]];
	[self setRepresentedObject: anObject];
	[self updateHandleLocations];
}

- (NSPoint) anchorPoint
{
	id manipulatedObject = [self valueForVariableStorageKey: kETManipulatedObjectProperty];

	if (manipulatedObject == nil)
		return NSZeroPoint;

	return [(ETLayoutItem *)manipulatedObject anchorPoint];
}

- (void) setAnchorPoint: (NSPoint)anchor
{
	return [(ETLayoutItem *)[self valueForVariableStorageKey: kETManipulatedObjectProperty] setAnchorPoint: anchor];
}

- (NSPoint) position
{
	id manipulatedObject = [self valueForVariableStorageKey: kETManipulatedObjectProperty];

	if (manipulatedObject == nil)
		return NSZeroPoint;

	return [(ETLayoutItem *)manipulatedObject position];
}

- (void) setPosition: (NSPoint)aPosition
{
	[(ETLayoutItem *)[self valueForVariableStorageKey: kETManipulatedObjectProperty] setPosition: aPosition];
	[self updateHandleLocations];
}

/** Returns the content bounds associated with the receiver. */
- (NSRect) contentBounds
{
	id manipulatedObject = [self valueForVariableStorageKey: kETManipulatedObjectProperty];

	if (manipulatedObject == nil)
		return NSZeroRect;
 
	NSRect manipulatedFrame = [(ETLayoutItem *)manipulatedObject frame];
	ETAssert(manipulatedFrame.size.width >= 0 && manipulatedFrame.size.height >= 0);
	return ETMakeRect(NSZeroPoint, manipulatedFrame.size);
}

- (void) setContentBounds: (NSRect)rect
{
	NSParameterAssert(rect.size.width >= 0 && rect.size.height >= 0);
	NSRect manipulatedFrame = ETMakeRect([[self valueForVariableStorageKey: kETManipulatedObjectProperty] origin], rect.size);
	[[self valueForVariableStorageKey: kETManipulatedObjectProperty] setFrame: manipulatedFrame];
	[self updateHandleLocations];
}

- (NSRect) frame
{
	id manipulatedObject = [self valueForVariableStorageKey: kETManipulatedObjectProperty];

	if (manipulatedObject == nil)
		return NSZeroRect;
 
	NSRect frame = [(ETLayoutItem *)manipulatedObject frame];
	ETAssert(frame.size.width >= 0 && frame.size.height >= 0);
	return frame;
}

// NOTE: We need to figure out what we really needs. For example,
// -setBoundingBox: could be called when a handle group is inserted, or the 
// layout and/or the style could have a hook -boundingBoxForItem:. We 
// probably want to cache the bounding box value in an ivar too.
- (void) setFrame: (NSRect)frame
{
	NSParameterAssert(frame.size.width >= 0 && frame.size.height >= 0);
	[[self valueForVariableStorageKey: kETManipulatedObjectProperty] setFrame: frame];
	[self updateHandleLocations];
}

- (void) setBoundingBox: (NSRect)extent
{
	[super setBoundingBox: extent];
	[[self valueForVariableStorageKey: kETManipulatedObjectProperty] setBoundingBox: extent];
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

/** Returns YES. */
- (BOOL) acceptsActionsForItemsOutsideOfFrame
{
	return YES;
}

- (NSRect) contentDrawingBox
{
	return [self boundingBox];
}

@end


@implementation ETResizeRectangle

- (id) initWithManipulatedObject: (id)aTarget objectGraphContext: (COObjectGraphContext *)aContext
{
	return [super initWithActionHandler: nil manipulatedObject: aTarget objectGraphContext: aContext];
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
		[[self leftHandle] setPosition: NSMakePoint(0, frame.size.height / 2)];
		[[self rightHandle] setPosition: NSMakePoint(frame.size.width, frame.size.height / 2)];
		[[self topHandle] setPosition: NSMakePoint(frame.size.width / 2, 0)];
		[[self bottomHandle] setPosition: NSMakePoint(frame.size.width / 2, frame.size.height)];
	}
	else
	{
		[[self topLeftHandle] setPosition: NSMakePoint(0, frame.size.height)];
		[[self topRightHandle] setPosition: NSMakePoint(frame.size.width, frame.size.height)];
		[[self bottomRightHandle] setPosition: NSMakePoint(frame.size.width, 0)];
		[[self bottomLeftHandle] setPosition: NSZeroPoint];
		[[self leftHandle] setPosition: NSMakePoint(0, frame.size.height / 2)];
		[[self rightHandle] setPosition: NSMakePoint(frame.size.width, frame.size.height / 2)];
		[[self topHandle] setPosition: NSMakePoint(frame.size.width / 2, frame.size.height)];
		[[self bottomHandle] setPosition: NSMakePoint(frame.size.width / 2, 0)];
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

/** Returns the handle item located on the left side. */
- (ETHandle *) leftHandle
{
	return (ETHandle *)[self itemAtIndex: 4];
}

/** Returns the handle item located on the right side. */
- (ETHandle *) rightHandle
{
	return (ETHandle *)[self itemAtIndex: 5];
}

/** Returns the handle item located on the top. */
- (ETHandle *) topHandle
{
	return (ETHandle *)[self itemAtIndex: 6];
}

/** Returns the handle item located on the bottom. */
- (ETHandle *) bottomHandle
{
	return (ETHandle *)[self itemAtIndex: 7];
}


/** Draws the receiver style. See ETStyle. */
- (void) render: (NSMutableDictionary *)inputValues 
	  dirtyRect: (NSRect)dirtyRect
      inContext: (id)ctxt
{
	[self drawOutlineInRect: [self contentBounds]];
	/* Now draw the handles that are our children */
	[super render: inputValues dirtyRect: dirtyRect inContext: ctxt];
}

/** Draws a rectangular outline. */
- (void) drawOutlineInRect: (NSRect)rect
{
	NSGraphicsContext *ctxt = [NSGraphicsContext currentContext];
	BOOL gstateAntialias = [ctxt shouldAntialias];
	[ctxt setShouldAntialias: NO];

	[[[NSColor blackColor] colorWithAlphaComponent: 0.90] set];
	NSFrameRectWithWidthUsingOperation(rect, 0.0, NSCompositeSourceOver);

	[ctxt setShouldAntialias: gstateAntialias];
}

@end
