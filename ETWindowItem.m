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
#import <EtoileUI/NSWindow+Etoile.h>
#import <EtoileUI/ETCompatibility.h>


@implementation ETWindowItem

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
	}
	
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
	DESTROY(_itemWindow);
	
	[super dealloc];
}

- (NSWindow *) window
{
	return _itemWindow;
}

/* Overriden Methods */

/** Returns YES when item can be decorated with a window by the receiver, 
	otherwise returns no. */
- (BOOL) canDecorateItem: (id)item
{
	/* Will call back -[item acceptsDecoratorItem: self] */
	BOOL canDecorate = [super canDecorateItem: item];
	
	if (canDecorate && [item decoratorItem] != nil)
	{
		ETLog(@"To be decorated with a window, item %@ must have no existing "
			@"decorator item %@", item, [item decoratorItem]);
		canDecorate = NO;
	}
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
	the last decorator item */
- (void) handleDecorateItem: (ETLayoutItem *)item inView: (ETView *)parentView;
{
	id window = [self window];

	/* Will call back -[ETWindowItem setView:] overriden version */
	[super handleDecorateItem: item inView: parentView]; 
	// TODO: Use KVB by default to bind the window title
	[window setTitle: [[self firstDecoratedItem] displayName]];
	[window makeKeyAndOrderFront: self];
	[item updateLayout];
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
	[[self window] setContentView: view];
}

- (id) supervisorView
{
	return [[[self window] contentView] superview]; // NSThemeFrame on Mac OS X
}

@end
