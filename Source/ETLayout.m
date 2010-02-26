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
#import "ETGeometry.h"
#import "ETInstrument.h"
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

	FOREACH([self allSubclasses], subclass, Class)
	{
		[self registerLayout: AUTORELEASE([[subclass alloc] init])];
	}
}

/** Returns ET. */
+ (NSString *) typePrefix
{
	return @"ET";
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
	// TODO: Make a class instance available as an aspect in the aspect 
	// repository.
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
- (Class) layoutClassForLayoutView: (NSView *)layoutView
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
- (id) initWithLayoutView: (NSView *)layoutView
{
	SUPERINIT
	
	/* Class cluster initialization */
	
	/* ETLayout itself takes the placeholder object role. By removing the 
	   following if statement, concrete subclass would have the possibility
	   to override the concrete subclass... No utility right now. */
	if (layoutView != nil && [self isMemberOfClass: [ETLayout class]])
	{
		/* Find the concrete layout class to instantiate */
		Class layoutClass = [self layoutClassForLayoutView: layoutView];
		
		/* Eventually replaces the receiver by a new concrete instance */
		if (layoutClass != nil)
		{
			if ([self isMemberOfClass: layoutClass] == NO)
			{
				NSZone *zone = [self zone];
				RELEASE(self);
				self = [[layoutClass allocWithZone: zone] initWithLayoutView: layoutView];
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
	_delegate = nil;
	_instrument = nil;
	ASSIGN(_dropIndicator, [ETDropIndicator sharedInstance]);
	_isLayouting = NO;
	_layoutSize = NSMakeSize(200, 200); /* Dummy value */
	_layoutSizeCustomized = NO;
	_maxSizeLayout = NO;
	_itemSize = NSMakeSize(256, 256); /* Default max item size */
	/* By default both width and height must be equal or inferior to related _itemSize values */
	_itemSizeConstraintStyle = ETSizeConstraintStyleNone;
	 /* Will ensure -resizeItems:toScaleFactor: isn't called until the scale changes */
	 _previousScaleFactor = 1.0;

	if (layoutView != nil) /* Use layout view parameter */
	{
		[self setLayoutView: layoutView];
	}
	else if ([self nibName] != nil) /* Use layout view in nib */
	{
		if ([self loadNibNamed: [self nibName]] == NO)
		{
			self = nil;
		}
	}
	
	return self;
}

/** <overidde-dummy />
Returns the name of the nib file the receiver should automatically load when 
it gets instantiated.

Overrides in your subclass when you want to retrieve objects stored in a nib 
to initialize your subclass instances. e.g. you can bind the _layoutView outlet 
to any view to make it transparently available with -layoutView. -setLayoutView: 
will be invoked when the outlet is set.

Returns nil by default. */
- (NSString *) nibName
{
	return nil;
}

- (BOOL) loadNibNamed: (NSString *)nibName
{
	BOOL nibLoaded = [NSBundle loadNibNamed: nibName owner: self];
	
	if (nibLoaded)
	{
		// TODO: Remove this branch statement once the outlet has been renamed 
		// layoutView
		/* This outlet will be removed from its superview by -setLayoutView:. 
		   However the nib loading doesn't send a retain when connecting it to 
		   the outlet ivar and ASSIGN(_displayViewPrototype, protoView) in 
		   -setLayoutView:  won't retain it either in our case, because both 
		   members of the expression are identical. That's why we do a RETAIN 
		   here, it simply plays the role of the ASSIGN in -setLayoutView:.

		   When _displayViewPrototype will be later renamed layoutView, the nib 
		   loading will call -setLayoutView: to connect the view to the ivar 
		   outlet, in this case ASSIGN will play its role as expected by 
		   retaining the view. */ 
		RETAIN(_displayViewPrototype);
		[self setLayoutView: _displayViewPrototype];
	}
	else
	{
		ETLog(@"WARNING: Failed to load nib %@", nibName);
		AUTORELEASE(self);
	}
	return nibLoaded;
}

- (id) init
{
	return [self initWithLayoutView: nil];
}

- (void) dealloc
{
	/* Neither layout context and delegate have to be retained. 
	   The layout context is our owner and retains us. */
	DESTROY(_displayViewPrototype);
	DESTROY(_instrument);
	DESTROY(_rootItem);
	DESTROY(_dropIndicator);

	[super dealloc];
}

/** <override-dummy />
Returns a copy of the receiver.<br />
The given context which might be nil will be set as the layout context on the copy.

This method is ETLayout designated copier. Subclasses that want to extend 
the copying support must invoke it instead of -copyWithZone:.

Subclasses must be aware that this method calls -setAttachedInstrument: with an 
instrument copy. */ 
- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETLayout *newLayout = [[self class] alloc];

	/* We copy all ivars except _layoutContext and _isLayouting */

	newLayout->_layoutContext = ctxt;
	newLayout->_delegate = _delegate;
	newLayout->_displayViewPrototype = [_displayViewPrototype copyWithZone: aZone];
	newLayout->_rootItem = [_rootItem copyWithZone: aZone];
	newLayout->_dropIndicator = RETAIN(_dropIndicator);
	[newLayout setAttachedInstrument: [[self attachedInstrument] copyWithZone: aZone]];
	RELEASE([newLayout attachedInstrument]);
	newLayout->_layoutSize = _layoutSize;
	newLayout->_layoutSizeCustomized = _layoutSizeCustomized;
	newLayout->_maxSizeLayout  = _maxSizeLayout;
	newLayout->_itemSize = _itemSize;
	newLayout->_itemSizeConstraintStyle = _itemSizeConstraintStyle;
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
}

/** <override-never />
Returns a copy of the receiver.

The layout context in the copy is nil.

Subclasses must be aware that this method calls -setAttachedInstrument: with an 
instrument copy.

To customize the copying in a subclass, you must override 
-copyWithZone:layoutContext:. */ 
- (id) copyWithZone: (NSZone *)aZone
{
	return [self copyWithZone: aZone layoutContext: nil];
}

/** Returns the instrument or tool bound to the receiver. */
- (id) attachedInstrument
{
	return _instrument;
}

/** Sets the instrument or tool bound to the receiver. 

The instrument set becomes the receiver owner. See -[ETInstrument layoutOwner].

If the previously attached instrument was the active instrument, the new one 
becomes the active instrument. See -[ETInstrument setActiveInstrument:].

Also invokes -didChangeAttachedInstrument:toInstrument:.  */
- (void) setAttachedInstrument: (ETInstrument *)newInstrument
{
	if ([newInstrument isEqual: _instrument] == NO)
		[_instrument setLayoutOwner: nil];
		
	ETInstrument *oldInstrument = RETAIN(_instrument);

	ASSIGN(_instrument, newInstrument);
	[newInstrument setLayoutOwner: self];

	if ([oldInstrument isEqual: [ETInstrument activeInstrument]])
	{
		[ETInstrument setActiveInstrument: newInstrument];
	}

	[self didChangeAttachedInstrument: oldInstrument  toInstrument: newInstrument];

	RELEASE(oldInstrument);
}

/** <override-dummy />
Tells the receiver the attached instrument owned by an ancestor layout (or itself) 
has changed. This instrument may or may not be active.

You can override this method in subclasses to adjust the receiver layout to the 
new instrument that can now be used to interact with the presented content. 

By default, propagates the message recursively in the layout item tree through 
the layout context arranged items.

You can override this method to hide or show layout items that belong the item 
tree returned by -[ETLayout rootItem] on an instrument change. e.g. ETFreeLayout 
toggles the handle visibility when the select tool is attached (or detached) to 
the receiver layout or any ancestor layout.

The ancestor layout on which the instrument was changed can be retrieved with 
[newInstrument layoutOwner]. */
- (void) didChangeAttachedInstrument: (ETInstrument *)oldInstrument
                        toInstrument: (ETInstrument *)newInstrument
{
	FOREACH([_layoutContext arrangedItems], item, ETLayoutItem *)
	{
		[[item layout] didChangeAttachedInstrument: oldInstrument
		                              toInstrument: newInstrument];
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

	/* We remove the display views of layout items.
	   Take note they may be invisible by being located outside of the container 
	   bounds.	
	   If we don't and we switch from a computed layout to a view-based layout,
	   they might remain visible as subviews (think ETBrowserLayout on GNUstep 
	   which has transparent areas) because view-based layout are not required 
	   to call -setVisibleItems: when they override -renderWithLayoutItems:XXX:. 
	   By introducing a null layout, we would be able to move that in -tearDown. 
	   That doesn't work presently when we switch from a nil layout to a non-nil 
	   layout, because -setLayoutContext: nil isn't called, hence -tearDown 
	   neither. */
	ETDebugLog(@"Remove views of layout items currently displayed");
	[context setVisibleItems: [NSArray array]];	

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
	/* Don't forget to remove existing layout view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	// NOTE: Be careful of layout instances which can share a common class but 
	// all differ by their unique layout view prototype.
	// Triggers scroll view display which triggers layout render in turn to 
	// compute the content size
	[_layoutContext setLayoutView: nil];
	[self unmapRootItemFromLayoutContext];
}

/** <override-dummy />Overrides if your subclass requires extra transformation 
when the layout context is switched to the receiver (it becomes the new layout 
and starts to be used and visible).

The new layout context has been set when this method is called.

You must call the superclass implementation if you override this method. */
- (void) setUp
{
	NSParameterAssert(_layoutContext != nil);
	[self setUpLayoutView];
	[self mapRootItemIntoLayoutContext];
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

/** Returns YES when the receiver is a layout that does nothing, otherwise 
returns NO. See ETNullLayout which is the only built-in class that returns YES.

By default, returns NO. */
- (BOOL) isNull
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
	return [self conformsToProtocol: @protocol(ETPositionalLayout)];
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
	_layoutSizeCustomized = flag;
}

/** Returns whether a custom area size where the layout should be rendered. */
- (BOOL) usesCustomLayoutSize
{
	return _layoutSizeCustomized;
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
	[self syncRootItemGeometryWithSize: size];
}

/** Returns the last computed layout size.

The layout area size is usually computed every time 
-renderWithLayoutItems:isNewContent: is invoked with a new content. */
- (NSSize) layoutSize
{
	return _layoutSize;
}

/** Sets whether the layout context can be resized, when its current size is 
not enough to let the layout present the items in its own way. 

The only common case where -isContentSizeLayout should return YES is when the 
layout context is scrollable, and ETLayout does it transparently. Which means 
you very rarely need to use this method.

See also -isContentSizeLayout:. */
- (void) setIsContentSizeLayout: (BOOL)flag
{
	//ETDebugLog(@"-setContentSizeLayout");
	_maxSizeLayout = flag;
}

/** Returns whether the layout context can be resized, when its current size is 
not enough to let the layout present the items in its own way. 

When a scrollable area item decorates the layout context, -isContentSizeLayout 
always returns YES. */
- (BOOL) isContentSizeLayout
{
	if ([_layoutContext isScrollViewShown])
		return YES;

	return _maxSizeLayout;
}

/** Sets the delegate.

The delegate is not retained.

Not used presently. */
- (void) setDelegate: (id)delegate
{
	_delegate = delegate;
}

/** Returns the delegate. 

See also -setDelegate:. */
- (id) delegate
{
	return _delegate;
}

/* Item Sizing Accessors */

/** Sets how the item is resized based on the constrained item size.

See ETSizeConstraintStyle enum. */
- (void) setItemSizeConstraintStyle: (ETSizeConstraintStyle)constraint
{
	_itemSizeConstraintStyle = constraint;
}

/** Returns how the item is resized based on the constrained item size.

See ETSizeConstraintStyle enum. */
- (ETSizeConstraintStyle) itemSizeConstraintStyle
{
	return _itemSizeConstraintStyle;
}

/** Sets the width and/or height to which the items should be resized when their 
width and/or is greater than the given one.

Whether the width, the height or both are resized is controlled by 
-itemSizeConstraintStyle.

See also setItemSizeConstraintStyle: and -resizeLayoutItems:toScaleFactor:. */
- (void) setConstrainedItemSize: (NSSize)size
{
	_itemSize = size;
}

/** Returns the width and/or height to which the items should be resized when 
their width and/or height is greater than the returned one.

See also -setContrainedItemSize:. */
- (NSSize) constrainedItemSize
{
	return _itemSize;
}

/** Returns whether -renderXXX methods can be invoked now. */
- (BOOL) canRender
{
	return (_layoutContext != nil && [self isRendering] == NO);
}

/** Returns whether the layout phase in underway.

When you want to use Layouting related methods, you must check this method 
returns YES. When NO is returned, wait until it returns YES.  */
- (BOOL) isRendering
{
	return _isLayouting;
}

/** Requests the items to present to the layout context, then renders the 
layout with -renderWithLayoutItems:isNewContent:.

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
- (void) render: (NSDictionary *)inputValues isNewContent: (BOOL)isNewContent
{
	if (_layoutContext == nil)
	{
		ETLog(@"WARNING: Missing layout context in %@... Won't render.", self);
	}

	if ([self canRender] == NO)
		return;

	_isLayouting = YES;

	/* When the number of layout items is zero and doesn't vary, no layout 
	   update is necessary */
	// TODO: Try some optimizations, in the vein of...
	// if ([[[self layoutContext] items] count] == 0 && _nbOfItemCache != [[[self layoutContext] items] count])
	//	 return;

	[self renderWithLayoutItems: [_layoutContext arrangedItems] isNewContent: isNewContent];

	_isLayouting = NO;
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
		if ([[self layoutContext] isScrollViewShown])
		{
			/* Better to request the visible rect than the container frame 
			   which might be severely altered by the previouly set layout. */
			[self setLayoutSize: [[self layoutContext] visibleContentSize]];
		}
		else /* Using content layout size without scroll view is supported */
		{
			[self setLayoutSize: [[self layoutContext] size]];
		}
	}
}

/** <override-dummy />
Renders the layout.<br />
This is a skeleton implementation which only invokes -resetLayoutSize: and 
-resizeLayoutItems:toScaleFactor:.

You can reuse this implementation in your subclass or not.

isNewContent indicates when the layout update is triggered by a node insertion 
or removal in the tree structure that belongs to the layout context.

Any layout item which belongs to the layout context, but not present in the item 
array argument, can be ignored in the layout logic implemented by subclasses.<br />
This optimization is not yet used and a subclass is not required to comply to 
it (this is subject to change though). */
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{	
	ETDebugLog(@"Render layout items: %@", items);

	float scale = [[self layoutContext] itemScaleFactor];

	[self resetLayoutSize];
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
	if (scale != _previousScaleFactor 
	 || [self itemSizeConstraintStyle] != ETSizeConstraintStyleNone)
	{
		[self resizeLayoutItems: items toScaleFactor: scale];
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
		[self render: nil isNewContent: NO];
		[[self layoutContext] setNeedsDisplay: YES];
	}
}

/** Resizes layout item by scaling of the given factor the -defaultFrame 
    returned by each item, then applying the scaled rect with -setFrame:.
	Once the scaled rect has been computed, right before applying it to the 
	item, this method checks for the item size contraint. If the size constraint 
	is ETSizeConstraintStyleNone, the scaled rect is used as is. For other 
	size constraint values, the scaled rect is checked against 
	-constrainedItemSize for either width, height or both, then altered if the 
	rect width or height is superior to the allowed maximum value. 
	If -itemSizeConstraintStyle returns ETConstraintStyleNone, the layout will 
	respect the autoresizing mask returned by -[ETLayoutItem autoresizingMask],
	otherwise it won't. */
- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	FOREACH(items, item, ETLayoutItem *)
	{
		/* Scaling is always computed from item default frame rather than
		   current item view size (or  item display area size) in order to
		   avoid rounding error that would increase on each scale change 
		   because of size width and height expressed as float. */
		NSRect itemFrame = ETScaleRect([item defaultFrame], factor);
		
		/* Apply item size constraint if needed */
		if ([self itemSizeConstraintStyle] != ETSizeConstraintStyleNone 
		 && (itemFrame.size.width > [self constrainedItemSize].width
		 || itemFrame.size.height > [self constrainedItemSize].height))
		{ 
			BOOL isVerticalResize = NO;
			
			if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleVerticalHorizontal)
			{
				if (itemFrame.size.height > itemFrame.size.width)
				{
					isVerticalResize = YES;
				}
				else /* Horizontal resize */
				{
					isVerticalResize = NO;
				}
			}
			else if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleVertical
			      && itemFrame.size.height > [self constrainedItemSize].height)
			{
				isVerticalResize = YES;	
			}
			else if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleHorizontal
			      && itemFrame.size.width > [self constrainedItemSize].width)
			{
				isVerticalResize = NO; /* Horizontal resize */
			}
			
			if (isVerticalResize)
			{
				float maxItemHeight = [self constrainedItemSize].height;
				float heightDifferenceRatio = maxItemHeight / itemFrame.size.height;
				
				itemFrame.size.height = maxItemHeight;
				itemFrame.size.width *= heightDifferenceRatio;
					
			}
			else /* Horizontal resize */
			{
				float maxItemWidth = [self constrainedItemSize].width;
				float widthDifferenceRatio = maxItemWidth / itemFrame.size.width;
				
				itemFrame.size.width = maxItemWidth;
				itemFrame.size.height *= widthDifferenceRatio;				
			}
		}
		
		/* Apply Scaling */
		itemFrame.origin = [item origin];
		[item setFrame: itemFrame];
		ETDebugLog(@"Scale %@ to %@", NSStringFromRect([item defaultFrame]), 
			NSStringFromRect(ETScaleRect([item defaultFrame], factor)));
	}
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
/** Returns the root item specific to the receiver. This layout-specific tree 
includes additional items such as resize handles, positioning indicators etc. 

These items can be composed into the semantic layout item tree, each time the 
receiver is set on a layout context. At this point, the layout item tree visible 
on screen is really a composite between the main item tree which owns the layout 
context and the tree rooted in -rootItem. */
- (ETLayoutItemGroup *) rootItem
{
	/* A layout set on a root item encapsulated in a layout must have no root 
	   item otherwise -[ETLayout rootItem] results in an endless recursion:
	   -[ETFixedLayout rootItem]
	   -[ETFixedLayout mapRootItemInLayoutContext]
	   -[ETFixedLayout setUp]
	   -[ETFixedLayout setLayoutContext:]
	   -[ETLayoutItemGroup init]
	   -[ETFixedLayout rootItem]
	   -[ETFixedLayout mapRootItemInLayoutContext]
	   -[ETFixedLayout setUp]
	   -[ETFixedLayout setLayoutContext:]
	   -[ETLayoutItemGroup init]
	   That's why we check -isLayoutOwnedRootItem. */
	if (_rootItem == nil && [_layoutContext isLayoutItem] && [_layoutContext isLayoutOwnedRootItem] == NO)
	{
		_rootItem = [[ETLayoutItemGroup alloc] initAsLayoutOwnedRootItem];
	}

	return _rootItem;
}

/** Resizes the root item to the given size and sets its -isFlipped property 
to be identical to the layout context. */
- (void) syncRootItemGeometryWithSize: (NSSize)aSize
{
	[[self rootItem] setFlipped: [[self layoutContext] isFlipped]];
	/* The root item is rendered in the coordinate space of the layout context */
	[[self rootItem] setSize: aSize];
}

- (void) mapRootItemIntoLayoutContext
{
	NSParameterAssert(nil != _layoutContext);

	if ([self rootItem] == nil)
		return;

	ETLayoutItemGroup *layoutContext = (ETLayoutItemGroup *)[self layoutContext];

	/* We don't insert the root item in the layout context, because we don't 
	   want to make it visible in the semantic tree. Yet to support -display 
	   in the root item tree, we set the layout context as its parent, hence 
	   redisplay requests can flow back to the closest ancestor view in the 
	   main layout item tree. */
	if ([layoutContext isLayoutItem])
	{
		[[self rootItem] setParentItem: layoutContext];
	}
	else /* For layout composition, when the layout context is a layout */
	{
		[[self rootItem] setParentItem: [layoutContext rootItem]];
	}

	[self syncRootItemGeometryWithSize: [layoutContext visibleContentSize]];
}

- (void) unmapRootItemFromLayoutContext
{
	[[self rootItem] setParentItem: nil];
}

/* Wrapping Existing View */

- (void) setLayoutView: (NSView *)protoView
{
	// FIXME: Horrible hack to work around the fact Gorm doesn't support 
	// connecting an outlet to the content view of a window. Hence we connect 
	// _displayViewPrototype to the window embedding the view and retrieve the 
	// layout view when this method is called during the nib awaking.
	// This hack isn't used anymore, so it could probably be removed...
	if ([protoView isKindOfClass: [NSWindow class]])
	{
		ETLog(@"NOTE: -setLayoutView: received a window as parameter");
		ASSIGN(_displayViewPrototype, [(NSWindow *)protoView contentView]);
	}
	else
	{
		ASSIGN(_displayViewPrototype, protoView);
	}

	[_displayViewPrototype removeFromSuperview];
}

- (NSView *) layoutView
{
	return _displayViewPrototype;
}

/** Returns YES if the layout view is presently visible in the layout item tree 
of the layout context, otherwise returns NO.

A layout view can be inserted in a superview bound to a parent item and 
yet not be visible.<br />
For example, if an ancestor item of the parent uses an opaque layout, the layout 
view can be inserted in the parent view but the parent view (or another ancestor 
superview which owns it) might not be inserted as a subview in the visible view 
hierarchy of the layout item tree. */
- (BOOL) isLayoutViewInUse
{
	// NOTE: A visible view hierarchy is always rooted in a window, itself bound 
	// to the layout item representing the content view.
	return ([[self layoutView] window] == nil);
}

/** <override-dummy />
You should call this method in -renderWithLayoutItems:isNewContent: if you 
write a view-based layout subclass.

This method may be overriden by subclasses to handle view-specific configuration 
before the view gets injected in the layout context. You must then call the 
superclass method to let the layout view be inserted in the layout context 
supervisor view. */
- (void) setUpLayoutView
{
	NSParameterAssert(nil != _layoutContext);

	id layoutView = [self layoutView];

	if (nil == layoutView || [layoutView superview] != nil)
		return;

	[layoutView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[_layoutContext setLayoutView: layoutView];
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

You usually override this method if you need to reflect the selected items 
in the layout context on the custom UI encapsulated by the receiver (usually 
a widget layout or a less specialized opaque layout).<br />

This method is called on a regular basis each time the layout context selection 
is modified and needs to be mirrored in the receiver (e.g. in a widget view). */
- (void) selectionDidChangeInLayoutContext
{

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
	[[self layoutView] setNeedsDisplayInRect: [self displayRectOfItem: anItem]];
}

/* Item Property Display */

/** <override-dummy />
Returns the laid out item properties that should be visible in the layout.

Overrides this method in your subclasses to return which properties are 
presented by the layout.<br />
You can choose to make the ordering in the property array reflects the order 
in which properties are presented by the layout.

By default, returns an empty array.

NOTE: In future, the overriding might become mandatory in every subclass. */
- (NSArray *) displayedProperties
{
	return [NSArray array];
}

/** <override-dummy /> 
Sets the laid out item properties that should be visible in the layout.

Overrides this method in your subclasses to adjust which properties are 
presented by the layout.<br />
You can choose to make the order in which properties are presented by the 
layout reflect the ordering in the property array.

If you override this method, you must override -displayedProperties too. */
- (void) setDisplayedProperties: (NSArray *)properties
{
	
}

/** <override-dummy /> 
Returns an arbitrary style object used to draw the given property in the layout. 

The returned style object type is determined by each subclass. Usually the 
style will simply be an ETLayoutItem or ETStyle instance.

Overrides in your subclass to return a style object per property and documents 
the class or type of the returned object. Several properties can share the 
same style object. */
- (id) styleForProperty: (NSString *)property
{
	return nil;
}

/** <override-dummy /> 
Sets a style object to should be used to present the given property in the 
layout. 

The accepted style object type is determined by each subclass. Usually the 
style will simply be an ETLayoutItem or ETStyle instance.<br />
Subclasses must raise an exception when the style object type doesn't match 
their expectation or cannot be used in conjunction with the given property.

Overrides in your subclass to adjust the style per property and documents the 
class or type of the accepted object. Suclasses can use the given style directly 
or interpret/convert it. e.g. ETTableLayout converts ETLayoutItem into NSCell 
(internal representation only relevant to the AppKit widget backend).

If you override this method, you must override -styleForProperty: too. */
- (void) setStyle: (id)style forProperty: (NSString *)property
{

}

/* Pick & Drop */

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
