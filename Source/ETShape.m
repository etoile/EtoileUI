/*  <title>ETShape</title>

	ETShape.m
	
	<abstract>An ETStyle subclass used to represent arbitrary shapes. These 
	shapes can be primitives such as rectangles, oval etc., or more complex 
	shapes that embed or combine text, image, shadow, mask etc.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2007
 
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
#import "ETShape.h"
#import "ETCompatibility.h"
#import "ETLayoutItem.h"
#import "NSView+Etoile.h"

typedef NSBezierPath* (*PathProviderFunction)(id, SEL, NSRect);

@interface ETShape (Private)
- (NSBezierPath *) providedPathWithRect: (NSRect)aRect;
- (id) pathProvider;
@end


@implementation ETShape

static NSRect shapeFactoryRect = {{ 0, 0 }, { 150, 100 }};

+ (NSRect) defaultShapeRect
{
	return shapeFactoryRect;
}

+ (void) setDefaultShapeRect: (NSRect)aRect
{
	shapeFactoryRect = aRect;
}

/** Returns a custom shape based on the given bezier path. */
+ (ETShape *) shapeWithBezierPath: (NSBezierPath *)aPath
{
	return AUTORELEASE([[self alloc] initWithBezierPath: aPath]);
}

/** Returns a rectangular shape with the width and height of aRect. */
+ (ETShape *) rectangleShapeWithRect: (NSRect)aRect
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRect: aRect];
	ETShape *shape = AUTORELEASE([[self alloc] initWithBezierPath: path]);
	[shape setPathResizeSelector: @selector(bezierPathWithRect:)];
	return shape;
}

/** Returns a rectangular shape with the width and height of +shapeFactoryRect. */
+ (ETShape *) rectangleShape
{
	return [self rectangleShapeWithRect: [self defaultShapeRect]];
}

/** Returns an oval shape that fits in the width and height of aRect. */
+ (ETShape *) ovalShapeWithRect: (NSRect)aRect
{
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect: aRect];
	ETShape *shape = AUTORELEASE([[self alloc] initWithBezierPath: path]);
	[shape setPathResizeSelector: @selector(bezierPathWithOvalInRect:)];
	return shape;
}

/** Returns an oval shape that fits in the width and height of +shapeFactoryRect. */
+ (ETShape *) ovalShape
{
	return [self ovalShapeWithRect: [self defaultShapeRect]];
}

/** Initializes and returns a new custom shape based on the given bezier path. */
- (id) initWithBezierPath: (NSBezierPath *)aPath
{
	SUPERINIT

	[self setPath: aPath];
	[self setFillColor: [NSColor darkGrayColor]];
	[self setStrokeColor: [NSColor lightGrayColor]];
	[self setAlphaValue: 0.5];
	[self setHidden: NO];
	
    return self;
}

- (void) dealloc
{
	DESTROY(_path);
    DESTROY(_fillColor);
    DESTROY(_strokeColor);
    [super dealloc];
}

/** Returns a copy of the receiver shape.

The copied shape is never hidden, even when the receiver was. */
- (id) copyWithZone: (NSZone *)aZone
{
	ETShape *newShape = [super copyWithZone: aZone];
	newShape->_path = [_path copyWithZone: aZone];
	newShape->_fillColor = [_fillColor copyWithZone: aZone];
	newShape->_strokeColor = [_strokeColor copyWithZone: aZone];
	newShape->_alpha = _alpha;
	newShape->_resizeSelector = _resizeSelector;
	return newShape;
}

- (NSBezierPath *) path
{
	return _path;
}

- (void) setPath: (NSBezierPath *)aPath
{
	ASSIGN(_path, aPath);
}

- (NSRect) bounds
{
	return [_path bounds];
}

- (void) setBounds: (NSRect)aRect
{
	if (_resizeSelector != NULL)
	{
		NSBezierPath *resizedPath = [self providedPathWithRect: aRect];

		if (resizedPath != nil)
			[self setPath: resizedPath];
	}
	else
	{
		// TODO: Scale with an affine transform. We should add a method 
		// -[NSAffineTransform scaleFromRect:toRect:]
	}
}

- (NSBezierPath *) providedPathWithRect: (NSRect)aRect
{
	PathProviderFunction resizeFunction;
	
	resizeFunction = (PathProviderFunction)[[self pathProvider] methodForSelector: _resizeSelector];
	
	if (resizeFunction == NULL)
		return nil;

	return resizeFunction([self pathProvider], _resizeSelector, aRect);
}

- (id) pathProvider
{
	return [NSBezierPath class];
}

- (SEL) pathResizeSelector
{
	return _resizeSelector;
}

- (void) setPathResizeSelector: (SEL)aSelector
{
	_resizeSelector = aSelector;
}

- (NSColor *) fillColor
{
    return AUTORELEASE([_fillColor copy]); 
}

- (void) setFillColor: (NSColor *)color
{
	ASSIGN(_fillColor, [color copy]);
}

- (NSColor *) strokeColor
{
    return AUTORELEASE([_strokeColor copy]); 
}

- (void) setStrokeColor: (NSColor *)color
{
	ASSIGN(_strokeColor, [color copy]);
}

- (float) alphaValue
{
    return _alpha;
}

- (void) setAlphaValue: (float)newAlpha
{
    _alpha = newAlpha;
}

- (BOOL) hidden
{
    return _hidden;
}

- (void) setHidden: (BOOL)flag
{
    _hidden = flag;
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
{
	// FIXME: May be we should better support dirtyRect. The next drawing 
	// methods don't take in account it and simply redraw all their content.

	[self drawInRect: [item drawingFrame]];

	if ([item isSelected])
		[self drawSelectionIndicatorInRect: [item drawingFrame]];
	
	//[super render: inputValues layoutItem: item dirtyRect: dirtyRect];
}

- (void) drawInRect: (NSRect)rect
{
	[NSGraphicsContext saveGraphicsState];

	float alpha = [self alphaValue];
	[[[self fillColor] colorWithAlphaComponent: alpha] setFill];
	[[[self strokeColor] colorWithAlphaComponent: alpha] setStroke];
	[[self path] fill];
	[[self path] stroke];

	[NSGraphicsContext restoreGraphicsState];
}

/** Draws a selection indicator that covers the whole item frame if 
    indicatorRect is equal to it. */
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

- (void) didChangeItemBounds: (NSRect)bounds
{
	[self setBounds: bounds];
	[super didChangeItemBounds: bounds];
}

@end
