/**	<title>ETStyle/title>

	<abstract>Base class to implement pluggable styles as subclasses and make 
	possible UI styling at runtime.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETObjectChain.h>
#import <EtoileFoundation/ETRendering.h>

@class ETLayoutItem;

/** ETStyle is an abstract base class that represents a style element.

EtoileUI pluggable styles are usually written by subclassing ETStyle.

Many classes in EtoileUI are subclasses of ETStyle whose instances are inserted 
in an ETStyleGroup object bound to a layout item. 

Each style can be asked to render or draw with -render:layoutItem:dirtyRect:. 
This method is usually called indirectly like that:
-[ETStyle render:layoutItem:dirtyRect:]
-[ETStyleGroup render:layoutItem:dirtyRect:]
-[ETLayoutItem render:dirtyRect:inContext:]
...
-[ETLayoutItem display] or similar redisplay methods.

ETStyle objects are usually shared between multiple style groups 
(or other owners) . Thereby they don't know on which UI areas they are applied 
and expect to be provided a layout item through -render:layoutItem:dirtyRect:. */
@interface ETStyle : NSObject <ETRendering, NSCopying>
{
	BOOL _isSharedStyle;
}

- (BOOL) isSharedStyle;

/* Copying */

- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone;

/* Style Rendering */

- (SEL) styleSelector;
- (void) render: (NSMutableDictionary *)inputValues;
- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
	  
- (void) didChangeItemBounds: (NSRect)bounds;

@end


/** ETBasicItemStyle is a very generic style that knows how to draw:
<list> 
<item>various basic ETLayoutItem properties when available (such as name, image 
etc.),</item>
<item>UI visual feedback such as selected state, first responder status, etc.</item>
</list>

ETBasicItemStyle shared instance is also the only style automatically inserted 
in -[ETLayoutItem styleGroup], when a new layout item is initialized.

Tailored items build by ETUIItemFactory might not use ETBasicItemStyle, but 
a custom style object. */
@interface ETBasicItemStyle : ETStyle
{
	BOOL _titleVisible;
}

+ (id) sharedInstance;

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;

- (void) drawImage: (NSImage *)itemImage 
           flipped: (BOOL)itemFlipped 
            inRect: (NSRect)aRect;	  
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;
- (void) drawStackIndicatorInRect: (NSRect)indicatorRect;
- (void) drawFirstResponderIndicatorInRect: (NSRect)indicatorRect;

// TODO: Implement
//- (BOOL) setTitleVisible: (BOOL)flag;
//- (BOOL) isTitleVisible;
//- (void) drawTitleInRect: (NSRect)aRect;

@end

@interface ETGraphicsGroupStyle : ETBasicItemStyle
{

}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
	  
- (void) drawBorderInRect: (NSRect)aRect;

@end

@interface ETDropIndicator : ETStyle
{
	NSPoint _dropLocation;
	ETLayoutItem *_hoveredItem;
	BOOL _dropOn;
	NSRect _prevInsertionIndicatorRect;
	NSRect _lastIndicatorRect;
}

- (id) initWithLocation: (NSPoint)dropLocation 
            hoveredItem: (ETLayoutItem *)hoveredItem
           isDropTarget: (BOOL)dropOn;

- (float) thickness;
- (NSColor *) color;

- (void) drawVerticalInsertionIndicatorInRect: (NSRect)indicatorRect;
- (void) drawRectangularInsertionIndicatorInRect: (NSRect)indicatorRect;
- (NSRect) previousIndicatorRect;
- (NSRect) currentIndicatorRect;

@end

@interface ETShadowStyle : ETStyle
{
	ETStyle *_content;
	id _shadow;
}
+ (id) shadowWithStyle: (ETStyle *)style;

@end

@interface ETTintStyle : ETStyle
{
	ETStyle *_content;
	NSColor *_color;
}

+ (id) tintWithStyle: (ETStyle *)style color: (NSColor *)color;
+ (id) tintWithStyle: (ETStyle *)style;
- (void) setColor: (NSColor *)color;
- (NSColor *) color;

@end