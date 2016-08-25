/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import <CoreObject/COObjectGraphContext.h>
#import "ETLayout.h"
#import "ETApplication.h"
#import "ETAspectRepository.h"
#import "ETDropIndicator.h"
#import "ETGeometry.h"
#import "ETTool.h"
#import "ETLayoutExecutor.h"
#import "ETLayoutItem+Private.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETPositionalLayout.h"
#import "NSObject+EtoileUI.h"
#import "NSView+EtoileUI.h"
#import "ETCompatibility.h"

@interface ETLayout (Private)
+ (void) registerBuiltInLayoutClasses;
- (BOOL) loadNibNamed: (NSString *)nibName;
@property (nonatomic, getter=isLayoutViewInUse, readonly) BOOL layoutViewInUse;
@end

@interface COObject (RelationshipCache)
- (void) updateCachedOutgoingRelationshipsForOldValue: (id)oldVal
                                             newValue: (id)newVal
                            ofPropertyWithDescription: (ETPropertyDescription *)aProperty;
@end


@implementation ETLayout

@dynamic contextItem;

static NSMutableSet *layoutPrototypes = nil;

/** Registers a prototype for every ETLayout subclasses.

The implementation won't be executed in the subclasses but only the abstract 
base class.

You should never need to call this method.

See also NSObject(ETAspectRegistration). */
+ (void) registerAspects
{
	layoutPrototypes = [NSMutableSet set];

	NSArray *skippedClasses = A(NSClassFromString(@"ETWidgetLayout"),  
		NSClassFromString(@"ETWindowLayout"), 
		NSClassFromString(@"ETTemplateItemLayout"),
		NSClassFromString(@"ETComputedLayout"),
		NSClassFromString(@"ETFormLayout"),
		NSClassFromString(@"ETTextEditorLayout"));
	NSArray *subclasses = [[self allSubclasses] arrayByRemovingObjectsInArray: skippedClasses];

	for (Class subclass in subclasses)
	{
		@autoreleasepool
		{
    		[self registerLayout: [[subclass alloc]
				initWithObjectGraphContext: [self defaultTransientObjectGraphContext]]];
		}
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

	ETAspectRepository *repo = [ETAspectRepository mainRepository];
	ETAspectCategory *category = [repo aspectCategoryNamed: _(@"Layout")];

	if (category == nil)
	{
		category = [[ETAspectCategory alloc] initWithName: _(@"Layout")
		                               objectGraphContext: [repo objectGraphContext]];
		[category setIcon: [NSImage imageNamed: @"layout-design"]];
		[[ETAspectRepository mainRepository] addAspectCategory: category];
	}
	[category setAspect: aLayout forKey: [[aLayout class] displayName]];
}

/** Returns all the layout prototypes directly available for EtoileUI facilities 
that allow to transform the UI at runtime. */
+ (NSSet *) registeredLayouts
{
	return [layoutPrototypes copy];
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
+ (instancetype) layoutWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	return [[[self class] alloc] initWithObjectGraphContext: aContext];
}

/** <init /> 
Returns a new ETLayout instance. */
- (instancetype) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	_attachedTool = nil;
	_dropIndicator = [ETDropIndicator sharedInstanceForObjectGraphContext: aContext];
	_isRendering = NO;
	_layoutSize = ETNullSize;
	_oldProposedLayoutSize = ETNullSize;
	 /* Will ensure -resizeItems:toScaleFactor: isn't called until the scale changes */
	_previousScaleFactor = 1.0;

	return self;
}

- (instancetype) init
{
	return [self initWithObjectGraphContext: nil];
}

- (void) dealloc
{
    // TODO: If the attached tool is active, we should tell ETTool class about
    // it, and switch the active tool (if the default transient object graph
    // context is not currently discarding all its changes).
    if ([[[self objectGraphContext] loadedObjects] isEmpty] == NO)
    {
        // NOTE: At this point, the attached tool is unloaded.
        ETAssert([[_attachedTool UUID] isEqual: [ETTool activeToolUUID]] == NO);
    }
}

- (BOOL) isLayout
{
	return YES;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"ui-layered-pane"];
}

/** Returns the tool or tool bound to the receiver. */
- (id) attachedTool
{
	ETAssert(_attachedTool == nil || [_attachedTool layoutOwner] == self);
	return _attachedTool;
}

- (ETTool *) proposedActiveToolForNewTool: (ETTool *)newTool
{
	if (newTool != nil)
		return newTool;
		
	return [ETTool activatableToolForItem: (ETLayoutItem *)[self layoutContext]];
}

/** Sets the tool or tool bound to the receiver. 

The tool set becomes the receiver owner. See -[ETTool layoutOwner].

If the previously attached tool was the active tool, the new one 
becomes the active tool (the receiver must be present in the item tree bound to 
-[ETApplication layoutItem], otherwise nothing happens). See -[ETTool setActiveTool:].

If the tool is already attached to another layout, raises an 
NSInvalidArgumentException.

If the layout context is not a layout item (e.g. the receiver is a secondary 
layout), raises a NSInvalidArgumentException.

Also invokes -didChangeAttachedTool:toTool:.  */
- (void) setAttachedTool: (ETTool *)newTool
{
	INVALIDARG_EXCEPTION_TEST(newTool, [newTool layoutOwner] == nil);
	if ([self layoutContext] != nil)
	{
		INVALIDARG_EXCEPTION_TEST(newTool, [(id)[self layoutContext] isLayoutItem]);
	}

	if (_attachedTool == newTool)
		return;

	ETTool *oldTool = _attachedTool;

	[newTool validateLayoutOwner: self];
	[self willChangeValueForProperty: @"attachedTool"];
	/* Reset target item previously set for another layout */
	[newTool setTargetItem: nil];
	_attachedTool = newTool;
	/* Will update ETTool.layoutOwner inverse relationship */
	[self didChangeValueForProperty: @"attachedTool"];

	ETAssert(newTool == nil
		|| ([newTool layoutOwner] == self && [newTool targetItem] == (id)[self layoutContext]));

	// NOTE: The remaining code requires ETTool.layoutOwner to be set, so we
	// execute it last
	if ([oldTool isEqual: [ETTool activeTool]])
	{
		[ETTool setActiveTool: [self proposedActiveToolForNewTool: newTool]];
	}
	[self didChangeAttachedTool: oldTool toTool: newTool];
}

/** <override-dummy />
Tells the receiver the attached tool owned by an ancestor layout (or itself) 
has changed. This tool may or may not be active.

Will be called by -setAttachedTool: and -renderWithItems:isNewContent: (if there 
is some new content). So this means tool changes are reported even for 
-[ETLayoutItemGroup setLayout:] or ETLayoutItemGroup content mutation.

You can override this method in subclasses to adjust the receiver layout to the 
new tool that can now be used to interact with the presented content. 

You must correctly handle cases where the old tool and the new tool are nil. 
For changes reported by -renderWithItems:isNewContent, the old tool is always 
reported as nil.

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
	for (ETLayoutItem *item in [[self layoutContext] arrangedItems])
	{
		[[item layout] didChangeAttachedTool: oldTool
		                              toTool: newTool];
	}
}

/** <override-dummy />
Returns the tool attached to the layout, if it replies YES to 
-acceptsFirstResponder, otherwise returns the layout context. */
- (id) responder
{
	return ([[self attachedTool] acceptsFirstResponder] ? [self attachedTool] : [self layoutContext]);
}

/** <override-never />
Validates the context where the layout should happen. 

When a layout context is set, with the next layout update the receiver will 
arrange the layout items in a specific style and order.

You must override -setUp and/or -tearDown to react to a layout change and not 
this method.

If a tool is attached, the layout context must be a layout item, otherwise a 
NSInvalidArgumentException is raised.

The layout context is expected to retain its layout, hence the receiver doesn't 
retain the given context. */
- (void) validateLayoutContext: (id <ETLayoutingContext>)context
{
	if (context != nil)
	{
		INVALIDARG_EXCEPTION_TEST(context, [self attachedTool] == nil || [(id)context isLayoutItem]);
	}
	ETDebugLog(@"Modify layout context from %@ to %@ in %@", [self layoutContext], context, self);
}

/** Returns the context where the layout happens. */
- (id <ETLayoutingContext>) layoutContext
{
    return [self contextItem];
}

/** <override-dummy />Overrides if your subclass requires extra cleanup when the 
layout context is switched to another layout (the receiver stops to be used and 
visible).

The layout context hasn't yet been touched when this method is called.

You must call the superclass implementation if you override this method. */
- (void) tearDown
{
	NSParameterAssert([self layoutContext] != nil);
	ETAssert(_isSetUp);

	[self unmapLayerItemFromLayoutContext];
	_isSetUp = NO;
}

/** <override-dummy />Overrides if your subclass requires long-term or immediate 
adjustments when the layout context is switched to the receiver (it becomes the 
new layout and starts to be used and visible).

The new layout context has been set when this method is called.
 
Don't override this method, unless you want to apply changes to the internal
state that will hold until -tearDown, or cannot wait until 
-renderWithItems:isNewContent:.

You must not touch the layout context state or some other external state.

You must call the superclass implementation if you override this method. */
- (void) setUp: (BOOL)isDeserialization
{
	NSParameterAssert([self layoutContext] != nil);
	ETAssert(_isSetUp == NO);

	_isSetUp = YES;
	[self mapLayerItemIntoLayoutContext];

	if (isDeserialization)
		return;

	/* Reset the layout size to ensure -resizeItems:forNewLayoutSize:oldSize:
	   receives a valid old size (neither zero or computed for a previous layout context). */
	[self resetLayoutSize];
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

/** <override-dummy />
See -[ETPositionalLayout isContentSizeLayout].
 
By default, returns NO. */
- (BOOL) isContentSizeLayout
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
	return ([[[self layoutContext] exposedItems] count] == [[[self layoutContext] items] count]);
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
	[self willChangeValueForProperty: @"layoutSize"];
	_layoutSize = size;
	[self syncLayerItemGeometryWithSize: size];
	[self didChangeValueForProperty: @"layoutSize"];
}

/** Returns the last computed layout size.

The layout area size is usually computed every time 
-renderWithItems:isNewContent: is invoked with a new content. */
- (NSSize) layoutSize
{
	return _layoutSize;
}

/** <override-dummy />Returns nil.
 
Can be overriden by subclasses to return the positional layout used to present 
the items.
 
Subclasses can return the receiver.
 
See ETPositionalLayout and -[ETPositionalLayout positionalLayout]. */
- (ETPositionalLayout *) positionalLayout
{
	return nil;
}

/** Returns whether -renderXXX methods can be invoked now. */
- (BOOL) canRender
{
	BOOL hasValidContext = ([self layoutContext] != nil);

	/* When the layout context is a layout */
	if (hasValidContext && [(id)[self layoutContext] isLayoutItem] == NO)
	{
		ETAssert([(ETLayout *)[self layoutContext] isComposite]);
		hasValidContext = ([(ETLayout *)[self layoutContext] layoutContext] != nil);
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
	   -renderAndInvalidDisplay.

	   Don't use -ifResponds to support testing item creation retain count 
	   easily (see TestLayoutItem.m). */
	return (_isRendering || ([(id)[self layoutContext] isLayout] && [(ETLayout *)[self layoutContext] isRendering]));
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
	if ([self layoutContext] == nil)
	{
		ETLog(@"WARNING: Missing layout context in %@... Won't render.", self);
	}

	if ([self canRender] == NO)
		return;

	_isRendering = YES;
	[self setLayoutSize: [self renderWithItems: [[self layoutContext] arrangedItems]
	                              isNewContent: isNewContent]];

	/* Adjust layout context size (e.g. when it is embedded in a scroll view) */
	if ([self isContentSizeLayout])
	{
		[[self layoutContext] setContentSize: [self layoutSize]];
		ETDebugLog(@"Layout size is %@ with layout context size %@ and clip view size %@", 
			NSStringFromSize([self layoutSize]), 
			NSStringFromSize([[self layoutContext] size]), 
			NSStringFromSize([[self layoutContext] visibleContentSize]));
	}
	_isRendering = NO;
}

- (NSSize) proposedLayoutSize
{
	return [[self layoutContext] visibleContentSize];
}

/** Sets the layout size to match the current content size of the layout context,
and returns the old layout size.

You call this method to reset the layout size to a value that should be used
as a basis to compute the layout. By default, the items are laid out within the 
boundaries of -[ETLayoutingContext visibleContentSize].

If the layout context is a scrollable area, this method will take it in account. */
- (NSSize) resetLayoutSize
{
	NSSize oldLayoutSize = _oldProposedLayoutSize;
	NSSize newLayoutSize = [self proposedLayoutSize];

	/* We always set the layout size which should be used to compute the 
	   layout unless a custom layout size is set later. */
	[self setLayoutSize: newLayoutSize];
	_oldProposedLayoutSize = newLayoutSize;

	return oldLayoutSize;
}

/** <override-dummy />
Renders the layout.<br />
This is a skeleton implementation which only invokes -resetLayoutSize:, 
-resizeItems:forNewLayoutSize:oldSize:, -resizeLayoutItems:toScaleFactor: and 
-didChangeAttachedTool:toTool:.

You can reuse this implementation in your subclass or not.

isNewContent indicates when the layout update is triggered by a node insertion 
or removal in the tree structure that belongs to the layout context.

Any layout item which belongs to the layout context, but not present in the item 
array argument, can be ignored in the layout logic implemented by subclasses.<br />
This optimization is not yet used and a subclass is not required to comply to 
it (this is subject to change though). */
- (NSSize) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{	
	ETDebugLog(@"Render layout items: %@", items);

	CGFloat scale = [[self layoutContext] itemScaleFactor];
	NSSize oldLayoutSize = [self resetLayoutSize];
	ETAssert(NSEqualSizes(oldLayoutSize, ETNullSize) == NO);

	if ([(ETPositionalLayout *)[self ifResponds] isContentSizeLayout] == NO)
	{
		[self resizeItems: items
		 forNewLayoutSize: [self layoutSize]
		          oldSize: oldLayoutSize];
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
	if ([self shouldResizeItemsToScaleFactor: scale])
	{
		[self resizeItems: items toScaleFactor: scale];
		_previousScaleFactor = scale;
	}
	if (isNewContent && [(id)[self layoutContext] isLayoutItem])
	{
		[self didChangeAttachedTool: nil
		                     toTool: [ETTool activatableToolForItem: (ETLayoutItem *)[self layoutContext]]];
	}
	return [self layoutSize];
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
Returns YES if the scale factor has changed since the last rendering.
 
Can be overriden to decide about scaling the items or not on more conditions. 
For example, ETPositionalLayout overrides it to return YES if vertical or 
horizontal size constraints are set. */
- (BOOL) shouldResizeItemsToScaleFactor: (CGFloat)aFactor
{
	return (aFactor != _previousScaleFactor);
}

/** <override-dummy />
Does nothing.
 
Overrides this method to support a custom resizing policy bound to   
-[ETLayoutContext itemScaleFactor].
 
See also -[ETLayoutItemGroup itemScaleFactor] and 
-[ETPositionalLayout resizeItems:toScaleFactor:]. */
- (void) resizeItems: (NSArray *)items toScaleFactor: (CGFloat)factor
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
	   -[ETLayoutItemGroup init]
	   -[ETFixedLayout layerItem]
	   -[ETFixedLayout mapLayerItemInLayoutContext]
	   -[ETFixedLayout setUp]
	   -[ETLayoutItemGroup init]
	   That's why we check -isLayerItem. */
	if (_layerItem == nil && [(id)[self layoutContext] isLayoutItem] && [(ETLayoutItem *)[self layoutContext] isLayerItem] == NO)
	{
		_layerItem = [[ETLayoutItemGroup alloc]
			initAsLayerItemWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
	}

	/* When the layout context is a composite layout, the positional layout 
	   reuses its layer item */
	if ([self layoutContext] != nil && [(id)[self layoutContext] isLayoutItem] == NO)
	{
		return [(ETLayout *)[self layoutContext] layerItem];
	}

	return _layerItem;
}

/** Resizes the layer item to the given size and sets its -isFlipped property 
to be identical to the layout context. */
- (void) syncLayerItemGeometryWithSize: (NSSize)aSize
{
	[[self layerItem] setFlipped: [[self layoutContext] isFlipped]];
	/* The layer item is rendered in the coordinate space of the layout context */
	[[self layerItem] setSize: aSize];
	
	/* For a flexible parent item, the layer item is flexible due to 
	   -isLayoutExecutionItemDependent evaluated against the parent in
	   -[ETLayoutExecutor isFlexibleItem:], so we must not schedule the layer 
	   item in this case (to prevent scheduling in the executor). 
	   A better solution would be to ensure all layer items are non-flexible 
	   e.g. -isLayoutLayer could be added to ETLayoutItemGroup and checked in 
	   -isFlexibleItem: (their resizing is managed by the owning layout). */
	if ([self isRendering] || [self layerItem] == nil)
		return;

	/* Autolayout is disabled during a layout change or update, so we mark 
	  -layerItem as requiring a layout update (-setNeedsLayoutUpdate won't work). */
	[[ETLayoutExecutor sharedInstance] addItem: [self layerItem]];
}

- (void) mapLayerItemIntoLayoutContext
{
	NSParameterAssert(nil != [self layoutContext]);

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
		[[self layerItem] setHostItem: layoutContext];
	}

	[self syncLayerItemGeometryWithSize: [layoutContext visibleContentSize]];
}

- (void) unmapLayerItemFromLayoutContext
{
	[[self layerItem] setHostItem: nil];
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
	for (ETLayoutItem *item in [[self layoutContext] visibleItems])
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

	if (nil == [self layoutContext])
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
	[self willChangeValueForProperty: @"dropIndicator"];
	_dropIndicator = aStyle;
	[self didChangeValueForProperty: @"dropIndicator"];
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
