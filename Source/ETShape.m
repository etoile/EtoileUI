/**
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETShape.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"
#import "ETLayoutItem.h"

typedef NSBezierPath* (*PathProviderFunction)(id, SEL, NSRect);

@interface ETShape (Private)
- (void) setIcon: (NSImage *)anIcon;
- (NSBezierPath *) providedPathWithRect: (NSRect)aRect;
- (id) pathProvider;
@end


@implementation ETShape

+ (NSString *) baseClassName
{
	return @"Shape";
}

+ (NSSet *) keyPathsForValuesAffectingBounds
{
    return S(@"path");
}

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
	[shape setIcon: [NSImage imageNamed: @"layer-shape"]];
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
	[shape setIcon: [NSImage imageNamed: @"layer-shape-ellipse"]];
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

	ASSIGN(_icon, [NSImage imageNamed: @"layer-shape-curve"]);
	[self setPath: aPath];
	[self setFillColor: [NSColor darkGrayColor]];
	[self setStrokeColor: [NSColor lightGrayColor]];
	[self setAlphaValue: 0.5];
	[self setHidden: NO];
	
    return self;
}

- (id) init
{
	return [self initWithBezierPath: nil];
}

- (void) dealloc
{
	DESTROY(_icon);
	DESTROY(_path);
    DESTROY(_fillColor);
    DESTROY(_strokeColor);
    [super dealloc];
}

/** Returns a copy of the receiver shape.

The copied shape is never hidden, even when the receiver was.

See also -[ETUIObject copyWithZone:copier:isAliasedCopy:]. */
- (id) copyWithCopier: (ETCopier *)aCopier 
{
	ETShape *newShape = [super copyWithCopier: aCopier];

	if ([aCopier isAliasedCopy])
		return newShape;

	NSZone *zone = [aCopier zone];

	[aCopier beginCopyFromObject: self toObject: newShape];

	newShape->_icon = RETAIN(_icon);
	newShape->_path = [_path copyWithZone: zone];
	newShape->_fillColor = [_fillColor copyWithZone: zone];
	newShape->_strokeColor = [_strokeColor copyWithZone: zone];
	newShape->_alphaValue = _alphaValue;
	newShape->_resizeSelector = _resizeSelector;

	[aCopier endCopy];
	return newShape;
}

- (NSImage *) icon
{
	return _icon;
}

- (void) setIcon: (NSImage *)anIcon
{
	ASSIGN(_icon, anIcon);
}

/** Returns NO to indicate the receiver can never be shared between several 
owners.

See also -[ETUIObject isShared] and -[ETStyle isShared]. */
- (BOOL) isShared
{
	return NO;
}

- (NSBezierPath *) path
{
	return _path;
}

- (void) setPath: (NSBezierPath *)aPath
{
	[self willChangeValueForProperty: @"path"];
	ASSIGN(_path, aPath);
	[self didChangeValueForProperty: @"path"];
}

- (NSRect) bounds
{
	return [_path bounds];
}

- (void) setBounds: (NSRect)aRect
{
	BOOL isSameBounds = (NSEqualSizes([_path bounds].size, aRect.size)
		&& NSEqualPoints([_path bounds].origin, aRect.origin));

	if (isSameBounds)
		return;

	[self willChangeValueForProperty: @"bounds"];
	if (_resizeSelector != NULL)
	{
		NSBezierPath *resizedPath = [self providedPathWithRect: aRect];

		if (resizedPath != nil)
		{
			[self setPath: resizedPath];
		}
	}
	else
	{
		// TODO: Scale with an affine transform. We should add a method 
		// -[NSAffineTransform scaleFromRect:toRect:]
	}
	[self didChangeValueForProperty: @"bounds"];
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
	[self willChangeValueForProperty: @"pathResizeSelector"];
	_resizeSelector = aSelector;
	[self didChangeValueForProperty: @"pathResizeSelector"];
}

- (NSColor *) fillColor
{
    return AUTORELEASE([_fillColor copy]); 
}

- (void) setFillColor: (NSColor *)color
{
	[self willChangeValueForProperty: @"fillColor"];
	ASSIGN(_fillColor, [color copy]);
	[self didChangeValueForProperty: @"fillColor"];
}

- (NSColor *) strokeColor
{
    return AUTORELEASE([_strokeColor copy]); 
}

- (void) setStrokeColor: (NSColor *)color
{
	[self willChangeValueForProperty: @"strokeColor"];
	ASSIGN(_strokeColor, [color copy]);
	[self didChangeValueForProperty: @"strokeColor"];
}

- (float) alphaValue
{
    return _alphaValue;
}

- (void) setAlphaValue: (float)newAlpha
{
	[self willChangeValueForProperty: @"alphaValue"];
    _alphaValue = newAlpha;
	[self didChangeValueForProperty: @"alphaValue"];
}

- (BOOL) hidden
{
    return _hidden;
}

- (void) setHidden: (BOOL)flag
{
	[self willChangeValueForProperty: @"hidden"];
    _hidden = flag;
	[self didChangeValueForProperty: @"hidden"];
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
{
	NSRect bounds = [item drawingBoundsForStyle: self];

	[self drawInRect: bounds];

	if ([item isSelected])
	{
		[self drawSelectionIndicatorInRect: bounds];
	}
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
