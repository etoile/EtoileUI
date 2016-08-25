/**	<title>ETUIItem</title>

	<abstract>An abstract class/mixin that provides some basic behavior common 
	to both ETLayoutItem and ETDecoratorItem.</abstract>

	Copyright (C) 20O9 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETResponder.h>
#import <EtoileUI/ETStyle.h>

@class ETDecoratorItem, ETLayoutItemGroup, ETView;

/** Enum used internally by EtoileUI to synchronize supervisor view and item 
properties. */
typedef NS_ENUM(NSUInteger, ETSyncSupervisorView)
{
	ETSyncSupervisorViewToItem,
	ETSyncSupervisorViewFromItem
};

// TODO: Turn this class into a mixin and a protocol

/** ETUIItem is an abstract class which serves as a basic item protocol. 

This protocol formalizes the EtoileUI decoration mechanism and as such is shared 
by both ETLayoutItem and ETDecoratorItem.

EtoileUI has no event responder chain unlike the AppKit, it only uses an 
action responder chain.<br />
When an action cannot be handled by the first responder or its action handler, 
then the action is handed to its next responder and so on until the end of the 
responder chain (when -nextResponder returns nil).<br />
When the first responder is a view, the view hierarchy will traversed upwards 
until a supervisor view is found. If no view responds to the action, then 
the supervisor view next responder will be the item bound to it.<br />
When the first responder is a layout item or the last tested responder was a 
supervisor view, the layout item tree will be traversed upwards until the root 
item is reached. The traversal will include each decorator item chain.<br />
For any item, the next responder is the enclosing item which is either a 
decorator item or a parent item. When an item has a controller bound to it, 
the controller becomes the next responder and the enclosing item becomes the 
responder that follows the controller.<br />
This process is usually executed twice. First, EtoileUI will try to find a 
responder in the item tree located in the key window, then in the item tree 
located in the main window. When no responder has been found, then the action 
is handed to the application object, to its delegate and finally to the 
persistency controller (when CoreObject is installed).

You must never subclass ETUIItem. ETUIItem ivars must be considered private. */
@interface ETUIItem : ETStyle <ETResponder>
{
	ETDecoratorItem *_decoratorItem; // next decorator
	IBOutlet ETView *supervisorView;
}

/** @taskunit Default Settings */

+ (NSRect) defaultItemRect;

/** @taskunit Supervisor View and View */

@property (nonatomic, readonly) BOOL usesWidgetView;
@property (nonatomic, getter=isFlipped, readonly) BOOL flipped;
@property (nonatomic, strong) ETView *supervisorView;

- (void) setSupervisorView: (ETView *)aView sync: (ETSyncSupervisorView)syncDirection;

@property (nonatomic, readonly) ETView *displayView;

/** @taskunit Drawing */

- (void) render: (NSMutableDictionary *)inputValues 
      dirtyRect: (NSRect)dirtyRect 
      inContext: (id)ctxt;

/** @taskunit Accessing and Manipulating Decoration */

@property (nonatomic, strong) ETDecoratorItem *decoratorItem;

- (void) removeDecoratorItem: (ETDecoratorItem *)decorator;

@property (nonatomic, readonly) id lastDecoratorItem;
@property (nonatomic, readonly, weak) ETUIItem *decoratedItem;
@property (nonatomic, readonly) id firstDecoratedItem;

- (BOOL) acceptsDecoratorItem: (ETDecoratorItem *)item;
- (ETUIItem *) decoratorItemAtPoint: (NSPoint)aPoint;

@property (nonatomic, readonly) NSRect decorationRect;

/** @taskunit Decoration Notifications */

- (void) didDecorateItem: (ETUIItem *)item;
- (void) didUndecorateItem: (ETUIItem *)item;

/* @taskunit Basic Type Querying */

@property (nonatomic, readonly) BOOL isUIItem;

/** @taskunit Decoration Type Querying */

@property (nonatomic, readonly) BOOL isDecoratorItem;
@property (nonatomic, readonly) BOOL isWindowItem;
@property (nonatomic, readonly) BOOL isScrollableAreaItem;

/** @taskunit Enclosing Item */

@property (nonatomic, readonly) id enclosingItem;

- (NSRect) convertRectToEnclosingItem: (NSRect)aRect;
- (NSPoint) convertPointToEnclosingItem: (NSPoint)aPoint;

/** @taskunit Actions */

@property (nonatomic, readonly) id nextResponder;
@property (nonatomic, readonly) ETLayoutItem *candidateFocusedItem;

/** @taskunit Framework Private */

@property (nonatomic, readonly) BOOL shouldSyncSupervisorViewGeometry;

- (void) syncSupervisorViewGeometry: (ETSyncSupervisorView)syncDirection;
- (NSRect) convertDisplayRect: (NSRect)rect 
        toAncestorDisplayView: (NSView **)aView 
                     rootView: (NSView *)topView
                   parentItem: (ETLayoutItemGroup *)parent;
- (ETUIItem *) decoratedItemAtPoint: (NSPoint)aPoint;

@end
