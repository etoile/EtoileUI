/*	<title>ETPaneSwitcherLayout</title>

	ETPaneSwitcherLayout.m

	<abstract>Description forthcoming.</abstract>

	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
 
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
#import "ETPaneSwitcherLayout.h"
#import "ETPaneLayout.h"
#import "ETStackLayout.h"
#import "ETLineLayout.h"
#import "ETLayoutItem+Factory.h"
#import "ETLayoutItemGroup.h"
#import "ETContainer.h"
#import "GNUstep.h"

#import "ETTableLayout.h"

/* For debugging, it might be practical to comment the following lines */
#define USE_INTERNAL_LAYOUT
//#define USE_SWITCHER

@interface ETPaneSwitcherLayout (Private)
- (ETLayout *) internalLayout;
- (void) setInternalLayout: (ETLayout *)layout;
- (NSImageView *) imageViewForImage: (NSImage *)image;
- (NSArray *) switcherTabItemsForPaneItems: (NSArray *)items;
- (void) syncItemsOfDisplayContainersWithItems: (NSArray *)items;
- (IBAction) switchPane: (id)sender;
//- (void) syncItemsOfInternalContainer;
@end

@implementation ETPaneSwitcherLayout

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		_internalContainer = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 400, 400)];
		/* Let content view and switcher view handles mouse click on their own */
		[_internalContainer setEnablesHitTest: YES];
		
		/* We cannot yet know container/view related to both content and 
		   switcher layout, that's why we create placeholder items waiting for 
		   a view. */
		[self resetSwitcherContainer];
		[self resetContentContainer];
		
		[self setSwitcherPosition: 1]; /* Will set internal layout */
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
		
	DESTROY(_internalContainer);
	DESTROY(_switcherItem);
	DESTROY(_contentItem);
	[super dealloc];
}

// FIXME: When a new container is bound to the layout, undo any modifications 
// made on previous container on which was set the layout.
- (void) setContainer: (ETContainer *)container
{
	/* Disconnect layout from container */
	if ([self container] != nil)
	{
		[[NSNotificationCenter defaultCenter] 
			removeObserver: self 
					  name: ETItemGroupSelectionDidChangeNotification
					object: [[self container] layoutItem]];
		[_internalContainer removeFromSuperview];
	}	

	/* Connect layout to container */
	// FIXME: Use layout context
	//[super setContainer: container];
	
	[[NSNotificationCenter defaultCenter] 
		addObserver: self 
		   selector: @selector(itemGroupSelectionDidChange:) 
		       name: ETItemGroupSelectionDidChangeNotification  
			 object: [[self container] layoutItem]];
	/* Let content view and switcher view handles mouse click on their own */
	[[self container] setEnablesHitTest: YES];
}

- (ETLayout *) switcherLayout
{
	return [[self switcherContainer] layout];
}

- (void) setSwitcherLayout: (ETLayout *)layout
{
	if ([self switcherContainer] == nil)
		[self resetSwitcherContainer];

	NSArray *items = [[self container] items];
	
	NSLog(@"-setSwitcherLayout: with items %@", items);

	/* Sync items of the switcher with items of container using 
	   ETPaneSwitcherLayout. */
	[[self switcherContainer] removeAllItems];
	[[self switcherContainer] addItems: [self switcherTabItemsForPaneItems: items]];
	[[self switcherContainer] setLayout: layout];
	/*[[self switcherLayout] renderWithLayoutItems: [self switcherTabItemsForPaneItems: items] 
							         inContainer: switcherView];*/
}

/** By default the content layout is of style pane layout. */
- (ETLayout *) contentLayout
{
	return [[self contentContainer] layout];
}

- (void) setContentLayout: (ETLayout *)layout
{
	if ([self contentContainer] == nil)
		[self resetContentContainer];

	NSArray *items = [[self container] items];
			
	NSLog(@"-setContentLayout: with items %@", items);

	/* Sync items of the content with items of container using 
	   ETPaneSwitcherLayout. */
	[[self contentContainer] removeAllItems];
	[[self contentContainer] addItems: items];
	[[self contentContainer] setLayout: layout];
}

- (ETContainer *) switcherContainer
{
	//NSAssert([[_switcherItem view] isKindOf
	
	return (ETContainer *)[_switcherItem view];
}

- (void) setSwitcherContainer: (ETContainer *)container
{
	if (container == nil)
		NSLog(@"For -setSwitcherContainer: in %@, container must not be nil", self); // FIXME: Throw exception
		
	[_switcherItem setView: (NSView *)container];
	[[NSNotificationCenter defaultCenter] 
		addObserver: self 
		   selector: @selector(itemGroupSelectionDidChange:) 
		       name: ETItemGroupSelectionDidChangeNotification  
			 object: [container layoutItem]];
}

- (ETContainer *) contentContainer
{
	return (ETContainer *)[_contentItem view];
}

- (void) setContentContainer: (ETContainer *)container
{
	if (container == nil)
		NSLog(@"For -setContentContainer: in %@,  container must not be nil", self); // FIXME: Throw exception
		
	[_contentItem setView: (NSView *)container];
	[[NSNotificationCenter defaultCenter] 
		addObserver: self 
		   selector: @selector(itemGroupSelectionDidChange:) 
		       name: ETItemGroupSelectionDidChangeNotification  
			 object: [container layoutItem]];
}

/** O means hidden switcher
	1 top switcher, bottom content
	2 top content, bottom switcher 
	3 left switcher, right content
	4 right switcher, left content */
- (ETPaneSwitcherPosition) switcherPosition
{
	return _switcherPosition;
}

- (void) setSwitcherPosition: (ETPaneSwitcherPosition)position
{
	Class layoutClass = nil;
	
	_switcherPosition = position;
	
	switch (position)
	{
		case 0:
		case ETPaneSwitcherPositionTop:
		case ETPaneSwitcherPositionBottom:
			layoutClass = [ETStackLayout class];
			break;
		case ETPaneSwitcherPositionLeft:
		case ETPaneSwitcherPositionRight:
			layoutClass = [ETLineLayout class];
			break;
		default:
			NSLog(@"Invalid switcher position for %@", self);
	}
	
	// FIXME: Remove line below.
	//layoutClass = [ETStackLayout class];
	[self setInternalLayout: [[layoutClass alloc] init]];
	NSAssert1([_internalContainer layout] != nil, @"Internal layout cannot be nil in %@", self);
	
	/* -[self updateLayout] -> -[self computeViewLocationsForLayoutModel:] 
	   -> -[_internalContainer updateLayout] */
	[[self container] updateLayout];
}

- (ETLayout *) internalLayout
{
	return [_internalContainer layout];
}

- (void) setInternalLayout: (ETLayout *)layout
{
	[_internalContainer setLayout: layout];
}

- (void ) resetSwitcherContainer
{
	ETContainer *switcherView = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 400, 100)];
	ETContainer *prevSwitcherView = (ETContainer *)[_switcherItem view];
	
	if (prevSwitcherView != nil)
	{
		[[NSNotificationCenter defaultCenter] 
			removeObserver: self 
					  name: ETItemGroupSelectionDidChangeNotification 
					object: [prevSwitcherView layoutItem]];
	}	
	[[NSNotificationCenter defaultCenter] 
		addObserver: self 
		   selector: @selector(itemGroupSelectionDidChange:) 
		       name: ETItemGroupSelectionDidChangeNotification 
			 object: [switcherView layoutItem]];
			 
	if ([[_internalContainer items] containsObject: _switcherItem])
		[_internalContainer removeItem: _switcherItem];
	ASSIGN(_switcherItem, [ETLayoutItem layoutItemWithView: switcherView]);
	[_switcherItem setName: @"PaneSwitcher"];
	[_internalContainer addItem: _switcherItem];
	
	[self setSwitcherLayout: AUTORELEASE([[ETLineLayout alloc] init])];
			
	/* Post condition tests */
	ETLayoutItem *item = [[_internalContainer items] firstObjectMatchingValue: @"PaneSwitcher" forKey: @"name"];
	NSAssert1(item != nil, @"Found nil item matching PaneSwitcher in %@", _internalContainer);
	NSAssert1([item view] != nil, @"Found nil item matching PaneSwitcher in %@", _internalContainer);
	// -isEqual: ETLineLayout
	//NSAssert1([(ETContainer *)[item view] layout] != nil, @"Found nil item matching PaneSwitcher in %@", _internalContainer);
}

- (void ) resetContentContainer
{
	ETContainer *contentView = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 400, 300)];
	ETContainer *prevContentView = (ETContainer *)[_contentItem view];
	
	if (prevContentView != nil)
	{
		[[NSNotificationCenter defaultCenter] 
			removeObserver: self 
					  name: ETItemGroupSelectionDidChangeNotification 
					object: [prevContentView layoutItem]];
	}	
	[[NSNotificationCenter defaultCenter] 
		addObserver: self 
		   selector: @selector(itemGroupSelectionDidChange:) 
		       name: ETItemGroupSelectionDidChangeNotification 
			 object: [contentView layoutItem]];
			 
	if ([[_internalContainer items] containsObject: _contentItem])
		[_internalContainer removeItem: _contentItem];
	ASSIGN(_contentItem, [ETLayoutItem layoutItemWithView: contentView]);
	[_contentItem setName: @"PaneContent"];
	[_internalContainer addItem: _contentItem];
	
	[self setContentLayout: AUTORELEASE([[ETPaneLayout alloc] init])];
	
	/* Post condition tests */
	ETLayoutItem *item = [[_internalContainer items] firstObjectMatchingValue: @"PaneContent" forKey: @"name"];
	NSAssert1(item != nil, @"Found nil item matching PaneContent in %@", _internalContainer);
	NSAssert1([item view] != nil, @"Found nil item matching PaneContent in %@", _internalContainer);
	// -isEqual: ETLineLayout
	//NSAssert1([(ETContainer *)[item view] layout] != nil, @"Found nil item matching PaneSwitcher in %@", _internalContainer);
}

/* Layouting */

- (NSImageView *) imageViewForImage: (NSImage *)image
{
	if (image != nil)
    {
        NSImageView *view = [[NSImageView alloc] 
            initWithFrame: NSMakeRect(0, 0, 48, 48)];
        
		[image setScalesWhenResized: YES];
		[view setImageScaling: NSScaleProportionally];
        [view setImage: image];

		return (NSImageView *)AUTORELEASE(view);
    }

    return nil;
}

- (NSArray *) switcherTabItemsForPaneItems: (NSArray *)items
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *paneItem = nil;
	NSMutableArray *tabItems = [NSMutableArray array];
	
	while ((paneItem = [e nextObject]) != nil)
	{
		ETLayoutItem *tabItem = [paneItem copy];
		NSImage *img = nil;
		
		img = [tabItem valueForProperty: @"icon"];
		if (img == nil)
			img = [tabItem valueForProperty: @"image"];	
		if (img == nil)
		{
			NSLog(@"WARNING: Pane item  %@ has no image or icon available to be displayed in switcher of %@", 
				paneItem, [self container]);
			/*NSAssert([img isEqual: [paneItem valueForProperty: @"image"]] ||
					 [img isEqual: [paneItem valueForProperty: @"icon"]], 
					  @"Pane and tab items must have identical values by properties");*/
		}
		[tabItem setView: [self imageViewForImage: img]];
		[tabItems addObject: tabItem];
	}
	
	return tabItems;
}

/* Propagate pane switch from switcher to content, and additionaly from 
   immediate container to switcher when selection is done in code through 
   methods like -[ETPaneSwitcherLayout setSelectionIndex:] */
- (void) itemGroupSelectionDidChange: (NSNotification *)notif
{
	NSLog(@"Propagate selection change from %@ in %@", [notif object], [self container]);
	
	// NOTE: Not really proud of the following code, but right now I'm unable
	// to work out a solution which is as safe and simple as the one below.
	
	if ([[notif object] isEqual: [self switcherContainer]]) /* User clicks inside pane switcher view */
	{
		int index = [[self switcherContainer] selectionIndex];
		
		if ([[self container] selectionIndex] != index)
		{
			[[self container] setSelectionIndex: index];
		}
		else
		{
			NSLog(@"WARNING: Encounter incorrect selection sync in switcher subcontainer of %@", self);
		}
	}
	else if ([[notif object] isEqual: [self container]]) /* Selection is set in code or triggered by previous branch statement */
	{
		int index = [[self container] selectionIndex];
		 
		if ([[self contentContainer] selectionIndex] != index)
		{
			[[self contentContainer] setSelectionIndex: index];
		}
		else
		{
			NSLog(@"WARNING: Encounter incorrect selection sync in content subcontainer of %@", self);
		}
		
		/* Update switcher container only if needed to avoid an infinite loop */
		if ([[self switcherContainer] selectionIndex] != index)
			[[self switcherContainer] setSelectionIndex: index];
	}
}

- (void) testRenderWithLayoutItems { }

- (void) syncItemsOfDisplayContainersWithItems: (NSArray *)items;
{
	[[self contentContainer] removeAllItems];
	[[self contentContainer] addItems: items];
	[[self switcherContainer] removeAllItems];
	[[self switcherContainer] addItems: [self switcherTabItemsForPaneItems: items]];
	
	/* Select an item if none is already and keep display containers in sync */
	if ([[[self container] items] count] > 0)
	{
		int index = [[self container] selectionIndex];
		
		if (index == NSNotFound)
			index = 0;
		
		/* Will propagate to switcher container and content container through 
		    itemGroupSelectionDidChange: */
		[[self container] setSelectionIndex: index];
		
		NSAssert1([[self container] selectionIndex] != NSNotFound, 
			@"Selection index (%d) must be different from NSNotFound", [[self container] selectionIndex]);
	}
	NSAssert2([[self container] selectionIndex] == [[self contentContainer] selectionIndex], 
		@"Selection index mismatch between pane switcher container (%d) and related content container (%d)",
		[[self container] selectionIndex], [[self contentContainer] selectionIndex]);
}

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	if ([self contentLayout] == nil)
	{	
		NSLog(@"For % content layout cannot be nil", self); 
		return; // FIXME: throw exception
	}
	
	if ([self switcherLayout] == nil)
	{
		NSLog(@"For % switcher layout cannot be nil", self); 
		return; // FIXME: throw exception
	}
		
	ETContainer *switcherView = [self switcherContainer];
	ETContainer *contentView = [self contentContainer];
	
	/* When no container is bound to switcher and/or content layout, we create
	   such container as needed. */
	
	if (contentView == nil)
	{
		NSLog(@"Found nil container of content layout in %@", self);
		[self resetContentContainer];
	}
	
	if (switcherView == nil)
	{
		NSLog(@"Found nil container of switcher layout in %@", self);
		[self resetSwitcherContainer];
	}
	
	[self syncItemsOfDisplayContainersWithItems: items];

#ifdef USE_INTERNAL_LAYOUT		
	/* First renders myself always made of two containers packed in a wrapper 
	   container. */
	[_internalContainer setFrame: [[self container] frame]];
	[_internalContainer setFrameOrigin: NSZeroPoint];
	[self computeLayoutItemLocationsForLayoutModel: nil];
#endif

	/* Update layout in a way equivalent to [[layoutObject container] updateLayout] */
	[[self contentLayout] renderWithLayoutItems: items isNewContent: YES];
	/* Content layout preempts item views over switcher layout. To eliminate 
	   this issue, first switcher layout tries to use properties like value, 
	   image, icon, name. Eventually it makes a copy of the item view as an
	   image which can be easily displayed. */
#ifdef USE_SWITCHER
	[switcherView setItemScaleFactor: [[self layoutContext] itemScaleFactor]];
	[[self switcherLayout] renderWithLayoutItems: [self switcherTabItemsForPaneItems: items]];
#endif
	/* Don't forget to remove existing display view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	[[self container] setLayoutView: nil];
	
	/* Move internal item switcher and content container into enclosing container */
	// NOTE: Done by [_internalContainer updateLayout]
	/*[switcherView removeFromSuperview];
	if ([[_internalContainer subviews] containsObject: switcherView] == NO)
		[_internalContainer addSubview: switcherView];
	[contentView removeFromSuperview];
	if ([[_internalContainer subviews] containsObject: contentView] == NO)
		[_internalContainer addSubview: contentView];*/

#ifdef USE_INTERNAL_LAYOUT	
	/* Put wrapper container in the container which delegates its layout to us */
	if ([[[self container] subviews] containsObject: _internalContainer] == NO)
		[[self container] addSubview: _internalContainer];
#else
	[switcherView removeFromSuperview];
	[[self container] addSubview: switcherView];
	[contentView removeFromSuperview];
	[[self container] addSubview: contentView];
	NSLog(@"Add view %@ at %@", contentView, NSStringFromRect([contentView frame]));
	NSAssert2([[[self container] subviews] containsObject: contentView], 
		@"View %@ must be a subview of container %@", contentView, [self container]);
#endif
	
	// FIXME: Write post conditions code checking everything is properly wired up.

}

#if 0
- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		NSRect unscaledFrame = [item defaultFrame];
		
		if ([item view] != nil)
		{
			[[item view] setFrame: ETScaleRect(unscaledFrame, factor)];
			//NSLog(@"Scale %@ to %@", NSStringFromRect(unscaledFrame), 
			//	NSStringFromRect(ETScaleRect(unscaledFrame, factor)));
		}

		if ([item view] == nil)
			NSLog(@"% can't be rescaled because it has no view");
	}
}
#endif

/* Not necessary to override, but better to be sure it returns nil */
- (ETLayoutLine *) layoutLineForLayoutItems: (NSArray *)items
{
	return nil;
}

/* Not necessary to override, but better to be sure it returns nil */
- (NSArray *) layoutModelForLayoutItems: (NSArray *)items
{
	return nil;
}

- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel
{
	if ([[_internalContainer layout] isMemberOfClass: [ETStackLayout class]])
	{
		switch ([self switcherPosition])
		{
			case 0:
				break;
			case ETPaneSwitcherPositionTop:
				NSAssert1(_switcherItem != nil, @"Missing item matching PaneSwitcher in %@", _internalContainer);
				
				if ([_internalContainer indexOfItem: _switcherItem] > 0)
				{
					[_internalContainer removeItem: _switcherItem];
					[_internalContainer insertItem: _switcherItem atIndex: 0];
				}
				break;
			case ETPaneSwitcherPositionBottom:
				NSAssert1(_contentItem != nil, @"Missing item matching PaneContent in %@", _internalContainer);
				
				if ([_internalContainer indexOfItem: _contentItem] > 0)
				{
					[_internalContainer removeItem: _contentItem];
					[_internalContainer insertItem: _contentItem atIndex: 0];
				}
				break;
			default:
				NSLog(@"Invalid switcher position with stack layout %@", self);
		}
		/*[[self switcherContainer] setFrame: NSMakeRect(0, 0, 400, 100)];
		[[self contentContainer] setFrame: NSMakeRect(0, 0, 400, 300)];*/
		NSLog(@"Resize for top or bottom");
		[_switcherItem setDefaultFrame: NSMakeRect(0, 0, 400, 100)];
		[_contentItem setDefaultFrame: NSMakeRect(0, 0, 400, 300)];
	}
	else if ([[_internalContainer layout] isMemberOfClass: [ETLineLayout class]])
	{
		switch ([self switcherPosition])
		{
			case 0:
				break;
			case ETPaneSwitcherPositionLeft:
				NSAssert1(_switcherItem != nil, @"Missing item matching PaneSwitcher in %@", _internalContainer);
				
				if ([_internalContainer indexOfItem: _switcherItem] > 0)
				{
					[_internalContainer removeItem: _switcherItem];
					[_internalContainer insertItem: _switcherItem atIndex: 0];
				}
				break;
			case ETPaneSwitcherPositionRight:
				NSAssert1(_contentItem != nil, @"Missing item matching PaneContent in %@", _internalContainer);
				
				if ([_internalContainer indexOfItem: _contentItem] > 0)
				{
					[_internalContainer removeItem: _contentItem];
					[_internalContainer insertItem: _contentItem atIndex: 0];
				}
				break;
			default:
				NSLog(@"Invalid switcher position with line layout for %@", self);
		}
		/*[[self switcherContainer] setFrame: NSMakeRect(0, 0, 100, 400)];
		[[self contentContainer] setFrame: NSMakeRect(0, 0, 300, 400)];*/
		NSLog(@"Resize for left or right");
		[_switcherItem setDefaultFrame: NSMakeRect(0, 0, 100, 400)];
		[_contentItem setDefaultFrame: NSMakeRect(0, 0, 300, 400)];
	}
	else
	{
		NSLog(@"Internal layout of %@ must be either of type ETStackLayout or ETLineLayout", self);
	}
	
	[_internalContainer updateLayout];
}


@end
