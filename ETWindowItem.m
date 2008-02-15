/*  <title>ETWindowItem</title>

	ETWindowItem.m
	
	<abstract>ETLayoutItem subclass which makes possibe to decorate any layout 
	items with a window.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
 
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

#import <EtoileUI/ETWindowItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayoutItemGroup+Factory.h>
#import <EtoileUI/NSWindow+Etoile.h>
#import <EtoileUI/ETCompatibility.h>

#define IS_EMPTY_STRING(x) (x == nil || [x isEqual: @""])
#define NC [NSNotificationCenter defaultCenter]

@implementation ETWindowItem

+ (id) layoutItemWithWindow: (NSWindow *)window
{
	return AUTORELEASE([[self alloc] initWithWindow: window]);
}

/** <init /> */
- (id) initWithWindow: (NSWindow *)window
{
	self = [super initWithView: nil value: nil representedObject: nil];
	
	if (self != nil)
	{
		if (window != nil)
		{
			ASSIGN(_itemWindow, window);
		}
		else
		{
			_itemWindow = [[NSWindow alloc] init];
		}
		[_itemWindow setDelegate: self];
		_usesCustomWindowTitle = (IS_EMPTY_STRING([_itemWindow title]) == NO);
	}
	
	ETLog(@"Init item %@ with window %@", self, _itemWindow);
	
	return self;
}

/** Discards all usual ETLayoutItem item parameters view, value and represented 
	object and calls -initWithWindow: designated initializer. */
- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
{
	return [self initWithWindow: nil];
}

- (void) dealloc
{
	ETLog(@"Dealloc item %@ with window %@", self, _itemWindow);
	[_itemWindow close];
	/* Don't release a window which is in charge of releasing itself.
	   We are usually in the middle of a window close handling and -dealloc has
	   been called as a side-effect of removing the decorated item from the 
	   window layer in -windowWillClose: notification. */
	if ([_itemWindow isReleasedWhenClosed] == NO)
		DESTROY(_itemWindow);
	
	[super dealloc];
}

/* -windowWillClose: ins't appropriate because it would be called when the window 
   is sent -close on window item release/deallocation (see -dealloc). */
- (BOOL) windowShouldClose: (NSNotification *)notif
{
	/* If the window doesn' t get hidden on close, we release the item 
	   we decorate simply by removing it from the window layer */
	if ([[self window] isReleasedWhenClosed])
		[[ETLayoutItemGroup windowGroup] removeItem: [self firstDecoratedItem]];
		
	return YES;
}

- (NSWindow *) window
{
	return _itemWindow;
}

- (BOOL) usesCustomWindowTitle
{
	return _usesCustomWindowTitle;
}

/* Overriden Methods */

/** Returns YES when item can be decorated with a window by the receiver, 
	otherwise returns no. */
- (BOOL) canDecorateItem: (id)item
{
	/* Will call back -[item acceptsDecoratorItem: self] */
	BOOL canDecorate = [super canDecorateItem: item];
	
	/*if (canDecorate && [item decoratorItem] != nil)
	{
		ETLog(@"To be decorated with a window, item %@ must have no existing "
			@"decorator item %@", item, [item decoratorItem]);
		canDecorate = NO;
	}*/
	if (canDecorate && [item isKindOfClass: [ETWindowItem class]])
	{
		ETLog(@"To be decorated with a window, item %@ must not be a window "
			@"item %@", item, [item decoratorItem]);
		canDecorate = NO;
	}

	return canDecorate;
}

/* A window can never be decorated */
- (BOOL) acceptsDecoratorItem: (ETLayoutItem *)item
{
	return NO;
}

/** Returns NO to refuse decorating an item. This happens when item has already
	a decorator item since ETWindowItem instance must always be inserted as
	the last decorator item. */
- (void) handleDecorateItem: (ETLayoutItem *)item inView: (ETView *)parentView;
{
	id window = [self window];

	/* -handleDecorateItem:inView: will call back 
	   -[ETWindowItem setDecoratedView:] which overrides ETLayoutItem.
	   We pass nil instead of parentView because we want to move the decorated
	   item view into the window and not reinsert it once decorated into its
	   superview. Reinserting into the existing superview is the usual behavior 
	   implemented by -handleDecorateItem:inView: that works well when the 
	   decorator is a view  (box, scroll view etc.). */
	[super handleDecorateItem: item inView: nil];
	
	if (item != nil) /* Window decorator is set up */
	{
		/* Move decorated item into the window layer
		   Take note the item might be already part of the window group if the 
		   decoration was triggered by [ETWindowLayer addItem:] instead of 
		   calling -setDecoratorItem: directly. */
		//[[ETLayoutItemGroup windowGroup] addItem: item];

		// TODO: Use KVB by default to bind the window title
		if ([self usesCustomWindowTitle] == NO)
			[window setTitle: [[self firstDecoratedItem] displayName]];
		[window makeKeyAndOrderFront: self];
		//[item updateLayout];
	}
	else /* Window decorator is teared down */
	{
		/* Remove decorated item from the window layer
		   Take note the item might be already removed from the window group if 
		   the decoration was triggered by [ETWindowLayer removeItem:] */
		//[[ETLayoutItemGroup windowGroup] removeItem: item];
		[window orderOut: self];
	}
}

- (NSView *) view
{
	return [[self window] contentView];
}

/*- (void) setView: (NSView *)view
{
	[[self window] setContentView: view];
}*/
- (void) setDecoratedView: (NSView *)view
{
	NSWindow *window = [self window];
	
if (view != nil)
{
	NSRect rect = [window frame];
	NSPoint topLeftPoint = NSMakePoint(rect.origin.x, rect.size.height);

	rect = [window frameRectForContentRect: [view frame]];
	[window setFrame: rect display: NO];
	[window setFrameTopLeftPoint: topLeftPoint];
}
	[window setContentView: view];
	[window flushWindowIfNeeded];
	[window display];
	RETAIN(window);
}

- (void) setView: (NSView *)view
{

}

- (id) supervisorView
{
	return [[[self window] contentView] superview]; // NSThemeFrame on Mac OS X
}

@end
