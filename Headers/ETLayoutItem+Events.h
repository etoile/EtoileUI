/*
	ETLayoutItem+Events.h
	
	The EtoileUI event handling model for the layout item tree. Also defines the 
	Pick and Drop model.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>

/* WARNING: Unstable API, the method names won't radically change but the event 
            handler concept will be refined as pluggable aspect and reworked to 
            support the notion of instruments that can encapsulate the logic of
            graphic tools for example. 
            More explanations available in TODO file. */

@class ETPickboard, ETEvent;

@protocol ETEventHandler

- (ETLayoutItem *) eventForwarder;

/* Event Handling */

- (void) mouseDown: (ETEvent *)event on: (id)item;
- (void) mouseUp: (ETEvent *)event on: (id)item;
- (void) mouseDragged: (ETEvent *)event on: (id)item;

- (void) handleMouseDown: (ETEvent *)event forItem: (id)item layout: (id)layout;
- (void) handleClick: (ETEvent *)event forItem: (id)item layout: (id)layout;


/* Pick and Drop Filtering */

- (BOOL) allowsDragging;
- (BOOL) allowsDropping;

/* Pick and Drop Handling */

- (void) handlePick: (ETEvent *)event forItem: (id)item layout: (id)layout;
- (void) handleDrag: (ETEvent *)event forItem: (id)item layout: (id)layout;
- (void) beginDrag: (ETEvent *)event forItem: (id)item 
	image: (NSImage *)customDragImage layout: (id)layout;
- (NSDragOperation) handleDragEnter: (id)dragInfo forItem: (id)item;
- (void) handleDragExit: (id)dragInfo forItem: (id)item;
- (NSDragOperation) handleDragMove: (id)dragInfo forItem: (id)item;
- (void) handleDragEnd: (id)dragInfo forItem: (id)item on: (id) dropTargetItem;
- (BOOL) handleDrop: (id)dragInfo forItem: (id)item on: (id)dropTargetItem;
//- (BOOL) handleDrop: (id)dragInfo forObject: (id)object; // on: (id)item
/*- (void) handlePickForObject: (id)object;
- (void) handleAcceptDropForObject: (id)object;
- (void) handleDropForObject: (id)object;*/

- (BOOL) handlePick: (ETEvent *)event forItems: (NSArray *)items pickboard: (ETPickboard *)pboard;
- (BOOL) handleAcceptDrop: (id)dragInfo forItems: (NSArray *)items on: (id)item pickboard: (ETPickboard *)pboard;
- (BOOL) handleDrop: (id)dragInfo forItems: (NSArray *)items on: (id)item pickboard: (ETPickboard *)pboard;

/* Helper Methods */

//-itemGroup:dropIndexAtLocation:forItem:on:
- (BOOL) acceptsDropAtLocationInWindow: (NSPoint)loc;
- (NSRect) dropOnRect;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal;
- (BOOL) shouldRemoveItemsAtPickTime;
- (int) itemGroup: (ETLayoutItemGroup *)itemGroup dropIndexAtLocation: (NSPoint)localDropPosition 
	forItem: (id)item on: (id)dropTargetItem;
- (void) itemGroup: (ETLayoutItemGroup *)itemGroup insertDroppedObject: (id)movedObject atIndex: (int)index;
- (void) itemGroup: (ETLayoutItemGroup *)itemGroup insertDroppedItem: (id)movedObject atIndex: (int)index;

/* Cut, Copy and Paste Compatibility */

- (IBAction) copy: (id)sender;
- (IBAction) paste: (id)sender;
- (IBAction) cut: (id)sender;

@end

/** Informal Event Handling Protocol that ETLayout subclasses can implement to 
	override the default event handling implemented by ETEventHandler. 
	ETEventHandler automatically takes care of checking whether the layout bound 
	to the item that handles the event, implements one or several of the 
	following methods and calling these methods on the layout object when the 
	event handling behavior can be delegated. */
@interface NSObject (ETLayoutEventHandling)
- (void) handlePick: (ETEvent *)event forItem: (id)item layout: (id)layout;
- (void) handleDrag: (ETEvent *)event forItem: (id)item layout: (id)layout;
- (void) beginDrag: (ETEvent *)event forItem: (id)item 
	image: (NSImage *)customDragImage layout: (id)layout;
- (int) dropIndexAtLocation: (NSPoint)localDropPosition forItem: (id)item 
	on: (id)dropTargetItem;
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
	- ETStackLayout
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
@interface ETLayoutItem (Events) <ETEventHandler>

@end

extern NSString *ETLayoutItemPboardType;
