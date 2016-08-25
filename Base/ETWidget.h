/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>

// FIXME: Don't expose NSActionCell in the public API
@class NSActionCell;

/** @group Base
@abstract Widget Proxy Protocol

See -[ETLayoutItem widget]. */
@protocol ETWidget
@property (nonatomic, assign) id target;
@property (nonatomic) SEL action;
@property (nonatomic, strong) id objectValue;
- (void) takeObjectValueFrom: (id)sender;
- (id) objectValueForCurrentValue: (id)aValue;
- (id) currentValueForObjectValue: (id)aValue;
/** Returns the widget formatter.
 
If the widget is the item, then returns the formatter for -objectValue. 

See -setFormatter:. */
- (id) formatter;
/** Returns the widget formatter.
 
If the widget is the item, then sets the formatter for -objectValue. 
If you want to set multiple formatters per item, there are two options:
 
<list>
<item>put multiple items into to a common item group, each item presenting a 
distinct property</item>
<item>use a layout that implements -setFormatter:forProperty: and
-formatterForProperty: (or write a subclass to support these). For example,
-[ETTableLayout setFormatter:forProperty:].</item>
</list>
 
See -formatter: and -[ETLayoutItem valueTransformerForProperty:]. */
- (void) setFormatter: (NSFormatter *)aFormatter;
/** Returns the widget cell.

If the widget is the item, returns nil. */
@property (nonatomic, readonly) NSActionCell *cell;
@optional
/** Returns the widget title.
 
See -title. */
@property (nonatomic, copy) NSString *title;
/** Sets the widget title and resets the image position for a nil or empty title.
 
For example, a NSButton image position is reset to NSImageOnly.
 
See -setTitle: */
@property (nonatomic) double minValue;
@property (nonatomic) double maxValue;
@end
