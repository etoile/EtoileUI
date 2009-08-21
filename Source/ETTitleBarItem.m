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
#import "ETLayoutItem+Factory.h"
#import "ETTitleBarView.h"
#import "ETUIItemFactory.h"
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
	/* Reset autoresizing */
	//[_contentView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[_titleBarView setAutoresizingMask: NSViewWidthSizable];	 
	[[self supervisorView] setAutoresizesSubviews: YES];
	
	float width = [[self supervisorView] frame].size.width;
	float height = [[self supervisorView] frame].size.height;
	float barHeight = 24;
	NSRect contentFrame;
	NSRect titleBarFrame;
	
	if (_contentView != nil)	 
	{	 
		if ([self isFlipped])	 
		{	 
			titleBarFrame = NSMakeRect(0, 0, width, barHeight);
			contentFrame = NSMakeRect(0, barHeight, width, height -barHeight);
		}	 
		else	 
		{	 
			titleBarFrame = NSMakeRect(0, 0, width, barHeight);
			contentFrame = NSMakeRect(0, barHeight, width, height -barHeight);
		}	 
	}	 
	else	 
	{	 
		if ([self isFlipped])	 
		{
			titleBarFrame = NSMakeRect(0, 0, width, barHeight);
			contentFrame = NSMakeRect(0, barHeight, width, height -barHeight);
		}	 
		else	 
		{
			titleBarFrame = NSMakeRect(0, 0, width, barHeight);
			contentFrame = NSMakeRect(0, barHeight, width, height -barHeight);
		}	 
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
	}
	
	if ([item isLayoutItem])
	{
		[_titleBarView setTitleString: [(ETLayoutItem *)item displayName]];
	}
	[self tile];	 

	[super handleDecorateItem: item supervisorView: nil inView: parentView];
}

- (void) handleUndecorateItem: (ETUIItem *)item
               supervisorView: (NSView *)decoratedView 
                       inView: (ETView *)parentView 
{
	if (nil != _contentView)
	{
		[_contentView removeFromSuperview];
		_contentView = nil;
	}
	[self tile];
	[super handleUndecorateItem: item supervisorView: nil inView: parentView];
}

- (NSRect) contentRect
{	
	NSRect frame = [[self supervisorView] frame];
	//frame.size.height += [_titleBarView frame].size.height;
	//frame.origin.y -= [_titleBarView frame].size.height;
	return frame;
}

- (void) toggleExpanded: (id)sender
{
	if ([_titleBarView isExpanded])
	{		
		NSRect frame = [[self supervisorView] frame];
		frame.size.height = 240;
		[[self supervisorView] setFrame: frame];		
	}
	else
	{
		NSRect frame = [[self supervisorView] frame];
		frame.size.height = 24;
		[[self supervisorView] setFrame: frame];
	}
}

@end
