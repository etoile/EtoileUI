/*
	Copyright (C) 2009 Eric Wasylishen

	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  August 2009
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "NSObject+EtoileUI.h"
#import "ETTitleBarItem.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETTitleBarView.h"
#import "ETLayoutItemFactory.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

#define NC [NSNotificationCenter defaultCenter]

@implementation ETTitleBarItem

- (id) initWithSupervisorView: (ETView *)supervisorView
{
	self = [super initWithSupervisorView: AUTORELEASE([[ETView alloc] init])];
	if (nil == self)
	{
		return nil;
	}
	
	_titleBarView = AUTORELEASE([[ETTitleBarView alloc] init]);
	[[self supervisorView] addSubview: _titleBarView];
	[_titleBarView setTarget: self];
	[_titleBarView setAction: @selector(toggleExpanded:)];
	
	[self tile];
	
	return self;
}

- (id) init
{
	return [self initWithSupervisorView: nil];
}

- (void) tile
{
	ETAssert([[self supervisorView] autoresizesSubviews]);

	/* Don't set _contentView autoresizing mask here, because 
	   -saveAndOverrideAutoresizingMaskOfDecoratedItem: does it at the right time */;
	[_titleBarView setAutoresizingMask: 
		([self isFlipped] ? NSViewWidthSizable : NSViewMinYMargin | NSViewWidthSizable)];	 
	
	float width = [[self supervisorView] frame].size.width;
	float height = [[self supervisorView] frame].size.height;
	float barHeight = 24;
	NSRect contentFrame;
	NSRect titleBarFrame;
	
	if ([self isFlipped])	 
	{
		titleBarFrame = NSMakeRect(0, 0, width, barHeight);
		contentFrame = NSMakeRect(0, barHeight, width, height - barHeight);
	}	 
	else	 
	{
		titleBarFrame = NSMakeRect(0, height - barHeight, width, barHeight);
		contentFrame = NSMakeRect(0, 0, width, height - barHeight);	
	}
	
	[_titleBarView setFrame: titleBarFrame];
	[_contentView setFrame: contentFrame];
}
	

- (void) handleDecorateItem: (ETUIItem *)item 
             supervisorView: (ETView *)decoratedView 
                     inView: (ETView *)parentView 
{
	if (decoratedView != _contentView)
	{
		if (nil != _contentView)
		{
			[_contentView removeFromSuperview];
		}
		_contentView = decoratedView;
		[[self supervisorView] addSubview: _contentView];
		//[[self supervisorView] setWrappedView: decoratedView];
	}

	if ([item isLayoutItem])
	{
		[_titleBarView setTitleString: [(ETLayoutItem *)item displayName]];
	}
	[self tile];

	/* -handleDecorateItem:supervisorView:inView: ensures 
	   [[item supervisorView] autoresizingMask] is set to NSViewWidthSizable and 
	   NSViewHeightSizable by -saveAndOverrideAutoresizingMaskOfDecoratedItem: */
	[super handleDecorateItem: item supervisorView: nil inView: parentView];
}

- (void) handleUndecorateItem: (ETUIItem *)item
               supervisorView: (ETView *)decoratedView 
                       inView: (ETView *)parentView 
{
	if (nil != _contentView)
	{
		[_contentView removeFromSuperview];
		//[[self supervisorView] setWrappedView: nil];
		_contentView = nil;
	}
	[self tile];
	[super handleUndecorateItem: item supervisorView: nil inView: parentView];
}

- (void) toggleExpanded: (id)sender
{
	if ([_titleBarView isExpanded])
	{
		ETLayoutItem *item = [self firstDecoratedItem];

		[item setHeight: _expandedHeight];
		[_contentView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];

		/* We retile the subviews in case [self isFlipped] returns NO */ 
		//[self tile];
		if ([self isFlipped] == NO)
		{
			[_contentView setY: 0];
			[_titleBarView setY: [_contentView height]];
		}

		// NOTE: See note in the else block...
		[item setNeedsLayoutUpdate];
		[[item parentItem] setNeedsLayoutUpdate];
	}
	else
	{
		/* We don't draw the bottom border when the item is collapsed, except 
		   when the item is the last one. By substracting one pixel to the title 
		   bar height, we can hide the bottom border. */
		ETLayoutItem *item = [self firstDecoratedItem];
		BOOL isLastItem = ([item isEqual: [[item parentItem] lastItem]]);
		
		_expandedHeight = [[self firstDecoratedItem] height];

		[_contentView setAutoresizingMask: NSViewNotSizable];
		[item setHeight: (isLastItem ? 24 : 24 - 1)];

		/* We retile the subviews in case [self isFlipped] returns NO */ 
		if ([self isFlipped] == NO)
		{
			[_contentView setY: -([_contentView height] + 1)];
			[_titleBarView setY: -1];
		}

		// NOTE: Because we have the content view not sizable when the title 
		// bar item supervisor view is resized, it doesn't resize the decorated 
		// item bound to the content view.
		[item setNeedsLayoutUpdate];
		[[item parentItem] setNeedsLayoutUpdate];
	}
}

@end
