/*  <title>ETLayer</title>

	ETLayer.m
	
	<abstract>Layer class models the traditional layer element, very common in 
	Computer Graphics applications.</abstract>
 
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

#import <EtoileFoundation/Macros.h>
#import "ETLayer.h"
#import "ETApplication.h"
#import "ETContainer.h"
#import "ETCompatibility.h"
#import "ETLayoutItem+Factory.h"
#import "ETWindowItem.h"
#import "NSWindow+Etoile.h"

#define DEFAULT_FRAME NSMakeRect(0, 0, 200, 200)


@implementation ETLayer

- (id) init
{
	ETContainer *containerAsLayer = [[ETContainer alloc] initWithFrame: DEFAULT_FRAME];
	
	AUTORELEASE(containerAsLayer);
    self = (ETLayer *)[super initWithView: (NSView *)containerAsLayer];
    
    if (self != nil)
    {
		_visible = YES;
		_outOfFlow = YES;
    }
    
    return self;
}

/** Sets whether the layer view has its frame bound to the one of its parent 
	container or not.
	If you change the value to NO, the layer view will be processed during 
	layout rendering as any other layout items. 
	See -movesOutOfLayoutFlow for more details. */
- (void) setMovesOutOfLayoutFlow: (BOOL)floating
{
	_outOfFlow = floating;
}

/** Returns whether the layer view has its frame bound to the one of its parent 
	container. Layouts items are usually displayed in some kind of flow unlike
	layers which are designed to float over their parent container layout.
	Returns YES by default. */
- (BOOL) movesOutOfLayoutFlow
{
	return _outOfFlow;
}

- (void) setVisible: (BOOL)visibility
{
	_visible = visibility;
}

- (BOOL) isVisible
{
	return _visible;
}

@end


@implementation ETWindowLayer

/** Returns a new bordeless panel which can be used as a temporary root window 
when a layout other than ETWindowLayout is set on the receiver. */
- (NSWindow *) _createRetainedRootWindow
{
	NSPanel *win = [[NSPanel alloc] initWithFrame: [self frame] 
	                                  styleMask: NSBorderlessWindowMask];
	[win center];
	[win setFloatingPanel: YES];
	[win setContentView: [self supervisorView]];

	return win;
}

- (id) init
{
	SUPERINIT

	_rootWindow = [self _createRetainedRootWindow];
	_visibleWindows = [[NSMutableArray alloc] init];
	[self setLayout: [ETWindowLayout layout]];

	return self;
}

DEALLOC(DESTROY(_rootWindow); DESTROY(_visibleWindows));

- (void) handleAttachViewOfItem: (ETLayoutItem *)item
{
	// Disable ETLayoutItemGroup implementation that would remove the display 
	// view of the item from its superview. If a window decorator is bound to 
	// the item, the display view is the window view (NSThemeFrame on Mac OS X)
	// Removing NSThemeFrame results in a very weird behavior: the window 
	// remains visible but a -lockFocus assertion is thrown on mouse down.
}

- (void) handleDetachViewOfItem: (ETLayoutItem *)item
{
	// Ditto. More explanations in -handleDetachItem:.
}

- (void) handleAttachItem: (ETLayoutItem *)item
{
	RETAIN(item);
	/* Before setting the decorator, the item must have become a child of the 
	   window layer, because -[super handleAttachItem:] triggers 
	   -handleDetachItem: in the existing parent of this item. -[previousParent 
	   handleDetachItem:] then removes the item display view from its superview 
	   by the mean of -[previousParent handleDetachViewOfItem:], and if 
	   -setDecoratorItem: has already been called, removing the item display 
	   view will mean removing the window view returned by 
	   -[ETWindowItem supervisorView] (NSThemeFrame on Mac OS X).
	   Hence you can expect problems similar to what is described 
	   -[ETWindowLayer handleAttachViewOfItem:] if you change the order of the 
	   code.
	   Take note that the overriden -handleDetachViewOfItem: in ETWindowLayer 
	   doesn't help here, because -handleDetachViewOfItem: is called on the old 
	   parent. */	
	[super handleAttachItem: item];
	// NOTE: We could eventually check whether the item to decorate already 
	// has a window decorator before creating a new one that will be 
	// refused by -setDecoratorItem: and hence never used. 
	[[item lastDecoratorItem] setDecoratorItem: [ETWindowItem layoutItem]];
	RELEASE(item);
}

- (void) handleDetachItem: (ETLayoutItem *)item
{
	RETAIN(item);
	/* Detaching the item before removing the window decorator doesn't result 
	   in removing the window view (NSThemeFrame on Mac OS X) because 
	   ETWindowLayer overrides -handleDetachViewOfItem:. */
	[super handleDetachItem: item];
	[[[item windowDecoratorItem] decoratedItem] setDecoratorItem: nil];
	RELEASE(item);
}

- (void) setLayout: (ETLayout *)aLayout
{
	if ([_layout isKindOfClass: [ETWindowLayout class]])
		[self hideHardWindows];

	if ([aLayout isKindOfClass: [ETWindowLayout class]])
		[self showHardWindows];

	[super setLayout: aLayout];
}

/** Hides currently visible WM-based windows that decorate the items owned by 
the receiver. 

You should never call this method unless you write an ETWindowLayout subclass. */
- (void) hideHardWindows
{
	[_visibleWindows removeAllObjects];

	/* Display our root window before ordering out all visible windows, 
	   it literally covers the small delay that might be needed to order out the 
	   current windows.
	   FIXME: Moreover on GNUstep our root window won't receive the focus if we 
	   try to do that once all current windows have been ordered out. */
	[_rootWindow setFrame: [[NSScreen mainScreen] visibleFrame] display: NO];
	[_rootWindow makeKeyAndOrderFront: self];

	FOREACH([ETApp windows], win, NSWindow *)
	{
		if ([win isEqual: _rootWindow] == NO)
		{
			if ([win isVisible] && [win isSystemPrivateWindow] == NO)
			{
				ETDebugLog(@"%@ will order out %@", self, win);
				[_visibleWindows addObject: win];
				[win orderOut: self];
			}
		}	
	}
}

/** Shows all the previously visible WM-based windows that decorate the 
items owned by the receiver. 

You should never call this method unless you write an ETWindowLayout subclass. */
- (void) showHardWindows
{
	FOREACH(_visibleWindows, win, NSWindow *)
	{
		[win orderFront: self];
	}
	[_rootWindow orderOut: self];
}


@end

@implementation ETWindowLayout

/*- (void) tearDown
{
	
}*/

@end
