/*  <title>ETActionHandler</title>

	<abstract>The EtoileUI event handling model for the layout item tree. Also 
	defines the Pick and Drop model.</abstract>

	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/* WARNING: Unstable API, the method names won't radically change but the event 
            handler concept will be refined as pluggable aspect and reworked to 
            support the notion of instruments that can encapsulate the logic of
            graphic tools for example. 
            More explanations available in TODO file. */

@class ETUTI;
@class ETEvent, ETLayoutItem, ETPickboard, ETPickDropCoordinator;
@protocol ETKeyInputAction, ETTouchAction;

/** Action handler are lightweight objects whose instances can be shared between 
a large number of layout items.
 
The same action handler is automatically set on every new layout item 
instances. You can override it by calling -[ETLayoutItem setActionHandler:].
For example, ETActionHandler can be subclassed to handle the paint 
action in your own way: you might want to alter objects or properties bound
to the layout item  and not just the style object as the base class does. 

For an ETActionHandler subclass, you usually use a single shared instance 
accross all the layout items to which it is bound. To do so, a possibility 
is to write a factory method to build your layout items, this factory 
method will reuse the action handler to be set on every created items. */
@interface ETActionHandler : NSObject
{
	ETLayoutItem *_fieldEditorItem;
	ETLayoutItem *_editedItem;
	BOOL _wasFieldEditorParentModelMutator;
}

+ (Class) styleClass;

+ (id) sharedInstance;

/* Text Editing */

- (ETLayoutItem *) fieldEditorItem;
- (void) setFieldEditorItem: (ETLayoutItem *)anItem;
- (void) beginEditingItem: (ETLayoutItem *)item 
                 property: (NSString *)property
                   inRect: (NSRect)fieldEditorFrame;
- (void) endEditingItem;

/* Instrument/Tool Actions */

- (void) handleClickItem: (ETLayoutItem *)item;
- (void) handleDoubleClickItem: (ETLayoutItem *)item;
- (void) handleDragItem: (ETLayoutItem *)item byDelta: (NSSize)delta;
- (void) handleTranslateItem: (ETLayoutItem *)item byDelta: (NSSize)delta;
- (void) handleEnterItem: (ETLayoutItem *)item;
- (void) handleExitItem: (ETLayoutItem *)item;
- (void) handleEnterChildItem: (ETLayoutItem *)childItem;
- (void) handleExitChildItem: (ETLayoutItem *)childItem;

/* Key Actions */

- (BOOL) handleKeyEquivalent: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item;
- (void) handleKeyUp: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item;
- (void) handleKeyDown: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item;

/* Touch Tracking Actions */

- (BOOL) handleBeginTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item;
- (void) handleContinueTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item;
- (void) handleEndTouch: (id <ETTouchAction>)aTouch onItem: (ETLayoutItem *)item;

/* Select Actions */

//ETSelectTool produced actions.
//-canSelectIndexes:onItem:
//-selectIndexes:onItem:
- (BOOL) canSelect: (ETLayoutItem *)item;
- (void) handleSelect: (ETLayoutItem *)item;
- (BOOL) canDeselect: (ETLayoutItem *)item;
- (void) handleDeselect: (ETLayoutItem *)item;

/* Generic Actions */

- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;
- (BOOL) acceptsFirstMouse;

- (void) sendBackward: (id)sender onItem: (ETLayoutItem *)item;
- (void) sendToBack: (id)sender onItem: (ETLayoutItem *)item;
- (void) bringForward: (id)sender onItem: (ETLayoutItem *)item;
- (void) bringToFront: (id)sender onItem: (ETLayoutItem *)item;

@end


@interface ETButtonItemActionHandler : ETActionHandler
{

}

+ (Class) styleClass;

@end

/** Event Handling in the Layout Item Tree 

	What follows is only valid when the layout item tree is rendered by 
	EtoileUI/AppKit rendering backend (see ETEtoileUIRender).
	The events are routed through the AppKit view hierarchy to the proper child
	item of the layout item matching the view that replies YES to -hitTest. If 
	the view has no corresponding layout item and returns YES, the event 
	handling remains on AppKit side (following AppKit event model). If this 
	view returns NO, then -hitTest is done on the superview which may have a 
	matching layout item or not. 
	ETView class and subclasses replies YES to -hitTest unlike NSView, so the
	event they received are always routed to their corresponding layout item.
	Basic event handling methods in ETLayoutItem reuses the name of their 
	equivalent NSResponder methods plus an additional method keywoard 'on:'.
	Here is an example:
	- (void) mouseDown: (NSEvent *)event in Responder
	becomes
	- (void) mouseDown: (ETEvent *)event on: (id)item in ETLayoutItem.
	Presently these methods are declared on ETLayoutItem, although in future
	they will be moved to a separate ETEventHandler class making possible to
	to changing event handling at runtime by plugging another event handler.
	This will help to support multiple interaction modes very easily as needed 
	by many graphics applications and to implement custom mouse tracking 
	(radio buttons, menus, custom controls etc.) without subclassing.
	
	When a layout item receives an event, it looks up for the higher ancestor 
	item that wants to preempt the event. For example, if the root item has an
	outline layout active instead of the common UI layout, then the root item
	will handles the event in all cases. Even if the item which receives the
	event is ten levels below or more. This rule is important because it allows
	transparent pick and drop: if the item receiving the event has a parent 
	which uses a table layout, a drag should be handled according to the drag 
	semantic defined by table layout, but this doesn't hold if this table
	layout is invisible because some higher ancestor item in the tree uses an
	outline layout at this time.
	Most of time there are no ancestor items which want to preempt the event, 
	in this case
	
	Here is a list of layouts that preempts events:
	- ETTableLayout
	- ETOutlineLayout
	- ETBrowserLayout
	- ETModelViewLayout
	- any layouts which uses a layout view (injected in a container when you 
	  call -setLayout: on its layout item).
	  
	Layouts which don't preempt events:
	- ETFlowLayout
	- ETColumnLayout
	- ETLineLayout
	- ETFreeLayout
	- ETUILayout
	
	If you use a source with your container and you implement mutation source 
	methods, you don't need to worry about pick and drop interaction handling.
	ETLayoutItemGroup mutation methods like -addItem:, -removeItem: etc. hides 
	all the details involved by dealing with a source when one is set. These 
	methods takes care of finding whether the item is provided by a source or 
	not by looking up in the layout item tree.
	If an item group has a source which doesn't implement mutation methods. The
	selected and related children items will use another selection color (or
	visual indicator) than the usual one. This makes clear whether a selected 
	item will be picked if you try to. Usually unless the user tweaks the UI, he
	usually won't see two selection colors in a table to take an example. 
	(see ETLayoutItemGroup which provides detailed explanations about related 
	items and how a source can be overriden in a layout item subtree). 
	
	- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination 
	isn't officially supported by EtoileUI, all other methods of NSDraggingSource
	are implemented in ETGroupEventHandler and can be overriden. 
	WARNING: ETGroupEventHandler doesn't exist yet and is currently part of 
	ETLayoutItem (Events). */

// TODO: Refactor this category in a pluggable event handler object. 
// A new ETInteraction class or class hierachy should be introduced.
