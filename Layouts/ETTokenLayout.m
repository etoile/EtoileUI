/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import "ETTokenLayout.h"
#import "ETBasicItemStyle.h"
#import "ETComputedLayout.h"
#import "ETEvent.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "EtoileUIProperties.h"
#import "ETSelectTool.h"
#import "ETCompatibility.h"

// TODO: Find a better name...
@interface ETSelectAndClickTool : ETSelectTool
@end


@implementation ETTokenLayout

/** <init />
Initializes and returns a new icon layout. */
- (id) init
{
	SUPERINIT
	
	_maxTokenWidth = [[self class] defaultMaxTokenWidth];

	[self setAttachedTool: [ETSelectAndClickTool tool]];
	[[self attachedTool] setShouldRemoveItemsAtPickTime: NO];

	ETLayoutItem *templateItem = [[ETLayoutItemFactory factory] item];
	ETTokenStyle *tokenStyle = [ETTokenStyle new];

	[self setTemplateItem: templateItem];
	[templateItem setCoverStyle: tokenStyle];
	[templateItem setActionHandler: [ETTokenActionHandler sharedInstance]];
	/* Will delegate the icon/image rect computation to the icon style rather 
	   than stretching it. */
	[templateItem setContentAspect: ETContentAspectComputed];
	/* Icon must precede Style and View to let us snapshot the item in its 
	   initial state. See -setUpTemplateElementWithNewValue:forKey:inItem:
	   View must also be restored after Content Aspect, otherwise the view 
	   geometry computation occurs two times when the items are restored. */
	[self setTemplateKeys: A(@"icon", @"coverStyle", @"actionHandler", @"contentAspect", @"view")];

	[[self positionalLayout] setBorderMargin: 2];
	[[self positionalLayout] setItemMargin: 4];

	return self;
}

DEALLOC(DESTROY(_itemLabelFont))

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETTokenLayout *layoutCopy = [super copyWithZone: aZone layoutContext: ctxt];
	
	layoutCopy->_itemLabelFont = [_itemLabelFont copyWithZone: aZone];
	layoutCopy->_maxTokenWidth = _maxTokenWidth;

	return layoutCopy;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"picture--pencil.png"];
}

- (void) setItemTitleFont: (NSFont *)font
{
	ASSIGN(_itemLabelFont, font);
}

/** <override-dummy />
Returns the height used to size the token items.

By default, returns 20.

See also -setMaxTokenWidth:. */
+ (CGFloat) defaultTokenHeight
{
	return 18.;
}

/** Returns the minimum token width allowed.
 
See also -setMaxTokenWidth:. */
+ (CGFloat) defaultMinTokenWidth
{
	return 45.;
}

/** Returns 200.
 
 See also -setMaxTokenWidth:. */
+ (CGFloat) defaultMaxTokenWidth
{
	return 200.;
}

/** Returns the maximum token width allowed.
 
By default, returns -defaultMaxTokenWidth.
 
See also -resizeLayoutItems:toScaleFactor:. */
- (CGFloat) maxTokenWidth
{
	return _maxTokenWidth;
}

/** Sets the maximum token width allowed.
 
See also -maxTokenWidth. */
- (void) setMaxTokenWidth: (CGFloat)aWidth
{
	_maxTokenWidth = aWidth;
}

/* -[ETTemplateLayout renderLayoutItems:isNewContent:] doesn't invoke 
-resizeLayoutItems:toScaleFactor: unlike ETLayout, hence we override this method 
to trigger the resizing before ETTemplateItemLayout hands the items to the 
positional layout. */
- (void) willRenderItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	float scale = [_layoutContext itemScaleFactor];
	if (isNewContent || scale != _previousScaleFactor)
	{
		[self resizeLayoutItems: items toScaleFactor: scale];
		_previousScaleFactor = scale;
	}
}

- (CGFloat) tokenWidthForItem: (ETLayoutItem *)item tokenStyle: (ETTokenStyle *)tokenStyle
{
	CGFloat labelBasedWidth = [tokenStyle boundingSizeForItem: item
	                                          imageOrViewSize: NSZeroSize].width;
	
	if (labelBasedWidth > [self maxTokenWidth])
	{
		return [self maxTokenWidth];
	}
	else if (labelBasedWidth < [[self class] defaultMinTokenWidth])
	{
		return [[self class] defaultMinTokenWidth];
	}
	return labelBasedWidth;
}

/** Resizes every item by delegating it to 
 -[ETTokenStyle boundingSizeForItem:imageSize:].
 
For now, the scale factor is ignored.

Unlike the inherited implementation, the method ignores every ETLayout 
constraints that might be set such as -constrainedItemSize and 
-itemSizeConstraintStyle.

When the computed token width is greater than -maxTokenWidth, the latter value 
becomes the token width.

The resizing isn't delegated to the positional layout unlike in ETTemplateItemLayout. */
- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	id <ETFirstResponderSharingArea> editionCoordinator = 
		[[ETTool activeTool] editionCoordinatorForItem: _layoutContext];

	/* We use -arrangedItems in case we receive only a subset to resize (not true currently) */
	if ([[_layoutContext arrangedItems] containsObject: [editionCoordinator editedItem]])
	{
		[editionCoordinator removeActiveFieldEditorItem];
	}

	ETTokenStyle *tokenStyle = [[self templateItem] coverStyle];
	CGFloat tokenHeight = [[self class] defaultTokenHeight];

	/* We expect all the items to use the same style object */
	//NSParameterAssert([[items firstObject] coverStyle] == tokenStyle);

	for (ETLayoutItem *item in items)
	{
		CGFloat tokenWidth = [self tokenWidthForItem: item tokenStyle: tokenStyle];
		[item setSize: NSMakeSize(tokenWidth, tokenHeight)];
	}
}

@end


@implementation ETTokenStyle

+ (NSDictionary *) standardLabelAttributes
{
	return D([NSFont labelFontOfSize: 12], NSFontAttributeName);
}

+ (NSColor *) defaultTintColor
{
	return [[NSColor colorWithCalibratedRed: 0.5 green: 0.1 blue: 0.7 alpha: 0.8] highlightWithLevel: 0.6];
}

- (id) init
{
	SUPERINIT

	ASSIGN(_tintColor, [[self class] defaultTintColor]);
	[self setSelectedAttributesFromAttributes: [self labelAttributes]];

	NSSize maxLabelSize = [self maxLabelSize];

	maxLabelSize.width = 150;
	[self setMaxLabelSize: maxLabelSize];
	[self setLabelPosition: ETLabelPositionCentered];
	[self setLabelMargin: 8];
	[self setEdgeInset: 7];

	return self;
}

- (void) dealloc
{
	DESTROY(_tintColor);
	DESTROY(_selectedLabelAttributes);
	[super dealloc];
}

- (id) copyWithCopier: (ETCopier *)aCopier
{
	ETTokenStyle *newStyle = [super copyWithCopier: aCopier];
	
	if ([aCopier isAliasedCopy])
		return newStyle;
	
	[aCopier beginCopyFromObject: self toObject: newStyle];
	
	newStyle->_tintColor = [_tintColor copyWithZone: [aCopier zone]];
	newStyle->_selectedLabelAttributes = [_selectedLabelAttributes copyWithZone: [aCopier zone]];

	[aCopier endCopy];
	return newStyle;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"document-tag.png"];
}

/** Always returns the item display name. */
- (NSString *) labelForItem: (ETLayoutItem *)anItem
{
	return [anItem displayName];
}

/** Always returns nil. */
- (NSImage *) imageForItem: (ETLayoutItem *)anItem
{
	return nil;
}

- (void) setTintColor: (NSColor *)color
{
	ASSIGN(_tintColor, color);
}

- (NSColor *) tintColor
{
	return _tintColor;
}

- (void) render: (NSMutableDictionary *)inputValues
     layoutItem: (ETLayoutItem *)item
	  dirtyRect: (NSRect)dirtyRect
{
	// TODO: Perhaps add a method -drawBackgroundInRect: to ETBasicItemStyle

	// FIXME: May be we should better support dirtyRect. The next drawing
	// methods don't take in account it and simply redraw all their content.
	NSRect labelRect = NSZeroRect;
	
	NSRect bounds = [item drawingBoundsForStyle: self];
	NSString *itemLabel = [self labelForItem: item];
	
	if (nil != itemLabel)
	{
		labelRect = [self rectForLabel: itemLabel
		                               inFrame: bounds
		                                ofItem: item];
	}

	[self drawRoundedTokenInRect: [item drawingBoundsForStyle: self]
	                  isSelected: [self drawsItemAsSelected: item]];

	if (nil != itemLabel)
	{
		[self drawLabel: itemLabel attributes: [self labelAttributesForDrawingItem: item] flipped: [item isFlipped] inRect: labelRect];
	}
	
	/*if ([[[ETTool activeTool] firstKeyResponder] isEqual: item])
	{
		[self drawFirstResponderIndicatorInRect: bounds];
	}*/
}

- (void) setSelectedAttributesFromAttributes: (NSDictionary *)stringAttributes
{
	NSMutableDictionary *newAttributes = [[stringAttributes mutableCopy] autorelease];
	
	NSFont *font = [stringAttributes objectForKey: NSFontAttributeName];
	NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont: font
	                                                      toHaveTrait: NSBoldFontMask];

	[newAttributes setObject: boldFont forKey: NSFontAttributeName];
	[newAttributes setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];

	ASSIGNCOPY(_selectedLabelAttributes, newAttributes);
}

- (void) setLabelAttributes: (NSDictionary *)stringAttributes
{
	[super setLabelAttributes: stringAttributes];
	[self setSelectedAttributesFromAttributes: stringAttributes];
}

- (BOOL) drawsItemAsSelected: (ETLayoutItem *)item 
{
	// FIXME: We should pass a hint in inputValues that lets us known whether
	// we handle the selection visual clue or not, in order to eliminate the
	// hard check on ETFreeLayout...
	return ([item isSelected] && [[(ETLayoutItem *)[item parentItem] layout] isKindOfClass: NSClassFromString(@"ETFreeLayout")] == NO);
}

/** Draws a rounded rectangle that covers the given rect area. */
 - (void) drawRoundedTokenInRect: (NSRect)aRect isSelected: (BOOL)isSelected
{
	[NSGraphicsContext saveGraphicsState];

	CGFloat radius = (aRect.size.height / 2);
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: NSInsetRect(aRect, 0.5, 0.5)
	                                                     xRadius: radius
	                                                     yRadius: radius * 1.5];

	if (isSelected)
	{
		[[_tintColor shadowWithLevel: 0.8] setFill];
		[path fill];
		[[_tintColor shadowWithLevel: 0.8] setStroke];
		[path stroke];
	}
	else
	{
		[_tintColor setFill];
		[path fill];
		[[_tintColor shadowWithLevel: 0.2] setStroke];
		[path stroke];
	}

	[NSGraphicsContext restoreGraphicsState];
}

@end


@implementation ETTokenActionHandler

- (NSFont *) defaultFieldEditorFont
{
	return [NSFont labelFontOfSize: 12];
}

- (void) handleClickItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint
{
	ETBasicItemStyle *iconStyle = [item coverStyle];
	NSString *label = [iconStyle labelForItem: item];
	NSRect labelRect = [iconStyle rectForLabel: label
	                                   inFrame: [item frame]
	                                    ofItem: item];

	if (NSPointInRect(aPoint, labelRect) == NO)
		return;								

	NSSize labelSize = [label sizeWithAttributes: [iconStyle labelAttributes]];
	float lineHeight = labelSize.height;
	BOOL nbOfLines = 1;

	/* Limit the editing width to the max label width */
	if (labelSize.width > labelRect.size.width)
	{
		labelSize.width = labelRect.size.width;
		nbOfLines = 2;
		labelSize.height = lineHeight * nbOfLines; /* Add an extra line */
	}

	/* We need some extra width to fit the label into the field editor */
	labelSize.width += 11;

	/* Resize the field editor and compute its new location */
	labelRect.origin.x -= (labelSize.width - labelRect.size.width) * 0.5;
	// TODO: To be compensated in -beginEditingItem:property:inRect: when 
	// the window backed item is flipped.
	if ([item isFlipped] == NO)
	{
		labelRect.origin.y -= lineHeight * (nbOfLines - 1);
	}
	labelRect.size = labelSize;

	[self beginEditingItem: item property: kETNameProperty inRect: labelRect];
}

@end
