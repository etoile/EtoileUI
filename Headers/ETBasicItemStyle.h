/**	<title>ETBasicItemStyle</title>

	<abstract>Very generic style class to draw layout items.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETStyle.h>

@class ETLayoutItem;

/** Specifies the label position in the item drawing bounds as returned by 
-[ETLayoutItem drawingForStyle:] with the style to be drawn as argument.

See -setLabelPosition: and -labelPosition: */
typedef enum
{
/** Don't draw the label. */
	ETLabelPositionNone, 
/** Draw the label in a rect area computed based on the drawn item content aspect. 

See -[ETLayoutItem setContentAspect:] and ETContentAspect enum. */
	ETLabelPositionContentAspect, 
/** Draw the label right in the center of the item drawing bounds. */
	ETLabelPositionCentered, 
/** Draw the label close to the left border of the item drawing bounds and 
on the inner side. */
	ETLabelPositionInsideLeft,
/** Draw the label close to the left border of the item drawing bounds and 
on the outer side. */
	ETLabelPositionOutsideLeft,
/** Draw the label close to the top border of the item drawing bounds and 
on the inner side. */
	ETLabelPositionInsideTop,
/** Draw the label close to the top border of the item drawing bounds and 
on the outer side. */
	ETLabelPositionOutsideTop,
/** Draw the label close to the right border of the item drawing bounds and 
on the inner side. */
	ETLabelPositionInsideRight,
/** Draw the label close to the right border of the item drawing bounds and 
on the outer side. */
	ETLabelPositionOutsideRight,
/** Draw the label close to the bottom border of the item drawing bounds and 
on the inner side. */
	ETLabelPositionInsideBottom,
/** Draw the label close to the bottom border of the item drawing bounds and 
on the outer side. */
	ETLabelPositionOutsideBottom
} ETLabelPosition;

/** ETBasicItemStyle is a very generic style that knows how to draw:
<list> 
<item>various basic ETLayoutItem properties when available (such as name, image 
etc.),</item>
<item>UI visual feedback such as selected state, first responder status, etc.</item>
</list>

ETBasicItemStyle shared instance is also the only style automatically set 
as -[ETLayoutItem coverStyle], when a new layout item is initialized.

Tailored items build by ETLayoutItemFactory might not use ETBasicItemStyle, but 
a custom style object.

You can control the label visibility with -setLabelPosition:, ETLabelPositionNone 
makes the label invisible. */
@interface ETBasicItemStyle : ETStyle
{
	@private
	ETLabelPosition _labelPosition;
	float _labelMargin;
	NSDictionary *_labelAttributes;
	NSSize _maxLabelSize;
	NSSize _maxImageSize;
	float _edgeInset;
	NSRect _currentLabelRect;
	NSRect _currentImageRect;
}

+ (NSDictionary *) standardLabelAttributes;

+ (ETBasicItemStyle *) iconAndLabelBarElementStyle;
+ (ETBasicItemStyle *) styleWithLabelPosition: (ETLabelPosition)aPositionRule;

- (NSRect) currentLabelRect;
- (NSRect) currentImageRect;

/* Drawing */

- (void) drawImage: (NSImage *)itemImage 
           flipped: (BOOL)itemFlipped 
            inRect: (NSRect)aRect;
- (void) drawLabel: (NSString *)aLabel 
           flipped: (BOOL)itemFlipped 
            inRect: (NSRect)aRect;
- (void) drawStackIndicatorInRect: (NSRect)indicatorRect;
- (void) drawFirstResponderIndicatorInRect: (NSRect)indicatorRect;

/* Label */

- (void) setMaxLabelSize: (NSSize)aSize;
- (NSSize) maxLabelSize;
- (ETLabelPosition) labelPosition;
- (void) setLabelPosition: (ETLabelPosition)aPositionRule;
- (float) labelMargin;
- (void) setLabelMargin: (float)aMargin;
- (NSDictionary *) labelAttributes;
- (void) setLabelAttributes: (NSDictionary *)stringAttributes;

- (NSRect) rectForLabel: (NSString *)aLabel 
                inFrame: (NSRect)itemFrame 
                 ofItem: (ETLayoutItem *)anItem;
- (NSString *) labelForItem: (ETLayoutItem *)anItem;

/* Image */

- (NSImage *) imageForItem: (ETLayoutItem *)anItem;

- (NSSize) maxImageSize;
- (void) setMaxImageSize: (NSSize)aSize;

- (NSRect) rectForImage: (NSImage *)anImage 
                 ofItem: (ETLayoutItem *)anItem;
- (NSRect) rectForImage: (NSImage *)anImage 
                 ofItem: (ETLayoutItem *)anItem
          withLabelRect: (NSRect)labelRect;

/* View/Widget */

- (NSRect) rectForViewOfItem: (ETLayoutItem *)anItem;
- (NSRect) rectForViewOfItem: (ETLayoutItem *)anItem
               withLabelRect: (NSRect)labelRect;

- (float) edgeInset;
- (void) setEdgeInset: (float)anInset;

- (NSSize) boundingSizeForItem: (ETLayoutItem *)anItem imageOrViewSize: (NSSize)imgSize;
 
@end

/** ETGraphicsGroupStyle is a simple extension to ETBasicItemStyle that draws 
a border around a layout item.

You can use it in conjunction with ETLayoutItemGroup to show the boundaries of 
multiple graphics elements (shapes, images etc.) grouped together. e.g. in 
a graphics editor.

See also -[ETLayoutItemFactory graphicsGroup]. */
@interface ETGraphicsGroupStyle : ETBasicItemStyle
{

}

- (void) drawBorderInRect: (NSRect)aRect;

@end

/** ETFieldEditorItem is a simple extension to ETBasicItemStyle that draws 
a focus ring with -[ETBasicItemStyle drawFirstResponderIndicatorInRect:].

You can add it to -[ETLayoutItem styleGroup] when the item obtains the first 
responder status and remove it when the item gives up this status. */
@interface ETFieldEditorItemStyle : ETBasicItemStyle
{

}

@end
