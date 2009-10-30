/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import "ETStyle.h"
#import "ETFreeLayout.h"
#import "ETGeometry.h"
#import "ETInstrument.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem.h"
#import "EtoileUIProperties.h"
#import "ETCompatibility.h"

@implementation ETStyle

static NSMutableSet *stylePrototypes = nil;
static NSMapTable *styleSharedInstances = nil;

/** Registers a prototype for every ETStyle subclasses.

The implementation won't be executed in the subclasses but only the abstract 
base class.

Since ETUIItem is an ETStyle subclass, every ETLayoutItem and ETDecoratorItem 
subclass will also get registered as a style (not yet true).

You should never need to call this method.

See also NSObject(ETAspectRegistration). */
+ (void) registerAspects
{
	stylePrototypes = [[NSMutableSet alloc] init];
	ASSIGN(styleSharedInstances, [NSMapTable mapTableWithStrongToStrongObjects]);

	FOREACH([self allSubclasses], subclass, Class)
	{
		/* -init returns nil in in some ETDecoratorItem subclasses.
		   Astract class like ETUIItem should also not be registered.
		   In the long run we will replace this check by: nil == instance */
		if ([subclass isSubclassOfClass: [ETUIItem class]])	
			continue;

		[self registerStyle: AUTORELEASE([[subclass alloc] init])];
	}
}

/** Returns ET. */
+ (NSString *) typePrefix
{
	return @"ET";
}

/** Returns 'Style'. */
+ (NSString *) baseClassName
{
	return @"Style";
}

/** Makes the given prototype available to EtoileUI facilities (inspector, etc.) 
that allow to change a style at runtime.

Also publishes the prototype in the shared aspect repository (not yet implemented). 

If multiple instances of a single class are registered, the first registered   
becomes the shared instance to be returned by +sharedInstance.

Raises an invalid argument exception if aStyle class isn't a subclass of ETStyle. */
+ (void) registerStyle: (ETStyle *)aStyle
{
	if ([aStyle isKindOfClass: [ETStyle class]] == NO)
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Prototype %@ must be a subclass of ETStyle to get "
		                    @"registered as a style prototype.", aStyle];
	}

	[stylePrototypes addObject: aStyle];
	if ([styleSharedInstances objectForKey: [aStyle class]] == nil)
	{
		[styleSharedInstances setObject: aStyle forKey: [aStyle class]];
	}
	// TODO: Make a class instance available as an aspect in the aspect 
	// repository.
}

/** Returns all the style prototypes directly available for EtoileUI facilities 
that allow to transform the UI at runtime. */
+ (NSSet *) registeredStyles
{
	return AUTORELEASE([stylePrototypes copy]);
}

/** Returns all the style classes directly available for EtoileUI facilities 
that allow to transform the UI at runtime.

These style classes are a subset of the registered style prototypes since 
several prototypes might share the same class. */
+ (NSSet *) registeredStyleClasses
{
	return (NSSet *)[[[self registeredStyles] mappedCollection] class];
}

/** <override-never />
Returns the shared instance that corresponds to the receiver class. 

Those shared instances have been previously registered by +registerAspects and 
can be retrieved as a subset of +registeredStyles. */
+ (id) sharedInstance
{
	return [styleSharedInstances objectForKey: self];
}

/** <override-dummy />
Returns the initializer invocation used by -copyWithZone: to create a new 
instance. 

This method returns nil. You can override it to return a custom invocation and 
in this way shares complex initialization logic between -copyWithZone: and 
the designated initializer in a subclass.
 
e.g. if you return an invocation like -initWithWindow: aWindow. 
-copyWithZone: will automatically set the target to be the copy allocated with 
[[[self class] allocWithZone: aZone] and then initializes the copy by invoking 
the invocation. */
- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone
{
	return nil;
}

- (id) copyWithZone: (NSZone *)aZone
{
	NSInvocation *initInvocation = [self initInvocationForCopyWithZone: aZone];
	ETStyle *newStyle = [[self class] alloc];
	
	if (nil != initInvocation)
	{
		[initInvocation invokeWithTarget: newStyle];
		[initInvocation getReturnValue: &newStyle];
	}

	newStyle->_isSharedStyle = _isSharedStyle;

	return newStyle;
}

/** Returns whether the receiver can be shared between several owners.

TODO: Not really implemented yet... */
- (BOOL) isSharedStyle
{
	return _isSharedStyle;
}

/** Returns the selector uses for style rendering which is equal to -render:
if you don't override the method. 

Try also to override -render: if you override this method, so you your 
custom styles can be used in other style chains in some sort of fallback
mode.

TODO: Not really implemented yet and could be removed... */
- (SEL) styleSelector
{
	return @selector(render:);
}

/** Renders the receiver in the active graphics context.

You should never override this method but -render:layoutItem:dirtyRect: to 
implement the custom drawing of the style. 

This method calls -render:layoutItem:dirtyRect: and try to figure out the 
parameter by looking up kETLayoutItemObject and kETDirtyRect in inputValues. */
- (void) render: (NSMutableDictionary *)inputValues
{
	id item = [inputValues objectForKey: @"kETLayoutItemObject"];
	NSRect dirtyRect = [[inputValues objectForKey: @"kETDirtyRect"] rectValue];
	
	[self render: inputValues layoutItem: item dirtyRect: dirtyRect];
}

/** <override-subclass />
Main rendering method for the custom drawing implemented by subclasses.
    
Renders the receiver in the active graphics context with the given layout item 
in the role of the element on which the style is applied.

item indicates in which item the receiver is rendered. Usually this item is the 
one on which the receiver is indirectly set through -[ETLayoutItem styleGroup]. 
However the item can be unrelated to the style or nil.

dirtyRect can be used to optimize the drawing. You only need to redraw what is 
inside that redisplayed area and won't be clipped by the graphics context. */
- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{

}

/** <override-dummy />
Notifies the receiver that the styled layout item has been resized.

You can override this method to alter the style state. For example, ETShape 
overrides it to resize/scale the bezier path as needed. */
- (void) didChangeItemBounds: (NSRect)bounds
{

}

- (NSRect) boundingBoxForItem: (ETLayoutItem *)anItem
{
	return ETMakeRect(NSZeroPoint, [anItem size]);
}

@end


@implementation ETBasicItemStyle

/** Returns the string attributes used to draw the label by default.

The returned attributes only include the label font supplied by NSFont with a 
small system font size. */
+ (NSDictionary *) standardLabelAttributes
{
	return D([NSFont labelFontOfSize: [NSFont smallSystemFontSize]], NSFontAttributeName);
}

/** Returns a new autoreleased style that draws the item icon and its name as 
a label underneath. */
+ (ETBasicItemStyle *) iconAndLabelBarElementStyle
{
	ETBasicItemStyle *style = AUTORELEASE([[self alloc] init]);
	[style setLabelPosition: ETLabelPositionInsideBottom];
	[style setMaxImageSize: NSMakeSize(32, 32)];
	[style setEdgeInset: 7];
	return style;
}

/** <init />Initializes and returns a new basic item style. */
- (id) init
{
	SUPERINIT
	_isSharedStyle = YES;
	_labelPosition = ETLabelPositionCentered;
	ASSIGN(_labelAttributes, [[self class] standardLabelAttributes]);
	_maxImageSize = ETNullSize;
	_edgeInset = 0;
	return self;
}

DEALLOC(DESTROY(_labelAttributes));

- (id) copyWithZone: (NSZone *)aZone
{
	ETBasicItemStyle *newStyle = [super copyWithZone: aZone];

	newStyle->_labelAttributes = [_labelAttributes copyWithZone: aZone];
	newStyle->_labelPosition = _labelPosition;
	newStyle->_labelMargin = _labelMargin;
	newStyle->_labelVisible = _labelVisible;
	newStyle->_maxImageSize = _maxImageSize;
	newStyle->_edgeInset = _edgeInset;

	return newStyle;
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	// FIXME: May be we should better support dirtyRect. The next drawing 
	// methods don't take in account it and simply redraw all their content.
	NSImage *itemImage = [item valueForProperty: kETImageProperty];

	if (nil != itemImage)
	{
		[self drawImage: itemImage
		        flipped: [item isFlipped]
		         inRect: [self rectForImage: itemImage ofItem: item]]; 
	}

	NSString *itemLabel = [self labelForItem: item];

	if (nil != itemLabel)
	{
		//ETLog(@"Try to draw label in %@ of %@", NSStringFromRect([self rectForLabel: itemLabel ofItem: item]), item);
		[itemLabel drawInRect: [self rectForLabel: itemLabel ofItem: item]
		       withAttributes: _labelAttributes];
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

/** Returns the item title position. */
- (ETLabelPosition) labelPosition
{
	return _labelPosition;
}

/** Sets the title position. */
- (void) setLabelPosition: (ETLabelPosition)aPositionRule
{
	_labelPosition = aPositionRule;
}

/** Returns the margin between the item label and the item content. */
- (float) labelMargin
{
	return _labelMargin;
}

/** Sets the margin between the item label and the item content. */
- (void) setLabelMargin: (float)aMargin
{
	_labelMargin = aMargin;
}

/** Returns the string attributes used to draw the label. */
- (NSDictionary *) labelAttributes
{
	return _labelAttributes;
}

/** Sets the string attributes used to draw the label. */
- (void) setLabelAttributes: (NSDictionary *)stringAttributes
{
	ASSIGN(_labelAttributes, stringAttributes);
}

- (NSRect) rectForLabel: (NSString *)aLabel ofItem: (ETLayoutItem *)anItem
{
	NSParameterAssert(nil != aLabel);
	NSParameterAssert(nil != anItem);

	NSRect itemFrame = [anItem frame];
	NSSize labelSize = [aLabel sizeWithAttributes: _labelAttributes];
	NSRect rect = ETNullRect;

	switch (_labelPosition)
	{
		case ETLabelPositionCentered:
			rect = ETCenteredRect(labelSize, itemFrame);
			break;
		case ETLabelPositionOutsideTop:
		{
			float labelBaseY = itemFrame.size.height + labelSize.height;
			
			if ([anItem isFlipped])
			{
				labelBaseY = - labelSize.height;
			}
				
			rect = NSMakeRect(0, labelBaseY, labelSize.width, labelSize.height);
			break;
		}
		case ETLabelPositionOutsideLeft:
		{
			float labelBaseY = 0;
			
			if ([anItem isFlipped])
			{
				labelBaseY = itemFrame.size.height;
			}

			rect = NSMakeRect(itemFrame.size.width + _labelMargin, labelBaseY, labelSize.width, labelSize.height);
			break;
		}
		case ETLabelPositionInsideBottom:
		{
			float labelBaseX = (itemFrame.size.width - labelSize.width) / 2;
			float labelBaseY = 0;
			
			if ([anItem isFlipped])
			{
				labelBaseY = itemFrame.size.height - labelSize.height - _edgeInset;
			}
			else
			{
				labelBaseY = _edgeInset;
			}

			rect = NSMakeRect(labelBaseX, labelBaseY, labelSize.width, labelSize.height);
			break;
		}
		case ETLabelPositionNone:
			return NSZeroRect;
		default:
			ASSERT_INVALID_CASE;
			return NSZeroRect;
	}

	return NSIntersectionRect(rect, [anItem drawingFrame]);
}

/** Returns the string to be used as the label to draw.

When the given item has a view, returns the item name which might be nil, 
otherwise returns the item display name which is never nil. This behavior 
ensures no label is drawn when the item uses a custom view (such as a widget), 
unless you explicitly set one with -[ETLayoutItem setName:]. */
- (NSString *) labelForItem: (ETLayoutItem *)anItem
{
	NSString *label = nil;

	// TODO: We probably want extra flexibility. e.g. kETShouldDrawGroupLabelHint 
	// set by the parent item in inputValues based on the layout. 
	// ETLayoutItemGroup might want to query the layout with 
	// -[ETLayout shouldLayoutContextDraws(All)ItemLabel].
	if ([anItem view] != nil)
	{
		label = [anItem name];
	}
	else if ([anItem isGroup] == NO)
	{
		label = [anItem displayName];
	}

	return label;
}

- (NSRect) boundingBoxForItem: (ETLayoutItem *)anItem
{
	NSRect labelRect = [self rectForLabel: [self labelForItem: anItem] ofItem: anItem];
	return NSUnionRect([super boundingBoxForItem: anItem], labelRect);
}

/** Returns the max allowed size to draw to the image

When the image size is superior to this max size, 
-rectForImage:ofItem: will strink the image drawing area to this size. */
- (NSSize) maxImageSize
{
	return _maxImageSize;
}

/** Sets the max allowed size to draw the image.

See also -maxImageSize. */
- (void) setMaxImageSize: (NSSize)aSize
{
	_maxImageSize = aSize;
}

/** <override-never />
Returns the image drawing area in the given item content bounds. */
- (NSRect) rectForImage: (NSImage *)anImage 
                 ofItem: (ETLayoutItem *)anItem
{
	NSRect labelRect = [self rectForLabel: [self labelForItem: anItem] ofItem: anItem];
	return [self rectForImage: anImage 
	                   ofItem: anItem 
	            withLabelRect: labelRect];
}

- (NSRect) rectForAreaSize: (NSSize)aSize 
                    ofItem: (ETLayoutItem *)anItem
             withLabelRect: (NSRect)labelRect
{
	NSRect contentBounds = [anItem contentBounds];
	NSRect insetContentRect = NSInsetRect(contentBounds, _edgeInset, _edgeInset);
	NSSize viewSize = aSize;
	NSRect maxViewRect = insetContentRect;

	switch (_labelPosition)
	{
		case ETLabelPositionCentered:
			break;
		case ETLabelPositionInsideBottom:
		{
			if ([anItem isFlipped] == NO)
			{	
				maxViewRect.origin.y += labelRect.size.height + _labelMargin;	
			}
			maxViewRect.size.height -= labelRect.size.height + _labelMargin;
			break;
		}
		case ETLabelPositionNone:
			return NSZeroRect;
		default:
			ASSERT_INVALID_CASE;
			return NSZeroRect;
	}
	//return ETMakeRect(maxViewRect.origin, viewSize);

	NSRect viewRect = ETCenteredRect(viewSize, maxViewRect);

	/* When the existing view size was already smaller than the inset area we 
	   use this view measure rather than the inset area measure. */
	if (viewSize.width > insetContentRect.size.width)
	{
		viewRect.size.width = maxViewRect.size.width;
		viewRect.origin.x = maxViewRect.origin.x;
	}
	if (viewSize.height > insetContentRect.size.height)
	{
		viewRect.size.height = maxViewRect.size.height;
		viewRect.origin.y = maxViewRect.origin.y;
	}

	return viewRect;
}

/** Returns the image drawing area in the given item content bounds with enough 
room for the given label area based on the label position.

If the label position is not inside, the label area is simply ignored. */
- (NSRect) rectForImage: (NSImage *)anImage 
                 ofItem: (ETLayoutItem *)anItem
          withLabelRect: (NSRect)labelRect
{
	NSSize maxSize = NSEqualSizes(_maxImageSize, ETNullSize) ? [anItem contentBounds].size : _maxImageSize;
	ETContentAspect imageAspect = [anItem contentAspect];

	if (ETContentAspectComputed == imageAspect)
	{
		imageAspect = ETContentAspectScaleToFit;
	}

	NSRect imageRect = [anItem contentRectWithRect: ETMakeRect(NSZeroPoint, [anImage size])
	                                 contentAspect: imageAspect
	                                    boundsSize: maxSize];

	/*ETLog(@"Image size %@ to %@", NSStringFromSize([anImage size]), NSStringFromRect(imageRect));
	ETLog(@" -- %@", NSStringFromRect([self rectForAreaSize: imageRect.size
	                      ofItem: anItem
	               withLabelRect: labelRect]));*/

	return [self rectForAreaSize: imageRect.size
	                      ofItem: anItem
	               withLabelRect: labelRect];
}

/** <override-never />
Returns the view drawing area in the given item content bounds. */
- (NSRect) rectForViewOfItem: (ETLayoutItem *)anItem
{
	NSRect labelRect = [self rectForLabel: [self labelForItem: anItem] ofItem: anItem];
	return [self rectForViewOfItem: anItem 
	                 withLabelRect: labelRect];
}

/** Returns the view drawing area in the given item content bounds with enough 
room for the given label area based on the label position.

If the label position is not inside, the label area is simply ignored. */
- (NSRect) rectForViewOfItem: (ETLayoutItem *)anItem
               withLabelRect: (NSRect)labelRect
{
	NSSize viewSize = [[anItem view] frame].size;
	NSRect viewRect = [self rectForAreaSize: viewSize
	                                 ofItem: anItem
	                          withLabelRect: labelRect];

	// TODO: In most case, we want to keep the widget height but it would be 
	// nice to have a way to allow the widget width to be flexible. We could add 
	// minWidth and maxWidth properties to ETLayoutItem and rework the code below.
	viewRect.size = viewSize;

	return viewRect;
}

/** Returns the inset margin along each item content bounds edge.

The returned value can be used as inset along the item frame edge rather than 
the content bounds in subclasses. */
- (float) edgeInset
{
	return _edgeInset;
}

/** Sets the inset margin along each item content bounds edge.

See also -edgeInset. */
- (void) setEdgeInset: (float)anInset
{
	_edgeInset = anInset;
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

// NOTE: -copyWithZone: implementation can be omitted, the ivars are transient.

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


@implementation ETShadowStyle

+ (id) shadowWithStyle: (ETStyle *)style
{
	return [[[ETShadowStyle alloc] initWithStyle: style] autorelease];
}

- (id) initWithStyle: (ETStyle *)style
{
	SUPERINIT;
	ASSIGN(_content, style);
	// FIXME: implement on GNUstep
#ifndef GNUSTEP
	_shadow = [[NSShadow alloc] init];
	[_shadow setShadowOffset: NSMakeSize(4.0, -4.0)];
	[_shadow setShadowColor: [NSColor blackColor]];
	[_shadow setShadowBlurRadius: 5.0];
#endif
	return self;
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	// FIXME: This will usually draw outside of item's frame..
	//        A shadow should increase the size of the item's frame.
	//        Maybe the shadow style should be a decorator item instead?
	[NSGraphicsContext saveGraphicsState];
	[_shadow set];
	[_content render: inputValues layoutItem: item dirtyRect: dirtyRect];
	[NSGraphicsContext restoreGraphicsState];
}

- (void) didChangeItemBounds: (NSRect)bounds
{
	[_content didChangeItemBounds: bounds];
	[super didChangeItemBounds: bounds];
}

@end



@implementation ETTintStyle

+ (id) tintWithStyle: (ETStyle *)style color: (NSColor *)color
{
	ETTintStyle *tint = [[[ETTintStyle alloc] initWithStyle: style] autorelease];
	[tint setColor: color];
	return tint;
}

+ (id) tintWithStyle: (ETStyle *)style
{
	return [[[ETTintStyle alloc] initWithStyle: style] autorelease];
}

- (id) initWithStyle: (ETStyle *)style
{
	SUPERINIT;
	ASSIGN(_content, style);
	_color = [[NSColor colorWithDeviceRed:0.005 green:0.0 blue:0.01 alpha:0.7] retain];
	return self;
}

- (void) setColor: (NSColor *)color
{
	ASSIGN(_color, color);
}

- (NSColor *) color
{
	return _color;
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	[_content render: inputValues layoutItem: item dirtyRect: dirtyRect];
	
	[NSGraphicsContext saveGraphicsState];
	[_color set];
	NSRectFillUsingOperation([item drawingFrame], NSCompositeSourceOver);
	[NSGraphicsContext restoreGraphicsState];
}

- (void) didChangeItemBounds: (NSRect)bounds
{
	[_content didChangeItemBounds: bounds];
	[super didChangeItemBounds: bounds];
}

@end


/**
 * Draws a speech bubble around the item to which this style is applied.
 */
@implementation ETSpeechBubbleStyle

/**
 * Returns a bezier path for a speech bubble positioned around rect, to be
 * placed on the left side of a speaker.
 *
 * Coordinates are unflipped.
 *
 * Modelled after:
 * http://jesseross.com/clients/etoile/ui/concepts/01/workspace_200.jpg
 */
+ (NSBezierPath *)leftSpeechBubbleAroundRect: (NSRect)rect
{
	const float radius = 9.0;
	NSBezierPath *path = [NSBezierPath bezierPath];
	
	// Add some padding to the inner rectangle
	rect = NSInsetRect(rect, -1, -3);
	
	// Calculate the bounding points of the inner area of the bubble
	NSPoint bottomLeft = NSMakePoint(NSMinX(rect), NSMinY(rect));
	NSPoint topLeft = NSMakePoint(NSMinX(rect), NSMaxY(rect));
	NSPoint topRight = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
	NSPoint bottomRight = NSMakePoint(NSMaxX(rect), NSMinY(rect));
	
	// Bottom left corner
	[path moveToPoint: NSMakePoint(bottomLeft.x, bottomLeft.y + (-1 * radius))];
	[path appendBezierPathWithArcWithCenter: bottomLeft radius: radius startAngle: 270 endAngle: 180 clockwise: YES];
	// Left edge
	[path lineToPoint: NSMakePoint(bottomLeft.x - radius, topLeft.y)];	
	// Top left corner
	[path appendBezierPathWithArcWithCenter: topLeft radius: radius startAngle: 180 endAngle: 90 clockwise: YES];
	// Top edge
	[path lineToPoint: NSMakePoint(topRight.x, topLeft.y + (radius))];	
	// Top right corner
	[path appendBezierPathWithArcWithCenter: topRight radius: radius startAngle: 90 endAngle: 0 clockwise: YES];
	// Right edge
	[path lineToPoint: NSMakePoint(bottomRight.x + radius, bottomRight.y)];
	
	// Partial bottom right corner (62 degree arc)
	[path appendBezierPathWithArcWithCenter: bottomRight radius: radius startAngle: 0 endAngle: 298 clockwise: YES];
	// Curve out to the tip
	[path relativeCurveToPoint: NSMakePoint(7.5, -8.5) controlPoint1: NSMakePoint(-1, -4) controlPoint2: NSMakePoint(7.5, -8.5)];
	// Curve back to the bottom edge of the speech bubble
	[path curveToPoint: NSMakePoint(bottomRight.x - 5, bottomRight.y + (-1 * radius)) controlPoint1:NSMakePoint(bottomRight.x + 2.5, bottomRight.y + (-18)) controlPoint2: NSMakePoint(bottomRight.x - 5, bottomRight.y + (-1 * radius))];
	
	// Connect back to the bottom left corner
	[path closePath];
	
	return path;
}


+ (id) speechWithStyle: (ETStyle *)style
{
	return [[[ETSpeechBubbleStyle alloc] initWithStyle: style] autorelease];
}

- (id) initWithStyle: (ETStyle *)style
{
	SUPERINIT;
	ASSIGN(_content, style);
	return self;
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	[NSGraphicsContext saveGraphicsState];
	
	// The bubble uses unflipped coordinates
	NSBezierPath *bubble = [ETSpeechBubbleStyle leftSpeechBubbleAroundRect: [item drawingFrame]];
	NSRect bounds = NSInsetRect([bubble bounds], -6, -6); // Inset the rect to leave room for the shadow
	
	BOOL flipped = [item isFlipped];
	NSAffineTransform *xform = nil;
	if (flipped)
	{
		xform = [NSAffineTransform transform];
		[xform scaleXBy: 1.0 yBy: -1.0];
		[xform translateXBy: 0 yBy: -1 * [item drawingFrame].size.height];
		[xform concat];
		bounds.origin.y = [item drawingFrame].size.height - (bounds.size.height + bounds.origin.y);
	}
	
	[item setBoundingBox: bounds];
	
#ifndef GNUSTEP
	
	// Draw shadow
	[NSGraphicsContext saveGraphicsState];
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset: NSMakeSize(2.0, -2.0)];
	[shadow setShadowColor: [[NSColor blackColor] colorWithAlphaComponent: 0.3]];
	[shadow setShadowBlurRadius: 5.0];
	[shadow set];
	[[NSColor whiteColor] setFill];
	[bubble fill];
	[NSGraphicsContext restoreGraphicsState];
	[shadow release];
	
	// Draw gradient fill
	NSGradient *gradient = [[NSGradient alloc]initWithStartingColor: [NSColor whiteColor]
														endingColor: [NSColor colorWithCalibratedRed: 227.0/255.0 green: 226.0/255.0 blue: 228.0/255.0 alpha: 1]];
	[gradient drawInBezierPath: bubble angle: 90];
	[gradient release];
	
#else
	
	// Draw plain fill
	[[NSColor whiteColor] setFill];
	[bubble fill];
#endif
	
	[[[NSColor blackColor] colorWithAlphaComponent: 0.4] setStroke];
	[bubble stroke];
	
	if (flipped)
	{
		[xform invert];
		[xform concat];
	}
	
	[_content render: inputValues layoutItem: item dirtyRect: dirtyRect];
	
	[NSGraphicsContext restoreGraphicsState];
}

- (void) didChangeItemBounds: (NSRect)bounds
{
	[_content didChangeItemBounds: bounds];
	[super didChangeItemBounds: bounds];
}

@end
