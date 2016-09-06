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
#import "ETArrowTool.h"
#import "ETLayoutItem+Private.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup+Private.h"
#import "ETWindowItem.h"
// FIXME: Move related code to the Appkit widget backend (perhaps in a category or subclass)
#import "ETWidgetBackend.h"
#import "NSWindow+Etoile.h"
#import "ETCompatibility.h"

@interface COObject (Private)
- (void) markAsRemovedFromContext;
@end


@implementation ETWindowLayer

/** Returns a new bordeless panel which can be used as a temporary root window 
when a layout other than ETWindowLayout is set on the receiver. */
- (ETWindowItem *) createRootWindowItemWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	ETFullScreenWindow *fullScreenWindow = [[ETFullScreenWindow alloc] init];
	[fullScreenWindow setLevel: NSNormalWindowLevel]; 
	return [[ETWindowItem alloc] initWithWindow: fullScreenWindow objectGraphContext: aContext];
}

- (instancetype) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

    [self setName: _(@"Windows")];
	[self setFrame: [[NSScreen mainScreen] visibleFrame]];

	_rootWindowItem = [self createRootWindowItemWithObjectGraphContext: aContext];
	_hiddenWindows = [[NSMutableArray alloc] init];
	[self setLayout: [ETWindowLayout layoutWithObjectGraphContext: aContext]];

	return self;
}

- (void) markAsRemovedFromContext
{
    [super markAsRemovedFromContext];
}


/* Prevents removing the display view.

If a window decorator is bound to the item, the display view is the window view 
(NSThemeFrame on Mac OS X). Removing NSThemeFrame results in a weird behavior, 
the window remains visible but a -lockFocus assertion is thrown on mouse down. */
- (void) updateExposedViewsForItems: (NSArray *)items
                     exposedIndexes: (NSIndexSet *)exposedIndexes
                   unexposedIndexes: (NSIndexSet *)unexposedIndexes
{
	if ([[self layout] isKindOfClass: [ETWindowLayout class]])
		return;

	[super updateExposedViewsForItems: items
	                   exposedIndexes: exposedIndexes
	                 unexposedIndexes: unexposedIndexes];
}

- (void) didAttachItem: (ETLayoutItem *)item
{
	// NOTE: We could eventually check whether the item to decorate already 
	// has a window decorator before creating a new one that will be 
	// refused by -setDecoratorItem: and hence never used. 
	if ([[self layout] isKindOfClass: [ETWindowLayout class]])
	{
		[[item lastDecoratorItem] setDecoratorItem: [item provideWindowItem]];
	}
}

- (void) didDetachItem: (ETLayoutItem *)item
{
	if ([[self layout] isKindOfClass: [ETWindowLayout class]])
	{
		[[[item windowItem] decoratedItem] setDecoratorItem: nil];
	}
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

	for (NSWindow *win in [ETApp windows])
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
	for (NSWindow *win in _hiddenWindows)
	{
		[win orderFront: self];
	}
	[_hiddenWindows removeAllObjects];

	[self removeDecoratorItem: _rootWindowItem]; /* Order out the root window */
}

- (void) removeWindowDecoratorItems
{
	for (ETLayoutItem *item in [self items])
	{
		[item setDefaultValue: [item windowItem] forProperty: @"windowItem"];
		[[[item windowItem] decoratedItem] setDecoratorItem: nil];
	}
}

- (void) restoreWindowDecoratorItems
{
	for (ETLayoutItem *item in [self items])
	{
		ETWindowItem *windowItem = [item defaultValueForProperty: @"windowItem"];

		/* Usually when the item wasn't present when ETWindowLayout was last used */
		if (nil == windowItem)
		{
			windowItem = [ETWindowItem itemWithObjectGraphContext: [item objectGraphContext]];
		}
		[[item lastDecoratorItem] setDecoratorItem: windowItem];
		[item setDefaultValue: nil forProperty: @"windowItem"];
	}
}

@end

@implementation ETWindowLayout

- (instancetype) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	[self setAttachedTool: [ETArrowTool toolWithObjectGraphContext: aContext]];

	return self;
}

@end
