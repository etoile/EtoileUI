/*
	ETLayoutItem+Events.h
	
	Description forthcoming.
 
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

@protocol ETEventHandler
@end

// TODO: Refactor this category in a pluggable event handler object. 
// A new ETInteraction class or class hierachy should be introduced.

/** Event Handling in the Layout Item Tree 

	What follows is only valid when the layout item tree is rendered by 
	EtoileUI/AppKit rendering backend (see ETEtoileUIRender).
	The events are routed through the AppKit view hierarchy to the proper child
	item of the layout item matching the view that replies YES to -hitTest. If 
	the view has no corresponding layout item and returns YES, the event 
	handling remains on AppKit side (following AppKit event model). If this 
	view returns NO, then -hitTest is done the superview which may have a 
	matching layout item or not. 
	ETView class and subclasses replies YES to -hitTest unlike NSView, so the
	event they received are always routed to their corresponding layout item.
	Basic vent handling methods in ETLayoutItem reuses the name of their 
	equivalent NSResponder methods plus an additional method keywoard 'on:'.
	Here is an example:
	- (void) mouseDown: (NSEvent *)event in Responder
	becomes
	- (void) mouseDown: (NSEvent *)event on: (id)item in ETLayoutItem.
	Presently these methods are declared on ETLayoutItem, although in future
	they will be moved to a separate ETEventHandler class making possible to
	to changing event handling at runtime by plugging another event handler.
	This will help to support multiple interaction modes very easily as needed 
	by many graphics applications and to implement custom mouse tracking 
	(radio buttons, menus, custom controls etc.)
	
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
    */

@interface ETLayoutItem (Events) <ETEventHandler>

- (BOOL) allowsDragging;

- (void) mouseDown: (NSEvent *)event on: (id)item;
- (void) mouseDragged: (NSEvent *)event on: (id)item;
- (void) handleDrag: (NSEvent *)event forItem: (id)item;
- (void) beginDrag: (NSEvent *)event forItem: (id)item image: (NSImage *)customDragImage;
/*- (void) handlePickForObject: (id)object;
- (void) handleAcceptDropForObject: (id)object;
- (void) handleDropForObject: (id)object;*/

@end

extern NSString *ETLayoutItemPboardType;
