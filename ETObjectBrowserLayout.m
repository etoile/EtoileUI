/*
	ETObjectBrowserLayout.m
	
	A layout view which implements a reusable object browser supporting 
	CoreObject and EtoileUI object models
 
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

#import <EtoileUI/ETObjectBrowserLayout.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETOutlineLayout.h>
#import <EtoileUI/ETCollection.h>
#import <EtoileUI/NSObject+EtoileUI.h>
#import <EtoileUI/NSIndexPath+Etoile.h>
#import <EtoileUI/ETCompatibility.h>

#define PALETTE_FRAME NSMakeRect(200, 200, 400, 200)
#define itemGroupView (id)[self layoutView]


@implementation ETObjectBrowserLayout

- (id) browsedObject
{
	return [[self layoutContext] representedObject];
}

- (id) init
{
	return [self initWithLayoutView: nil];
}

- (ETLayout *) initWithLayoutView: (NSView *)view
{
	self = [super initWithLayoutView: nil];
	
	if (self != nil)
	{
		id container = [[ETContainer alloc] initWithFrame: PALETTE_FRAME];
		
		[container setLayout: AUTORELEASE([[ETOutlineLayout alloc] init])];
		[container setSource: self];
		[container setDelegate: self];
		[container setDoubleAction: @selector(doubleClickInItemGroupView:)];
		[container setTarget: self];
		[container setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
		[self setLayoutView: container];
		//[self awakeFromNib];
		RELEASE(container);
	}
	
	return self;
}

- (void) setLayoutView: (NSView *)protoView
{
	[super setLayoutView: protoView];
	// NOTE: nothing special right now
}

- (void) awakeFromNib
{
	[itemGroupView setLayout: AUTORELEASE([[ETOutlineLayout alloc] init])];
	[itemGroupView setSource: self];
	[itemGroupView setDelegate: self];
	[itemGroupView setDoubleAction: @selector(doubleClickInItemGroupView:)];
	[itemGroupView setTarget: self];
}

- (void) renderWithLayoutItems: (NSArray *)items;
{
	[self setUpLayoutView];
	[itemGroupView reloadAndUpdateLayout];
}

- (void) doubleClickInItemGroupView: (id)sender
{
	ETLayoutItem *item = [[itemGroupView items] objectAtIndex: [itemGroupView selectionIndex]];
	
	[item browse: self];
}

- (int) container: (ETContainer *)container numberOfItemsAtPath: (NSIndexPath *)path
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
	
	ETLog(@"Returns %d as number of items in %@", nbOfItems, container);
	
	return nbOfItems;
}

- (ETLayoutItem *) container: (ETContainer *)container itemAtPath: (NSIndexPath *)path
{
	id viewItem = [(id)[self layoutView] layoutItem];
	id itemGroup = nil;
	id contentArray = nil;
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
					
		if ([object isCollection])
		{
			item = [ETLayoutItemGroup layoutItemWithRepresentedObject: object];
		}
		else
		{
			item = [ETLayoutItem layoutItemWithRepresentedObject: object];
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
	
	ETLog(@"Returns item %@ at path %@ in %@", item, path, container);

	return item;
}

- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container
{
	return [NSArray arrayWithObjects: @"name", @"description", @"frame", nil]; // @"frame", @"model",
}

@end


@implementation ETObjectBrowser

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		/* UI set up */
		ETContainer *browserView = [[ETContainer alloc] initWithFrame: PALETTE_FRAME layoutItem: self];
		int windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask;

		// FIXME: Update this code when a layout item representation exists for NSWindow instances.
		window = [[NSWindow alloc] initWithContentRect: PALETTE_FRAME
											 styleMask: windowStyle
											   backing: NSBackingStoreBuffered
												 defer: YES];

		[browserView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
		[browserView setLayout: [ETObjectBrowserLayout layout]];
		[window setContentView: browserView];
		[window setTitle: _(@"Object Browser")];
		RELEASE(browserView);
		
		_browsedObject = nil;
	}
	
	return self;
}

- (void) dealloc
{
	DESTROY(window);
	DESTROY(_browsedObject);
	
	[super dealloc];
}

- (id) browsedObject
{
	return [self representedObject];
}

- (void) setBrowsedObject: (id)object
{
	[self setRepresentedObject: object];
	[self reloadAndUpdateLayout];
}

- (NSWindow *) window
{
	return window;
}

- (NSPanel *) panel
{
	return (NSPanel *)window;
}

- (IBAction) browse: (id)sender
{
	[[NSApplication sharedApplication] sendAction: @selector(browse:) to: nil from: sender];
}

@end
