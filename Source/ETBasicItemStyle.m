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
	_maxLabelSize = ETNullSize;
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
	newStyle->_maxLabelSize = _maxLabelSize;
	newStyle->_maxImageSize = _maxImageSize;
	newStyle->_edgeInset = _edgeInset;

	return newStyle;
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	/* Compute Label And Image Geometry */

	// FIXME: May be we should better support dirtyRect. The next drawing 
	// methods don't take in account it and simply redraw all their content.
	_currentLabelRect = NSZeroRect;
	_currentImageRect = NSZeroRect;

	NSString *itemLabel = [self labelForItem: item];

	if (nil != itemLabel)
	{
		_currentLabelRect = [self rectForLabel: itemLabel 
		                               inFrame: [item drawingFrame] 
		                                ofItem: item];	
	}

	NSImage *itemImage = [self imageForItem: item];

	if (nil != itemImage)
	{
		_currentImageRect = [self rectForImage: itemImage 
		                                ofItem: item 
		                         withLabelRect: _currentLabelRect];
	}

	/* Draw */

	if (nil != itemImage)
	{
		[self drawImage: itemImage flipped: [item isFlipped] inRect: _currentImageRect]; 	
	}

	if (nil != itemLabel)
	{
		//ETLog(@"Try to draw label in %@ of %@", NSStringFromRect(_currentLabelRect), item);
		[itemLabel drawInRect: _currentLabelRect withAttributes: _labelAttributes];
	}

	if ([item isGroup] && [(ETLayoutItemGroup *)item isStack])
	{
		[self drawStackIndicatorInRect: [item drawingFrame]];
	}

	// FIXME: We should pass a hint in inputValues that lets us known whether 
	// we handle the selection visual clue or not, in order to eliminate the 
	// hard check on ETFreeLayout...
	if ([item isSelected] && [[[item parentItem] layout] isKindOfClass: [ETFreeLayout layout]] == NO)
	{
		[self drawSelectionIndicatorInRect: [item drawingFrame]];
	}

	if ([[[ETInstrument activeInstrument] firstKeyResponder] isEqual: item])
	{
		[self drawFirstResponderIndicatorInRect: [item drawingFrame]];
	}

	[super render: inputValues layoutItem: item dirtyRect: dirtyRect];
}

/** Returns the last value computed for -rectForLabel:inFrame:ofItem:. 

This value is computed at the beginning of -render:layoutItem:dirtyRect:. Which  
means you can safely use it when overriding other drawing methods. */
- (NSRect) currentLabelRect
{
	return _currentLabelRect;
}

/** Returns the last value computed for -rectForImage:ofItem:withLabelRect:.

This value is computed at the beginning of -render:layoutItem:dirtyRect:. Which  
means you can safely use it when overriding other drawing methods. */
- (NSRect) currentImageRect
{
	return _currentImageRect;
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
	[NSGraphicsContext saveGraphicsState];

	// TODO: Implement NSSetFocusRingStyle() on GNUstep
#ifndef GNUSTEP
	NSSetFocusRingStyle(NSFocusRingOnly);
	[[NSBezierPath bezierPathWithRect: indicatorRect] fill];
#else
	/* For debugging, this code draws it with a square look... */
	[[[NSColor keyboardFocusIndicatorColor] colorWithAlphaComponent: 0.8] setStroke];
	[NSBezierPath setDefaultLineWidth: 6.0];
	[NSBezierPath strokeRect: indicatorRect];
#endif

	[NSGraphicsContext restoreGraphicsState];
}

/** Returns the max allowed size to draw to the label.

When the label size is superior to this max size, 
-rectForLabel:ofItem: will shrink the label drawing area to this size. */
- (void) setMaxLabelSize: (NSSize)aSize
{
	_maxLabelSize = aSize;
}

/** Sets the max allowed size to draw the label.

See also -maxLabelSize. */
- (NSSize) maxLabelSize
{
	return _maxLabelSize;
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

- (NSRect) rectForLabel: (NSString *)aLabel 
                inFrame: (NSRect)itemFrame 
                 ofItem: (ETLayoutItem *)anItem
{
	NSParameterAssert(nil != aLabel);
	NSParameterAssert(nil != anItem);

	NSSize labelSize = [aLabel sizeWithAttributes: _labelAttributes];
	float maxLabelWidth = (_maxLabelSize.width != ETNullSize.width ? _maxLabelSize.width : itemFrame.size.width);
	float maxLabelHeight = (_maxLabelSize.height != ETNullSize.height ? _maxLabelSize.height : itemFrame.size.height);
	float labelSizeWidth = MIN(labelSize.width, maxLabelWidth);
	float labelSizeHeight = MIN(labelSize.height, maxLabelHeight);
	NSRect rect = ETNullRect;

	switch (_labelPosition)
	{
		case ETLabelPositionCentered:
			rect = ETCenteredRect(labelSize, itemFrame);
			break;
		case ETLabelPositionOutsideTop:
		{
			float labelBaseX = (itemFrame.size.width - labelSizeWidth) / 2;
			float labelBaseY = 0;

			if ([anItem isFlipped])
			{
				labelBaseY = - _labelMargin - labelSizeHeight;
			}
			else
			{
				labelBaseY = itemFrame.size.height + _labelMargin + labelSizeHeight;
			}
				
			rect = NSMakeRect(labelBaseX, labelBaseY, labelSizeWidth, labelSizeHeight);
			break;
		}
		case ETLabelPositionOutsideLeft:
		{
			float labelBaseY = 0;
			// TODO: Support max label size in a better way rather than only 
			// allowing a width equal to the item width when no max size is set.

			if ([anItem isFlipped])
			{
				labelBaseY = itemFrame.size.height;
			}

			rect = NSMakeRect(itemFrame.size.width + _labelMargin, labelBaseY, labelSizeWidth, labelSizeHeight);
			break;
		}
		case ETLabelPositionInsideBottom:
		{
			float labelBaseX = (itemFrame.size.width - labelSizeWidth) / 2;
			float labelBaseY = 0;

			if ([anItem isFlipped])
			{
				labelBaseY = itemFrame.size.height - labelSizeHeight - _edgeInset;
			}
			else
			{
				labelBaseY = _edgeInset;
			}

			rect = NSMakeRect(labelBaseX, labelBaseY, labelSizeWidth, labelSizeHeight);
			break;
		}
		case ETLabelPositionOutsideBottom:
		{
			float labelBaseX = (itemFrame.size.width - labelSizeWidth) / 2;
			float labelBaseY = 0;

			if ([anItem isFlipped])
			{
				labelBaseY = itemFrame.size.height + _labelMargin + labelSizeHeight;
			}
			else
			{
				labelBaseY = - _labelMargin - labelSizeHeight;
			}
				
			rect = NSMakeRect(labelBaseX, labelBaseY, labelSizeWidth, labelSizeHeight);
			break;
		}
		case ETLabelPositionNone:
			return NSZeroRect;
		default:
			ASSERT_INVALID_CASE;
			return NSZeroRect;
	}

	return rect;
}

/** Returns the string to be used as the label to draw.

When the given item has a view or a layout, returns the item name which might be 
nil, otherwise returns thedisplay name which is never nil. This behavior 
ensures no label is drawn when the item uses a custom view (such as a widget) 
or a layout, unless you explicitly set one with -[ETLayoutItem setName:]. */
- (NSString *) labelForItem: (ETLayoutItem *)anItem
{
	NSString *label = nil;
	ETLayout *layout = [anItem layout];

	// TODO: We probably want extra flexibility. e.g. kETShouldDrawGroupLabelHint 
	// set by the parent item in inputValues based on the layout. 
	// ETLayoutItemGroup might want to query the layout with 
	// -[ETLayout shouldLayoutContextDraws(All)ItemLabel].

	// TODO: Remove nil layout check once ETNullLayout is used everywhere.
	if ((nil != layout && NO == [layout isNull]) || [anItem view] != nil)
	{
		label = [anItem name];
	}
	else
	{
		label = [anItem displayName];
	}

	return label;
}

/** Returns the size required to present the item image (at the given size) and 
label, without scaling the image down and trimming the label while respecting 
the max image size and the max label size.

The computed size can be either greather and lesser than the existing item size.

You can use the returned size to resize the item without moving it with 
-[ETLayoutItem setSize:] or alternatively computes a bouding box and sets it 
with -[ETLayoutItem setBoundingBox:]. */
- (NSSize) boundingSizeForItem: (ETLayoutItem *)anItem imageSize: (NSSize)imgSize
{
	NSParameterAssert(nil != anItem);

	float maxImgWidth = (_maxImageSize.width != ETNullSize.width ? _maxImageSize.width : imgSize.width);
	float maxImgHeight = (_maxImageSize.height != ETNullSize.height ? _maxImageSize.height : imgSize.height);
	float imgWidth = MIN(imgSize.width, maxImgWidth);
	float imgHeight = MIN(imgSize.height, maxImgHeight);

	NSSize labelSize = [[self labelForItem: anItem] sizeWithAttributes: _labelAttributes];
	float maxLabelWidth = (_maxLabelSize.width != ETNullSize.width ? _maxLabelSize.width : labelSize.width);
	float maxLabelHeight = (_maxLabelSize.height != ETNullSize.height ? _maxLabelSize.height : labelSize.height);
	float labelWidth = MIN(labelSize.width, maxLabelWidth);
	float labelHeight = MIN(labelSize.height, maxLabelHeight);

	float insetSpace = _edgeInset * 2;

	switch (_labelPosition)
	{
		case ETLabelPositionNone:
		case ETLabelPositionContentAspect:
		{
			return [anItem size];
		}
		/* We ignore the label margin in that case */	
		case ETLabelPositionCentered:
		{
			float width = MAX(labelWidth, imgWidth);
			float height = MAX(labelHeight, imgHeight);

			return NSMakeSize(width + insetSpace, height + insetSpace);
		}
		case ETLabelPositionInsideTop:
		case ETLabelPositionOutsideTop:
		case ETLabelPositionInsideBottom:
		case ETLabelPositionOutsideBottom:
		{
			float width = MAX(labelWidth, imgWidth);
			/* In ETLabelPositionOutsideBottom/Top, the bottom edge inset is between 
			   the image and the label margin but the final height is the same.
			   The height computation below corresponds to ETLabelPositionInsideBottom. */
			float height = imgHeight + _labelMargin + labelHeight;

			return NSMakeSize(width + insetSpace, height + insetSpace);
		}
		case ETLabelPositionInsideLeft:
		case ETLabelPositionOutsideLeft:
		case ETLabelPositionInsideRight:
		case ETLabelPositionOutsideRight:
		{
			/* In ETLabelPositionOutsideLeft/Right, the left edge inset is between 
			   the image and the label margin but the final width is the same.
			   The width computation below corresponds to ETLabelPositionInsideLeft. */
			float width = imgWidth + _labelMargin + labelWidth;
			float height = MAX(labelHeight, imgHeight);

			return NSMakeSize(width + insetSpace, height + insetSpace);
		}
		default:
			ASSERT_INVALID_CASE;
			return NSZeroSize;
	}
}

/** <override-dummy />
Returns the image to be drawn.

When the given item has a view or a layout, returns nil, otherwise returns the 
item icon which is never nil. This behavior ensures no image is drawn when the 
item uses a custom view (such as a widget) or a layout.

You can override this method to return any item or represented object property 
which corresponds to an image. Don't access the represented object directly 
but through [anItem valueForProperty:].

See also -[ETLayoutItem icon]. */
- (NSImage *) imageForItem: (ETLayoutItem *)anItem
{
	ETLayout *layout = [anItem layout];

	// TODO: Remove nil layout check once ETNullLayout is used everywhere.
	if ((nil != layout && NO == [layout isNull]) || nil != [anItem view])
		return nil;

	return [anItem icon];
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
	NSRect labelRect = [self rectForLabel: [self labelForItem: anItem] 
	                              inFrame: [anItem frame]
	                               ofItem: anItem];
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

	// TODO: Write the missing cases...
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

// TODO: We could add an extra parameter to override the image scaling policy 
// (i.e. ETContentAspectScaleToFit) used when the item content aspect is computed.
// For example -rectForImage:ofItem:withLabelRect:scalingHint: (ETContentAspect)imgAspect
// We don't know yet whether subclasses that override -render:layoutItem:dirtyRect:
// might want this extra flexibility.

/** Returns the image drawing area in the given item content bounds.

When the item content aspect is set to ETContentAspectComputed, the image rect
is limited to -imageMaxSize and resized proportionally to occupy as much space 
as possible while letting enough room to the label rect (label margin included).<br />
If the label position is not inside or the content aspect is not computed, the 
label area is simply ignored.

The edge inset is taken in account in all cases, even when the content aspect 
is not computed. */
- (NSRect) rectForImage: (NSImage *)anImage 
                 ofItem: (ETLayoutItem *)anItem
          withLabelRect: (NSRect)labelRect
{
	NSRect contentBounds = [anItem contentBounds];
	NSRect insetContentRect = NSInsetRect(contentBounds, _edgeInset, _edgeInset);
	ETContentAspect contentAspect = [anItem contentAspect];

	if (ETContentAspectComputed == contentAspect)
	{
		NSSize imageAreaSize = insetContentRect.size;

		switch (_labelPosition)
		{
			case ETLabelPositionCentered:
				break;
			case ETLabelPositionInsideLeft:
			case ETLabelPositionInsideRight:
			{
				imageAreaSize.width -= labelRect.size.width + _labelMargin;	
				break;
			}
			case ETLabelPositionInsideTop:
			case ETLabelPositionInsideBottom:
			{
				imageAreaSize.height -= labelRect.size.height + _labelMargin;	
				break;
			}
			case ETLabelPositionOutsideLeft:
			case ETLabelPositionOutsideTop:
			case ETLabelPositionOutsideRight:
			case ETLabelPositionOutsideBottom:
			case ETLabelPositionNone:
				break;
			default:
				ASSERT_INVALID_CASE;
		}

		NSSize maxSize = NSEqualSizes(_maxImageSize, ETNullSize) ? imageAreaSize : _maxImageSize;
		NSRect imageRect = [anItem contentRectWithRect: ETMakeRect(NSZeroPoint, [anImage size])
		                                 contentAspect: ETContentAspectScaleToFit
	                                        boundsSize: maxSize];
									 
		return [self rectForAreaSize: imageRect.size
							  ofItem: anItem
					   withLabelRect: labelRect];
	}
	else
	{
		// FIXME: We lost the edge inset at the origin here. Probably rename 
		// boundsSize: method keyword to boundingRect: so we can pass insetContentRect.
		return [anItem contentRectWithRect: ETMakeRect(NSZeroPoint, [anImage size])
		                     contentAspect: contentAspect
	                            boundsSize: insetContentRect.size];
	}

	/*ETLog(@"Image size %@ to %@", NSStringFromSize([anImage size]), NSStringFromRect(imageRect));
	ETLog(@" -- %@", NSStringFromRect([self rectForAreaSize: imageRect.size
	                      ofItem: anItem
	               withLabelRect: labelRect]));*/
}

/** <override-never />
Returns the view drawing area in the given item content bounds. */
- (NSRect) rectForViewOfItem: (ETLayoutItem *)anItem
{
	NSRect labelRect = [self rectForLabel: [self labelForItem: anItem] 
	                              inFrame: [anItem frame] 
	                               ofItem: anItem];
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


@implementation ETFieldEditorItemStyle

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	[self drawFirstResponderIndicatorInRect: [item drawingFrame]];
}

@end
