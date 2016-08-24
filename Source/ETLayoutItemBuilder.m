/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+DoubleDispatch.h>
#import <CoreObject/COObjectGraphContext.h>
#import "ETTemplateItemLayout.h"
#import "ETLayoutItemBuilder.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETWindowItem.h"
#import "ETLayer.h"
#import "ETView.h"
#import "ETScrollableAreaItem.h"
#import "ETLayoutItemFactory.h"
#import "ETUIItemIntegration.h"
#import "NSObject+EtoileUI.h"
#import "NSView+EtoileUI.h"
#import "NSWindow+Etoile.h"
#import "ETCompatibility.h"


@implementation ETLayoutItemBuilder

/** Returns a new autoreleased builder. */
+ (id) builderWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	return [[[self class] alloc] initWithObjectGraphContext: aContext];
}

/** <init />
Initializes and returns the receiver builder. */
- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	SUPERINIT
	itemFactory = [ETLayoutItemFactory factoryWithObjectGraphContext: aContext];
	return self;
}

- (NSString *) doubleDispatchPrefix
{
	return @"render";
}

/** Tries to build a method name based on the given object type and invoke it.

See -[NSObject visit:].

Built method names follows the pattern <em>render</em> + <em>object type</em>. */
- (id) render: (id)anObject
{
	return [self visit: anObject];
}

@end


@implementation ETEtoileUIBuilder

- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	_allowsWidgetLayout = YES;
	return self;
}

/** Returns whether the receiver should generate ETWidgetLayout subclass 
instances in -renderView: when possible. 

See also -setAllowsWidgetLayout. */ 
- (BOOL) allowsWidgetLayout
{
	return _allowsWidgetLayout;
}

/** Sets whether the receiver should generate ETWidgetLayout subclass instances 
in -renderView: when possible.

For example, let's suppose -renderView: is invoked with an outline view:
<enum> 
<item>if set to YES, -renderView: will return an ETLayoutItemGroup whose layout 
is an ETOutlineLayout initialized with the NSOutlineView.</item>
<item>if set to NO, -renderView: will return an ETLayoutItem whose view is the 
NSOutlineView (the outline view won't become EtoileUI-driven).</item>
</list> */ 
- (void) setAllowsWidgetLayout: (BOOL)allowed
{
	_allowsWidgetLayout = allowed;
}

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

/** Returns items built with the elements (windows, pasteboards) that makes up 
the given application object. */
- (id) renderApplication: (NSApplication *)app
{
	NSMutableArray *items = [NSMutableArray array];
	NSArray *pasteboards = A([NSPasteboard generalPasteboard]);

	[items addObjectsFromArray: [self renderWindows: [app windows]]];
	[items addObjectsFromArray: [self renderPasteboards: pasteboards]];

	return items;
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
	ETWindowItem *windowDecorator = [item windowItem];
	BOOL isWindowDecorationNeeded = (windowDecorator == nil);

	if (isWindowDecorationNeeded)
	{
		windowDecorator = [ETWindowItem itemWithWindow: window
		                            objectGraphContext: [itemFactory objectGraphContext]];
		[windowDecorator setShouldKeepWindowFrame: YES];
		[[item lastDecoratorItem] setDecoratorItem: windowDecorator];
	}

	return item;
}

// TODO: Move to ETWidgetLayout
- (BOOL) canBuildWidgetLayoutWithView: (NSView *)aView
{
	return ([[ETWidgetLayout layoutClassForLayoutView: aView] isEqual: [ETWidgetLayout class]] == NO);
}

- (id) renderViews: (NSArray *)views
{
	NSMutableArray *items = [NSMutableArray arrayWithCapacity: [views count]];

	FOREACH([NSArray arrayWithArray: views], view, NSView *)
	{
		[items addObject: [self renderView: view]];
	}
	return items;
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

	if ([self allowsWidgetLayout] && [self canBuildWidgetLayoutWithView: view])
	{
		item = [self renderWidgetLayoutView: view];
	}
	else if ([view isKindOfClass: [NSScrollView class]])
	{
		item = [self renderView: [view documentView]];
		[item setDecoratorItem: [ETScrollableAreaItem itemWithScrollView: view
		                                              objectGraphContext: [itemFactory objectGraphContext]]];
	}
	else if ([view isKindOfClass: [NSBox class]])
	{
		item = [itemFactory itemGroupWithFrame: [view frame]];
		[item addItems: [self renderViews: [view subviews]]];
		// TODO: Decorate with ETGroupBoxItem/ETBoxedAreaItem
	}
	else if ([view isSupervisorView] && [view layoutItem] == nil)
	{
		item = [itemFactory performSelector: [view defaultItemFactorySelector]];
		[item setSupervisorView: view];
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
		[item addItems: [self renderViews: [view subviews]]];
	}
	else
	{
		item = [itemFactory itemWithView: view];
	}

	NSParameterAssert([item isLayoutItem]);

	/* Fixed layouts such as ETFreeLayout are expected to restore the 
		   initial view frame on the item. */
	[item setPersistentFrame: [item frame]];

	return item;
}

/** Returns a new layout item group using the layout returned by
-[ETWidgetLayout initWithLayoutView:]. When no matching layout exists, nil is 
returned. */
- (id) renderWidgetLayoutView: (NSView *)aView
{
	NSUInteger initialAutoresizing = (NSUInteger)[aView autoresizingMask];
	NSRect initialFrame = [aView frame];
	ETWidgetLayout *layout =
		[[ETWidgetLayout alloc] initWithLayoutView: aView
	                            objectGraphContext: [itemFactory objectGraphContext]];
	if (nil == layout)
		return nil;

	ETLayoutItemGroup *item = [itemFactory itemGroupWithFrame: initialFrame];
	[item setAutoresizingMask: initialAutoresizing];
	[item setLayout: layout];

	ETAssert([aView isEqual: [layout layoutView]] && [aView superview] != nil);

	return item;
}

// TODO: Think about it and implement...
- (id) renderMenu: (NSMenu *)menu
{
	return nil;
}

@end
