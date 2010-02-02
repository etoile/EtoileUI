/**	<title>ETBasicItemStyle/title>

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

// TODO: Write correct enum doc
typedef enum
{
	ETLabelPositionNone, 
/** Lets the content aspect positions and resizes the title. */
	ETLabelPositionContentAspect, 
/** Lets the content as is. */
	ETLabelPositionCentered, 
	ETLabelPositionInsideLeft,
	ETLabelPositionOutsideLeft,
	ETLabelPositionInsideTop,
	ETLabelPositionOutsideTop,
	ETLabelPositionInsideRight,
	ETLabelPositionOutsideRight,
	ETLabelPositionInsideBottom,
	ETLabelPositionOutsideBottom
} ETLabelPosition;

/** ETBasicItemStyle is a very generic style that knows how to draw:
<list> 
<item>various basic ETLayoutItem properties when available (such as name, image 
etc.),</item>
<item>UI visual feedback such as selected state, first responder status, etc.</item>
</list>

ETBasicItemStyle shared instance is also the only style automatically inserted 
in -[ETLayoutItem styleGroup], when a new layout item is initialized.

Tailored items build by ETLayoutItemFactory might not use ETBasicItemStyle, but 
a custom style object.

You can control the label visibility with -setLabelPosition:, ETLabelPositionNone 
makes the label invisible. */
@interface ETBasicItemStyle : ETStyle
{
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

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;

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


@interface ETGraphicsGroupStyle : ETBasicItemStyle
{

}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
	  
- (void) drawBorderInRect: (NSRect)aRect;

@end

@interface ETFieldEditorItemStyle : ETBasicItemStyle
{

}

@end
