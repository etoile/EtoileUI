/**
	<abstract>A layout subclass that provides form-based presentation.</abstract>

	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETTemplateItemLayout.h>

/** Describes how the form is horizontally positioned inside the layout 
context.

ETFormLayout resets -[ETComputedLayout horizontalAlignment] to 
ETLayoutHorizontalAlignmentGuided, in order to right align the labels at the 
left of the guide, and to left align the views at the right of the guide. 
Which means we cannot use the positional layout to control how the whole content 
is aligned. */
typedef enum
{
	ETFormLayoutAlignmentCenter,
/** Centers the content horizontally in the layout context.

Also means the inset is interpreted as a left and right inset.  */
	ETFormLayoutAlignmentLeft,
/** Shifts the content as much as possible towards the left edge of the layout context.

Also means the inset is interpreted as a left inset. */
	ETFormLayoutAlignmentRight,
/** Shifts the content as much as possible towards the right edge of the layout context.

Also means the inset is interpreted as a right inset. */
} ETFormLayoutAlignment;

@interface ETFormLayout : ETTemplateItemLayout <ETAlignmentHint>
{
	@private
	ETFormLayoutAlignment _alignment;
	float highestLabelWidth;
	float _currentMaxLabelWidth;
	float _currentMaxItemWidth;
}

/** @taskunit Label and Form Alignment */

- (ETFormLayoutAlignment) alignment;
- (void) setAlignment: (ETFormLayoutAlignment)alignment;
- (NSFont *) itemLabelFont;
- (void) setItemLabelFont: (NSFont *)aFont;

/** @taskunit Shared Alignment Support */

- (float) alignmentHintForLayout: (ETLayout *)aLayout;
- (void) setHorizontalAlignmentGuidePosition: (float)aPosition;

@end
