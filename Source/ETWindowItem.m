/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/NSInvocation+Etoile.h>
#import <EtoileFoundation/Macros.h>
#import "ETWindowItem.h"
#import "ETLayer.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem+Factory.h"
#import "ETPickDropCoordinator.h"
#import "ETLayoutItemFactory.h"
#import "NSWindow+Etoile.h"
#import "ETGeometry.h"
#import "ETCompatibility.h"

#define NC [NSNotificationCenter defaultCenter]

@implementation ETWindowItem

/* Factory Methods */

/** Returns a new window item to which the given concrete window gets bound. 

The returned item can be used as a decorator to wrap an existing layout item 
into a window. */
+ (ETWindowItem *) itemWithWindow: (NSWindow *)window
{
	return AUTORELEASE([[self alloc] initWithWindow: window]);
}

/** Returns a new window item to which a fullscreen concrete window gets bound.

The returned item can be used as a decorator to make an existing layout item 
full screen. 

The concrete window class used is ETFullScreenWindow. */
+ (ETWindowItem *) fullScreenItem
{
	ETWindowItem *window = [self itemWithWindow: AUTORELEASE([[ETFullScreenWindow alloc] init])];
	[window setShouldKeepWindowFrame: YES];
	return window;
}

/** Returns a new window item to which a fullscreen concrete window gets bound.
This window has a transparent background.
 
The returned item can be used as a decorator to make an existing layout item 
full screen. 
 
The concrete window class used is ETFullScreenWindow. */
+ (ETWindowItem *) transparentFullScreenItem
{
	NSWindow *window = AUTORELEASE([[ETFullScreenWindow alloc] init]);
	[window setOpaque: NO];
	[window setBackgroundColor: [NSColor clearColor]];
	ETWindowItem *windowItem = [self itemWithWindow: window];
	[windowItem setShouldKeepWindowFrame: YES];
	return windowItem;
}

/* Initialization */

/** <init />
Initializes and returns a new window decorator with a hard window (provided by 
the widget backend) and its next responder. 

Unless you write a subclass, you should never use this initializer but rather 
the factory methods.

This responder is the widget window next responder and not the window item next 
responder. The widget window is the receiver next responder.<br />
Factory methods will initialize the receiver with -[ETLayoutItemFactory windowGroup] 
as the next responder of the widget window.

If window is nil, the receiver creates a standard widget backend window. */
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
		_shouldKeepWindowFrame = NO;
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

- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone
{
	NSWindow *windowCopy = [_itemWindow copyWithZone: aZone];
	NSInvocation *inv = [NSInvocation invocationWithTarget: self
	                                              selector: @selector(initWithWindow:)
                                                 arguments: A(windowCopy)];
	RELEASE(windowCopy); // NOTE: We don't autorelease to simplify debugging.
	return inv;
}

- (id) copyWithZone: (NSZone *)aZone
{
	ETWindowItem *newItem = [super copyWithZone: aZone];

	// NOTE: The copying logic is largely handled with -initWithInvocationForCopyWithZone:

	newItem->_shouldKeepWindowFrame = _shouldKeepWindowFrame;
	newItem->_flipped = _flipped; // Probably not necessary

	return newItem;
}

/* Main Accessors */

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

/** Returns the height of the window title bar or zero when no title bar is used. */
- (float) titleBarHeight
{
	return [self decorationRect].size.height - [self contentRect].size.height;
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
- (BOOL) acceptsDecoratorItem: (ETDecoratorItem *)item
{
	return NO;
}

/** Returns whether the window should keep its size when used as a 
decorator, rather than getting resized to match the decorated item size. */
- (BOOL) shouldKeepWindowFrame
{
	return _shouldKeepWindowFrame;
}

/** Sets whether the window should keep its size when used as a decorator.

This is needed for fullscreen windows, so that they fill the screen
regardless of the size of the item they decorate. */
- (void) setShouldKeepWindowFrame: (BOOL)shouldKeepWindowFrame
{
	_shouldKeepWindowFrame = shouldKeepWindowFrame;
}

/* Converts the given rect expressed in the EtoileUI window layer coordinate 
space to the AppKit screen coordinate space.

This method will check whether the window layer (aka window group) is flipped 
and make the necessary adjustments. */
- (NSRect) convertRectToWidgetBackendScreenBase: (NSRect)rect
{
	ETWindowLayer *windowLayer = (ETWindowLayer *)[[ETLayoutItemFactory factory] windowGroup];

	if ([windowLayer isFlipped] == NO)
		return rect;

	/* We call -rootWindowFrame on ETWindowLayer and not -frame which would 
	   call back the current method and results in an endless recursion. */
	float windowLayerHeight = [windowLayer rootWindowFrame].size.height;
	float flippedY = windowLayerHeight - (rect.origin.y + rect.size.height);

	return NSMakeRect(rect.origin.x, flippedY, rect.size.width, rect.size.height);	
}

/* Converts the given rect expressed in the AppKit screen coordinate space to 
the EtoileUI window layer coordinate space.

This method will check whether the window layer (aka window group) is flipped 
and make the necessary adjustments. */
- (NSRect) convertRectFromWidgetBackendScreenBase: (NSRect)windowFrame
{
	ETWindowLayer *windowLayer = (ETWindowLayer *)[[ETLayoutItemFactory factory] windowGroup];

	if ([windowLayer isFlipped] == NO)
		return windowFrame;

	/* We call -rootWindowFrame on ETWindowLayer and not -frame which would 
	   call back the current method and results in an endless recursion. */
	float windowLayerHeight = [windowLayer rootWindowFrame].size.height;
	float flippedY = windowLayerHeight - (windowFrame.origin.y + windowFrame.size.height);

	return NSMakeRect(windowFrame.origin.x, flippedY, windowFrame.size.width, windowFrame.size.height);
}

- (void) handleDecorateItem: (ETUIItem *)item 
             supervisorView: (NSView *)decoratedView 
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
		
		if ([self shouldKeepWindowFrame] == NO)
		{
			[_itemWindow setFrame: [self convertRectToWidgetBackendScreenBase: [decoratedView frame]]
			              display: YES];
		}
	
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

- (void) handleUndecorateItem: (ETUIItem *)item
               supervisorView: (NSView *)decoratedView 
                       inView: (ETView *)parentView
{
	[_itemWindow orderOut: self];
	[super handleUndecorateItem: item supervisorView: decoratedView inView: parentView];
}

- (void) saveAndOverrideAutoresizingMaskOfDecoratedItem: (ETUIItem *)item
{
	_oldDecoratedItemAutoresizingMask = [[item supervisorView] autoresizingMask];
	[[item supervisorView] setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
}

- (void) restoreAutoresizingMaskOfDecoratedItem: (ETUIItem *)item
{
	[[item supervisorView] setAutoresizingMask: _oldDecoratedItemAutoresizingMask];
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

/** Returns the window frame in the window layer coordinate base which is 
flipped by default.

See also -[ETItemFactory windowGroup]. */
- (NSRect) decorationRect
{
	return [self convertRectFromWidgetBackendScreenBase: [_itemWindow frame]];
}

/** Returns the content view rect expressed in the window coordinate space. 

This coordinate space includes the window decoration (titlebar etc.).  */
- (NSRect) contentRect
{
	NSRect windowFrame = [_itemWindow frame];
	NSRect rect = [_itemWindow contentRectForFrameRect: windowFrame];

	NSParameterAssert(rect.size.width <= windowFrame.size.width 
		&& rect.size.height <= windowFrame.size.height);

	rect.origin.x = rect.origin.x - windowFrame.origin.x;
	rect.origin.y = rect.origin.y - windowFrame.origin.y;

	if ([self isFlipped])
	{
		rect.origin.y = windowFrame.size.height - (rect.origin.y + rect.size.height);	
	}

	NSParameterAssert(rect.origin.x >= 0 && rect.origin.y >= 0);

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

	if ([self shouldKeepWindowFrame])
		return;

	[_itemWindow setFrame: [self convertRectToWidgetBackendScreenBase: rect] 
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

/** Returns the widget backend window as the next responder. */
- (id) nextResponder
{
	// NOTE: See -targetForAction:to:from: to understand how ETApplication
	// simulates [_itemWindow setNextResponder: [itemFactory windowGroup]]
	return _itemWindow;
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
