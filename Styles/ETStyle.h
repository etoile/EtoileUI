/**
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETCompatibility.h>
#import <EtoileUI/ETUIObject.h>

@class COObjectGraphContext;
@class ETLayoutItem;

/** @abstract Base class to implement pluggable styles as subclasses and make
 possible UI styling at runtime.
 
ETStyle is an abstract base class that represents a style element.

EtoileUI pluggable styles are usually written by subclassing ETStyle.

Many classes in EtoileUI are subclasses of ETStyle whose instances are inserted 
in an [ETStyleGroup] object bound to a layout item. 

Each style can be asked to render or draw with -render:layoutItem:dirtyRect:. 
This method is usually called indirectly like that:

<list>
<item>-[ETStyle render:layoutItem:dirtyRect:]</item>
<item>-[ETStyleGroup render:layoutItem:dirtyRect:]</item>
<item>-[ETLayoutItem render:dirtyRect:inContext:]</item>
<item>...</item>
<item>-[ETLayoutItem display] or similar redisplay methods.</item>
</list>

ETStyle objects are usually shared between multiple style groups 
(or other owners) . Thereby they don't know on which UI areas they are applied 
and expect to be provided a layout item through -render:layoutItem:dirtyRect:.

@section Initialization

For new instances, you should usually use +sharedInstanceForObjectGraphContex: 
rather than -initWithObjectGraphContext:.  */
@interface ETStyle : ETUIObject
{
	@private
	BOOL _isShared;
}

/** @taskunit Aspect Registration */

+ (void) registerAspects;
+ (void) registerStyle: (ETStyle *)aStyle;
+ (NSSet *) registeredStyles;
+ (NSSet *) registeredStyleClasses;

/** @taskunit Aspect Sharing */

- (BOOL) isShared;
- (void) setIsShared: (BOOL)shared;

/** @taskunit Style Rendering */

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
      dirtyRect: (NSRect)dirtyRect;

/** @taskunit Drawing Primitives */
	  
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;

/** @taskunit Notifications */
	  
- (void) didChangeItemBounds: (NSRect)bounds;

@end
