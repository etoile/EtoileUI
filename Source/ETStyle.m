/*  <title>ETStyle</title>

	ETStyle.m
	
	<abstract>Generic object chain class to implement late-binding of behavior
	through delegation.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <EtoileFoundation/Macros.h>
#import "ETStyle.h"
#import "ETFreeLayout.h"
#import "ETInstrument.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETCompatibility.h"

@implementation ETStyle

/** Returns a new style connected to an existing style. */
- (id) initWithStyle: (ETStyle *)style
{
	return [self initWithObject: style];
}

/** <init /> Returns a new style by chaining styles passed in parameter. */
- (id) initWithCollection: (id <ETCollection>)styles
{
	return [super initWithCollection: styles];
}

/** Returns the style following the receiver in the style chain. */
- (ETStyle *) nextStyle
{
	return (ETStyle *)[self nextObject];
}

/** Sets the style following the receiver in the style chain. 
	Take note this method discards the existing next style and the whole 
	style chain connected to it. If you want to reconnect the existing 
	next style, it's up to you to handle it. */
- (void) setNextStyle: (ETStyle *)style
{
	[self setNextObject: style];
}

/** Returns the style terminating the style chain the receiver belongs
	to. In other words, returns the first style that has no next style 
	connected to it. */
- (ETStyle *) lastStyle
{
	return (ETStyle *)[self lastObject];
}

/** Returns whether the receiver can be inserted in several style chains. */
- (BOOL) isSharedStyle
{
	return _isSharedStyle;
}

/** Returns the selector uses for style rendering which is equal to -render:
	if you don't override the method. 
	Try also to override -render: if you override this method, so you your 
	custom styles can be used in other style chains in some sort of fallback
	mode. */
- (SEL) styleSelector
{
	return @selector(render:);
}

/** Renders the receiver in the active graphics context and the rest of the 
    style chain connected to it, by passing the input values from style-to-style 
	with the order resulting from calling -nextStyle on eachstyle.
	You should never override this method but -render:layoutItem:dirtyRect: 
	to implement the custom drawing of the style. 
	This method calls -render:layoutItem:dirtyRect: and try to figure out the 
	parameter by looking up kETLayoutItemObject and kETDirtyRect in inputValues. */
- (void) render: (NSMutableDictionary *)inputValues
{
	id item = [inputValues objectForKey: @"kETLayoutItemObject"];
	NSRect dirtyRect = [[inputValues objectForKey: @"kETDirtyRect"] rectValue];
	
	[self render: inputValues layoutItem: item dirtyRect: dirtyRect];
}

/** Main rendering method for the custom drawing implemented by subclasses.
    Renders the receiver in the active graphics context and the rest of the 
    style chain connected to it, by passing the input values from style-to-style 
	with the order resulting from calling -nextStyle on each style.
	When overriding this method, you should usually handle the receiver 
	rendering before delegating it to the rest of the style chain. This 
	implies using 
	    return [super render: inputValues item: item dirtyRect: dirtyRect] 
	at the end of the overriden method. */
- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	[[self nextStyle] render: inputValues layoutItem: item dirtyRect: dirtyRect];
}

/** Notifies the receiver that the styled layout item has been resized.

You can override this method to alter the style state. For example, ETShape 
overrides it to resize/scale the bezier path as needed.

You must call the superclass implementation. */
- (void) didChangeItemBounds: (NSRect)bounds
{
	[[self nextStyle] didChangeItemBounds: bounds];
}

@end


@implementation ETBasicItemStyle

static ETBasicItemStyle *sharedBasicItemStyle = nil;

+ (id) sharedInstance
{
	if (sharedBasicItemStyle == nil)
	{
		sharedBasicItemStyle = [[ETBasicItemStyle alloc] init];
		sharedBasicItemStyle->_isSharedStyle = YES;
	}

	return sharedBasicItemStyle;
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	// FIXME: May be we should better support dirtyRect. The next drawing 
	// methods don't take in account it and simply redraw all their content.
	NSImage *itemImage = [item valueForProperty: kETImageProperty];

	if (itemImage != nil)
	{
		[self drawImage: itemImage
		        flipped: [item isFlipped]
		         inRect: [item drawingFrame]]; 
	}

	if ([item isGroup] && [(ETLayoutItemGroup *)item isStack])
		[self drawStackIndicatorInRect: [item drawingFrame]];

	// FIXME: We should pass a hint in inputValues that lets us known whether 
	// we handle the selection visual clue or not, in order to eliminate the 
	// hard check on ETFreeLayout...
	if ([item isSelected] && [[[item parentItem] layout] isKindOfClass: [ETFreeLayout layout]] == NO)
		[self drawSelectionIndicatorInRect: [item drawingFrame]];

	if ([[[ETInstrument activeInstrument] firstKeyResponder] isEqual: item])
		[self drawFirstResponderIndicatorInRect: [item drawingFrame]];
	
	[super render: inputValues layoutItem: item dirtyRect: dirtyRect];
}

/** Draws an image at the origin of the current graphics coordinates. */
- (void) drawImage: (NSImage *)itemImage flipped: (BOOL)itemFlipped inRect: (NSRect)aRect
{
	//ETLog(@"Drawing image %@ flipped %d in view %@", itemImage, [itemImage isFlipped], [NSView focusView]);
	BOOL flipMismatch = (itemFlipped && (itemFlipped != [itemImage isFlipped]));
	NSAffineTransform *xform = nil;

	if (flipMismatch)
	{
		xform = [NSAffineTransform transform];
		[xform translateXBy: 0.0 yBy: aRect.size.height];
		[xform scaleXBy: 1.0 yBy: -1.0];
		[xform concat];
	}

	[itemImage drawInRect: aRect
	             fromRect: NSZeroRect // Draw the entire image
	            operation: NSCompositeSourceOver 
	             fraction: 1.0];

	if (flipMismatch)
	{
		[xform invert];
		[xform concat];
	}
}

/** Draws a selection indicator that covers the whole item frame if 
    indicatorRect is equal to it. */
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect
{
	//ETLog(@"--- Drawing selection %@ in view %@", NSStringFromRect([item drawingFrame]), [NSView focusView]);
	
	// TODO: We disable the antialiasing for the stroked rect with direct 
	// drawing, but this code may be better moved in 
	// -[ETLayoutItem render:dirtyRect:inView:] to limit the performance impact.
	BOOL gstateAntialias = [[NSGraphicsContext currentContext] shouldAntialias];
	[[NSGraphicsContext currentContext] setShouldAntialias: NO];
	
	/* Align on pixel boundaries for fractional pixel margin and frame. 
	   Fractional item frame results from the item scaling. 
	   NOTE: May be we should adjust pixel boundaries per edge and only if 
	   needed to get a perfect drawing... */
	NSRect normalizedIndicatorRect = NSInsetRect(NSIntegralRect(indicatorRect), 0.5, 0.5);
	
	/* Draw the interior */
	// FIXME: -setFill doesn't work on GNUstep
	[[[NSColor lightGrayColor] colorWithAlphaComponent: 0.45] set];

	// NOTE: [NSBezierPath fillRect: indicatorRect]; doesn't handle color alpha 
	// on GNUstep
	NSRectFillUsingOperation(normalizedIndicatorRect, NSCompositeSourceOver);

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

/** Draws a stack/pile indicator that covers the whole item frame if 
indicatorRect is equal to it. */
- (void) drawStackIndicatorInRect: (NSRect)indicatorRect
{
	// NOTE: Read comments in -drawSelectionIndicatorInRect:.
	BOOL gstateAntialias = [[NSGraphicsContext currentContext] shouldAntialias];
	[[NSGraphicsContext currentContext] setShouldAntialias: NO];
	NSRect normalizedIndicatorRect = NSInsetRect(NSIntegralRect(indicatorRect), 0.5, 0.5);
	// TODO: Implement +bezierPathWithRoundedRect:xRadius:yRadius in GNUstep...
#ifdef GNUSTEP
	NSBezierPath *roundedRectPath = [NSBezierPath bezierPathWithRect: normalizedIndicatorRect];
#else
	NSBezierPath *roundedRectPath = [NSBezierPath bezierPathWithRoundedRect: normalizedIndicatorRect xRadius: 15 yRadius: 15];
#endif

	/* Draw the interior */
	[[[NSColor darkGrayColor] colorWithAlphaComponent: 0.9] setFill];
	[roundedRectPath fill];

	/* Draw the outline */
	[[[NSColor yellowColor] colorWithAlphaComponent: 0.55] setStroke];
	[roundedRectPath stroke];

	[[NSGraphicsContext currentContext] setShouldAntialias: gstateAntialias];
}

- (void) drawFirstResponderIndicatorInRect: (NSRect)indicatorRect
{
	[[[NSColor keyboardFocusIndicatorColor] colorWithAlphaComponent: 0.8] setStroke];
	[NSBezierPath setDefaultLineWidth: 6.0];
	[NSBezierPath strokeRect: indicatorRect];
}

@end


@implementation ETGraphicsGroupStyle

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	//[super render: inputValues layoutItem: item dirtyRect: dirtyRect];
	[self drawBorderInRect: [item drawingFrame]];
}

/** Draws a border that covers the whole item frame if aRect is equal to it. */
- (void) drawBorderInRect: (NSRect)aRect
{
	[[NSColor darkGrayColor] setStroke];
	[NSBezierPath strokeRect: aRect];
}

@end


@implementation ETDropIndicator

- (id) initWithLocation: (NSPoint)dropLocation 
            hoveredItem: (ETLayoutItem *)hoveredItem
           isDropTarget: (BOOL)dropOn
{
	SUPERINIT

	_dropLocation = dropLocation;
	ASSIGN(_hoveredItem, hoveredItem);
	_dropOn = dropOn;

	return self;
}

// FIXME: Handle layout orientation, only works with horizontal layout
// currently, in other words the insertion indicator is always vertical.
- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	//ETLog(@"Draw indicator rect %@ in %@", NSStringFromRect([self currentIndicatorRect]), item);

	if (_dropOn) /* Add */
	{
		//NSRect hoveredRect = [_hoveredItem frame];
		[self drawRectangularInsertionIndicatorInRect: [item drawingFrame]];
	}
	else /* Insert */
	{
		[self drawVerticalInsertionIndicatorInRect: [self currentIndicatorRect]];
	}
}

- (void) setUpDrawingAttributes
{

}

/** Returns the line width to used to draw the indicator. */
- (float) thickness
{
	return 8.0;
}

/** Returns the color used to draw to the indicator. */
- (NSColor *) color
{
	return [NSColor blueColor];
}

- (void) drawVerticalInsertionIndicatorInRect: (NSRect)indicatorRect
{
	[[self color] setFill];
	[NSBezierPath setDefaultLineWidth: [self thickness] / 2];
	[NSBezierPath fillRect: indicatorRect];
	/*[NSBezierPath strokeLineFromPoint: NSMakePoint(indicatorLineX, NSMinY(hoveredRect))
							  toPoint: NSMakePoint(indicatorLineX, NSMaxY(hoveredRect))];*/
	
	_prevInsertionIndicatorRect = indicatorRect;
}

- (void) drawRectangularInsertionIndicatorInRect: (NSRect)indicatorRect
{
	[[self color] setStroke];
	[NSBezierPath setDefaultLineCapStyle: NSButtLineCapStyle];
	[NSBezierPath setDefaultLineWidth: [self thickness]];
	[NSBezierPath strokeRect: indicatorRect];

	_prevInsertionIndicatorRect = indicatorRect;
}

- (NSRect) previousIndicatorRect
{
	return NSIntegralRect(_prevInsertionIndicatorRect);
}

- (NSRect) verticalIndicatorRect
{
	// NOTE: Should we use... -[[item layout] displayRectOfItem: hoveredItem];
	NSRect hoveredRect = [_hoveredItem frame];
	float itemMiddleWidth = hoveredRect.origin.x + hoveredRect.size.width / 2;
	float indicatorWidth = 4.0;
	float indicatorLineX = 0.0;

	/* Decides whether to draw on left or right border of hovered item */
	if (_dropLocation.x >= itemMiddleWidth)
	{
		indicatorLineX = NSMaxX(hoveredRect);
		//ETDebugLog(@"Draw right insertion bar");
	}
	else if (_dropLocation.x < itemMiddleWidth)
	{
		indicatorLineX = NSMinX(hoveredRect);
		//ETDebugLog(@"Draw left insertion bar");
	}

	/* Computes indicator rect */
	return NSMakeRect(indicatorLineX - indicatorWidth / 2.0, 
		NSMinY(hoveredRect), indicatorWidth, NSHeight(hoveredRect));
}

- (NSRect) currentIndicatorRect
{
	if (_dropOn)
	{
		return ETMakeRect(NSZeroPoint, [_hoveredItem drawingFrame].size);
	}
	else
	{
		return [self verticalIndicatorRect];
	}
}

@end
