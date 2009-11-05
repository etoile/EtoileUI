/** <title>ETShape</title>

	<abstract>An ETStyle subclass used to represent arbitrary shapes. These 
	shapes can be primitives such as rectangles, oval etc., or more complex 
	shapes that embed or combine text, image, shadow, mask etc.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETStyle.h>

// WARNING: Unstable API

/** ETShape instances are model objects. As such they are never manipulated 
directly by a layout, but ETLayout subclasses interact with them indirectly 
through layout items. A shape is made of a path and optional style and transform. U
nlike NSBezierPath instances, they support boolean operations (will probably 
implemented in a another framework with a category). */
@interface ETShape : ETStyle
{
	NSBezierPath *_path;
	NSColor *_fillColor;
	NSColor *_strokeColor;
	float _alpha;
	BOOL _hidden;
	SEL _resizeSelector;
}

+ (NSRect) defaultShapeRect;
+ (void) setDefaultShapeRect: (NSRect)aRect;

+ (ETShape *) shapeWithBezierPath: (NSBezierPath *)aPath;
+ (ETShape *) rectangleShapeWithRect: (NSRect)aRect;
+ (ETShape *) ovalShapeWithRect: (NSRect)aRect;

- (id) initWithBezierPath: (NSBezierPath *)aPath;

- (NSBezierPath *) path;
- (void) setPath: (NSBezierPath *)aPath;
- (NSRect) bounds;
- (void) setBounds: (NSRect)aRect;
- (SEL) pathResizeSelector;
- (void) setPathResizeSelector: (SEL)aSelector;

- (NSColor *) fillColor;
- (void) setFillColor: (NSColor *)color;
- (NSColor *) strokeColor;
- (void) setStrokeColor: (NSColor *)color;

- (float) alphaValue;
- (void) setAlphaValue: (float)newAlpha;

- (BOOL) hidden;
- (void) setHidden: (BOOL)flag;

/** Returns whether the shape acts as a mask over previous drawing. All drawing
done by all previous renderers will be clipped by the path of the receiver. 
Following this renderer, only the area matching the non-filled part the shape 
will remain and be put through next renderers. */
/*- (BOOL) isMask;
- (void) setMask: (BOOL)flag;*/

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
- (void) drawInRect: (NSRect)rect;

- (void) didChangeItemBounds: (NSRect)bounds;

@end
