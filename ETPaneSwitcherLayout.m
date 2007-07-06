//
//  ETPaneSwitcherLayout.m
//  Container
//
//  Created by Quentin Mathé on 07/06/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ETPaneSwitcherLayout.h"
#import "ETPaneLayout.h"
#import "ETStackLayout.h"
#import "ETLineLayout.h"
#import "ETLayoutItem.h"
#import "ETContainer.h"
#import "GNUstep.h"

#import "ETTableLayout.h"

/* For debugging, it might be practical to comment the following lines */
#define USE_INTERNAL_LAYOUT
#define USE_SWITCHER

@interface ETPaneSwitcherLayout (Private)
- (ETViewLayout *) internalLayout;
- (void) setInternalLayout: (ETViewLayout *)layout;
- (NSImageView *) imageViewForImage: (NSImage *)image;
- (NSArray *) switcherTabItems;
//- (void) syncItemsOfInternalContainer;
@end

@implementation ETPaneSwitcherLayout

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		_internalContainer = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 400, 400)];
		
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
	DESTROY(_internalContainer);
	DESTROY(_switcherItem);
	DESTROY(_contentItem);
	[super dealloc];
}

- (ETViewLayout *) switcherLayout
{
	return [[self switcherContainer] layout];
}

- (void) setSwitcherLayout: (ETViewLayout *)layout
{
	if ([self switcherContainer] == nil)
		[self resetSwitcherContainer];
	
	[[self switcherContainer] setLayout: layout];
}

/** By default the content layout is of style pane layout. */
- (ETViewLayout *) contentLayout
{
	return [[self contentContainer] layout];
}

- (void) setContentLayout: (ETViewLayout *)layout
{
	if ([self contentContainer] == nil)
		[self resetContentContainer];
		
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
}

/** O means hidden switcher
	1 top switcher, bottom content
	2 top content, bottom switcher 
	3 left switcher, right content
	4 right switcher, left content */
- (int) switcherPosition
{
	return 0;
}

- (void) setSwitcherPosition: (int)position
{
	Class layoutClass = nil;
	
	switch (position)
	{
		case 0:
		case 1:
		case 2:
			layoutClass = [ETStackLayout class];
			break;
		case 3:
		case 4:
			layoutClass = [ETLineLayout class];
			break;
		default:
			NSLog(@"Invalid switcher position for %@", self);
	}
	
	// FIXME: Remove line below.
	//layoutClass = [ETStackLayout class];
	[self setInternalLayout: [[layoutClass alloc] init]];
	NSAssert1([_internalContainer layout] != nil, @"Internal layout cannot be nil in %@", self);
	[[self container] updateLayout];
}

- (ETViewLayout *) internalLayout
{
	return [_internalContainer layout];
}

- (void) setInternalLayout: (ETViewLayout *)layout
{
	[_internalContainer setLayout: layout];
}

- (void ) resetSwitcherContainer
{
	ETContainer *switcherView = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 400, 50)];
	
	if ([[_internalContainer items] containsObject: _switcherItem])
		[_internalContainer removeItem: _switcherItem];
	ASSIGN(_switcherItem, [ETLayoutItem layoutItemWithView: switcherView]);
	[_switcherItem setName: @"PaneSwitcher"];
	[_internalContainer addItem: _switcherItem];
	
	[self setSwitcherLayout: AUTORELEASE([[ETLineLayout alloc] init])];
			
	/* Post condition tests */
	ETLayoutItem *item = [[_internalContainer items] objectWithValue: @"PaneSwitcher" forKey: @"name"];
	NSAssert1(item != nil, @"Found nil item matching PaneSwitcher in %@", _internalContainer);
	NSAssert1([item view] != nil, @"Found nil item matching PaneSwitcher in %@", _internalContainer);
	// -isEqual: ETLineLayout
	//NSAssert1([(ETContainer *)[item view] layout] != nil, @"Found nil item matching PaneSwitcher in %@", _internalContainer);
}

- (void ) resetContentContainer
{
	ETContainer *contentView = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 400, 350)];

	if ([[_internalContainer items] containsObject: _contentItem])
		[_internalContainer removeItem: _contentItem];
	ASSIGN(_contentItem, [ETLayoutItem layoutItemWithView: contentView]);
	[_contentItem setName: @"PaneContent"];
	[_internalContainer addItem: _contentItem];
	
	[self setContentLayout: AUTORELEASE([[ETPaneLayout alloc] init])];
	
	/* Post condition tests */
	ETLayoutItem *item = [[_internalContainer items] objectWithValue: @"PaneContent" forKey: @"name"];
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
            initWithFrame: NSMakeRect(0, 0, [image size].width, [image size].height)];
        
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

- (void) testRenderWithLayoutItems { }

- (void) renderWithLayoutItems: (NSArray *)items inContainer: (ETContainer *)container
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

#ifdef USE_INTERNAL_LAYOUT		
	/* First renders myself always made of two containers packed in a wrapper 
	   container. */
	[_internalContainer setFrame: [container frame]];
	[_internalContainer setFrameOrigin: NSZeroPoint];
	// NOTE: Following line is roughly close to [_internalContainer updateLayout] */
	[self computeViewLocationsForLayoutModel: nil inContainer: _internalContainer];
#endif

	/* Update layout in a way equivalent to [[layoutObject container] updateLayout] */
	[[self contentLayout] renderWithLayoutItems: items inContainer: contentView];
	/* Content layout preempts item views over switcher layout. To eliminate 
	   this issue, first switcher layout tries to use properties like value, 
	   image, icon, name. Eventually it makes a copy of the item view as an
	   image which can be easily displayed. */
#ifdef USE_SWITCHER
	[[self switcherLayout] renderWithLayoutItems: [self switcherTabItemsForPaneItems: items] 
	                                 inContainer: switcherView];
#endif
	/* Don't forget to remove existing display view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	[container setDisplayView: nil];
	
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
	if ([[container subviews] containsObject: _internalContainer] == NO)
		[container addSubview: _internalContainer];
#else
	[switcherView removeFromSuperview];
	[container addSubview: switcherView];
	[contentView removeFromSuperview];
	[container addSubview: contentView];
	NSLog(@"Add view %@ at %@", contentView, NSStringFromRect([contentView frame]));
	NSAssert2([[container subviews] containsObject: contentView], 
		@"View %@ must be a subview of container %@", contentView, container);
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
- (ETViewLayoutLine *) layoutLineForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer
{
	return nil;
}

/* Not necessary to override, but better to be sure it returns nil */
- (NSArray *) layoutModelForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer
{
	return nil;
}

- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container
{
	if ([[_internalContainer layout] isMemberOfClass: [ETStackLayout class]])
	{
		switch ([self switcherPosition])
		{
			case 0:
				break;
			case 1:
				NSAssert1(_switcherItem != nil, @"Missing item matching PaneSwitcher in %@", _internalContainer);
				
				if ([_internalContainer indexOfItem: _switcherItem] > 0)
				{
					[_internalContainer removeItem: _switcherItem];
					[_internalContainer insertItem: _switcherItem atIndex: 0];
				}
				break;
			case 2:
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
	}
	else if ([[_internalContainer layout] isMemberOfClass: [ETLineLayout class]])
	{
		switch ([self switcherPosition])
		{
			case 0:
				break;
			case 3:
				break;
			case 4:
				break;
			default:
				NSLog(@"Invalid switcher position with line layout for %@", self);
		}
	}
	else
	{
		NSLog(@"Internal layout of %@ must be either of type ETStackLayout or ETLineLayout", self);
	}
	
	[_internalContainer updateLayout];
}


@end
