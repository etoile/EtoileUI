/*  <title>ETContainer</title>

	ETContainer.m
	
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

#import <EtoileFoundation/NSIndexSet+Etoile.h>
#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETContainer+Controller.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItem+Factory.h>
#import <EtoileUI/ETLayoutItem+Events.h>
#import <EtoileUI/ETEvent.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETLayer.h>
#import <EtoileUI/ETInspector.h>
#import <EtoileUI/ETPickboard.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETCompatibility.h>

NSString *ETContainerSelectionDidChangeNotification = @"ETContainerSelectionDidChangeNotification";
NSString *ETLayoutItemPboardType = @"ETLayoutItemPboardType"; // FIXME: replace by UTI

@interface ETContainer (ETEventHandling)
- (void) mouseDoubleClick: (NSEvent *)event item: (ETLayoutItem *)item;
@end

@interface ETContainer (PackageVisibility)
- (int) checkSourceProtocolConformance;
- (BOOL) isScrollViewShown;
- (void) setShowsScrollView: (BOOL)scroll;
- (BOOL) hasScrollView;
- (void) setHasScrollView: (BOOL)scroll;
@end

@interface ETContainer (Private)
- (void) syncDisplayViewWithContainer;
- (NSInvocation *) invocationForSelector: (SEL)selector;
- (void) sendInvocationToDisplayView: (NSInvocation *)inv;
- (NSView *) layoutViewWithoutScrollView;
- (void) cacheScrollViewDecoratorItem: (ETLayoutItem *)decorator;
- (ETLayoutItem *) cachedScrollViewDecoratorItem;
- (ETLayoutItem *) createScrollViewDecoratorItem;
- (BOOL) doesSelectionContainsPoint: (NSPoint)point;
- (void) fixOwnerIfNeededForItem: (ETLayoutItem *)item;
@end


@implementation ETContainer

- (id) initWithLayoutView: (NSView *)layoutView
{
	self = [self initWithFrame: [layoutView frame]];

	if (self != nil)
	{
		id existingSuperview = [layoutView superview];
		ETLayout *layout = [ETLayout layoutWithLayoutView: layoutView];
		
		if ([existingSuperview isContainer]) // existingSuperview must respond to -layoutItem
		{
		   [(ETContainer *)existingSuperview addItem: [self layoutItem]];
		}
		else // existingSuperview isn't a view-based node in a layout item tree
		{
		   [existingSuperview addSubview: self];
		}

		[self setLayout: layout]; // inject the initial view as a layout
	}
	
	return self;
}

/** <init /> Returns a new container instance that is bound to item. This layout 
     item becomes the abstract representation associated with the new container.
     A container plays the role of a concrete representation specific to the 
     underlying UI toolkit, for a collection of layout items.
     item should be an ETLayoutItemGroup instance in almost all cases.
     The returned container is created by default with a flexible height and 
     width, this autoresizingMask also holds for the layout item bound to it. 
    (see -[ETLayoutItem autoresizingMask]). */
- (id) initWithFrame: (NSRect)rect layoutItem: (ETLayoutItem *)item
{
	if (item != nil && [item isGroup] == NO)
	{
		[NSException raise: NSInvalidArgumentException format: @"Layout item "
			@"parameter %@ must be of class ETLayoutItemGroup for initializing "
			@"an ETContainer instance", item];
	}

	/* Before all, bind layout item group representing the container */

	ETLayoutItemGroup *itemGroup = (ETLayoutItemGroup *)item;
	
	if (itemGroup == nil)
		itemGroup = AUTORELEASE([[ETLayoutItemGroup alloc] init]);

	// NOTE: Very important to destroy ETView layout item to avoid any 
	// layout update in ETLayoutItem
	// -setView: -> -setDefaultFrame: -> -restoreDefaultFrame -> -setFrame:
	// then reentering ETContainer
	// -setFrameSize: -> -canUpdateLayout
	// and failing because [self layoutItem] returns ETLayoutItem instance
	// and not ETLayoutItemGroup instance; ETLayoutItem doesn't respond to
	// -canUpdateLayout...
	self = [super initWithFrame: rect layoutItem: itemGroup];
    
	if (self != nil)
    {
		[self setRepresentedPath: @"/"];
		[self setTemplateItem: nil];
		[self setTemplateItemGroup: nil];
		_subviewHitTest = NO;
		[self setFlipped: YES];
		_itemScale = 1.0;
		// NOTE: Not in use currently (see ivars in the header)
		//_selection = [[NSMutableIndexSet alloc] init];
		_selectionShape = nil;
		_dragAllowed = YES;
		_dropAllowed = YES;
		[self setShouldRemoveItemsAtPickTime: NO];
		[self setAllowsMultipleSelection: YES];
		[self setAllowsEmptySelection: YES];
		_prevInsertionIndicatorRect = NSZeroRect;
		_scrollViewDecorator = nil; /* First instance created by calling private method -setShowsScrollView: */
		_inspector = nil; /* Instantiated lazily in -inspector if needed */
		
		[self registerForDraggedTypes: [NSArray arrayWithObjects:
			ETLayoutItemPboardType, nil]];
		[self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    }
    
    return self;
}

- (id) initWithFrame: (NSRect)rect
{
	return [self initWithFrame: rect layoutItem: nil];
}

- (void) dealloc
{
	// FIXME: Clarify memory management of _displayView and _scrollView
	DESTROY(_doubleClickedItem);
	DESTROY(_displayView);
	DESTROY(_path);
	// NOTE: Not in use currently
	//DESTROY(_selection);
	DESTROY(_selectionShape);
	DESTROY(_inspector);
	DESTROY(_templateItem);
	DESTROY(_templateItemGroup);
	_dataSource = nil;
    
    [super dealloc];
}

/* Archiving */

- (id) archiver: (NSKeyedArchiver *)archiver willEncodeObject: (id)object
{
	ETDebugLog(@"---- Will encode %@", object);
	
	/* Don't encode layout view and item views */
	if ([object isEqual: [self subviews]])
	{
		id archivableSubviews = [object mutableCopy];
		id itemViews = [[self items] valueForKey: @"displayView"];

		ETDebugLog(@"> Won't be encoded");	
		if ([self displayView] != nil)	
			[archivableSubviews removeObject: [self displayView]];
		[itemViews removeObjectsInArray: archivableSubviews];
		return archivableSubviews;
	}
		
	return object;
}

// TODO: Probably implement EtoileSerialize-based archiving (on Etoile only)
- (void) encodeWithCoder: (NSCoder *)coder
{
	if ([coder allowsKeyedCoding] == NO)
	{	
		[NSException raise: NSInvalidArgumentException format: @"ETContainer "
			@"only supports keyed archiving"];
	}

	/* We must disable the encoding of item subviews by catching it on 
	   -[ETView encodeWithCoder:] with call back -archiver:willEncodeObject: */
	[(NSKeyedArchiver *)coder setDelegate: self];
	[super encodeWithCoder: coder];

	/* Don't encode displayView, source, delegate and inspector.
	   NOTE: It could be useful to encode tham as late-bound objects though
	   like [coder encodeLateBoundObject: [self source] forKey: @"ETSource"]; */
	[coder encodeObject: [self scrollView] forKey: @"NSScrollView"];
	[coder encodeBool: [self isDisclosable] forKey: @"ETFlipped"];
	[coder encodeObject: [self representedPath] forKey: @"ETRepresentedPath"];
	[coder encodeBool: [self isHitTestEnabled] forKey: @"ETHitTestEnabled"];	
	[coder encodeObject: NSStringFromSelector([self doubleAction]) 
	          forKey: @"ETDoubleAction"];
	[coder encodeObject: [self target] forKey: @"ETTarget"];
	[coder encodeFloat: [self itemScaleFactor] forKey: @"ETItemScaleFactor"];
	// FIXME: selectionShape not yet implemented
	//[coder encodeObject: [self selectionShape] forKey: @"ETSelectionShape"];

	[coder encodeBool: [self allowsEmptySelection] 
	           forKey: @"ETAllowsMultipleSelection"];
	[coder encodeBool: [self allowsEmptySelection] 
	           forKey: @"ETAllowsEmptySelection"];
	// FIXME: Replace encoding of allowsDragging and allowsDropping by
	// allowedDraggingTypes and allowedDroppingTypes
	[coder encodeBool: [self allowsDragging] forKey: @"ETAllowsDragging"];
	[coder encodeBool: [self allowsDropping] forKey: @"ETAllowsDropping"];
	[coder encodeBool: [self shouldRemoveItemsAtPickTime] 
	           forKey: @"ETShouldRemoveItemAtPickTime"];
			   
	[(NSKeyedArchiver *)coder setDelegate: nil];
}

- (id) initWithCoder: (NSCoder *)coder
{
	self = [super initWithCoder: coder];
	
	if ([coder allowsKeyedCoding] == NO)
	{	
		[NSException raise: NSInvalidArgumentException format: @"ETView only "
			@"supports keyed unarchiving"];
		return nil;
	}
	
	// FIXME: We need to write -setScrollView: or may be come up with some other 
	// way to reconstruct the scroll view decorator
	//[self setScrollView: [coder decodeObjectForKey: @"NSScrollView"]];
	[self setFlipped: [coder decodeBoolForKey: @"ETFlipped"]];
	[self setRepresentedPath: [coder decodeObjectForKey: @"ETRepresentedPath"]];
	[self setEnablesHitTest: [coder decodeBoolForKey: @"ETHitTestEnabled"]];	
	[self setDoubleAction: 
		NSSelectorFromString([coder decodeObjectForKey: @"ETDoubleAction"])];
	[self setTarget: [coder decodeObjectForKey: @"ETTarget"]];
	[self setItemScaleFactor: [coder decodeFloatForKey: @"ETItemScaleFactor"]];
	//[self setSelectionShape: [coder decodeObjectForKey: @"ETSelectionShape"]];

	[self setAllowsMultipleSelection: 
		[coder decodeBoolForKey: @"ETAllowsMultipleSelection"]];
	[self setAllowsEmptySelection: 
		[coder decodeBoolForKey: @"ETAllowsEmptySelection"]];
	[self setAllowsDragging: [coder decodeBoolForKey: @"ETAllowsDragging"]];
	[self setAllowsDropping: [coder decodeBoolForKey: @"ETAllowsDropping"]];
	[self setShouldRemoveItemsAtPickTime: 
		[coder decodeBoolForKey: @"ETShouldRemoveItemAtPickTime"]];

	return self;
}

#if 0
- (void) copyWithZone: (NSZone *)zone
{
	#ifndef ETOILE_SERIALIZE
	id container = [super copyWithZone: zone];
	
	/* Copy objects which doesn't support encoding usually or must not be copied
	   but rather shared by the receiver and the copy. */
	[container setSource: [self source]];
	[container setDelegate: [self delegate]];
	
	
	return container;
	#else
	
	#endif
}
#endif
/** Deep copies are never created by the container itself, but they are instead
	delegated to the item group returned by -layoutItem. When the layout item
	receives a deep copy request it will call back -copy on each view (including
	containers) embedded in descendant items. Subview hierarchy will later get 
	transparently reconstructed when -updateLayout will be called on the 
	resulting layout item tree copy.
	
		View Tree							Layout Item Tree
	
	-> [container deepCopy] 
									-> [containerItem deepCopy] 
	-> [container copy]
									-> [childItem deepCopy]
	-> [subview copy] 
	
	For ETView and ETContainer, view copies created by -copy are shallow copies
	that don't include subviews unlike -copy invoked on NSView and other 
	related subclasses. Layout/Display view isn't copied either. However title 
	bar view is copied unlike other subviews (as explained in -[ETView copy]).
	Remember -[NSView copy] returns a deep copy (view hierachy copy) 
	but -[ETView copy] doesn't. */
- (id) deepCopy
{
	id item = [[self layoutItem] deepCopy];
	id container = [item view];
	
	//NSAssert3([container isKindOfClass: [ETContainer class]], 
	
	return container;
}

- (NSString *) description
{
	NSString *desc = [super description];
	
	desc = [@"<" stringByAppendingString: desc];
	desc = [desc stringByAppendingFormat: @" + %@>", [self layout], nil];
	return desc;
}

- (NSString *) displayName
{
	// FIXME: Trim the angle brackets out.
	return [self description];
}

/** Returns the layout item representing the receiver container in the layout
	item tree. Layout item representing a container is always an instance of
	ETLayoutItemGroup class kind (and not ETLayoutItem unlike ETView).
	Never returns nil. */
- (id) layoutItem
{
	/*NSAssert([[super layoutItem] isGroup], 
		@"Layout item in a container must of ETLayoutItemGroup type");*/
	if ([[super layoutItem] isGroup] == NO)
		ETLog(@"Layout item in a container must of ETLayoutItemGroup type");
	return [super layoutItem];
}

/* Basic Accessors */

/** Returns the represented path which is the model path whose content is 
	currently displayed in the receiver. It is useful to keep track of your 
	location inside the model currently browsed. Tree-related methods 
	implemented by a data source are passed paths which are subpaths of the 
	represented path.
	This path is used as the represented path base in the layout item 
	representing the receiver. [self representedPath] and
	[[self layoutItem] representedPathBase] are equal and must always be.
	[[self layoutItem] representedPath] returns a path which is also identical
	to the previous methods. See ETLayoutItem and ETLayoutItemGroup to know 
	more about path management and understand the difference between a 
	represented path base and a represented path.
	Finally take note represented paths are relative to the container unlike 
	paths returned by -[ETLayoutItem path] which are absolute paths. */
- (NSString *) representedPath
{
	return _path;
}

/** Sets the represented path. Path is only critical when a source is used, 
	otherwise it's up to the developer to track the level of navigation inside 
	the tree structure. 
	Without a source, you can use -setRepresentedPath: as a conveniency to 
	memorize the location currently displayed by the container. In this case, 
	each time the user enters a new level, you are in charge of removing then 
	adding the proper items which are associated with the level requested by 
	the user. Implementing a data source, alleviates you from this task,
	you simply need to return the items, EtoileUI will build takes care of 
	building and managing the tree structure. 
	To set a represented path turning the container into an entry point in your
	model, you should use paths like '/', '/blabla/myModelObjectName'
	You cannot pass an empty string to this method or it will throw an invalid
	argument exception. If you want no represented path, use nil.
	-representedPath is also used by ETLayoutItem as a represented path base, 
	turning the item group related to the container into a base item which 
	handles events. See also -representedPath, -[ETLayoutItem baseItem] and 
	-[ETLayoutItem representedPathBase]. */
- (void) setRepresentedPath: (NSString *)path
{
	if ([path isEqual: @""])
	{
		[NSException raise: NSInvalidArgumentException format: @"For %@ "
			@"-setRepresentedPath argument must never be an empty string", self];
		
	}
	
	ASSIGN(_path, path);
	
	// NOTE: If the selection is cached, here the cache should be cleared
	// [_selection removeAllIndexes]; /* Unset any selection */
	[self updateLayout];
}

/** Returns the source which provides the content displayed by the receiver. 
	A source implements either ETIndexSource or ETPathSource protocols.
	If the container handles the layout item tree directly without the help of
	a source object, then this method returns nil.*/
- (id) source
{
	return _dataSource;
}

/** Sets the source which provides the content displayed by the receiver. 
	A source can be any objects conforming to ETIndexSource or ETPathSource
	protocol, both are variants of ETSource abstract protocol.
	So you can write you own data source object by implementing either:
	1) numberOfItemsInContainer:
	   container:itemAtIndex:
	2) container:numberOfItemsAtPath:
	   container:itemAtPath:
	Another common solution is to use an off-the-shelf controller object like
	ETController, ETTreeController etc. which implements the source protocol
	for you. This works well for basic stuff and brings extra flexibility at
	runtime: you can edit how the controller access the model or simply 
	replaces it by a different one.
	A third solution is to use a component. EtoileUI implements a category on 
	ETComponent (EtoileFoundation class) and this category conforms to 
	ETPathSource protocol. Then every components can be used as a content 
	provider for the receiver.
	By calling -setComponent:, the input source of the component parameter will
	automatically be set as the source of the receiver, replacing any 
	previously set source. Usually you create a new component with 
	-initWithContainer: or -initWithLayoutItem: which handles -setComponent:
	call. 
	Take note that modifying a source is followed by a layout update, the new 
	content is immediately loaded and displayed. By setting a source, the
	receiver represented path is automatically set to '/' unless another path 
	was set previously. If you pass nil to get rid of a source, the represented
	path isn't reset to nil but keeps its actual value in order to maintain it 
	as a base item and avoid disturbing the related event handling logic. */
//- (void) setSource: (id <ETSource>)source
- (void) setSource: (id)source
{
	/* By safety, avoids to trigger extra updates */
	if (_dataSource == source)
		return;
	
	/* Also resets any particular state associated with the container like
	   selection */
	[self removeAllItems];
	
	_dataSource = source;
	
	// NOTE: -setPath: takes care of calling -updateLayout
	if (source != nil && ([self representedPath] == nil || [[self representedPath] isEqual: @""]))
	{
		[self setRepresentedPath: @"/"];
	}
}

- (id) delegate
{
	return _delegate;
}

- (void) setDelegate: (id)delegate
{
	_delegate = delegate;
}

/* Layout */

/** See -[ETLayoutItemGroup isAutolayout] */
- (BOOL) isAutolayout
{
	return [(ETLayoutItemGroup *)[self layoutItem] isAutolayout];
}

/** See -[ETLayoutItemGroup setAutolayout:] */
- (void) setAutolayout: (BOOL)flag
{
	[(ETLayoutItemGroup *)[self layoutItem] setAutolayout: flag];
}

/** See -[ETLayoutItemGroup canUpdateLayout] */
- (BOOL) canUpdateLayout
{
	return [(ETLayoutItemGroup *)[self layoutItem] canUpdateLayout];
}

/** See -[ETLayoutItemGroup updateLayout] */
- (void) updateLayout
{
	[[self layoutItem] updateLayout];
}

/** See -[ETLayoutItemGroup reloadAndUpdateLayout] */
- (void) reloadAndUpdateLayout
{
	[(ETLayoutItemGroup *)[self layoutItem] reloadAndUpdateLayout];
}

/** Returns 0 when source doesn't conform to any parts of ETContainerSource 
	informal protocol.
    Returns 1 when source conform to protocol for flat collections and display 
	of items in a linear style.
	Returns 2 when source conform to protocol for tree collections and display 
	of items in a hiearchical style.
	If tree collection part of the protocol is implemented through 
	-container:numberOfItemsAtPath: , ETContainer by default ignores flat 
	collection part of protocol like -numberOfItemsInContainer. */
- (int) checkSourceProtocolConformance
{
	if ([[self source] isEqual: [self layoutItem]])
	{
		return 3;
	}
	else if ([[self source] respondsToSelector: @selector(container:numberOfItemsAtPath:)])
	{
		if ([[self source] respondsToSelector: @selector(container:itemAtPath:)])
		{
			return 2;
		}
		else
		{
			ETLog(@"%@ implements container:numberOfItemsAtPath: but misses "
				  @"container:itemAtPath: as requested by ETContainerSource "
				  @"protocol.", [self source]);
			return 0;
		}
	}
	else if ([[self source] respondsToSelector: @selector(numberOfItemsInContainer:)])
	{
		if ([[self source] respondsToSelector: @selector(container:itemAtIndex:)])
		{
			return 1;
		}
		else
		{
			ETLog(@"%@ implements numberOfItemsInContainer: but misses "
				  @"container:itemAtIndex as  requested by "
				  @"ETContainerSource protocol.", [self source]);
			return 0;
		}
	}
	else
	{
		ETLog(@"%@ implements neither numberOfItemsInContainer: nor "
			  @"container:numberOfItemsAtPath: as requested by "
			  @"ETContainerSource protocol.", [self source]);
		return 0;
	}
}

/** See -[ETLayoutItemGroup layout] */
- (ETLayout *) layout
{
	return [(ETLayoutItemGroup *)[self layoutItem] layout];
}

/** See -[ETLayoutItemGroup setLayout] */
- (void) setLayout: (ETLayout *)layout
{
	[(ETLayoutItemGroup *)[self layoutItem] setLayout: layout];
}

/* Private helper methods to sync display view and container */

/* Various adjustements necessary when layout object is a wrapper around an 
   AppKit view. This method is called on a regular basis each time a setting of
   the container is modified and needs to be mirrored on the display view. */
- (void) syncDisplayViewWithContainer
{
	NSInvocation *inv = nil;
	
	if (_displayView != nil)
	{
		SEL doubleAction = @selector(forwardDoubleActionFromLayout:);
		id target = self;
		
		inv = RETAIN([self invocationForSelector: @selector(setDoubleAction:)]);
		[inv setArgument: &doubleAction atIndex: 2];
		[self sendInvocationToDisplayView: inv];
		
		inv = RETAIN([self invocationForSelector: @selector(setTarget:)]);
		[inv setArgument: &target atIndex: 2];
		[self sendInvocationToDisplayView: inv];
		
		BOOL hasVScroller = [self hasVerticalScroller];
		BOOL hasHScroller = [self hasHorizontalScroller];
		
		if ([self isScrollViewShown] == NO)
		{
			hasVScroller = NO;
			hasHScroller = NO;
		}
		
		inv = RETAIN([self invocationForSelector: @selector(setHasHorizontalScroller:)]);
		[inv setArgument: &hasHScroller atIndex: 2];
		[self sendInvocationToDisplayView: inv];
		
		inv = RETAIN([self invocationForSelector: @selector(setHasVerticalScroller:)]);
		[inv setArgument: &hasVScroller atIndex: 2];
		[self sendInvocationToDisplayView: inv];
		
		BOOL allowsEmptySelection = [self allowsEmptySelection];
		BOOL allowsMultipleSelection = [self allowsMultipleSelection];
		
		inv = RETAIN([self invocationForSelector: @selector(setAllowsEmptySelection:)]);
		[inv setArgument: &allowsEmptySelection atIndex: 2];
		[self sendInvocationToDisplayView: inv];
		
		inv = RETAIN([self invocationForSelector: @selector(setAllowsMultipleSelection:)]);
		[inv setArgument: &allowsMultipleSelection atIndex: 2];
		[self sendInvocationToDisplayView: inv];
	}
}

- (NSInvocation *) invocationForSelector: (SEL)selector
{
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature: 
		[self methodSignatureForSelector: selector]];
	
	/* Method signature doesn't embed the selector, but only type infos related to it */
	[inv setSelector: selector];
	
	return inv;
}

- (void) sendInvocationToDisplayView: (NSInvocation *)inv
{
	//id result = [[inv methodSignature] methodReturnLength];
	
	if ([_displayView respondsToSelector: [inv selector]])
	{
			[inv invokeWithTarget: _displayView];
	}
	else if ([_displayView isKindOfClass: [NSScrollView class]])
	{
		/* May be the display view is packaged inside a scroll view */
		id enclosedDisplayView = [(NSScrollView *)_displayView documentView];
		
		if ([enclosedDisplayView respondsToSelector: [inv selector]]);
			[inv invokeWithTarget: enclosedDisplayView];
	}
	
	//if (inv != nil)
	//	[inv getReturnValue: &result];
		
	RELEASE(inv); /* Retained in -syncDisplayViewWithContainer otherwise it gets released too soon */
	
	//return result;
}

/** Returns the control view enclosed in the layout view if the latter is a
    scroll view, otherwise the returned view is identical to -layoutView. */
- (NSView *) layoutViewWithoutScrollView
{
	id layoutView = [self displayView];

	if ([layoutView isKindOfClass: [NSScrollView class]])
		return [layoutView documentView];

	return layoutView;
}

- (void) forwardDoubleActionFromLayout: (id)sender
{
	id layout = [self layout];
	NSView *layoutView = [self layoutViewWithoutScrollView];
	NSEvent *evt = [NSApp currentEvent];

	NSAssert1(layoutView != nil, @"Layout must not be nil if a double action "
		@"is handed by the layout %@", sender);
	NSAssert2([sender isEqual: layoutView], @"sender %@ must be the layout "
		@"view %@ currently in uses", sender, layoutView);

	ETDebugLog(@"Double action on %@ in %@ with selected items %@", sender, evt,
		[layout selectedItems]);

	if ([layout respondsToSelector: @selector(doubleClickedItem)])
	{
		[self mouseDoubleClick: evt item: [layout doubleClickedItem]];
	}
	else
	{
		ETLog(@"WARNING: Layout %@ based on a layout view must implement "
			@"-doubleClickedItem", layout);
	}
}

/* Inspecting */

- (IBAction) inspect: (id)sender
{
	ETDebugLog(@"Inspect %@", self);
	[[[self inspector] panel] makeKeyAndOrderFront: self];
}

- (IBAction) inspectSelection: (id)sender
{
	ETDebugLog(@"Inspect %@ selection", self);
	
	NSArray *selectedItems = [(id)[self layoutItem] selectedItemsInLayout];
	id inspector = [self inspectorForItems: selectedItems];
	
	[[inspector panel] makeKeyAndOrderFront: self];
}

- (void) setInspector: (id <ETInspector>)inspector
{
	ASSIGN(_inspector, inspector);
}

/** Returns inspector based on selection unlike ETLayoutItem.
	If the inspector hasn't been set by calling -setInspector:, it gets lazily
	instantiated when this accessors is called. */
- (id <ETInspector>) inspector
{
	return [self inspectorForItems: [NSArray arrayWithObject: [self layoutItem]]];
}

- (id <ETInspector>) inspectorForItems: (NSArray *)items
{
	if (_inspector == nil)
		_inspector = [[ETInspector alloc] init];
		
	[_inspector setInspectedItems: items];
	
	return _inspector;
}

/** Returns whether the receiver uses flipped coordinates or not. 
	Default returned value is YES. */
- (BOOL) isFlipped
{
#ifdef USE_NSVIEW_RFLAGS
 	return _rFlags.flipped_view;
#else
	return _flipped;
#endif
}

/** Unlike NSView, ETContainer uses flipped coordinates by default in order to 
	simplify layout computation.
	You can revert to non-flipped coordinates by passing NO to this method. */
- (void) setFlipped: (BOOL)flag
{
#ifdef USE_NSVIEW_RFLAGS
	_rFlags.flipped_view = flag;
#else
	_flipped = flag;
#endif
}

/* Scrollers */

- (BOOL) letsLayoutControlsScrollerVisibility
{
	return NO;
}


- (void) setLetsLayoutControlsScrollerVisibility: (BOOL)layoutControl
{
	// FIXME: Implement or remove
}

/* About the container scroll view and layouts

   From API viewpoint, it makes little sense to keep these scroller methods if
   we offer a direct access to the underlying scroll view. However a layout view 
   may want to heavily alter the scroll view in a way that only works in this 
   specific layout case. That's why layouts have the choice to use or not the 
   scroll view set up and cached by the container.
   It also makes easier to support AppKit views/controls wrapped in a layout. 
   For example NSBrowser has a method like -setHasHorizontalScroller: but isn't 
   wrapped inside a scroll view. Setting up and tearing down the container 
   scroll view to be reused by a NSTableView-based layout or a NSTextView-based 
   layout would also introduce an extra chunk of non-trivial code.
   We only keep in sync (with the container scroll view) basic properties like 
   scroller visibility, when a layout uses its own scroll view. They are the 
   only scroll view settings which are very commonly altered independently of 
   the presentation (the layout in EtoileUI case). 
   NOTE: Another approach would be move this logic into ETScrollView but obvious 
   benefits have to be found. */

/** Returns YES when the vertical scroller of the current scroll view managed 
	by the container or its layout is visible, otherwise returns NO. */
- (BOOL) hasVerticalScroller
{
	return [[self scrollView] hasVerticalScroller];
}

/** Sets the vertical scroller visibility of the current scroll view that can 
	be owned either by the container or its layout.
	Even if both vertical and horizontal scroller are made invisible, this 
	method won't remove the scroll view managed by the container from the 
	decorator chain bound to its layout item. */
- (void) setHasVerticalScroller: (BOOL)scroll
{
	[self setShowsScrollView: YES];
	[[self scrollView] setHasVerticalScroller: scroll];
	
	/* Updated NSBrowser, NSOutlineView enclosing scroll view etc. */
	[self syncDisplayViewWithContainer];
}

/** Returns YES when the horizontal scroller of the current scroll view managed 
	by the container or its layout is visible, otherwise returns NO. */
- (BOOL) hasHorizontalScroller
{
	return [[self scrollView] hasHorizontalScroller];
}

/** Sets the horizontal scroller visibility of the current scroll view that can 
	be owned either by the container or its layout.
	Even if both vertical and horizontal scroller are made invisible, this 
	method won't remove the scroll view managed by the container from the 
	decorator chain bound to its layout item. */
- (void) setHasHorizontalScroller: (BOOL)scroll
{
	[self setShowsScrollView: YES];
	[[self scrollView] setHasHorizontalScroller: scroll];
	
	/* Updated NSBrowser, NSOutlineView enclosing scroll view etc. */
	[self syncDisplayViewWithContainer];
}

// TODO: Evaluates whether we really need to keep public the following methods 
// exposing NSScrollView directly. Would be cleaner to provide a ready to use 
// ETScrollView in the UI builder and the related inspector to configure it.

/** Returns the scroll view managed by the receiver to let you modify its 
	settings. 
	This underlying scroll view is wrapped inside an ETScrollView instance, 
	itself referenced by a layout item that can be inserted and removed in the 
	decorator chain by calling hide/unhide methods. */
- (NSScrollView *) scrollView
{
	id cachedDecorator = [self cachedScrollViewDecoratorItem];
	
	if (cachedDecorator == nil)
	{
		[self cacheScrollViewDecoratorItem: [self createScrollViewDecoratorItem]];
		cachedDecorator = [self cachedScrollViewDecoratorItem];
	}

	return (NSScrollView *)[[cachedDecorator supervisorView] mainView];
}

- (void) cacheScrollViewDecoratorItem: (ETLayoutItem *)decorator
{
	ASSIGN(_scrollViewDecorator, decorator);
}


- (ETLayoutItem *) cachedScrollViewDecoratorItem
{
	return _scrollViewDecorator;
}

/* When a new scroll view decorator is inserted in the decorator chain we cache 
   it. -unhidesScrollViewDecoratorItem triggers this call back. */
- (void) didChangeDecoratorOfItem: (ETLayoutItem *)item
{
	if ([item firstScrollViewDecoratorItem] != nil)
		[self cacheScrollViewDecoratorItem: [item firstScrollViewDecoratorItem]];
		
	// TODO: We might cache the position of the first scroll view decorator in  
	// the decorator chain in order to be able to reinsert it at the same 
	// position in -unhidesScrollViewDecoratorItem. We currently only support 
	// reinserting it in the first position.
}

/* Returns whether the scroll view of the current container is really used. If
   the container shows currently an AppKit control like NSTableView as display 
   view, the built-in scroll view of the table view is used instead of the one
   provided by the container. 
   It implies you can never have -hasScrollView returns NO and -isScrollViewShown 
   returns YES. There is no such exception with all other boolean combinations. */
- (BOOL) isScrollViewShown
{
	return _scrollViewShown;
}

- (BOOL) isContainerScrollViewInserted
{
	return ([[self layoutItem] firstScrollViewDecoratorItem] != nil);
}

/** Inserts a scroll view as the first decorator item bound to the receiver 
	layout item if no scroll view decorator can be found in the decorator chain. 
	If such a decorator already exists, does nothing.
	The receiver container caches a scroll view decorator, hence it is possible 
	to remove/insert the scroll view in the decorator chain by calling 
	hide/unhide methods without losing the scroll view settings.
	When no scroll view decorator has already been cached, behind the scene, 
	this method creates a ETScrollView instance and builds a decorator item with 
	this view. This new scroll view decorator item is finally inserted as the 
	first decorator. */
- (void) unhidesScrollViewDecoratorItem 
{
	if ([self isContainerScrollViewInserted])
		return;

	id scrollDecorator = [self cachedScrollViewDecoratorItem];	
	
	/* If no scroll view exists we create one even when a display view is in use
	   simply because we use the container scroll view instance to store all
	   scroller settings. We update any scroller settings defined in a display
	   view with that of the newly created scroll view.  */
	if (scrollDecorator == nil)
		scrollDecorator = [self createScrollViewDecoratorItem];

	// NOTE: Will call back -didChangeScrollDecoratorOfItem: which takes care of 
	// caching the scroll decorator
	[[self layoutItem] setDecoratorItem: scrollDecorator];
	//[_scrollView setAutoresizingMask: [self autoresizingMask]];
		
	// TODO: This should be handled rather on scroll view decorator 
	// insertion and probably in ETLayoutItem itself
	[[self layout] setContentSizeLayout: YES];
}

- (void) hidesScrollViewDecoratorItem 
{
	if ([self isContainerScrollViewInserted] == NO)
		return;
		
	NSAssert([[self scrollView] superview] != nil, @"A scroll view without "
		@"superview cannot be hidden");

	id scrollDecorator = [[self layoutItem] firstScrollViewDecoratorItem];
	id nextDecorator = [scrollDecorator decoratorItem];	
		
	[[scrollDecorator decoratedItem] setDecoratorItem: nextDecorator];
	//[self setAutoresizingMask: [_scrollView autoresizingMask]];
	
	// NOTE: The assertion below was added to ensure [self setFrame: 
	// [_scrollView frame]]; was correctly applied, it may be better to move
	// it in decorator handling of ETLayoutItem. As it is, it doesn't make 
	// much sense anymore because it is valid only when the scroll view is 
	// the first decorator of the layout item bound to the container.
	// WARNING: More about next line and following assertion can be read here: 
	// <http://www.cocoabuilder.com/archive/message/cocoa/2006/9/29/172021>
	// Stop also to receive any view/window notifications in ETContainer code 
	// before turning scroll view on or off.
	#if 0
	// This test will never work unless you retain scrollDecorator before 
	// removing it
	NSAssert1(NSEqualRects([self frame], [[scrollDecorator supervisorView] frame]), 
		@"Unable to update the frame of container %@, you must stop watch "
		@"any notifications posted by container before hiding or showing "
		@"its scroll view (Cocoa bug)", self);
	#endif

	// TODO: This should be handled rather on scroll view decorator 
	// removal and probably in ETLayoutItem itself
	[[self layout] setContentSizeLayout: NO];
}

- (void) setShowsScrollView: (BOOL)show
{
	if (_scrollViewShown == show)
		return;

	// FIXME: Asks layout whether it handles scroll view itself or not. If 
	// needed like with table layout, delegate scroll view handling.
	BOOL layoutHandlesScrollView = ([self displayView] != nil);
	
	_scrollViewShown = show;

	if (layoutHandlesScrollView)
	{
		[self syncDisplayViewWithContainer];	
	}
	else
	{
		if (show)
		{
			[self unhidesScrollViewDecoratorItem];
		}
		else
		{
			[self hidesScrollViewDecoratorItem];
		}
	}
}

- (ETLayoutItem *) createScrollViewDecoratorItem
{
	ETScrollView *scrollViewWrapper = nil;
	
	scrollViewWrapper = [[ETScrollView alloc] initWithFrame: [self frame]];
	AUTORELEASE(scrollViewWrapper);

	return [scrollViewWrapper layoutItem];
}

/** Returns the view that takes care of the display. Most of time it is equal
    to the container itself. But for some layout like ETTableLayout, the 
	returned view would be an NSTableView instance. */
- (NSView *) displayView
{
	return _displayView;
}

/** Never calls this method unless you write an ETLayout subclass.
	Method called when we switch between layouts. Manipulating the display view
	is the job of ETContainer, ETLayout instances may provide display view
	prototype but they never never manipulate it as a subview in view hierachy. */
- (void) setDisplayView: (NSView *)view
{
	if (_displayView == nil && view == nil)
		return;
	if (_displayView == view && (_displayView != nil || view != nil))
	{
		ETLog(@"WARNING: Trying to assign an identical display view to container %@", self);
		return;
	}
	
	[_displayView removeFromSuperview];
	
	_displayView = view;
	
	/* Be careful with scroll view code, it will call -displayView and thereby
	   needs up-to-date _displayView */
	/*if (view != nil && [self scrollView] != nil)
	{
		if ([self isScrollViewShown])
			[self setShowsScrollView: NO];
	}
	else if (view == nil && [self scrollView] != nil)
	{
		if ([self isScrollViewShown] == NO)
			[self setShowsScrollView: YES];		
	}*/
	
	if (view != nil)
	{
		[self hidesScrollViewDecoratorItem];
		
		/* Inserts the layout view */
		[view removeFromSuperview];
		[view setFrameSize: [self frame].size];
		[view setFrameOrigin: NSZeroPoint];
		[self addSubview: view];
		
		[self syncDisplayViewWithContainer];
	}
	else
	{
		if ([self isScrollViewShown])
			[self unhidesScrollViewDecoratorItem];		
	}	
}

#if 0
- (void) setAutoresizingMask: (unsigned int)mask
{
	ETDebugLog(@"--- Resizing mask from %d to %d %@", [self autoresizingMask], mask, self);
	[super setAutoresizingMask: mask];
}
#endif

/* FIXME: Implement

- (ETLayoutOverflowStyle) overflowStyle
{

}

- (void) setOverflowStyle: (ETLayoutOverflowStyle)
{

}
*/

/*  Manipulating Layout Item Tree */

/** See -[ETLayoutItemGroup addItem:] */
- (void) addItem: (ETLayoutItem *)item
{
	[(ETLayoutItemGroup *)[self layoutItem] addItem: item];
}

/** See -[ETLayoutItemGroup insertItem:atIndex:] */
- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index
{
	[(ETLayoutItemGroup *)[self layoutItem] insertItem: item atIndex: index];
}

/** See -[ETLayoutItemGroup removeItem:] */
- (void) removeItem: (ETLayoutItem *)item
{
	[(ETLayoutItemGroup *)[self layoutItem] removeItem: item];
}

/** See -[ETLayoutItemGroup removeItem:atIndex:] */
- (void) removeItemAtIndex: (int)index
{
	[(ETLayoutItemGroup *)[self layoutItem] removeItemAtIndex: index];
}

/** See -[ETLayoutItemGroup itemAtIndex:] */
- (ETLayoutItem *) itemAtIndex: (int)index
{
	return [(ETLayoutItemGroup *)[self layoutItem] itemAtIndex: index];
}

/** See -[ETLayoutItemGroup addItems:] */
- (void) addItems: (NSArray *)items
{
	[(ETLayoutItemGroup *)[self layoutItem] addItems: items];
}

/** See -[ETLayoutItemGroup removeItems] */
- (void) removeItems: (NSArray *)items
{
	[(ETLayoutItemGroup *)[self layoutItem] removeItems: items];
}

/** See -[ETLayoutItemGroup removeAllItems] */
- (void) removeAllItems
{
	[(ETLayoutItemGroup *)[self layoutItem] removeAllItems];
}

/** See -[ETLayoutItemGroup indexOfItem:] */
- (int) indexOfItem: (ETLayoutItem *)item
{
	return [(ETLayoutItemGroup *)[self layoutItem] indexOfItem: item];
}

/** See -[ETLayoutItemGroup containsItem:] */
- (BOOL) containsItem: (ETLayoutItem *)item
{
	return [(ETLayoutItemGroup *)[self layoutItem] containsItem: item];
}

/** See -[ETLayoutItemGroup numberOfItems] */
- (int) numberOfItems
{
	return [(ETLayoutItemGroup *)[self layoutItem] numberOfItems];
}

/** See -[ETLayoutItemGroup items] */
- (NSArray *) items
{
	return [(ETLayoutItemGroup *)[self layoutItem] items];
}

/* Selection */

/** See -[ETLayoutItemGroup selectedItemsInLayout] */
- (NSArray *) selectedItemsInLayout
{
	return [(ETLayoutItemGroup *)[self layoutItem] selectedItemsInLayout];
}

/** See -[ETLayoutItemGroup selectionIndexPaths] */
- (NSArray *) selectionIndexPaths
{
	return [(ETLayoutItemGroup *)[self layoutItem] selectionIndexPaths];
}

/** See -[ETLayoutItemGroup setSelectionIndexPaths] */
- (void) setSelectionIndexPaths: (NSArray *)indexPaths
{
	[(ETLayoutItemGroup *)[self layoutItem] setSelectionIndexPaths: indexPaths];
	
	// FIXME: Move this code into -[ETLayoutItemGroup setSelectionIndexPaths:]
	/* Finally propagate changes by posting notification */
	NSNotification *notif = [NSNotification 
		notificationWithName: ETContainerSelectionDidChangeNotification object: self];
	
	if ([[self delegate] respondsToSelector: @selector(containerSelectionDidChange:)])
		[[self delegate] containerSelectionDidChange: notif];

	[[NSNotificationCenter defaultCenter] postNotification: notif];
	
	/* Reflect selection change immediately */
	[self display];
}

/** Sets the selected items identified by indexes in the receiver and discards 
	any existing selection index paths previously set. */
- (void) setSelectionIndexes: (NSIndexSet *)indexes
{
	int numberOfItems = [[self items] count];
	int lastSelectionIndex = [[self selectionIndexes] lastIndex];
	
	ETDebugLog(@"Set selection indexes to %@ in %@", indexes, self);
	
	if (lastSelectionIndex > (numberOfItems - 1) && lastSelectionIndex != NSNotFound) /* NSNotFound is a big value and not -1 */
	{
		ETLog(@"WARNING: Try to set selection index %d when container %@ only contains %d items",
			lastSelectionIndex, self, numberOfItems);
		return;
	}

	/* Update selection */
	[self setSelectionIndexPaths: [indexes indexPaths]];
}

/** Returns all indexes matching selected items which are immediate children of
	the receiver. 
	Put in another way, the method returns the first index of all index paths
	with a length equal one. */
- (NSMutableIndexSet *) selectionIndexes
{
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	NSEnumerator *e = [[self selectionIndexPaths] objectEnumerator];
	NSIndexPath *indexPath = nil;
	
	while ((indexPath = [e nextObject]) != nil)
	{
		if ([indexPath length] == 1)
			[indexes addIndex: [indexPath firstIndex]];
	}
	
	return indexes;
}

/** Sets the selected item identified by index in the receiver and discards 
	any existing selection index paths previously set. */
- (void) setSelectionIndex: (unsigned int)index
{
	ETDebugLog(@"Modify selection index from %d to %d of %@", [self selectionIndex], index, self);
	
	/* Check new selection validity */
	NSAssert1(index >= 0, @"-setSelectionIndex: parameter must not be a negative value like %d", index);
	
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	
	if (index != NSNotFound)
		[indexes addIndex: index];
		
	[self setSelectionIndexes: indexes];
}

/** Returns the index of the first selected item which is an immediate child of
	the receiver. If there is none, returns NSNotFound. 
	Calling this method is equivalent to [[self selectionIndexes] firstIndex].
	Take note that -selectionIndexPaths may return one or multiple values when 
	this method returns NSNotFound. See -selectionIndexes also. */
- (unsigned int) selectionIndex
{
	return [[self selectionIndexes] firstIndex];
}

- (BOOL) allowsMultipleSelection
{
	return _multipleSelectionAllowed;
}

- (void) setAllowsMultipleSelection: (BOOL)multiple
{
	_multipleSelectionAllowed = multiple;
	[self syncDisplayViewWithContainer];
}

- (BOOL) allowsEmptySelection
{
	return _emptySelectionAllowed;
}

- (void) setAllowsEmptySelection: (BOOL)empty
{
	_emptySelectionAllowed = empty;
	[self syncDisplayViewWithContainer];
}

- (ETSelection *) selectionShape
{
	return _selectionShape;
}

/** point parameter must be expressed in receiver coordinates */
- (BOOL) doesSelectionContainsPoint: (NSPoint)point
{
	ETLayoutItem *item = [[self layout] itemAtLocation: point];

	if ([item isSelected])
	{
		NSAssert2([[self selectionIndexes] containsIndex: [self indexOfItem: item]],
			@"Mismatch between selection indexes and item %@ selected state in %@", 
			item, self);
		return YES;
	}
		
	return NO;

// NOTE: The code below could be significantly faster on large set of items
#if 0
	NSArray *selectedItems = [[self items] objectsAtIndexes: [self selectionIndexes]];
	NSEnumerator *e = [selectedItems objectEnumerator];
	ETLayoutItem *item = nil;
	BOOL hitSelection = NO;
	
	while ((item = [nextObject]) != nil)
	{
		if ([item displayView] != nil)
		{
			hitSelection = NSPointInRect(point, [[item displayView] frame]);
		}
		else /* Layout items uses no display view */
		{
			// FIXME: Implement
		}
	}
	
	return hitSelection;
#endif
}

/*
- (ETSelection *) selection
{
	return _selection;
}

- (void) setSelection: (ETSelection *)
{
	_selection;
} */

/* Pick & Drop */

- (BOOL) shouldRemoveItemsAtPickTime
{
	return _removeItemsAtPickTime;
}

- (void) setShouldRemoveItemsAtPickTime: (BOOL)flag
{
	_removeItemsAtPickTime = flag;
}

- (void) setAllowsDragging: (BOOL)flag
{
	_dragAllowed = flag;
}

- (BOOL) allowsDragging
{
	return _dragAllowed;
}

- (void) setAllowsDropping: (BOOL)flag
{
	_dropAllowed = flag;
}

- (BOOL) allowsDropping
{
	// FIXME: We should rather check whether source implement dragging data
	// source methods.
	if ([self source] != nil)
		return NO;
	
	return _dropAllowed;
}

- (IBAction) copy: (id)sender
{
	[[[self layoutItem] eventHandler] copy: sender];
}

- (IBAction) paste: (id)sender
{
	[[[self layoutItem] eventHandler] paste: sender];
}

- (IBAction) cut: (id)sender
{
	[[[self layoutItem] eventHandler] cut: sender];
}

/* Layers */

- (void) fixOwnerIfNeededForItem: (ETLayoutItem *)item
{
	/* Check the item to be now embedded in a new container (owned by the new 
	   layer) isn't already owned by current container */
	if ([[self items] containsObject: item])
		[self removeItem: item];
}

- (void) addLayer: (ETLayoutItem *)item
{
	ETLayer *layer = [ETLayoutItem layerWithLayoutItem: item];
	
	/* Insert layer on top of the layout item stack */
	if (layer != nil)
		[self addItem: (ETLayoutItem *)layer];
}

- (void) insertLayer: (ETLayoutItem *)item atIndex: (int)layerIndex
{
	[self fixOwnerIfNeededForItem: item];
	
	ETLayer *layer = [ETLayoutItem layerWithLayoutItem: item];
	
	// FIXME: the insertion code is truly unefficient, it could prove to be
	// a bottleneck when we have few hundreds of layout items.
	if (layer != nil)
	{
		NSArray *layers = nil;
		ETLayer *layerToMoveUp = nil;
		int realIndex = 0;
		
		/*
		           _layoutItems            by index (or z order)
		     
		               *****  <-- layer 2      4  <-- higher
		   item          -                     3
		   item          -                     2
		               *****  <-- layer 1      1
		   item          -                     0  <-- lower visual element (background)
		   
		   Take note that layout items embedded inside a layer have a 
		   distinct z order. Rendering isn't impacted by this point.
		   
		  */
		
		/* Retrieve layers spread in _layoutItems */
		layers = [[self items] objectsMatchingValue: [ETLayer class] forKey: @"class"];
		/* Find the layer to be replaced in layers array */
		layerToMoveUp = [layers objectAtIndex: layerIndex];
		/* Retrieve the index in layoutItems array for this particular layer */
		realIndex = [self indexOfItem: layerToMoveUp];
		
		/* Insertion will move replaced layer at index + 1 (to top) */
		[self insertItem: layer atIndex: realIndex];
	}
}

- (void) insertLayer: (ETLayoutItem *)item atZIndex: (int)z
{

}

- (void) removeLayer: (ETLayoutItem *)item
{

}

- (void) removeLayerAtIndex: (int)layerIndex
{

}

/* Grouping and Stacking */

- (void) group: (id)sender
{
	/*ETLayoutItem *item = [self itemAtIndex: [self selectionIndex]]; 
	
	if ([item isGroup])
	{
		[(ETLayoutItemGroup *)item make];
	}
	else
	{
		ETLog(@"WARNING: Layout item %@ must be an item group to be stacked", self);
	}
	
	if ([self canUpdateLayout])
		[self updateLayout];*/	
}

- (IBAction) stack: (id)sender
{
	ETLayoutItem *item = [self itemAtIndex: [self selectionIndex]]; 
	
	if ([item isGroup])
	{
		[(ETLayoutItemGroup *)item stack];
	}
	else
	{
		ETLog(@"WARNING: Layout item %@ must be an item group to be stacked", self);
	}
	
	if ([self canUpdateLayout])
		[self updateLayout];	
}

/* Item scaling */

- (float) itemScaleFactor
{
	return _itemScale;
}

- (void) setItemScaleFactor: (float)factor
{
	_itemScale = factor;
	if ([self canUpdateLayout])
		[self updateLayout];
}

/* Rendering Chain */

- (void) render
{
	//[_layoutItems makeObjectsPerformSelector: @selector(render)];
}

- (void) render: (NSMutableDictionary *)inputValues
{
	[[self items] makeObjectsPerformSelector: @selector(render:) withObject: nil];
}

- (void) drawRect: (NSRect)rect
{
	/* Takes care of drawing layout items with a view */
	[super drawRect: rect];
	
	/* Now we must draw layout items without view... using either a cell or 
	   their own renderer. Layout item are smart enough to avoid drawing their
	   view when they have one. */
	//[[self items] makeObjectsPerformSelector: @selector(render:) withObject: nil];
}

/* Actions */

/** Returns usually the lowest subcontainer of the receiver which contains 
    location point in the view hierarchy. For any other kind of subviews, hit 
	test doesn't succeed by default to eliminate potential issues you may 
	encounter by using subclasses of NSControl like NSImageView as layout item 
	view.
	If you want to layout controls which should support direct interaction like
	checkbox or popup menu, you can turn hit test on by calling 
	-setEnablesHitTest: with YES.
	If the point is located in the receiver itself but outside of any 
	subcontainers, returns self. When no subcontainer can be found, returns 
	nil. 
	*/
- (NSView *) hitTest: (NSPoint)location
{
	NSView *subview = [super hitTest: location];
	
	/* If -[NSView hitTest:] returns a container or if we use an AppKit control 
	   as a display view, we simply return the subview provided by 
	   -[NSView hitTest:]
	   If hit test is turned on, everything should be handled as usual. */
	if ([self displayView] || [self isHitTestEnabled] 
	 || [subview isKindOfClass: [self class]])
	{
		return subview;
	}
	else if (NSPointInRect(location, [self frame]))
	{
		return self;
	}
	else
	{
		return nil;
	}
}

- (void) setEnablesHitTest: (BOOL)passHitTest
{ 
	_subviewHitTest = passHitTest; 
}

- (BOOL) isHitTestEnabled { return _subviewHitTest; }

- (void) setTarget: (id)target
{
	_target = target;
	
	/* If a display view is used, sync its settings with container */
	[self syncDisplayViewWithContainer];
}

- (id) target
{
	return _target;
}

- (void) setDoubleAction: (SEL)selector
{
	_doubleClickAction = selector;
	
	/* If a display view is used, sync its settings with container */
	[self syncDisplayViewWithContainer];
}

- (SEL) doubleAction
{
	return _doubleClickAction;
}

- (ETLayoutItem *) doubleClickedItem
{
	return _doubleClickedItem;
}

/* Overriden NSView methods */

/* GNUstep doesn't rely on -setFrameSize: in -setFrame: unlike Cocoa, so we 
   patch frame parameter in -setFrame: too.
   See -setFrame: below to understand the reason behind this method. */
#ifdef GNUSTEP
- (void) setFrame: (NSRect)frame
{
	NSRect patchedFrame = frame;
	
	ETDebugLog(@"-setFrame to %@", NSStringFromRect(frame));
		
	if ([self isContainerScrollViewInserted])
	{
		NSSize clipViewSize = [[self scrollView] contentSize];

		if (clipViewSize.width < frame.size.width || clipViewSize.height < frame.size.height)
		{
			patchedFrame.size = clipViewSize;
		}
	}
	
	[super setFrame: patchedFrame];
	
	if ([self canUpdateLayout])
		[self updateLayout];
}
#endif

/* We override this method to patch the size in case we are located in a scroll 
   view owned by the receiver container. We must patch the container size to be 
   sure it will never be smaller than the clip view size. If both container and 
   clip view size don't match, you cannot click on the background to unselect 
   items and the drawing of the container background doesn't fully fill the 
   visible area of the scroll view.
   -setFrame: calls -setFrameSize: on Cocoa but not on GNUstep. */
- (void) setFrameSize: (NSSize)size
{
	NSSize patchedSize = size;

	//ETDebugLog(@"-setFrameSize: to %@", NSStringFromSize(size));

	// NOTE: Very weird resizing behavior can be observed if the following code 
	/// is executed when a layout view is in use. The layout view size will be 
	// constrained to the clip view size of the cached scroll view decorator.
	if ([self isContainerScrollViewInserted])
	{
		NSSize clipViewSize = [[self scrollView] contentSize];

		if (size.width < clipViewSize.width)
			patchedSize.width = clipViewSize.width;
		if (size.height < clipViewSize.height)
			patchedSize.height = clipViewSize.height;
	}
	
	[super setFrameSize: patchedSize];
	
	if ([self canUpdateLayout])
		[self updateLayout];
}

/* Collection Protocol */

- (BOOL) isOrdered
{
	return [(ETLayoutItemGroup *)[self layoutItem] isOrdered];
}

- (BOOL) isEmpty
{
	return [(ETLayoutItemGroup *)[self layoutItem] isEmpty];
}

- (id) content
{
	return [(ETLayoutItemGroup *)[self layoutItem] content];
}

- (NSArray *) contentArray
{
	return [(ETLayoutItemGroup *)[self layoutItem] contentArray];
}

- (void) addObject: (id)object
{
	[(ETLayoutItemGroup *)[self layoutItem] addObject: object];
}

- (void) insertObject: (id)object atIndex: (unsigned int)index
{
	[(ETLayoutItemGroup *)[self layoutItem] insertObject: object atIndex: index];
}

- (void) removeObject: (id)object
{
	[(ETLayoutItemGroup *)[self layoutItem] removeObject: object];
}

@end

/* Selection Caching Code (not used currently) */

#if 0
- (void) setSelectionIndexes: (NSIndexSet *)indexes
{
	int numberOfItems = [[self items] count];
	int lastSelectionIndex = [indexes lastIndex];
	
	ETDebugLog(@"Set selection indexes to %@ in %@", indexes, self);
	
	if (lastSelectionIndex > (numberOfItems - 1) && lastSelectionIndex != NSNotFound) /* NSNotFound is a big value and not -1 */
	{
		ETLog(@"WARNING: Try to set selection index %d when container %@ only contains %d items",
			lastSelectionIndex, self, numberOfItems);
		return;
	}
	
	/* Discard previous selection */
	if ([_selection count] > 0)
	{
		NSArray *selectedItems = [[self items] objectsAtIndexes: _selection];
		NSEnumerator *e = [selectedItems objectEnumerator];
		ETLayoutItem *item = nil;
		
		while ((item = [e nextObject]) != nil)
		{
			[item setSelected: NO];
		}
		[_selection removeAllIndexes];
	}

	/* Update selection */
	if (lastSelectionIndex != NSNotFound)
	{
		/* Cache selection locally in this container */
		if ([indexes isKindOfClass: [NSMutableIndexSet class]])
		{
			ASSIGN(_selection, indexes);
		}
		else
		{
			ASSIGN(_selection, [indexes mutableCopy]);
		}
	
		/* Update selection state in layout items directly */
		NSArray *selectedItems = [[self items] objectsAtIndexes: _selection];
		NSEnumerator *e = [selectedItems objectEnumerator];
		ETLayoutItem *item = nil;
			
		while ((item = [e nextObject]) != nil)
		{
			[item setSelected: YES];
		}
	}
	
	/* Finally propagate changes by posting notification */
	NSNotification *notif = [NSNotification 
		notificationWithName: ETContainerSelectionDidChangeNotification object: self];
	
	if ([[self delegate] respondsToSelector: @selector(containerSelectionDidChange:)])
		[[self delegate] containerSelectionDidChange: notif];

	[[NSNotificationCenter defaultCenter] postNotification: notif];
	
	/* Reflect selection change immediately */
	[self display];
}

- (NSMutableIndexSet *) selectionIndexes
{
	return AUTORELEASE([_selection mutableCopy]);
}

- (void) setSelectionIndex: (int)index
{
	int numberOfItems = [[self items] count];
	
	ETDebugLog(@"Modify selected item from %d to %d of %@", [self selectionIndex], index, self);
	
	/* Check new selection validity */
	NSAssert1(index >= 0, @"-setSelectionIndex: parameter must not be a negative value like %d", index);
	if (index > (numberOfItems - 1) && index != NSNotFound) /* NSNotFound is a big value and not -1 */
	{
		ETLog(@"WARNING: Try to set selection index %d when container %@ only contains %d items",
			index, self, numberOfItems);
		return;
	}

	/* Discard previous selection */
	if ([_selection count] > 0)
	{
		NSArray *selectedItems = [[self items] objectsAtIndexes: _selection];
		NSEnumerator *e = [selectedItems objectEnumerator];
		ETLayoutItem *item = nil;
		
		while ((item = [e nextObject]) != nil)
		{
			[item setSelected: NO];
		}
		[_selection removeAllIndexes];
	}
	
	/* Update selection */
	if (index != NSNotFound)
	{
		[_selection addIndex: index]; // cache
		[[self itemAtIndex: index] setSelected: YES];
	}
	
	NSAssert([_selection count] == 0 || [_selection count] == 1, @"-setSelectionIndex: must result in either no index or a single index but not more");
	
	/* Finally propagate changes by posting notification */
	NSNotification *notif = [NSNotification 
		notificationWithName: ETContainerSelectionDidChangeNotification object: self];
	
	if ([[self delegate] respondsToSelector: @selector(containerSelectionDidChange:)])
		[[self delegate] containerSelectionDidChange: notif];

	[[NSNotificationCenter defaultCenter] postNotification: notif];
	
	/* Reflect selection change immediately */
	[self display];
}

- (int) selectionIndex
{
	return [_selection firstIndex];
}
#endif
