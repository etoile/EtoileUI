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

/** ETFormLayout is a layout that allows to present an existing item tree in a 
form UI.

Form UI is UI pattern that present labelled widgets or views in a column. 
Usually the label is positioned on the left and the widget or view on the right.
 
By default, ETFormLayout uses a ETColumnLayout as its positional layout. To 
ensure all the form UI items are visible without manually resizing the item 
group bound to ETFormLayout, you can do the following:
 
<example>
[[[self positionalLayout] setIsContentSizeLayout: YES];
</example>

You can control the overall form alignment using -setFormAlignement:. 

ETFormLayout lets you control the built form precisely. The first time a 
ETFormLayout is updated using -renderLayoutItems:isNewContent:, it calls 
-[ETTemplateItemLayout prepareNewItems:]. All the item changes made at this time 
remains until the layout is removed or -restoreAllItems is called.<br />
If new layout updates occur, these item adjustments are not recomputed, the 
positional layout just receives the update and recompute the item positions as 
usual.
 
As explained in ETTemplateItemLayout,
-[ETTemplateItemLayout setUpTemplateElementsForItem:] overrides the item 
properties based on -templateItem and -templateKeys. For each template key, 
the template item value bound to this key is mirrored on the item (using 
Key-Value-Coding).
 
Some form arrangements are common:

<list>
<item>Centered and untouched item widths</item>
<item>Left aligned and flexible item widths</item>
<item>Left aligned and fixed item widths</item>
</list>
 
These arrangements can be reproduced by setting <em>width</em> and/or
<em>autoresizingMask</em> as template keys and proper values on the template 
item.
 
For the first case (as commonly in Mac OS X preferences panel), there is nothing 
to do, it is the default settings. Just create a ETFormLayout and assign it.

For the second case (as seen in Xcode 4 inspector):

<example>
ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factoryWithObjectGraphContext: someContext];
ETLayoutItemGroup *paneItem = [itemFactory itemGroup];
ETFormLayout *layout = [ETFormLayout layoutWithObjectGraphContext: someContext];

[layout setAlignment: ETFormLayoutAlignmentLeft];
[[layout templateItem] setAutoresizingMask: ETAutoresizingFlexibleWidth];
[layout setTemplateKeys: [[layout templateKeys] arrayByAddingObject: kETAutoresizingMaskProperty]];
 
[paneItem setLayout: layout];
</example> 
 
For the third case:

<example>
ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factoryWithObjectGraphContext: someContext];
ETLayoutItemGroup *paneItem = [itemFactory itemGroup];
ETFormLayout *layout = [ETFormLayout layoutWithObjectGraphContext: someContext];
 
[layout setAlignment: ETFormLayoutAlignmentLeft];
[[layout templateItem] setWidth: 250];
[layout setTemplateKeys: [[layout templateKeys] arrayByAddingObject: kETWidthProperty]];
 
[paneItem setLayout: layout];
</example>
 
If you customize both the autoresizing mask and the width, this means the items 
are all resized to the same width -setUpTemplateElementsForItem:, but their 
width remain flexible in case the UI is resized later. */
@interface ETFormLayout : ETTemplateItemLayout <ETAlignmentHint>
{
	@private
	ETFormLayoutAlignment _alignment;
	CGFloat highestLabelWidth;
	CGFloat _currentMaxLabelWidth;
	CGFloat _currentMaxItemWidth;
}

/** @taskunit Label and Form Alignment */

- (ETFormLayoutAlignment) alignment;
- (void) setAlignment: (ETFormLayoutAlignment)alignment;
- (NSFont *) itemLabelFont;
- (void) setItemLabelFont: (NSFont *)aFont;

/** @taskunit Shared Alignment Support */

- (CGFloat) alignmentHintForLayout: (ETLayout *)aLayout;
- (CGFloat) maxCombinedBoundingWidth;
- (void) setHorizontalAlignmentGuidePosition: (CGFloat)aPosition;

@end
