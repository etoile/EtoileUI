/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import "ETLayout.h"
#import "ETAspectRepository.h"
#import "ETGeometry.h"
#import "ETTool.h"
#import "ETLayoutItemGroup.h"
#import "ETTableLayout.h"
#import "ETOutlineLayout.h"
#import "ETBrowserLayout.h"
#import "NSObject+EtoileUI.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

@interface ETLayout (Private)
+ (void) registerBuiltInLayoutClasses;
- (BOOL) loadNibNamed: (NSString *)nibName;
- (BOOL) isLayoutViewInUse;
@end


@implementation ETLayout

static NSMutableSet *layoutPrototypes = nil;

/** Registers a prototype for every ETLayout subclasses.

The implementation won't be executed in the subclasses but only the abstract 
base class.

You should never need to call this method.

See also NSObject(ETAspectRegistration). */
+ (void) registerAspects
{
	ASSIGN(layoutPrototypes, [NSMutableSet set]);

	NSArray *skippedClasses = A(NSClassFromString(@"ETWidgetLayout"), 
		NSClassFromString(@"ETInspectorLayout"), 
		NSClassFromString(@"ETWindowLayout"), 
		NSClassFromString(@"ETTemplateItemLayout"), 
		NSClassFromString(@"ETCompositeLayout"),
		NSClassFromString(@"ETPaneLayout"),
		NSClassFromString(@"ETComputedLayout"),
		NSClassFromString(@"ETMasterDetailPaneLayout"),
		NSClassFromString(@"ETMasterContentPaneLayout"),
		NSClassFromString(@"ETFormLayout"),
		NSClassFromString(@"ETViewModelLayout"),
		NSClassFromString(@"ETTextEditorLayout"));
	NSArray *subclasses = [[self allSubclasses] arrayByRemovingObjectsInArray: skippedClasses];

	FOREACH(subclasses, subclass, Class)
	{
		CREATE_AUTORELEASE_POOL(pool);
		[self registerLayout: AUTORELEASE([[subclass alloc] init])];
		DESTROY(pool);
	}
}

/** Returns 'Layout'. */
+ (NSString *) baseClassName
{
	return @"Layout";
}

/** Makes the given prototype available to EtoileUI facilities (inspector, etc.) 
that allow to change a layout at runtime.

Also publishes the prototype in the shared aspect repository (not yet implemented). 

Raises an invalid argument exception if aLayout class isn't a subclass of ETLayout. */
+ (void) registerLayout: (ETLayout *)aLayout
{
	if ([aLayout isKindOfClass: [ETLayout class]] == NO)
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Prototype %@ must be a subclass of ETLayout to get "
		                    @"registered as a layout prototype.", aLayout];
	}

	[layoutPrototypes addObject: aLayout];

	ETAspectCategory *category = [[ETAspectRepository mainRepository] aspectCategoryNamed: _(@"Layout")];

	if (category == nil)
	{
		category = [[ETAspectCategory alloc] initWithName: _(@"Layout")];
		[category setIcon: [NSImage imageNamed: @"layout-design"]];
		[[ETAspectRepository mainRepository] addAspectCategory: category];
	}
	[category setAspect: aLayout forKey: [[aLayout class] displayName]];
}

/** Returns all the layout prototypes directly available for EtoileUI facilities 
that allow to transform the UI at runtime. */
+ (NSSet *) registeredLayouts
{
	return AUTORELEASE([layoutPrototypes copy]);
}

/** Returns all the layout classes directly available for EtoileUI facilities 
that allow to transform the UI at runtime.

These layout classes are a subset of the registered layout prototypes since 
several prototypes might share the same class. */
+ (NSSet *) registeredLayoutClasses
{
	return (NSSet *)[[layoutPrototypes mappedCollection] class];
}

/* Factory Method */

/** Returns a new autoreleased instance. */
+ (id) layout
{
	return AUTORELEASE([[[self class] alloc] init]);
}

/** Returns a new autoreleased instance whose class matches the given layout 
view.

See -initWithLayoutView:. */
+ (id) layoutWithLayoutView: (NSView *)layoutView
{
	return AUTORELEASE([[[self  class] alloc] initWithLayoutView: layoutView]);
}

/** Returns the layout class to  instantiate in -initWithLayoutView: for the 
given layout view.

For the view classes listed below, the substitute classes are:
<deflist>
<term>NSOutlineView</term><desc>ETOutlineLayout</desc>
<term>NSTableView</term><desc>ETTableLayout</desc>
<term>NSBrowserView</term><desc>ETColumnBrowserLayout</desc>
</deflist> */
+ (Class) layoutClassForLayoutView: (NSView *)layoutView
{
	Class layoutClass = nil;
	NSView *view = layoutView;
	
	if ([layoutView isKindOfClass: [NSScrollView class]])
		view = [(NSScrollView *)layoutView documentView];
	
	// NOTE: Outline test must be done before table test, otherwise table 
	// layout is returned in both cases (NSOutlineView is subclass of 
	// NSTableView)
	if ([view isKindOfClass: [NSOutlineView class]])
	{
		layoutClass = [ETOutlineLayout class];
	}
	else if ([view isKindOfClass: [NSTableView class]])
	{
		layoutClass = [ETTableLayout class];
	}
	else if ([view isKindOfClass: [NSBrowser class]])
	{
		layoutClass = [ETBrowserLayout class];	
	}
	else
	{
		layoutClass = [ETLayout class];
	}
	
	return layoutClass;
}

/** <init /> 
Returns a new ETLayout instance when the given view is nil, otherwise returns a 
concrete subclass instance based on the view type.

e.g. If you pass an NSOutlineView, an ETOutlineLayout instance is returned, the 
substitution list in -layoutClassForLayoutView:. The instantiation behaves like 
a class cluster.

The returned layout has both vertical and horizontal constraint on item size 
enabled. The size constraint is set to 256 * 256 px. You can customize item size 
constraint with -setItemSizeConstraint: and -setConstrainedItemSize:. */
- (id) initWithLayoutView: (NSView *)aView
{
	SUPERINIT
	
	/* Class cluster initialization */
	
	/* ETLayout itself takes the placeholder object role. By removing the 
	   following if statement, concrete subclass would have the possibility
	   to override the concrete subclass... No utility right now. */
	if (aView != nil && [self isMemberOfClass: [ETLayout class]])
	{
		/* Find the concrete layout class to instantiate */
		Class layoutClass = [[self class] layoutClassForLayoutView: aView];
		
		/* Eventually replaces the receiver by a new concrete instance */
		if (layoutClass != nil)
		{
			if ([self isMemberOfClass: layoutClass] == NO)
			{
				NSZone *zone = [self zone];
				RELEASE(self);
				self = [[layoutClass allocWithZone: zone] initWithLayoutView: aView];
			}
		}
		else /* No matching layout class */
		{
			self = nil;
		}
		
		return self; /* Instance already initialized */
	}
  
	/* Concrete instance initialization */
	
	_layoutContext = nil;
	delegate = nil;
	_tool = nil;
	ASSIGN(_dropIndicator, [ETDropIndicator sharedInstance]);
	_isRendering = NO;
	_layoutSize = NSMakeSize(200, 200); /* Dummy value */
	_proposedLayoutSize = ETNullSize;
	_usesCustomLayoutSize = NO;
	_isContentSizeLayout = NO;
	 /* Will ensure -resizeItems:toScaleFactor: isn't called until the scale changes */
	_previousScaleFactor = 1.0;

	if (aView != nil)
	{
		[[self ifResponds] setLayoutView: aView];
	}
	
	return self;
}

- (id) init
{
	return [self initWithLayoutView: nil];
}

- (void) dealloc
{
	/* Neither layout context and delegate have to be retained. 
	   The layout context is our owner and retains us. */
	
	/* If the layoutOwner weak reference is not reset, passing this tool to 
	   +[ETTool setActiveTool:] can cause a crash. */
	[_tool setLayoutOwner: nil];
	DESTROY(_tool);
	DESTROY(_layerItem);
	DESTROY(_dropIndicator);

	[super dealloc];
}

/** <override-dummy />
Returns a copy of the receiver.<br />
The given context which might be nil will be set as the layout context on the copy.

This method is ETLayout designated copier. Subclasses that want to extend 
the copying support must invoke it instead of -copyWithZone:.

Subclasses must be aware that this method calls -setAttachedTool: with an 
tool copy. */ 
- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETLayout *newLayout = [super copyWithZone: aZone];

	/* We copy all ivars except _layoutContext and _isRendering */

	newLayout->_layoutContext = ctxt;
	newLayout->delegate = delegate;
	newLayout->_layerItem = [_layerItem copyWithZone: aZone];
	newLayout->_dropIndicator = RETAIN(_dropIndicator);
	newLayout->_tool = [_tool copyWithZone: aZone];
	[newLayout->_tool setLayoutOwner: newLayout];
	newLayout->_layoutSize = _layoutSize;
	/* Must be copied to ensure autoresizing receives a correct old size */
	newLayout->_proposedLayoutSize = _proposedLayoutSize;
	newLayout->_usesCustomLayoutSize = _usesCustomLayoutSize;
	newLayout->_isContentSizeLayout  = _isContentSizeLayout;
	newLayout->_previousScaleFactor = _previousScaleFactor;

	return newLayout;
}

/** <override-dummy />
Overrides to set up the receiver when it is the copy and has just been assigned 
to its layout context.<br />
At that point, the item tree owned by the layout context has been fully copied, 
and object references that belongs to the original can now be resolved to their 
equivalent in the tree copy (or object graph copy to be precise).

The default implementation calls -setUp.

You can call the superclass implementation or not. */
- (void) setUpCopyWithZone: (NSZone *)aZone
                  original: (ETLayout *)layoutOriginal
{
	NSParameterAssert(_layoutContext != nil);
	[self setUp];
	// TODO: Implement -setUpCopyWithZone:original: in subclasses or change
	// -setUp to -setUp: (BOOL)resetLayoutSize.
	_layoutSize = layoutOriginal->_layoutSize;
	_proposedLayoutSize = layoutOriginal ->_layoutSize;
}

/** <override-never />
Returns a copy of the receiver.

The layout context in the copy is nil.

Subclasses must be aware that this method calls -setAttachedTool: with an 
tool copy.

To customize the copying in a subclass, you must override 
-copyWithZone:layoutContext:. */ 
- (id) copyWithZone: (NSZone *)aZone
{
	return [self copyWithZone: aZone layoutContext: nil];
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"ui-layered-pane"];
}

/** Returns the tool or tool bound to the receiver. */
- (id) attachedTool
{
	ETAssert(_tool == nil || [_tool layoutOwner] == self);
	return _tool;
}

/** Sets the tool or tool bound to the receiver. 

The tool set becomes the receiver owner. See -[ETTool layoutOwner].

If the previously attached tool was the active tool, the new one 
becomes the active tool. See -[ETTool setActiveTool:].

Also invokes -didChangeAttachedTool:toTool:.  */
- (void) setAttachedTool: (ETTool *)newTool
{
	[self willChangeValueForProperty: @"attachedTool"];

	if ([newTool isEqual: _tool] == NO)
		[_tool setLayoutOwner: nil];
		
	ETTool *oldTool = RETAIN(_tool);

	ASSIGN(_tool, newTool);
	[newTool setLayoutOwner: self];

	if ([oldTool isEqual: [ETTool activeTool]])
	{
		[ETTool setActiveTool: newTool];
	}

	[self didChangeValueForProperty: @"attachedTool"];
	[self didChangeAttachedTool: oldTool  toTool: newTool];

	RELEASE(oldTool);
}

/** <override-dummy />
Tells the receiver the attached tool owned by an ancestor layout (or itself) 
has changed. This tool may or may not be active.

You can override this method in subclasses to adjust the receiver layout to the 
new tool that can now be used to interact with the presented content. 

By default, propagates the message recursively in the layout item tree through 
the layout context arranged items.

You can override this method to hide or show layout items that belong the item 
tree returned by -[ETLayout rootItem] on an tool change. e.g. ETFreeLayout 
toggles the handle visibility when the select tool is attached (or detached) to 
the receiver layout or any ancestor layout.

The ancestor layout on which the tool was changed can be retrieved with 
[newTool layoutOwner]. */
- (void) didChangeAttachedTool: (ETTool *)oldTool
                        toTool: (ETTool *)newTool
{
	FOREACH([_layoutContext arrangedItems], item, ETLayoutItem *)
	{
		[[item layout] didChangeAttachedTool: oldTool
		                              toTool: newTool];
	}
}

/** <override-never />
Sets the context where the layout should happen. 

When a layout context is set, with the next layout update the receiver will 
arrange the layout items in a specific style and order.

You must override -setUp and/or -tearDown to react to a layout change and not 
this method.

The layout context is expected to retain its layout, hence the receiver doesn't 
retain the given context. */
- (void) setLayoutContext: (id <ETLayoutingContext>)context
{
	ETDebugLog(@"Modify layout context from %@ to %@ in %@", _layoutContext, context, self);

	if (context == nil)
		[self tearDown];

	// NOTE: Avoids retain cycle by weak referencing the context
	_layoutContext = context;

	if (context != nil)
		[self setUp];

	// TODO: May be safer to restore the default frame here rather than relying 
	// on the next layout update and -resizeItems:toScaleFactor:... 
	//[[_layoutContext items] makeObjectsPerformSelector: @selector(restoreDefaultFrame)];
}

/** Returns the context where the layout happens. */
- (id <ETLayoutingContext>) layoutContext
{
	return _layoutContext;
}

/** <override-dummy />Overrides if your subclass requires extra cleanup when the 
layout context is switched to another layout (the receiver stops to be used and 
visible).

The layout context hasn't yet been touched when this method is called.

You must call the superclass implementation if you override this method. */
- (void) tearDown
{
	NSParameterAssert(_layoutContext != nil);
	[self unmapLayerItemFromLayoutContext];
}

/** <override-dummy />Overrides if your subclass requires extra transformation 
when the layout context is switched to the receiver (it becomes the new layout 
and starts to be used and visible).

The new layout context has been set when this method is called.

You must call the superclass implementation if you override this method. */
- (void) setUp
{
	NSParameterAssert(_layoutContext != nil);
	/* Reset the layout size to ensure -resizeItems:forNewLayoutSize:oldSize: 
	   receives a valid old size (neither zero or computed for a previous layout context). */
	[self resetLayoutSize];
	[self mapLayerItemIntoLayoutContext];
}

// NOTE: -isSemantic will be a public method when its role has become clearer.
// Aspect support needs to be committed in order to precise this role.

/* Overrides in subclasses to indicate whether the layout is a semantic layout
or not. Returns NO by default.

A semantic layout would work by delegating everything to a concrete layout.
	
If you overrides this method to return YES, forwarding of all non-overidden 
methods to the normal layout will be handled automatically (not yet implemented). */
- (BOOL) isSemantic
{
	return NO;
}

/** Returns YES when the layout conforms to ETPositionalLayout protocol, 
otherwise returns NO.

A positional layout doesn't inject a custom UI, it presents the layout context 
items by either:
<list>
<item>computing their coordinates</item>
<item>using their fixed coordinates</item>
</list>

Fixed coordinates are encoded in persistentFrame property of ETLayoutItem. */
- (BOOL) isPositional
{
	return [self conformsToProtocol: @protocol(ETComputableLayout)];
}

- (BOOL) isComposite
{
	return [self conformsToProtocol: @protocol(ETCompositeLayout)];
}

/** <override-dummy />
Returns whether the receiver adapts and wraps a complex widget, provided by the 
widget backend, as a layout. By default, returns NO.

See ETWidgetLayout.*/
- (BOOL) isWidget
{
	return NO;
}

/** <override-dummy />
Returns YES when the layout is positional and computes every item geometry
(position, rotation, scale etc.) on demand.

See also ETComputedLayout, whose subclasses are all computed layouts.

By default returns NO, overrides to return YES when a positional layout 
subclass doesn't allow the user sets the item positions. 

The returned value alters the order in which ETLayoutItemGroup source methods 
are called. 

-[ETLayoutItem setFrame:] checks that the parent item layout is not a computed 
layout before updating the persistent frame. */
- (BOOL) isComputedLayout
{
	return NO;
}

/** <override-dummy />
Returns YES when the layout don't let the layout context items draw 
themselves and prevent the descendant item styles, views, layouts etc. to be 
visible.<br />
Opaque layouts completely impose their own presentation.

By default returns NO. 

Subclass instances that wrap widgets are opaque (e.g. ETTableLayout). */
- (BOOL) isOpaque
{
	return NO;
}

/** <override-dummy />
Returns whether the layout content is scrollable. By default, returns YES.

You can override this method to prevent the content to be scrollable. When 
NO is returned and a scrollable area item decorates the layout context, that  
decorator will be removed temporarily.

See also -hasScrollers. */
- (BOOL) isScrollable
{
	return YES;
}

/** <override-dummy />
Returns YES when the layout has its own scrollers. By default, returns NO.

You are expected to override this method to indicate that the layout makes the 
content scrollable by itself. By returning YES, the layout context can know 
that no scrollable area item has to be inserted.

See also -isScrollable and ETLayoutItem(Scrollable). */
- (BOOL) hasScrollers
{
	return NO;
}

/** Returns YES if all layout items are visible in the bounds of the related 
	container once the layout has been computed, otherwise returns NO when
	the layout has run out of space.
	Whether all items are visible depends of the layout itself and also whether
	the container is embedded in a scroll view because in such case the 
	container size is altered. */
- (BOOL) isAllContentVisible
{
	return ([[_layoutContext visibleItems] count] == [[_layoutContext items] count]);
}

/** By default layout size is precisely matching frame size of the container to 
	which the receiver is bound to.
	When the container uses a scroll view, layout size is set the mininal size 
	which encloses all the layout item frames once they have been layouted. 
	This size is the maximal layout size you can compute for the receiver with 
	the content provided by the container.
	Whether the layout size is computed in horizontal, vertical direction or 
	both depends of layout kind, settings of the layout and finally scroller 
	visibility in related container.
	If you call -setUsesCustomLayoutSize:, the layout size won't be adjusted anymore by
	the layout and container together until you delegate it again by calling
	-setUsesCustomLayoutSize: with NO as parameter. */ 
- (void) setUsesCustomLayoutSize: (BOOL)flag
{
	_usesCustomLayoutSize = flag;
}

/** Returns whether a custom area size where the layout should be rendered. */
- (BOOL) usesCustomLayoutSize
{
	return _usesCustomLayoutSize;
}

/** Sets the newly computed layout size.

Many layouts compute the extent necessary to present the items in their own way. 
This layout size is the minimal area which bounds the whole presentation and 
ensure every item to be presented is visible.

You should not need to use this method usually, -renderLayoutItems:isNewContent: 
automatically invokes -resetLayoutSize.

in.You can restrict the layout size to your personal needs by 
	calling -setLayoutSize: and only then -render. */
- (void) setLayoutSize: (NSSize)size
{
	//ETDebugLog(@"-setLayoutSize");
	_layoutSize = size;
	[self syncLayerItemGeometryWithSize: size];
}

/** Returns the last computed layout size.

The layout area size is usually computed every time 
-renderWithItems:isNewContent: is invoked with a new content. */
- (NSSize) layoutSize
{
	return _layoutSize;
}

/** Sets whether the layout context can be resized, when its current size is 
not enough to let the layout present the items in its own way. 

The only common case where -isContentSizeLayout should return YES is when the 
layout context is scrollable, and ETLayout does it transparently. Which means 
you very rarely need to use this method.
 
If -isContentSizeLayout is YES, the items are not autoresized.
 
Each time this method is called, the layout size is reset. This means resizing 
the layout context prior to -setIsContentSizeLayout: NO won't autoresize the 
items for the layout update at the end of the current event. If you want to 
autoresize the items, you must resize the layout context when 
-isContentSizeLayout returns NO (and ensure -isContentSizeLayout won't be 
switched again until the end of the currrent event).

See also -isContentSizeLayout:. */
- (void) setIsContentSizeLayout: (BOOL)flag
{
	//ETDebugLog(@"-setContentSizeLayout");
	_isContentSizeLayout = flag;
	[self resetLayoutSize];
}

/** Returns whether the layout context can be resized, when its current size is 
not enough to let the layout present the items in its own way. 

If -isContentSizeLayout is YES, the items are not autoresized.

When a scrollable area item decorates the layout context, -isContentSizeLayout 
always returns YES. */
- (BOOL) isContentSizeLayout
{
	if ([_layoutContext isScrollable])
		return YES;

	return _isContentSizeLayout;
}

/** Sets the delegate.

The delegate is not retained.

Not used presently. */
- (void) setDelegate: (id)aDelegate
{
	delegate = aDelegate;
	[self renderAndInvalidateDisplay];
}

/** Returns the delegate. 

See also -setDelegate:. */
- (id) delegate
{
	return delegate;
}

/** Returns whether -renderXXX methods can be invoked now. */
- (BOOL) canRender
{
	BOOL hasValidContext = (_layoutContext != nil);

	/* When the layout context is a layout */
	if (hasValidContext && [_layoutContext isLayoutItem] == NO)
	{
		ETAssert([_layoutContext isComposite]);
		hasValidContext = ([_layoutContext layoutContext] != nil);
	}

	return (hasValidContext && [self isRendering] == NO);
}

/** Returns whether the layout phase in underway.

When you want to use Layouting related methods, you must check this method 
returns YES. When NO is returned, wait until it returns YES.  */
- (BOOL) isRendering
{
	/* The second check avoids to execute -renderLayoutItems:isNewContent: 
	   on a positional layout inside 
	   -[ETTemplateItemLayout renderLayoutItems:isNewContent:], because 
	   -setHorizontalAlignmentGuidePosition: was called and in turn called 
	   -renderAndInvalidDisplay. */
	return (_isRendering || [[_layoutContext ifResponds] isRendering]);
}

/** This method is only exposed to be used internally by EtoileUI.

Requests the items to present to the layout context, then renders the layout 
with -renderWithItems:isNewContent:.

Layout items can be requested in two styles: 
<list>
<item>to the layout context itself</item>
<item>or indirectly to a data source provided by the layout context.</item>
</list>

When the items are provided through a data source, the layout retrieves the 
items lazily and tries to only request the subset to be presented (not yet 
implemented). 

You should rarely need to use this method. ETLayoutItemGroup does it 
transparently.<br />
To explictly update the layout, just uses -[ETLayoutItemGroup updateLayout]. */
- (void) render: (BOOL)isNewContent
{
	if (_layoutContext == nil)
	{
		ETLog(@"WARNING: Missing layout context in %@... Won't render.", self);
	}

	if ([self canRender] == NO)
		return;

	_isRendering = YES;
	[self renderWithItems: [_layoutContext arrangedItems] isNewContent: isNewContent];
	_isRendering = NO;
}

/** Sets the layout size to the unlayouted content size of the layout context,
    unless -usesCustomLayoutSize returns YES. In this last case, the layout size 
	isn't modified. 
    You call this method to reset the layout size to a value that should be used 
	as a basis to compute the layout. By default, the implementation considers 
	the layout of the content (layout items) should be computed within the 
	boundaries of the layout context size.
	If the layout context is enclosed inside a scroll view, this method will 
	take it in account. */
- (void) resetLayoutSize
{
	/* We always set the layout size which should be used to compute the 
	   layout unless a custom layout has been set by calling -setLayoutSize:
	   before -render. */
	if ([self usesCustomLayoutSize] == NO)
	{
		[self setLayoutSize: [[self layoutContext] visibleContentSize]];
	}
	_proposedLayoutSize = [self layoutSize];
}

/** <override-dummy />
Renders the layout.<br />
This is a skeleton implementation which only invokes -resetLayoutSize:, 
-resizeItems:forNewLayoutSize:oldSize: and -resizeLayoutItems:toScaleFactor:.

You can reuse this implementation in your subclass or not.

isNewContent indicates when the layout update is triggered by a node insertion 
or removal in the tree structure that belongs to the layout context.

Any layout item which belongs to the layout context, but not present in the item 
array argument, can be ignored in the layout logic implemented by subclasses.<br />
This optimization is not yet used and a subclass is not required to comply to 
it (this is subject to change though). */
- (void) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{	
	ETDebugLog(@"Render layout items: %@", items);

	float scale = [[self layoutContext] itemScaleFactor];
	NSSize oldProposedLayoutSize = _proposedLayoutSize;

	[self resetLayoutSize];
	if ([self isContentSizeLayout] == NO)
	{
		[self resizeItems: items
		 forNewLayoutSize: [self layoutSize]
		          oldSize: oldProposedLayoutSize];
	}
	// TODO: This is a welcome optimization that avoids unecessary computations, 
	// however this shouldn't be mandatory. Currently this is used as a
	// workaround to handle the fact that the default frame isn't updated if 
	// -setFrame: is called. The correct fix is probably to update the default 
	// frame in -setFrame: when the item is managed by a non-computed layout. 
	// This a little bit tricky to implement cleanly because the layout that 
	// manages the item may not be on the immediate parent but some higher 
	// ancestors. Another downside is that ETLayoutItem will become more 
	// coupled to ETLayoutItemGroup.
	/* Only scale if needed, but if a constraint exists on item width or height, 
	   resizing must be forced in all cases. */
	if (scale != _previousScaleFactor)
	{
		[self resizeItems: items toScaleFactor: scale];
		_previousScaleFactor = scale;
	}
}

/** <override-never />
Renders the layout with -render:isNewContent: and marks the layout context to be 
redisplayed.

You must only invoke this method in subclasses. In all other cases, to update 
and redisplay the layout, -[ETLayoutItem updateLayout] must be used. 
-renderAndInvalidateDisplay unlike -updateLayout doesn't result in a recursive 
layout update but remains limited to the receiver.

Subclasses can use this method in their setters to update the receiver, every 
time a setting changes:
<code>
- (void) setItemMargin: (NSUInteger)aMargin
{
	itemMargin = aMargin;
	[self renderAndInvalidateDisplay];
}
</code> */
- (void) renderAndInvalidateDisplay
{
	if ([self canRender])
	{	
		[self render: NO];
		[[self layoutContext] setNeedsDisplay: YES];
	}
}

/** <override-dummy />
Does nothing.
 
Overrides this method to support a custom resizing policy bound to   
-[ETLayoutContext itemScaleFactor].
 
See also -[ETLayoutItemGroup itemScaleFactor] and 
-[ETPositionalLayout resizeItems:toScaleFactor:]. */
- (void) resizeItems: (NSArray *)items toScaleFactor: (float)factor
{

}

/** <override-dummy />
Does nothing.
 
Overrides this method to support a custom resizing policy bound to   
-[ETLayoutContext size] or -[ETLayoutContext visibleContentSize].
 
Subclasses such as ETFixedLayout or ETComputedLayout implements a autoresizing 
policy based on -[ETLayoutItem autoresizing].
 
See also -[ETLayoutItemGroup contentSize]. */
- (void) resizeItems: (NSArray *)items
    forNewLayoutSize: (NSSize)newLayoutSize
             oldSize: (NSSize)oldLayoutSize
{

}

- (BOOL) isLayoutExecutionItemDependent
{
	return NO;
}

/* Presentational Item Tree */

/** Returns a layout item when the receiver is an aggregate layout which 
	doesn't truly layout items but rather wraps a predefined view (aka layout 
	view) or layout item. By default, returns nil.
	When a layout is such an aggregate, layout items passed to the receiver are
	handled by the layout item descendants of -layoutItem. These layout item 
	descendents are commonly subviews. 
	See ETUIComponent to understand how an aggregate layout can be wrapped in
	standalone and self-sufficient component which may act as live filter in 
	the continous model object flows. */
/** Returns the layer item specific to the receiver. This layout-specific tree 
includes additional items such as resize handles, positioning indicators etc. 

These items can be composed into the semantic layout item tree, each time the 
receiver is set on a layout context. At this point, the layout item tree visible 
on screen is really a composite between the main item tree which owns the layout 
context and the tree rooted in -layerItem. */
- (ETLayoutItemGroup *) layerItem
{
	/* A layout set on a layer item encapsulated in a layout must have no root 
	   item otherwise -[ETLayout layerItem] results in an endless recursion:
	   -[ETFixedLayout layerItem]
	   -[ETFixedLayout mapLayerItemInLayoutContext]
	   -[ETFixedLayout setUp]
	   -[ETFixedLayout setLayoutContext:]
	   -[ETLayoutItemGroup init]
	   -[ETFixedLayout layerItem]
	   -[ETFixedLayout mapLayerItemInLayoutContext]
	   -[ETFixedLayout setUp]
	   -[ETFixedLayout setLayoutContext:]
	   -[ETLayoutItemGroup init]
	   That's why we check -isLayerItem. */
	if (_layerItem == nil && [_layoutContext isLayoutItem] && [_layoutContext isLayerItem] == NO)
	{
		_layerItem = [[ETLayoutItemGroup alloc] initAsLayerItem];
	}

	/* When the layout context is a composite layout, the positional layout 
	   reuses its layer item */
	if (_layoutContext != nil && [_layoutContext isLayoutItem] == NO)
	{
		return [_layoutContext layerItem];
	}

	return _layerItem;
}

/** Resizes the layer item to the given size and sets its -isFlipped property 
to be identical to the layout context. */
- (void) syncLayerItemGeometryWithSize: (NSSize)aSize
{
	/* Autolayout is disabled during a layout change or update, so we temporarily 
	   enable it because -layerItem requires a layout update.
	   This won't work when +disablesAutolayout has been used just before by the 
	   framework user (this behavior is consistent, so the user shouldn't 
	   be surprised). */
	if (_isRendering)
	{
		[ETLayoutItem enablesAutolayout];
	}

	[[self layerItem] setFlipped: [[self layoutContext] isFlipped]];
	/* The layer item is rendered in the coordinate space of the layout context */
	[[self layerItem] setSize: aSize];

	if (_isRendering)
	{
		[ETLayoutItem disablesAutolayout];
	}
}

- (void) mapLayerItemIntoLayoutContext
{
	NSParameterAssert(nil != _layoutContext);

	if ([self layerItem] == nil)
		return;

	ETLayoutItemGroup *layoutContext = (ETLayoutItemGroup *)[self layoutContext];

	/* We don't insert the layer item in the layout context, because we don't 
	   want to make it visible in the semantic tree. Yet to support -display 
	   in the layer item tree, we set the layout context as its parent, hence 
	   redisplay requests can flow back to the closest ancestor view in the 
	   main layout item tree. */
	if ([layoutContext isLayoutItem])
	{
		[[self layerItem] setParentItem: layoutContext];
	}
	else /* For layout composition, when the layout context is a layout */
	{
		[[self layerItem] setParentItem: [layoutContext rootItem]];
	}

	[self syncLayerItemGeometryWithSize: [layoutContext visibleContentSize]];
}

- (void) unmapLayerItemFromLayoutContext
{
	[[self layerItem] setParentItem: nil];
}

/** <override-dummy />
See -[ETWidgetLayout syncLayoutViewWithItem:] */
- (void) syncLayoutViewWithItem: (ETLayoutItem *)item
{
	
}

/* Selection */

/** <override-dummy />
Returns the selected items in the layout, which might not be identical to the 
selected items in the layout context. 

For example, ETOutlineLayout reports the selected items accross every expanded 
item and not the items selected at the layout context level only.

You can override this method to implement a layout-based selection in your
subclass. This method is called by -[ETLayoutItemGroup selectedItemsInLayout].

Returns nil by default. Which means the layout uses no custom policy.<br />
A subclass must return an empty array when no items are selected. */
- (NSArray *) selectedItems
{
	return nil;
}

/** <override-dummy /> 
Synchronizes the layout selection state with the layout context.

The selection object provides access to the new selection state.

You usually override this method if you need to reflect the selected items 
in the layout context on the custom UI encapsulated by the receiver (usually 
a widget layout or a less specialized opaque layout).<br />

This method is called on a regular basis each time the layout context selection 
is modified and needs to be mirrored in the receiver (e.g. in a widget view). */
- (void) selectionDidChangeInLayoutContext: (id <ETItemSelection>)aSelection
{

}

/** <override-dummy />
Returns NO. 

Can be overriden to return YES and prevents -selectionDidChangeInLayoutContext: 
to be called.

For a concrete use case, see -[ETWidgetLayout isChangingSelection] . */
- (BOOL) isChangingSelection
{
	return NO;
}

/* Item Geometry and Display */

/** <override-dummy />
Returns the layout item positioned at the given location point and inside 
the visible part of the layout.

If several items overlap at this location, then the topmost item presented by 
the layout is returned. A topmost item which doesn't belong to the layout 
context won't be matched by default. Subclasses which override -isOpaque 
to return YES can supercede this policy.<br />
For example -[ETOutlineLayout itemAtLocation:] can match descendant items unlike 
ETFlowLayout which only matches immediate child items.<br />
The topmost item on screen is the deepest descendant item in the layout item 
tree perspective.
	
The location must be expressed in the layout context coordinates.<br />
If the given point doesn't lie inside the layout size, nil is returned. */
- (ETLayoutItem *) itemAtLocation: (NSPoint)location
{
	FOREACH([_layoutContext visibleItems], item, ETLayoutItem *)
	{
		if (NSPointInRect(location, [item frame]))
				return item;
	}
	
	return nil;
}

/** <override-dummy />
Returns the display area of the given layout item.
 
The returned rect is expressed in the layout context coordinates.

Overrides in your subclass to return the right display rect when the layout 
doesn't let the presented items draw themselves, but use its own drawing 
mechanism and a display area per item which might not match the item frame.

When no layout context is available, returns a null rect.<br />
This method doesn't check whether the given item really belongs to the layout 
context or not. When it doesn't, the returned rect value is undetermined. 
Subclasses which override -isOpaque to return YES can supercede this policy.<br />
For example -[ETOutlineLayout displayRectOfItem:] can match descendant items 
unlike ETFlowLayout which only matches immediate child items.

If the given item is nil, an NSInvalidArgumentException will be raised. */
- (NSRect) displayRectOfItem: (ETLayoutItem *)item
{
	NILARG_EXCEPTION_TEST(item);

	if (nil == _layoutContext)
		return ETNullRect;

	return [item frame];
}

/** <override-dummy />
Marks the layout view rect that corresponds the given item area in the receiver 
layout as needing display. 

You must override this method to handle the item redisplay when a layout 
subclass completely takes over the display and ignores the layout item geometry, 
styles, view etc. For example, ETTableLayout overrides this method to invalidate 
the row associated with the given item. */
- (void) setNeedsDisplayForItem: (ETLayoutItem *)anItem
{
	[[[self ifResponds] layoutView] setNeedsDisplayInRect: [self displayRectOfItem: anItem]];
}

/* Item State Indicators */

/** <override-never />
Returns the drop indicator style that should be drawn to indicate hovered 
items which are valid drop targets.

By default, returns an ETDropIndicator instance. */
- (ETDropIndicator *) dropIndicator
{
	return _dropIndicator;
}

/** <override-never />
Sets the drop indicator style that should be drawn to indicate hovered 
items which are valid drop targets. */
- (void) setDropIndicator: (ETDropIndicator *)aStyle
{
	ASSIGN(_dropIndicator, aStyle);
}

/** <override-dummy />
Returns NO when styles can draw selection indicators for selected items, 
otherwise returns YES.
 
Some layouts such as ETFreeLayout shows the selection using additional items 
(e.g. ETHandleGroup).
 
By default, returns NO.
 
See also -[ETBasicItemStyle shouldDrawItemAsSelected:]. */
- (BOOL) preventsDrawingItemSelectionIndicator
{
	return NO;
}

/* Sorting */

/** <override-dummy /> 
Returns the given sort descriptors.

Overrides in your subclass to customize the sort descriptors used to sort the 
the layout context.<br />
When the sorting is recursive, the returned descriptors will be also be used  
to sort the item subtree.

See also ETController which usually provides the sort descriptors we receive. */
- (NSArray *) customSortDescriptorsForSortDescriptors: (NSArray *)currentSortDescriptors
{
	return currentSortDescriptors;
}

@end
