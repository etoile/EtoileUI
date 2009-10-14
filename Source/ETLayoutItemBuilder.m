/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETTemplateItemLayout.h"
#import "ETLayoutItemBuilder.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETWindowItem.h"
#import "ETLayer.h"
#import "ETView.h"
#import "ETScrollableAreaItem.h"
#import "ETLayoutItemFactory.h"
#import "NSObject+EtoileUI.h"
#import "NSView+Etoile.h"
#import "NSWindow+Etoile.h"
#import "ETCompatibility.h"


@implementation ETLayoutItemBuilder

/** Returns a new autoreleased builder. */
+ (id) builder
{
	return AUTORELEASE([[[self class] alloc] init]);
}

/** <init />
Initializes and returns the receiver builder. */
- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	return self;
}

DEALLOC(DESTROY(itemFactory))

@end


@implementation ETEtoileUIBuilder

/** Returns items built with the given pasteboards (not yet implemented).

The returned items are not yet decorated by a window item, -renderApplication: 
handles that. */
- (id) renderPasteboards: (NSArray *)pasteboards
{
	// TODO: Implement
	return [NSArray array];
}

/** Returns an item built with the given pasteboard (not yet implemented). */
- (id) renderPasteboard: (NSPasteboard *)pasteboard
{
	// TODO: Implement...
	//ETPickboard *pickboard = nil;
	
	return nil;
}

/** Returns the window layer built with the elements (windows, pasteboards) 
that makes up the given application object. */
- (id) renderApplication: (NSApplication *)app
{
	ETLayoutItemGroup *windowLayer = [itemFactory windowGroup];
	NSArray *pasteboards = A([NSPasteboard generalPasteboard]);

	[windowLayer addItems: [self renderWindows: [app windows]]];
	[windowLayer addItems: [self renderPasteboards: pasteboards]];

	return windowLayer;	
}

/** Returns items built with the given windows. */
- (id) renderWindows: (NSArray *)windows
{
	NSMutableArray *items = [NSMutableArray array];

	FOREACH([NSArray arrayWithArray: windows], window, NSWindow *) 
	{
		BOOL isStandaloneWindow = ([[window contentView] isSupervisorView] == NO);
		BOOL shouldBecomeVisibleItem = ([window isVisible] 
			&& [window isSystemPrivateWindow] == NO && isStandaloneWindow);
	
		if (shouldBecomeVisibleItem)
		{
			[items addObject: [self renderWindow: window]];

			ETDebugLog(@"Rendered window %@ visibility %d into %@", window, 
				[window isVisible], [items lastObject]);
		}
	}

	return items;
}

/** Returns an item built with the given window.

The returned item is decorated by a window item that reuses this window and 
returns YES to -[ETWindowItem shouldKeepWindowFrame:].  */
- (id) renderWindow: (NSWindow *)window
{
	ETLayoutItem *item = [self renderView: [window contentView]];
	ETWindowItem *windowDecorator = [item windowDecoratorItem];
	BOOL isWindowDecorationNeeded = (windowDecorator == nil);

	if (isWindowDecorationNeeded)
	{
		windowDecorator = [ETWindowItem itemWithWindow: window];
		[windowDecorator setShouldKeepWindowFrame: YES];
		[[item lastDecoratorItem] setDecoratorItem: windowDecorator];
	}

	return item;
}

/** Returns an item built with the given view, by traversing the subview 
hierarchy recursively.

When we encounter a supervisor view (ETView subclasses), we stop the recursive 
traversal in the given view hierarchy and return its layout item.<br />
We never render subviews of supervisor views since we expect their content to be  
a valid layout item tree. 

The returned layout item is either the item bound to the view, or the first 
decorated item when the view is bound to a decorator item. 

All other views (other NSView subclasses) are rendered recursively until the end 
of their view hierachy (-subviews returns an empty arrary). */
- (id) renderView: (id)view
{
	id item = nil;

	if ([view isKindOfClass: [NSScrollView class]])
	{
		item = [self renderView: [view documentView]];
		[item setDecoratorItem: [ETScrollableAreaItem itemWithScrollView: view]];
	}
	else if ([view isSupervisorView] && [[view layoutItem] isDecoratorItem])
	{
		item = [[view layoutItem] firstDecoratedItem];

		NSAssert([item isLayoutItem], @"Your view hierarchy is invalid, it "
			"contains a supervisor view bound to a decorator item that isn't "
				"inserted in the layout item tree");
	}
	else if ([view isSupervisorView] && [[view layoutItem] isLayoutItem])
	{
		item = [view layoutItem];
	}
	else if ([view isMemberOfClass: [NSView class]])
	{
		item = [itemFactory itemGroupWithFrame: [view frame]];
		
		[item setFlipped: [view isFlipped]];

		// NOTE: -addItem: moves subview when subviews is enumerated, hence we 
		// have to iterate over a separate collection which isn't mutated.
		// May be we could avoid moving subviews in -addItem: when they are 
		// going to be reinserted at the location where they have been removed.
		FOREACH([NSArray arrayWithArray: [view subviews]], subview, NSView *)
		{
			id childItem = [self renderView: subview];
			[item addItem: childItem];
		}
	}
	else
	{
		RETAIN(view);
		item = [itemFactory itemWithView: view];
		RELEASE(view);
	}

	NSParameterAssert([item isLayoutItem]);

	/* Fixed layouts such as ETFreeLayout are expected to restore the 
		   initial view frame on the item. */
	[item setPersistentFrame: [item frame]];

	return item;
}

// TODO: Think about it and implement...
- (id) renderMenu: (NSMenu *)menu
{
	return nil;
}

@end
