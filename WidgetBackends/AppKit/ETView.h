/** <title>ETView</title>
	
	<abstract>Supervisor view class used to build view-backed items.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETFlippableView.h>

@class ETLayoutItem, ETUIItem;

/** ETView is the generic view class extensively used by EtoileUI and whose 
instance are named 'supervisor view'.

An ETView instance is bound to a layout item or a decorator item unlike NSView 
instances. ETLayoutItem automatically wraps any view you set with -setView: into 
a supervisor view.
	
The supervisor view is a wrapper that allows EtoileUI to intercept the drawing 
process. ETView delegates the drawing to its item in the -render:  method.<br />
More importantly, -render: isn't truly a delegated version of -drawRect:. 
This method makes possible to draw directly over the subviews rather than 
beneath. This drawing path is widely used in EtoileUI.
	
You must not subclass ETView.

Take note that we plan to eliminate ETView and the supervisor view concept in a 
next EtoileUI release. */
@interface ETView : ETFlippableView
{
	@private
	IBOutlet ETUIItem * __weak item;
	// NOTE: May be remove the view ivars to make the class more lightweight
	NSView *_wrappedView;
	/* _temporaryView is a weak reference (we retain it indirectly as a subview 
	   though).
	   We are owned by our layout item which retains its layout which itself 
	   retains the layout view. Each time the layout is switched on -layoutItem, 
	   we must update _temporaryView with -setLayoutView: otherwise the ivar
	   might reference a freed object. See -[ETLayoutItem setLayout:]. */
	NSView * __weak _temporaryView;
#ifndef GNUSTEP
	BOOL _wasJustRedrawn;
#endif
	NSRect _rectToRedraw;
}

- (SEL) defaultItemFactorySelector;

@property (nonatomic, readonly, copy) NSArray *propertyNames;

/** @taskunit Geometry Constraints */

@property (nonatomic) NSSize minSize;
@property (nonatomic) NSSize maxSize;

/** @taskunit Item */

// TODO: Rename -layoutItem to -item. Will be done separately because it is a 
// pretty big change which needs to be handled very carefully.
@property (nonatomic, readonly, weak) id layoutItem;

- (void) setItemWithoutInsertingView: (ETUIItem *)item;

/** @taskunit Embbeded Views */

@property (nonatomic, strong) NSView *wrappedView;
@property (nonatomic, strong) NSView *temporaryView;
@property (nonatomic, readonly) NSView *contentView;

/** @taskunit Child Item Views */

/** Inserts item views without altering the order of any pinned subviews
(wrapped, temporary and cover style).

Item views are drawn first and pinned subviews are drawn last.

The subviews to insert are listed in their item order (first views being the 
last drawn ones), so they will appear reversed in -[NSView subviews]. */
- (void) setItemViews: (NSArray *)itemViews;

/** @taskunit Drawing */

@property (nonatomic, strong) NSMutableDictionary *inputValues;

/** @taskunit Actions */

- (IBAction) inspectItem: (id)sender;

@end
