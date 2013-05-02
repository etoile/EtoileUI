/*  <title>ETObjectBrowserLayout</title>

	ETObjectBrowserLayout.m
	
	<abstract>A layout view which implements a reusable object browser 
	supporting CoreObject and EtoileUI object models</abstract>
 
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

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import <EtoileFoundation/NSString+Etoile.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import "ETObjectBrowserLayout.h"
#import "ETView.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETOutlineLayout.h"
#import "ETWindowItem.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"

#define PALETTE_FRAME NSMakeRect(200, 200, 600, 300)
#define mainViewItem (ETLayoutItemGroup *)[(ETView *)[self layoutView] layoutItem]

@interface ETObjectBrowserLayout (Private)
- (NSArray *) displayedItemPropertiesInItemGroup: (ETLayoutItemGroup *)baseItem;
@end


@implementation ETObjectBrowserLayout

// TODO: To be removed once this layout is not just an outline view. Then 
// -isScrollable should be added and returns NO.
- (BOOL) hasScrollers
{
	return YES;
}

- (id) browsedObject
{
	return [(ETLayoutItem *)[self layoutContext] representedObject];
}

- (ETLayout *) initWithLayoutView: (NSView *)view
{
	self = [super initWithLayoutView: nil];
	
	if (self != nil)
	{
		id mainView = [[ETView alloc] initWithFrame: PALETTE_FRAME];
	
		[mainViewItem setLayout: AUTORELEASE([[ETOutlineLayout alloc] init])];
		[mainViewItem setSource: self];
		[mainViewItem setDelegate: self];
		[mainViewItem setDoubleAction: @selector(doubleClickInItemGroupView:)];
		[mainViewItem setTarget: self];
		//[mainViewItem setHasVerticalScroller: YES];
		//[mainViewItem setHasHorizontalScroller: YES];
		[mainViewItem setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
		[self setLayoutView: mainView];
		//[self awakeFromNib];
		RELEASE(mainView);
	}
	
	return self;
}

- (ETLayoutItemGroup *) rootItem
{
	return [(ETView *)[self layoutView] layoutItem];
}

- (void) setLayoutView: (NSView *)protoView
{
	[super setLayoutView: protoView];
	// NOTE: nothing special right now
}

- (void) awakeFromNib
{
	[mainViewItem setLayout: AUTORELEASE([[ETOutlineLayout alloc] init])];
	//[mainViewItem setSource: self];
	[mainViewItem setDelegate: self];
	[mainViewItem setDoubleAction: @selector(doubleClickInItemGroupView:)];
	[mainViewItem setTarget: self];
}

- (void) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	
	// [mainViewItem setSource: [self browsedObject]];
	[[mainViewItem layout] setDisplayedProperties: [self displayedItemPropertiesInItemGroup: mainViewItem]];
	[mainViewItem setRepresentedObject: [self browsedObject]];
	[mainViewItem setSource: mainViewItem];
	if (isNewContent)
	{
		[mainViewItem reloadAndUpdateLayout];
	}
	else
	{
		[mainViewItem updateLayout];
	}
}

- (void) doubleClickInItemGroupView: (id)sender
{
	ETLayoutItem *item = [[mainViewItem items] objectAtIndex: [mainViewItem selectionIndex]];
	
	[item browse: self];
}

- (int) itemGroup: (ETLayoutItemGroup *)baseItem numberOfItemsAtPath: (NSIndexPath *)path
{
	int nbOfItems = 0;

	NSAssert2(path != nil, @"Index path %@ passed to data source %@ must not "
		@"be nil", path, self);
	
	if ([path length] == 0)
	{
		nbOfItems = [[[self browsedObject] contentArray] count];
	}
	else
	{
		id viewItem = [(id)[self layoutView] layoutItem];
		id itemGroup = [viewItem itemAtIndexPath: path];
		
		if (itemGroup == nil)
		{
			ETLog(@"WARNING: Found no item at subpath %@ for object browser %@", 
				path, self);
			return 0;
		}
		
		NSAssert1([itemGroup isGroup] && [[itemGroup representedObject] isCollection], 
			@"For -itemsAtPath:, path %@ must reference an instance of "
			@"ETLayoutItemGroup kind and the related represented object must be a "
			"collection", path);
		
		nbOfItems = [[[itemGroup representedObject] contentArray] count];
	}
	
	ETDebugLog(@"Returns %d as number of items in %@", nbOfItems, [baseItem supervisorView]);
	
	/* Useful to debug data source and property editing
	if (nbOfItems > 1)	
		return 1; */

	return nbOfItems;
}

- (ETLayoutItem *) itemGroup: (ETLayoutItemGroup *)baseItem itemAtPath: (NSIndexPath *)path
{
	id viewItem = [(id)[self layoutView] layoutItem];
	id itemGroup = nil;
	NSArray *contentArray = nil;
	id object = nil;
	id item = nil;
	
	if ([path length] == 1)
	{
		contentArray = [[self browsedObject] contentArray];
	}
	else /* path length > 1 */
	{
		itemGroup = [viewItem itemAtIndexPath: [path indexPathByRemovingLastIndex]];
		
		if (itemGroup == nil)
		{
			ETLog(@"WARNING: Found no item at subpath %@ for object browser %@", path, self);
			return nil;
		}

		NSAssert1([itemGroup isGroup] && [[itemGroup representedObject] isCollection], 
			@"For -itemsAtPath:, path %@ must reference an instance of "
			@"ETLayoutItemGroup kind and the related represented object must be a "
			"collection", path);
			
		contentArray = [[itemGroup representedObject] contentArray];
	}
	

	if (contentArray != nil && [contentArray count] > 0)
	{
		object = [contentArray objectAtIndex: [path lastIndex]];
		
		// FIXME: -isEmpty should removed here, we should always return aa item
		// group for a collection but disable node visual indicator when the 
		// collection is empty. Probably involves some changes in 
		// ETOutlineLayout, ETBrowserLayout etc.
		if ([object isCollection] && [object isEmpty] == NO)
		{
			item = [[ETLayoutItemFactory factory] itemGroupWithRepresentedObject: object];
		}
		else
		{
			item = [[ETLayoutItemFactory factory] itemWithRepresentedObject: object];
		}
		
		/*if ([object respondsToSelector: @selector(title)])
		{
			[item setValue: [object title] forProperty: @"name"];
		}
		else if ([object respondsToSelector: @selector(name)])
		{
			[item setValue: [object name] forProperty: @"name"];	
		}
		else
		{
			[item setValue: [NSString stringWithFormat: @"%d", [path lastIndex]] 
			   forProperty: @"name"];	
		}
		[item setValue: [object description] forProperty: @"description"];*/
	}
	
	ETDebugLog(@"Returns item %@ at path %@ in %@", item, path, [baseItem supervisorView]);

	return item;
}

- (NSArray *) displayedItemPropertiesInItemGroup: (ETLayoutItemGroup *)baseItem
{
	/* In case, the object browsed is refreshed before the browsed object is set */
	if ([self browsedObject] == nil)
		return [NSArray array];

	return [(NSObject *)[self browsedObject] propertyNames];
}

@end


@implementation ETObjectBrowser

- (void) setUpUI
{
	[self setHasVerticalScroller: YES];
	[self setHasHorizontalScroller: YES];
	[self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[self setLayout: [ETObjectBrowserLayout layout]];

	/* Moves the object browser into to the window layer
	   NOTE: The window item will be released on close. */
	[[self lastDecoratorItem] setDecoratorItem: [[ETWindowItem alloc] init]];
}

/** Initializes a new object browser and decorates it with a window.
	If the object browser is later moved outside of the window layer (in some 
	other part of the layout item tree), the initial window will be lost. */
- (id) init
{
	SUPERINIT;
	[self setFrame: PALETTE_FRAME];
	
	if (self != nil)
	{
		_browsedObject = nil;
		[self setName: _(@"Object Browser")];
		[self setUpUI];
	}
	
	return self;
}

- (void) dealloc
{
	[self stopKVOObservationIfNeeded];
	DESTROY(_browsedObject);
	[super dealloc];
}

/* Overrides -[ETLayoutItem displayName] */
- (NSString *) displayName
{
	NSString *displayName = [self name];
	
	if ([self browsedObject] != nil)
	{
		displayName = [displayName stringByAppendingString: @" - "];
		displayName = [displayName stringByAppendingString: 
			[[self browsedObject] displayName]];
	}
	
	return displayName;
}

- (id) browsedObject
{
	return [self representedObject];
}

- (void) setBrowsedObject: (id)object
{
	[self setRepresentedObject: object];
	[[self window] setTitle: [self displayName]];
	[self reloadAndUpdateLayout];
}

- (NSWindow *) window
{
	return [[self windowItem] window];
}

// FIXME: Implement or remove
- (NSPanel *) panel
{
	return (NSPanel *)[self window];
}

- (IBAction) browse: (id)sender
{
	[[NSApplication sharedApplication] sendAction: @selector(browse:) 
		to: nil from: sender];
}

@end
