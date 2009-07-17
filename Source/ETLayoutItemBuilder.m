/*  <title>ETLayoutItemBuilder</title>

	ETLayoutItemBuilder.m
	
	<abstract>Builder classes that can render document formats or object graphs
	into a layout item tree.</abstract>
 
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

#import <EtoileFoundation/Macros.h>
#import "ETTemplateItemLayout.h"
#import "ETLayoutItemBuilder.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Factory.h"
#import "ETLayoutItemGroup.h"
#import "ETWindowItem.h"
#import "ETLayer.h"
#import "ETView.h"
#import "ETContainer.h"
#import "ETScrollableAreaItem.h"
#import "NSView+Etoile.h"
#import "NSWindow+Etoile.h"
#import "ETCompatibility.h"


/** By inheriting from ETFilter, ETTransform instances can be chained together 
	in a filter/transform unit. For example, you can combine several tree 
	renderers into a new renderer to implement a new transform. */
@implementation ETLayoutItemBuilder

+ (id) builder
{
	return AUTORELEASE([[[self class] alloc] init]);
}

@end

/** Generates a layout item tree from an AppKit-based application */
@implementation ETEtoileUIBuilder

- (id) renderPasteboard: (NSPasteboard *)pasteboard
{
	//ETPickboard *pickboard = nil;
	
	return nil;
}

- (id) renderApplication: (id)app
{
	id windowLayer = [ETLayoutItem windowGroup];
	NSEnumerator *e = [[app windows] objectEnumerator];
	NSWindow *window = nil;
	id item = nil;

	/* Build window items */
	while ((window = [e nextObject]) != nil)
	{
		BOOL isStandaloneWindow = ([[window contentView] isKindOfClass: [ETView class]] == NO);
		if ([window isVisible] && [window isSystemPrivateWindow] == NO && isStandaloneWindow)
		{
			item = [self renderWindow: window];
			//ETLog(@"Rendered window %@ visibility %d into %@", window, [window isVisible], item);
			[windowLayer addItem: item];
		}
	}
	
	/* Build pickboards */
	/*[windowLayer addItem: 
		[self renderPasteboard: [NSPasteboard generalPasteboard]]];*/

	return windowLayer;	
}

#if 1
- (id) renderWindow: (id)window
{
	id item = [self renderView: [window contentView]];
	id windowDecorator = [item windowDecoratorItem];

	//[windowDecorator setRepresentedObject: window];
	/* Decorate only if needed */
	if (windowDecorator == nil)
	{
		windowDecorator = [ETLayoutItem itemWithWindow: window];
		[[item lastDecoratorItem] setDecoratorItem: windowDecorator];
	}

	return item;
}
#else
- (id) renderWindow: (id)window
{
	id contentView = [window contentView];
	id item = nil;
	
	RETAIN(contentView);
	//[window setContentView: nil];
	item = [self renderView: contentView];
	[window setContentView: [item displayView]];
	RELEASE(contentView);
	
	//id container = [[ETContainer alloc] initWithFrame: [contentView frame]];
	//[window setContentView: container];
	
	//id childItem = [[[ETContainer alloc] initWithFrame: [contentView frame]] layoutItem];
	//id childItem = [ETLayoutItem layoutItemGroupWithView: [[NSSlider alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]];
	//[window setContentView: [childItem displayView]];
	
	//[window setContentView: [item supervisorView]];
	
	//[[item displayView] addSubview: [[NSSlider alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]];
	
	return item;
}
#endif

/* When we encounter an EtoileUI native (ETView subclasses), we only return
   the proper layout item, either the item bound to the view or the first 
   decorated item if the view is used as a decorator. We never render 
   subviews of native views since we expect their content is properly set up 
   in term of layout item tree. All other views (other NSView subclasses) 
   are rendered recursively until the end of their view hierachy (-subviews
   returns an empty arrary). */
- (id) renderView: (id)view
{
	id item = nil;

	if ([view isKindOfClass: [NSScrollView class]])
	{
		ETScrollView *scrollViewWrapper = [[ETScrollView alloc] initWithMainView: view layoutItem: nil];
		id scrollDecorator = [scrollViewWrapper layoutItem];

		item = [self renderView: [view documentView]];
		[item setDecoratorItem: scrollDecorator];
	}
	else if ([view isKindOfClass: [ETScrollView class]])
	{
		item = [[view layoutItem] firstDecoratedItem];
	}
	else if ([view isSupervisorView])
	{
		item = [view layoutItem];
	}
	else if ([view isMemberOfClass: [NSView class]])
	{
		id container = [[ETContainer alloc] initWithFrame: [view frame]];

		item = [container layoutItem];
		
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
		item = [ETLayoutItem itemWithView: view];
		RELEASE(view);
	}
	
	/* Fixed layouts such as ETFreeLayout are expected to restore the 
	   initial view frame on the item. */
	[item setPersistentFrame: [item frame]];

	return item;
}

- (id) renderMenu: (id)menu
{
	return nil;
}

/** Returns existing subviews of the receiver as layout items.

First checks whether the receiver responds to -layoutItem and in such case
doesn't already include child items for these subviews. If no, either the
subview is an ETView or an NSView instance. When the subview is NSView-based, a
new layout item is instantiated by calling +itemWithView: with subview as
parameter. Then the new item is automatically inserted as a child item in the
layout item representing the receiver. If the subview is ETView-based, the item
representing the subview is immediately inserted in the receiver item. */
- (NSArray *) itemsWithSubviewsOfView: (NSView *)view
{
	// FIXME: Implement. But is this method really necessary...
	return nil;
}

@end
