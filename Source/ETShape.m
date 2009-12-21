/**
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2007
	License: Modified BSD (see COPYING)
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
	float alpha = [self alphaValue];
	[[[self fillColor] colorWithAlphaComponent: alpha] setFill];
	[[[self strokeColor] colorWithAlphaComponent: alpha] setStroke];
	[[self path] fill];
	[[self path] stroke];
}

- (void) didChangeItemBounds: (NSRect)bounds
{
	[self setBounds: bounds];
	[super didChangeItemBounds: bounds];
}

@end
