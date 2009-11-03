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
a custom style object. */
@interface ETBasicItemStyle : ETStyle
{
	ETLabelPosition _labelPosition;
	float _labelMargin;
	BOOL _labelVisible;
	NSDictionary *_labelAttributes;
	NSSize _maxImageSize;
	float _edgeInset;
}

+ (NSDictionary *) standardLabelAttributes;

+ (ETBasicItemStyle *) iconAndLabelBarElementStyle;

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;

/* Drawing */

- (void) drawImage: (NSImage *)itemImage 
           flipped: (BOOL)itemFlipped 
            inRect: (NSRect)aRect;
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;
- (void) drawStackIndicatorInRect: (NSRect)indicatorRect;
- (void) drawFirstResponderIndicatorInRect: (NSRect)indicatorRect;

/* Label */

- (ETLabelPosition) labelPosition;
- (void) setLabelPosition: (ETLabelPosition)aPositionRule;
- (NSDictionary *) labelAttributes;
- (void) setLabelAttributes: (NSDictionary *)stringAttributes;
- (NSRect) rectForLabel: (NSString *)aLabel ofItem: (ETLayoutItem *)anItem;
- (NSString *) labelForItem: (ETLayoutItem *)anItem;
// TODO: Implement
//- (BOOL) setLabelVisible: (BOOL)flag;
//- (BOOL) isLabelVisible;

/* Image & View */

- (NSSize) maxImageSize;
- (void) setMaxImageSize: (NSSize)aSize;
- (NSRect) rectForImage: (NSImage *)anImage 
                 ofItem: (ETLayoutItem *)anItem;
- (NSRect) rectForImage: (NSImage *)anImage 
                 ofItem: (ETLayoutItem *)anItem
          withLabelRect: (NSRect)labelRect;
- (NSRect) rectForViewOfItem: (ETLayoutItem *)anItem;
- (NSRect) rectForViewOfItem: (ETLayoutItem *)anItem
               withLabelRect: (NSRect)labelRect;

- (float) edgeInset;
- (void) setEdgeInset: (float)anInset;

@end


@interface ETGraphicsGroupStyle : ETBasicItemStyle
{

}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
	  
- (void) drawBorderInRect: (NSRect)aRect;

@end
