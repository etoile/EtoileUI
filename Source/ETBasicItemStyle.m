/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETBasicItemStyle.h"
#import "ETFreeLayout.h"
#import "ETGeometry.h"
#import "ETInstrument.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem.h"
#import "EtoileUIProperties.h"
#import "ETCompatibility.h"


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
		[xform translateXBy: aRect.origin.x yBy: aRect.origin.y + aRect.size.height];
		[xform scaleXBy: 1.0 yBy: -1.0];
		[xform concat];

		[itemImage drawInRect: ETMakeRect(NSZeroPoint, aRect.size)
	                 fromRect: NSZeroRect // Draw the entire image
	                operation: NSCompositeSourceOver 
	                 fraction: 1.0];

		[xform invert];
		[xform concat];
	}
	else
	{
		[itemImage drawInRect: aRect
	                 fromRect: NSZeroRect // Draw the entire image
	                operation: NSCompositeSourceOver 
	                 fraction: 1.0];
	}
}

/** Draws a selection indicator that covers the whole item frame if 
 the given indicator rect is equal to it. */
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect
{
	//ETLog(@"--- Drawing selection %@ in view %@", NSStringFromRect([item drawingFrame]), [NSView focusView]);
	
	NSGraphicsContext *ctxt = [NSGraphicsContext currentContext];
	BOOL gstateAntialias = [ctxt shouldAntialias];

	/* Disable the antialiasing for the stroked rect */
	[ctxt setShouldAntialias: NO];
	
	/* Align on pixel boundaries for fractional pixel margin and frame. 
	   Fractional item frame results from the item scaling. 
	   NOTE: May be we should adjust pixel boundaries per edge and only if 
	   needed to get a perfect drawing... */
	NSRect normalizedIndicatorRect = NSInsetRect(NSIntegralRect(indicatorRect), 0.5, 0.5);

	/* Draw the interior */
	[[[NSColor lightGrayColor] colorWithAlphaComponent: 0.45] setFill];
	[NSBezierPath fillRect: normalizedIndicatorRect];

	/* Draw the outline
	   FIXME: Cannot get the outline precisely aligned on pixel boundaries for 
	   GNUstep. With the current code which works well on Cocoa, the top border 
	   of the outline isn't drawn most of the time and the image drawn 
	   underneath seems to wrongly extend beyond the border. */
	[[[NSColor darkGrayColor] colorWithAlphaComponent: 0.55] setStroke];
	[NSBezierPath strokeRect: normalizedIndicatorRect];

	[ctxt setShouldAntialias: gstateAntialias];
}

/** Draws a stack/pile indicator that covers the whole item frame if 
the given indicator rect is equal to it. */
- (void) drawStackIndicatorInRect: (NSRect)indicatorRect
{
	// NOTE: Read comments in -drawSelectionIndicatorInRect:.
	NSGraphicsContext *ctxt = [NSGraphicsContext currentContext]; 
	BOOL gstateAntialias = [ctxt shouldAntialias];

	[ctxt setShouldAntialias: NO];

	NSRect normalizedIndicatorRect = NSInsetRect(NSIntegralRect(indicatorRect), 0.5, 0.5);
	NSBezierPath *roundedRectPath = 
		[NSBezierPath bezierPathWithRoundedRect: normalizedIndicatorRect xRadius: 15 yRadius: 15];

	/* Draw the interior */
	[[[NSColor darkGrayColor] colorWithAlphaComponent: 0.9] setFill];
	[roundedRectPath fill];

	/* Draw the outline */
	[[[NSColor yellowColor] colorWithAlphaComponent: 0.55] setStroke];
	[roundedRectPath stroke];

	[ctxt setShouldAntialias: gstateAntialias];
}

/** Draws a focus ring that covers the whole item frame if the given indicator 
rect is equal to it. */
- (void) drawFirstResponderIndicatorInRect: (NSRect)indicatorRect
{
	float gstateLineWidth = [NSBezierPath defaultLineWidth];

	[[[NSColor keyboardFocusIndicatorColor] colorWithAlphaComponent: 0.8] setStroke];
	[NSBezierPath setDefaultLineWidth: 6.0];
	[NSBezierPath strokeRect: indicatorRect];

	[NSBezierPath setDefaultLineWidth: gstateLineWidth];
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
