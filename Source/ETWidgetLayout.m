/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/runtime.h>
#import "ETWidgetLayout.h"
#import "ETActionHandler.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETCompatibility.h"

@interface ETWidgetLayout (Private)
- (NSInvocation *) invocationForSelector: (SEL)selector;
- (NSView *) layoutViewWithoutScrollView;
@end

@implementation ETWidgetLayout

/** Returns YES to indicate the receiver adapts and wraps a widget as a layout.

See also -[ETLayout isWidget].*/
- (BOOL) isWidget
{
	return YES;	
}

/** <override-dummy />
Returns YES to indicate the receiver makes the content scrollable by itself; 
layout views usually come with their own scrollers.

See also -[ETLayout hasScrollers].*/
- (BOOL) hasScrollers
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

/* Layout Context & Layout View Synchronization */

/** Synchronizes the widget view settings with the given item.

This layout item is usually the layout context.

This method is called on a regular basis each time a setting of the layout 
context is modified and needs to be mirrored on the widget view. */
- (void) syncLayoutViewWithItem: (ETLayoutItem *)item
{
	NSParameterAssert([self layoutView] != nil);
	NSParameterAssert([item supervisorView] != nil);

	NSInvocation *inv = nil;
	SEL doubleAction = @selector(doubleClick:);
	
	inv = RETAIN([self invocationForSelector: @selector(setDoubleAction:)]);
	[inv setArgument: &doubleAction atIndex: 2];
	[inv invoke];
	
	inv = RETAIN([self invocationForSelector: @selector(setTarget:)]);
	[inv setArgument: &self atIndex: 2];
	[inv invoke];
	
	BOOL hasVScroller = [item hasVerticalScroller];
	BOOL hasHScroller = [item hasHorizontalScroller];
	
	if ([item isScrollViewShown] == NO)
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

/** <override-never />
Tells the receiver that the layout view selection has changed and it needs to 
reflect this new selection in the layout context.

Keep in mind this method is invoked by various subclasses such as ETOutlineLayout 
which overrides -selectedItems. */
- (void) didChangeSelectionInLayoutView
{
	ETDebugLog(@"Selection did change to %@ in layout view %@ of %@", 
		[self selectionIndexPaths], [self layoutView], _layoutContext);
	
	/* Update selection state in the layout item tree and post a notification */
	[(id <ETWidgetLayoutingContext>)[_layoutContext ifResponds] 
		setSelectionIndexPaths: [self selectionIndexPaths]];
}

/** Returns the selected item index paths expressed relative to the layout 
context.

This method is used to collect the selection in the layout view reported by 
-selectedItems. For example, -didChangeSelectionInLayoutView invokes it to 
mirror the wdiget selection state on the layout context.

You can synchronize the selection between the layout view and the layout item 
tree with the following code: 
<code>
[[self layoutContext] setSelectionIndexPaths: [self selectionIndexPaths]]
</code>
	
TODO: We need more control over the way we set the selection in the layout 
item tree. To call -setSelectionIndexPaths: presently resets the selection 
state in every descendant item even in invisible descendants (e.g. the children 
bond to a collapsed row in an outline view). Various new methods could be 
introduced like -extendsSelectionIndexPaths: and -restrictsSelectionIndexPaths: 
to synchronize the selection by delta for newly selected and deselected items. 
Another possibility would be a method like -setSelectionIndexPathsInLayout:, but 
its usefulness is more limited. */
- (NSArray *) selectionIndexPaths
{
	NSMutableArray *indexPaths = [NSMutableArray array];

	FOREACH([self selectedItems], item, ETLayoutItem *)
	{
		[indexPaths addObject: [item indexPathFromItem: _layoutContext]];
	}

	return indexPaths;
}

/* Actions */

/** <override-subclass />
Overrides to return the item that was last double-clicked in the layout view. */
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

/* Custom Widget Subclass */

/** <override-always />
Returns the widget view class required by the layout.

You can use the returned class to invoke -updateWidgetView:toClass: when you 
override -setLayoutView:.

By default, returns Nil. */
- (Class) widgetViewClass
{
	return Nil;
}

/** Swizzles the widget class to the target class.

This method raises an invalid argument exception when the class cannot be changed.

For example, NSTableView is swizzled to ETTableView to integrate with pick and drop. */
- (void) upgradeWidgetView: (id)widgetView toClass: (Class)aClass
{
	if ([widgetView isKindOfClass: aClass])
		return;

	if (object_setClass(widgetView, aClass) == Nil)
	{
		[NSException raise: NSInvalidArgumentException format: @"The widget view "
			"class must be either the widget base class, the target class or "
			"a target class subclass."];
	}
}

@end
