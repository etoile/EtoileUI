/*  <title>ETWindowItem</title>

	ETWindowItem.m
	
	<abstract>ETDecoratorItem subclass which makes possibe to decorate any 
	layout items with a window.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
 
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

#import <EtoileFoundation/Macros.h>
#import "ETWindowItem.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem+Factory.h"
#import "ETPickDropCoordinator.h"
#import "NSWindow+Etoile.h"
#import "ETGeometry.h"
#import "ETCompatibility.h"

#define NC [NSNotificationCenter defaultCenter]

@implementation ETWindowItem

/** <init />
Initializes and returns a new window decorator with a hard window (provided by 
the widget backend). 

If window is nil, the receiver will create a standard window. */
- (id) initWithWindow: (NSWindow *)window
{
	self = [super initWithSupervisorView: nil];
	
	if (self != nil)
	{
		if (window != nil)
		{
			ASSIGN(_itemWindow, window);
		}
		else
		{
			_itemWindow = [[NSWindow alloc] init];
		}
		// TODO: Would be better not to break the window delegate... May be 
		// we should rather reimplement NSDraggingDestination protocol in 
		// a NSWindow category. 
		if ([_itemWindow delegate] != nil)
		{
			ETLog(@"WARNING: The window delegate %@ will be replaced by %@ "
				"-initWithWindow:", [_itemWindow delegate], self);
		}
		[_itemWindow setDelegate: self];
		[_itemWindow setAcceptsMouseMovedEvents: YES];
		[_itemWindow registerForDraggedTypes: A(ETLayoutItemPboardType)];
		_usesCustomWindowTitle = ([self isUntitled] == NO);
	}
	
	ETDebugLog(@"Init item %@ with window %@ %@ at %@", self, [_itemWindow title],
		_itemWindow, NSStringFromRect([_itemWindow frame]));
	
	return self;
}

- (id) initWithSupervisorView: (ETView *)aView
{
	return [self initWithWindow: nil];
}

- (id) init
{
	return [self initWithWindow: nil];
}

- (void) dealloc
{
	ETDebugLog(@"Dealloc item %@ with window %@ %@ at %@", self, [_itemWindow title],
		_itemWindow, NSStringFromRect([_itemWindow frame]));

	/* Retain the window to be sure we can send it -isReleasedWhenClosed. We 
	   must defer the deallocation in case -close releases it and drops the
	   retain count to zero. */
	RETAIN(_itemWindow);
	[_itemWindow close];
	/* Don't release a window which is in charge of releasing itself.
	   We are usually in the middle of a window close handling and -dealloc has
	   been called as a side-effect of removing the decorated item from the 
	   window layer in -windowWillClose: notification. */
	if ([_itemWindow isReleasedWhenClosed] == NO)
	{
		RELEASE(_itemWindow);
	}
	DESTROY(_itemWindow);  /* Balance first retain call */

	[super dealloc];
}

/** Returns YES when the receiver window has no title, otherwise returns NO. */
- (BOOL) isUntitled
{
	NSString *title = [[self window] title];
	return (title == nil || [title isEqual: @""] || [title isEqual: @"Window"]);
}

/* -windowWillClose: ins't appropriate because it would be called when the window 
   is sent -close on window item release/deallocation (see -dealloc). */
- (BOOL) windowShouldClose: (NSNotification *)notif
{
	ETDebugLog(@"Shoud close %@ with window %@ %@ at %@", self, [_itemWindow title],
		_itemWindow, NSStringFromRect([_itemWindow frame]));

	/* If the window doesn' t get hidden on close, we release the item 
	   we decorate by removing it from the window layer or removing ourself 
	   as a decorator. */
	if ([_itemWindow isReleasedWhenClosed])
	{
		if ([[ETLayoutItem windowGroup] containsItem: [self firstDecoratedItem]])
		{
			[[ETLayoutItem windowGroup] removeItem: [self firstDecoratedItem]];
		}
		else
		{
			[[self decoratedItem] setDecoratorItem: nil];
		}
	}

	return YES;
}

/** Returns the underlying hard window. */
- (NSWindow *) window
{
	return _itemWindow;
}

/** Returns YES when you have provided a custom window title, otherwise 
when returns NO when the receiver manages the window title. */
- (BOOL) usesCustomWindowTitle
{
	return _usesCustomWindowTitle;
}

/* Overriden Methods */

/** Returns YES when item can be decorated with a window by the receiver, 
otherwise returns no. */
- (BOOL) canDecorateItem: (id)item
{
	/* Will call back -[item acceptsDecoratorItem: self] */
	BOOL canDecorate = [super canDecorateItem: item];
	
	/*if (canDecorate && [item decoratorItem] != nil)
	{
		ETLog(@"To be decorated with a window, item %@ must have no existing "
			@"decorator item %@", item, [item decoratorItem]);
		canDecorate = NO;
	}*/
	if (canDecorate && [item isKindOfClass: [ETWindowItem class]])
	{
		ETLog(@"To be decorated with a window, item %@ must not be a window "
			@"item %@", item, [item decoratorItem]);
		canDecorate = NO;
	}

	return canDecorate;
}

/** Returns NO. A window can never be decorated. */
- (BOOL) acceptsDecoratorItem: (ETLayoutItem *)item
{
	return NO;
}

- (void) handleDecorateItem: (ETUIItem *)item 
             supervisorView: (ETView *)decoratedView 
                     inView: (ETView *)parentView
{
	/* -handleDecorateItem:inView: will call back 
	   -[ETWindowItem setDecoratedView:] which overrides ETLayoutItem.
	   We pass nil instead of parentView because we want to move the decorated
	   item view into the window and not reinsert it once decorated into its
	   superview. Reinserting into the existing superview is the usual behavior 
	   implemented by -handleDecorateItem:inView: that works well when the 
	   decorator is a view  (box, scroll view etc.). */
	[super handleDecorateItem: item supervisorView: nil inView: nil];
		
	if (decoratedView != nil)
	{
		// TODO: Rather than reusing the item size as other decorator do, 
		// ETWindowItem could extend it temporarily until it is removed. To 
		// do so, we could add -frameToRestore to retrieve the existingFrame 
		// in -setDecoratorItem: and -setFrameToRestore: which can be called 
		// here. This way we could also restore the initial item position when 
		// a window decorator is removed.
		//[_itemWindow setContentSizeFromTopLeft: [decoratedView frame].size];
		
		NSRect windowFrameWithItemSize = ETMakeRect([_itemWindow frame].origin, [decoratedView frame].size);
		[_itemWindow setFrame: windowFrameWithItemSize
		              display: YES];

		NSSize shrinkedItemSize = [_itemWindow contentRectForFrameRect: [_itemWindow frame]].size;
		[decoratedView setFrameSize: shrinkedItemSize];
		/* Previous line similar to [decoratedItem setContentSize: shrinkedItemSize] */
	}
	[_itemWindow setContentView: (NSView *)decoratedView];	

	// TODO: Use KVB by default to bind the window title
	if ([self usesCustomWindowTitle] == NO)
	{
		[_itemWindow setTitle: [[self firstDecoratedItem] displayName]];
	}
	[_itemWindow makeKeyAndOrderFront: self];
}

- (void) handleUndecorateItem: (ETLayoutItem *)item inView: (ETView *)parentView
{
	[_itemWindow orderOut: self];
	[super handleUndecorateItem: item inView: parentView];
}

/** Returns nil. */
- (id) supervisorView
{
	return nil;
}

/** Returns the window content view. */
- (NSView *) view
{
	return [_itemWindow contentView];
}

/** Returns the window frame. */
- (NSRect) decorationRect
{
	return [_itemWindow frame];
}

/** Returns the content view rect expressed in the window coordinate space. 

This coordinate space includes the window decoration (titlebar etc.).  */
- (NSRect) contentRect
{
	NSRect windowFrame = [_itemWindow frame];
	NSRect rect = [_itemWindow contentRectForFrameRect: windowFrame];

	NSParameterAssert(rect.size.width <= windowFrame.size.width && rect.size.height <= windowFrame.size.height);

	rect.origin.x = rect.origin.x - windowFrame.origin.x;
	rect.origin.y = rect.origin.y - windowFrame.origin.y;

	if ([self isFlipped])
	{
		rect.origin.y = windowFrame.size.height - (rect.origin.y + rect.size.height);	
	}

	NSParameterAssert(rect.origin.x >= 0 && rect.origin.x <= rect.size.width 
		&& rect.origin.y >= 0 && rect.origin.y <= rect.size.height);

	return rect;
	// TODO: Use [_itemWindow contentRectInFrame];
}

// NOTE: At this point, we lost the item position (aka the implicit frame 
// origin of the first decorated item). That means the item will have a "random" 
// position when the window decorator is removed.
- (void) handleSetDecorationRect: (NSRect)rect
{
	 /* Will be called back when the window is resized, but -setFrame:display: 
	    will do nothing then. In this case, the call stack looks like:
		-[ETDecoratorItem handleSetDecorationRect:]
		-[ETDecorator decoratedItemRectChanged:]
		-[ETLayoutItem setContentBounds:]
		... 
		-[ETView setFrame:] -- the window content view
		-[NSWindow setFrame:display:] */
	[_itemWindow setFrame: ETMakeRect([_itemWindow frame].origin, rect.size) 
	              display: YES];
}

- (BOOL) isFlipped
{
	return _flipped;
}

- (void) setFlipped: (BOOL)flipped
{
	_flipped = flipped;
	[_decoratorItem setFlipped: flipped];	
}

/* Dragging Destination (as Window delegate) */

/** This method can be called on the receiver when a drag exits. When a 
	view-based layout is used, existing the layout view results in entering
	the related container, that's probably a bug because the container should
	be fully covered by the layout view in all cases. */
- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Drag enter receives in dragging destination %@", self);
	return [[ETPickDropCoordinator sharedInstance] draggingEntered: drag];
}

- (NSDragOperation) draggingUpdated: (id <NSDraggingInfo>)drag
{
	//ETLog(@"Drag update receives in dragging destination %@", self);
	return [[ETPickDropCoordinator sharedInstance] draggingUpdated: drag];
}

- (void) draggingExited: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Drag exit receives in dragging destination %@", self);
	[[ETPickDropCoordinator sharedInstance] draggingExited: drag];
}

- (void) draggingEnded: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Drag end receives in dragging destination %@", self);
	[[ETPickDropCoordinator sharedInstance] draggingEnded: drag];
}

/* Will be called when -draggingEntered and -draggingUpdated have validated the drag
   This method is equivalent to -validateDropXXX data source method.  */
- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Prepare drag receives in dragging destination %@", self);
	return [[ETPickDropCoordinator sharedInstance] prepareForDragOperation: drag];	
}

/* Will be called when -draggingEntered and -draggingUpdated have validated the drag
   This method is equivalent to -acceptDropXXX data source method.  */
- (BOOL) performDragOperation: (id <NSDraggingInfo>)dragInfo
{
	ETDebugLog(@"Perform drag receives in dragging destination %@", self);
	return [[ETPickDropCoordinator sharedInstance] performDragOperation: dragInfo];
}

/* This method is called in replacement of -draggingEnded: when a drop has 
   occured. That's why it's not enough to clean insertion indicator in
   -draggingEnded:. Both methods called -handleDragEnd:forItem: on the 
   drop target item. */
- (void) concludeDragOperation: (id <NSDraggingInfo>)dragInfo
{
	ETDebugLog(@"Conclude drag receives in dragging destination %@", self);
	[[ETPickDropCoordinator sharedInstance] concludeDragOperation: dragInfo];
}

@end
