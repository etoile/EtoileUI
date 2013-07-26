/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETLayer.h"
#import "ETApplication.h"
#import "ETDecoratorItem.h"
#import "ETInstruments.h"
#import "ETLayoutItemFactory.h"
#import "ETWindowItem.h"
#import "NSWindow+Etoile.h"
#import "ETCompatibility.h"


@implementation ETWindowLayer

/** Returns a new bordeless panel which can be used as a temporary root window 
when a layout other than ETWindowLayout is set on the receiver. */
- (ETWindowItem *) createRootWindowItem
{
	ETFullScreenWindow *fullScreenWindow = AUTORELEASE([[ETFullScreenWindow alloc] init]);
	[fullScreenWindow setLevel: NSNormalWindowLevel]; 
	return AUTORELEASE([[ETWindowItem alloc] initWithWindow: fullScreenWindow]);
}

- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	[self setFrame: [[NSScreen mainScreen] visibleFrame]];
		
	ASSIGN(_rootWindowItem, [self createRootWindowItem]);
	_hiddenWindows = [[NSMutableArray alloc] init];
	[self setLayout: [ETWindowLayout layout]];

	return self;
}

- (void) dealloc
{
	[self stopKVOObservationIfNeeded];
	DESTROY(_rootWindowItem); 
	DESTROY(_hiddenWindows);
	[super dealloc];
}

- (void) handleAttachViewOfItem: (ETLayoutItem *)item
{
	// Disable ETLayoutItemGroup implementation that would remove the display 
	// view of the item from its superview. If a window decorator is bound to 
	// the item, the display view is the window view (NSThemeFrame on Mac OS X)
	// Removing NSThemeFrame results in a very weird behavior: the window 
	// remains visible but a -lockFocus assertion is thrown on mouse down.
	if ([[self layout] isKindOfClass: [ETWindowLayout class]])
		return;

	[super handleAttachViewOfItem: item];
}

- (void) handleDetachViewOfItem: (ETLayoutItem *)item
{
	// Ditto. More explanations in -handleDetachItem:.
	if ([[self layout] isKindOfClass: [ETWindowLayout class]])
		return;

	[super handleDetachViewOfItem: item];
}

- (void) handleAttachItem: (ETLayoutItem *)item
{
	RETAIN(item);
	/* Before setting the decorator, the item must have become a child of the 
	   window layer, because -[super handleAttachItem:] triggers 
	   -handleDetachItem: in the existing parent of this item. -[previousParent 
	   handleDetachItem:] then removes the item display view from its superview 
	   by the mean of -[previousParent handleDetachViewOfItem:], and if 
	   -setDecoratorItem: has already been called, removing the item display 
	   view will mean removing the window view returned by 
	   -[ETWindowItem supervisorView] (NSThemeFrame on Mac OS X).
	   Hence you can expect problems similar to what is described 
	   -[ETWindowLayer handleAttachViewOfItem:] if you change the order of the 
	   code.
	   Take note that the overriden -handleDetachViewOfItem: in ETWindowLayer 
	   doesn't help here, because -handleDetachViewOfItem: is called on the old 
	   parent. */	
	[super handleAttachItem: item];
	// NOTE: We could eventually check whether the item to decorate already 
	// has a window decorator before creating a new one that will be 
	// refused by -setDecoratorItem: and hence never used. 
	if ([[self layout] isKindOfClass: [ETWindowLayout class]])
	{
		[[item lastDecoratorItem] setDecoratorItem: [ETWindowItem item]];
	}
	/* When the item has no parent item until now, the window is ordered out */
	[[[item windowItem] window] makeKeyAndOrderFront: nil];
	RELEASE(item);
}

- (void) handleDetachItem: (ETLayoutItem *)item
{
	RETAIN(item);
	/* Detaching the item before removing the window decorator doesn't result 
	   in removing the window view (NSThemeFrame on Mac OS X) because 
	   ETWindowLayer overrides -handleDetachViewOfItem:. */
	[super handleDetachItem: item];
	if ([[self layout] isKindOfClass: [ETWindowLayout class]])
	{
		[[[item windowItem] decoratedItem] setDecoratorItem: nil];
	}
	RELEASE(item);
}

- (void) setLayout: (ETLayout *)aLayout
{
	if ([[self layout] isKindOfClass: [ETWindowLayout class]])
	{
		/* -hideHardWindows must be called first, because visible windows 
		   are going to changed once window decorators have been removed. */
		[self hideHardWindows];
		[self removeWindowDecoratorItems];
	}

	if ([aLayout isKindOfClass: [ETWindowLayout class]])
	{
		/* Ordering matters below because a window put back on screen and 
		   previously used in the item tree, will try to retrieve the window 
		   item while processing the events on the layout item.
		   ETEventProcessor uses -isWindowDecorationEvent which relies on  
		   -[ETEvent windowItem]. */
		[self restoreWindowDecoratorItems];
		[self showHardWindows];
	}

	[super setLayout: aLayout];
}

- (NSRect) rootWindowFrame
{
#ifdef DEBUG_LAYOUT
	return NSMakeRect(100, 100, 600, 500);
#else
#ifdef GNUSTEP
	NSRect frame = [[NSScreen mainScreen] visibleFrame];
	frame.size.height -= 23;
	return frame;
#else
	// FIXME: GNUstep should exclude the GNOME menu bar and task bar.
	return [[NSScreen mainScreen] visibleFrame];
#endif
#endif
}

/** Hides currently visible WM-based windows that decorate the items owned by 
the receiver. 

You should never call this method unless you write an ETWindowLayout subclass. */
- (void) hideHardWindows
{
	/* Display our root window before ordering out all visible windows, 
	   it literally covers the small delay that might be needed to order out the 
	   current windows.
	   FIXME: Moreover on GNUstep our root window won't receive the focus if we 
	   try to do that once all current windows have been ordered out. */
	[[self lastDecoratorItem] setDecoratorItem: _rootWindowItem];
	[[_rootWindowItem window] setFrame: [self rootWindowFrame] display: NO];
	[[_rootWindowItem window] makeKeyAndOrderFront: nil];

	FOREACH([ETApp windows], win, NSWindow *)
	{
		if ([win isEqual: [_rootWindowItem window]] == NO)
		{
			if ([win isVisible] && [win isSystemPrivateWindow] == NO)
			{
				ETDebugLog(@"%@ will order out %@", self, win);
				[_hiddenWindows addObject: win];
				[win orderOut: self];
			}
		}	
	}
}

/** Shows all the previously visible WM-based windows that decorate the 
items owned by the receiver. 

You should never call this method unless you write an ETWindowLayout subclass. */
- (void) showHardWindows
{
	FOREACH(_hiddenWindows, win, NSWindow *)
	{
		[win orderFront: self];
	}
	[_hiddenWindows removeAllObjects];

	[self removeDecoratorItem: _rootWindowItem]; /* Order out the root window */
}

- (void) removeWindowDecoratorItems
{
	FOREACH([self items], item, ETLayoutItem *)
	{
		[item setDefaultValue: [item windowItem] forProperty: @"windowItem"];
		[[[item windowItem] decoratedItem] setDecoratorItem: nil];
	}
}

- (void) restoreWindowDecoratorItems
{
	FOREACH([self items], item, ETLayoutItem *)
	{
		ETWindowItem *windowItem = [item defaultValueForProperty: @"windowItem"];

		/* Usually when the item wasn't present when ETWindowLayout was last used */
		if (nil == windowItem)
		{
			windowItem = [ETWindowItem item];
		}
		[[item lastDecoratorItem] setDecoratorItem: windowItem];
		[item setDefaultValue: nil forProperty: @"windowItem"];
	}
}

@end

@implementation ETWindowLayout

- (id) initWithLayoutView: (NSView *)aView
{
	self = [super initWithLayoutView: aView];
	if (self == nil)
		return nil;

	[self setAttachedTool: [ETArrowTool tool]];

	return self;
}

@end
