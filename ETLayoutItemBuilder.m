/*
	ETLayoutItemBuilder.m
	
	Description forthcoming.
 
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

#import <EtoileUI/ETLayoutItemBuilder.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayer.h>
#import <EtoileUI/ETView.h>
#import <EtoileUI/ETCompatibility.h>


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
	ETLayer *windowLayer = [ETLayer layer];
	NSEnumerator *e = [[app windows] objectEnumerator];
	NSWindow *window = nil;
	id item = nil;

	/* Build window items */
	while ((window = [e nextObject]) != nil)
	{
		item = [self renderWindow: window];
		[windowLayer addItem: item];
	}
	
	/* Build pickboards */
	[windowLayer addItem: 
		[self renderPasteboard: [NSPasteboard generalPasteboard]]];

	return item;	
}

- (id) renderWindow: (id)window
{
	id windowDecorator = [ETLayoutItem layoutItem];
	id item = [self renderView: [window contentView]];

	[windowDecorator setRepresentedObject: window];
	[[item lastDecoratorItem] setDecoratorItem: windowDecorator];

	return item;
}

- (id) renderView: (id)view
{
	if ([view isKindOfClass: [ETView class]] || [view isContainer])
	{
		return [view layoutItem];
	}
	else
	{
		id item = [ETLayoutItemGroup layoutItemWithView: view];
		// NOTE: -addItem: moves subview when subviews is enumerated, hence we have
		// to iterate over a separate collection which isn't mutated.
		// May be we could avoid moving subviews in -addItem: when they are 
		// going to be reinserted at the location where they have been removed.
		NSEnumerator *e = [[NSArray arrayWithArray: [view subviews]] objectEnumerator];
		NSView *subview = nil;

		while ((subview = [e nextObject]) != nil)
		{
			[item addItem: [self renderView: subview]];
		}
		
		return item;
	}
}

- (id) renderMenu: (id)menu
{
	return nil;
}

@end
