/*  <title>ETWidgetLayout</title>

	ETWidgetLayout.m

	<abstract>An abstract layout class whose subclasses adapt and wrap complex 
	widgets provided by widget backends such as tree view, popup menu, etc. and 
	turn them into pluggable layouts.</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009

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

#import "ETWidgetLayout.h"
#import "ETLayoutItem+Events.h"
#import "ETCompatibility.h"
#import "ETContainer.h"

@interface ETContainer (ETEventHandling)
- (void) mouseDoubleClickItem: (ETLayoutItem *)item;
@end

@interface ETWidgetLayout (Private)
- (NSInvocation *) invocationForSelector: (SEL)selector;
- (void) sendInvocationToDisplayView: (NSInvocation *)inv;
- (NSView *) layoutViewWithoutScrollView;
@end

@implementation ETWidgetLayout

/** Returns YES to indicate the receiver adapts and wraps a widget as a layout.

See also -[ETLayout isWidget].*/
- (BOOL) isWidget
{
	return YES;	
}

/** Returns YES to indicate the receiver don't let the layout context items draw 
themselves, but delegate it the wrapped widget.

See also -[ETLayout isOpaque].*/
- (BOOL) isOpaque
{
	return YES;	
}

/* Various adjustements necessary when layout object is a wrapper around an 
   AppKit view. This method is called on a regular basis each time a setting of
   the container is modified and needs to be mirrored on the display view. */
- (void) syncLayoutViewWithItem: (ETLayoutItem *)item
{
	if ([self layoutView] == nil && [[item supervisorView] isKindOfClass: [ETContainer class]] == NO)
		return;

	ETContainer *container = (ETContainer *)[item supervisorView];
	NSInvocation *inv = nil;
	SEL doubleAction = @selector(doubleClick:);
	
	inv = RETAIN([self invocationForSelector: @selector(setDoubleAction:)]);
	[inv setArgument: &doubleAction atIndex: 2];
	[inv invoke];
	
	inv = RETAIN([self invocationForSelector: @selector(setTarget:)]);
	[inv setArgument: &self atIndex: 2];
	[inv invoke];
	
	BOOL hasVScroller = [container hasVerticalScroller];
	BOOL hasHScroller = [container hasHorizontalScroller];
	
	if ([container isScrollViewShown] == NO)
	{
		hasVScroller = NO;
		hasHScroller = NO;
	}
	
	inv = RETAIN([self invocationForSelector: @selector(setHasHorizontalScroller:)]);
	[inv setArgument: &hasHScroller atIndex: 2];
	[inv invoke];
	
	inv = RETAIN([self invocationForSelector: @selector(setHasVerticalScroller:)]);
	[inv setArgument: &hasVScroller atIndex: 2];
	[inv invoke];
	
	BOOL allowsEmptySelection = YES; // FIXME: [[self attachedInstrument] allowsEmptySelection];
	BOOL allowsMultipleSelection = YES; // FIXME: [[self attachedInstrument] allowsMultipleSelection];
	
	inv = RETAIN([self invocationForSelector: @selector(setAllowsEmptySelection:)]);
	[inv setArgument: &allowsEmptySelection atIndex: 2];
	[inv invoke];
	
	inv = RETAIN([self invocationForSelector: @selector(setAllowsMultipleSelection:)]);
	[inv setArgument: &allowsMultipleSelection atIndex: 2];
	[inv invoke];

	RELEASE(inv); /* Retained previously otherwise it gets released too soon */
}

- (NSInvocation *) invocationForSelector: (SEL)selector
{
	NSMethodSignature *sig = [[self layoutView] methodSignatureForSelector: selector];
	id target = [self layoutView];

	if (sig == nil)
	{
		sig = [[self layoutViewWithoutScrollView] methodSignatureForSelector: selector];
		target = [self layoutViewWithoutScrollView];
	}

	if (sig == nil)
		return nil;

	NSInvocation *inv = [NSInvocation invocationWithMethodSignature: sig];
	/* Method signature doesn't embed the selector, but only type infos related to it */
	[inv setSelector: selector];
	[inv setTarget: target];
	
	return inv;
}

/** Returns the control view enclosed in the layout view if the latter is a
scroll view, otherwise the returned view is identical to -layoutView. */
- (NSView *) layoutViewWithoutScrollView
{
	id layoutView = [self layoutView];

	if ([layoutView isKindOfClass: [NSScrollView class]])
		return [layoutView documentView];

	return layoutView;
}

/** <override-subclass /> */
- (ETLayoutItem *) doubleClickedItem
{
	return nil;	
}

/** Forwards the double click to the action handler bound to the layout context.

Can be overriden by subclasses to update internal or external state in reaction 
to a double click in the widget view. The superclass implementation must always 
be called. */
- (void) doubleClick: (id)sender
{
	NSView *layoutView = [self layoutViewWithoutScrollView];

	NSAssert1(layoutView != nil, @"Layout must not be nil if a double action "
		@"is handed by the layout %@", sender);
	NSAssert2([sender isEqual: layoutView], @"sender %@ must be the layout "
		@"view %@ currently in uses", sender, layoutView);

	ETDebugLog(@"Double action in %@ with selected items %@", sender,
		[self selectedItems]);

	[[(ETLayoutItemGroup *)[self layoutContext] actionHandler] handleDoubleClickItem: [self doubleClickedItem]];
}

@end
