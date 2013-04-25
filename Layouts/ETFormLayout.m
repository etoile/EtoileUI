/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/Macros.h>
#import "ETFormLayout.h"
#import "ETBasicItemStyle.h"
#import "ETColumnLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETCompatibility.h"


@implementation ETFormLayout

- (id) init
{
	SUPERINIT

	ETLayoutItem *templateItem = [[ETLayoutItemFactory factory] item];;
	ETBasicItemStyle *formStyle = AUTORELEASE([[ETBasicItemStyle alloc] init]);

	[self setTemplateItem: templateItem];
	[formStyle setLabelPosition: ETLabelPositionOutsideLeft];
	[formStyle setLabelMargin: 10];
	[templateItem setCoverStyle: formStyle];

	[self setTemplateKeys: A(@"coverStyle")];
	[self setPositionalLayout: [ETColumnLayout layout]];
	[[self positionalLayout] setBorderMargin: 4];
	[[self positionalLayout] setItemMargin: 4];
	// TODO: As an option... Forms should support resizing themselves automatically based on their content.
	//[[(id)[self positionalLayout] ifResponds] setIsContentSizeLayout: YES];

	_alignment = ETFormLayoutAlignmentCenter;

	return self;
}

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETFormLayout *layoutCopy = [super copyWithZone: aZone layoutContext: ctxt];

	layoutCopy->_alignment = _alignment;

	return layoutCopy;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"ui-scroll-pane-form"];
}

- (float) maxLabelWidth
{
	return 300;
}

- (ETFormLayoutAlignment) alignment
{
	return _alignment;
}

- (void) setAlignment: (ETFormLayoutAlignment)alignment
{
	_alignment = alignment;
}

- (NSFont *) itemLabelFont
{
	NSDictionary *attributes = [[[[self templateItem] coverStyle] ifResponds] labelAttributes];

	if (attributes == nil)
		return nil;

	return [NSFont fontWithName: [attributes objectForKey: NSFontAttributeName]
	                       size: [[attributes objectForKey: NSFontSizeAttribute] floatValue]];
}

- (void) setItemLabelFont: (NSFont *)aFont
{
	ETAssert([[[self templateItem] coverStyle] isKindOfClass: [ETBasicItemStyle class]]);
	NSMutableDictionary *attributes = [[[[[self templateItem] coverStyle]
		labelAttributes] mutableCopy] autorelease];

	if (attributes == nil)
		return;

	[attributes setObject: [aFont fontName] forKey: NSFontAttributeName];
	[attributes setObject: [NSNumber numberWithFloat: [aFont pointSize]] forKey: NSFontSizeAttribute];

	[[[self templateItem] coverStyle] setLabelAttributes: attributes];
}

/* -[ETTemplateLayout renderLayoutItems:isNewContent:] doesn't invoke 
-resizeLayoutItems:toScaleFactor: unlike ETLayout, hence we override this method 
to trigger the resizing before ETTemplateItemLayout hands the items to the 
positional layout. */
- (void) willRenderItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	float scale = [[self layoutContext] itemScaleFactor];

	if (isNewContent || scale != _previousScaleFactor)
	{
		[self resizeLayoutItems: items toScaleFactor: scale];
		_previousScaleFactor = scale;
	}
	[self adjustAlignmentForMaxLabelWidth: _currentMaxLabelWidth
	                         maxItemWidth: _currentMaxItemWidth];
}

/** Resizes every item to the given scale by delegating it to 
-[ETBasicItemStyle boundingSizeForItem:imageOrViewSize:].

Unlike the inherited implementation, the method ignores every ETLayout 
constraints that might be set such as -constrainedItemSize and 
-itemSizeConstraintStyle.<br />

The resizing isn't delegated to the positional layout unlike in ETTemplateItemLayout. */
- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	_currentMaxLabelWidth = 0;
	_currentMaxItemWidth = 0;

	/* Scaling is always computed from the base image size (scaleFactor equal to 
	   1) in order to avoid rounding error that would increase on each scale change. */
	FOREACH(items, item, ETLayoutItem *)
	{
		/* When no view is present, we use the item size to get a valid 
		   boundingSize and be able to compute labelWidth */
		NSSize viewOrItemSize = ([item view] != nil ? [[item view] frame].size : [item size]);
		ETAssert([item coverStyle] != nil);
		NSSize boundingSize = [[item coverStyle] boundingSizeForItem: item 
		                                             imageOrViewSize: viewOrItemSize];
		NSRect boundingBox = ETMakeRect(NSZeroPoint, boundingSize);
		float labelWidth = boundingSize.width - [item width];

		if (labelWidth > _currentMaxLabelWidth)
		{
			_currentMaxLabelWidth = labelWidth;
		}
		if (viewOrItemSize.width > _currentMaxItemWidth)
		{
			_currentMaxItemWidth = viewOrItemSize.width;
		}

		// TODO: May be better to compute that in -[ETBasicItemStyle boundingBoxForItem:]
		boundingBox.origin.x = -boundingSize.width + [item width];
		boundingBox.origin.y = -boundingSize.height + [item height];
		[item setBoundingBox: boundingBox];
	}
}

- (void) adjustAlignmentForMaxLabelWidth: (float)maxLabelWidth
                            maxItemWidth: (float)maxItemWidth
{
	/* For this method, the bounding box width is the item frame width summed
	   with the label width (positioned to the left outside).

	   The combined bounding width below sums the widest item frame and label 
	   width, both frame and label can belong to distinct items. From this 
	   aggregate width, we compute the remaining space on the left and right,  
	   then the horizontal guide position (for ETColumnLayout). */
	float maxCombinedBoundingWidth = maxLabelWidth + maxItemWidth;

	float remainingSpace = [self layoutContext].size.width - maxCombinedBoundingWidth;
	float inset = 0; /* ETFormLayoutAlignmentLeft */
	
	if ([self alignment] == ETFormLayoutAlignmentCenter)
	{
		inset = remainingSpace * 0.5;
	}
	else if ([self alignment] == ETFormLayoutAlignmentRight)
	{
		inset = remainingSpace;
	}

	[self setHorizontalAlignmentGuidePosition: inset + maxLabelWidth];
}

- (float) alignmentHintForLayout: (ETComputedLayout *)aLayout
{
	return [(ETComputedLayout *)[self positionalLayout] horizontalAlignmentGuidePosition];
}

- (void) setHorizontalAlignmentGuidePosition: (float)aPosition
{
	//NSLog(@"New guide position %0.2f for %@", aPosition, [[self layoutContext] identifier]);
	[[self positionalLayout] setHorizontalAlignmentGuidePosition: aPosition];
}

@end
