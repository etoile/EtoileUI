/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import <EtoileFoundation/NSIndexSet+Etoile.h>
#import <EtoileFoundation/NSObject+Trait.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/Macros.h>
#import <CoreObject/COPrimitiveCollection.h>
#import "ETLayoutItemGroup.h"
#import "ETBasicItemStyle.h"
#import "ETController.h"
#import "ETFixedLayout.h"
#import "ETLayoutItemGroup+Mutation.h"
#import "ETLayoutItem+Private.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETLayoutExecutor.h"
#import "EtoileUIProperties.h"
#import "ETTool.h"
#import "ETView.h"
// FIXME: Add -concat to the Appkit graphics backend
#import "ETWidgetBackend.h"
#import "NSView+EtoileUI.h"
#import "ETCompatibility.h"

#pragma GCC diagnostic ignored "-Wprotocol"

/* Notifications */
NSString * const ETItemGroupSelectionDidChangeNotification = @"ETItemGroupSelectionDidChangeNotification";
NSString * const ETSourceDidUpdateNotification = @"ETSourceDidUpdateNotification";

@interface ETLayoutItem (SubclassVisibility)
- (ETView *) setUpSupervisorView;
- (Class)viewpointClassForProperty: (NSString *)aProperty ofObject: (id)anObject;
@end

@interface  ETController (Private)
- (void) setContent: (ETLayoutItemGroup *)aContent;
@end


@implementation ETLayoutItemGroup

+ (void) initialize
{
	if (self != [ETLayoutItemGroup class])
		return;

	[self applyTraitFromClass: [ETCollectionTrait class]];
	[self applyTraitFromClass: [ETMutableCollectionTrait class]];
}

/* Initialization */

- (id) initWithView: (NSView *)view
         coverStyle: (ETStyle *)aStyle
      actionHandler: (ETActionHandler *)aHandler
 objectGraphContext: (COObjectGraphContext *)aContext
{
    self = [super initWithView: view coverStyle: aStyle actionHandler: aHandler objectGraphContext: aContext];
	if (nil == self)
		return nil;

	_items = [[COUnsafeRetainedMutableArray alloc] init];
	_sortedItems = nil;
	_arrangedItems = nil;

	[self setLayout: [ETFixedLayout layoutWithObjectGraphContext: aContext]];
	//_hasNewLayout = NO;
	_hasNewContent = NO; /* Private accessors in ETMutationHandler category */
	_hasNewArrangement = NO;
	[self setValue: [NSNumber numberWithFloat: 1.0] forVariableStorageKey: kETItemScaleFactorProperty];

	_shouldMutateRepresentedObject = YES;

    return self;
}

/** Initializes and returns a layer item to be encaspulated in a layout.

You should never need to use this method.

See also -isLayerItem. */
- (id) initAsLayerItemWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	_isLayerItem = YES;
	self = [self initWithView: nil coverStyle: nil actionHandler: nil objectGraphContext: aContext];
	[[self layout] setAutoresizesItems: NO];
	return self;
}

- (void)willDiscard
{
	if ([_items isEmpty] == NO && [[ETLayoutExecutor sharedInstance] isEmpty] == NO)
	{
		NSSet *itemSet = [[NSSet alloc] initWithArray: _items];
		[(ETLayoutExecutor *)[ETLayoutExecutor sharedInstance] removeItems: itemSet];
	}
	_isDeallocating = YES;

	/* Tear down the receiver as a source and represented object observer */
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	/* Will mark the item as deallocating to prevent adding it to the layout 
	   executor, stop KVO observation on properties before they get deallocated 
	   in -dealloc, and clear cached outgoing relationships such as ETLayoutItemGroup.items. */
	[super willDiscard];
}

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event
{
	return YES;
}

/** Returns YES. An ETLayoutItemGroup is always a group and a collection by
default. */
- (BOOL) isGroup
{
	return YES;
}

/* Traversing Layout Item Tree */

/** Returns the layout item child identified by the index path parameter
interpreted as relative to the receiver.

For an empty path, returns self.<br />
For a nil path, returns nil. */
- (ETLayoutItem *) itemAtIndexPath: (NSIndexPath *)path
{
	if (nil == path)
		return nil;

	int length = [path length];
	ETLayoutItem *item = self;

	for (unsigned int i = 0; i < length; i++)
	{
		if ([item isGroup])
		{
			item = [(ETLayoutItemGroup *)item itemAtIndex: [path indexAtPosition: i]];
		}
		else
		{
			item = nil;
			break;
		}
	}

	return item;
}

/** Returns the first layout item descendant on which the identifier is set.

The descendant items are retrieved with -allDescendantItems, this results in
a pre-order traversal.<br />
Use this method cautiously when the item tree is big (e.g. more than 10 000 items).

See also -identifier. */
- (ETLayoutItem *) itemForIdentifier: (NSString *)anId
{
	if ([[self identifier] isEqual: anId])
	{
		return self;
	}
	return [[[self allDescendantItems] filteredArrayUsingPredicate:
		[NSPredicate predicateWithFormat: @"identifier == %@", anId]] firstObject];
}

/** Returns an indented tree description by traversing the tree with
-arrangedItems to get the children if usesArrangedItems is YES, otherwise with
-items.

When aProperty is a valid property name, each item description includes the
value bound to this property.

See also -[NSObject descriptionWithOptions:]. */
- (NSString *) descriptionWithProperty: (NSString *)aProperty arranged: (BOOL)usesArrangedItems
{
	NSString *childKey = (usesArrangedItems ? @"arrangedItems" : @"items");
	return [self descriptionWithOptions: [NSMutableDictionary dictionaryWithObjectsAndKeys:
		A(aProperty), kETDescriptionOptionValuesForKeyPaths, childKey, kETDescriptionOptionTraversalKey, nil]];
}

/* Manipulating Layout Item Tree */

/** Inserts the display view of the given item into the receiver view.

This method is used by -setExposedItems: to manage view insertion.
 
See also -handleDetachViewOfItem: and -[ETUItem displayView]. */
- (void) handleAttachViewOfItem: (ETLayoutItem *)item
{
	// TODO: For now, item group mutation calls this method and causes item
	// views to be attached immediately... In the future, we could skip calling
	// -handleAttachViewOfItem: at mutation time and just wait the layout update
	// to insert it (since all layouts call -setExposedItems:). Not yet sure though...
	ETView *itemDisplayView = [item displayView];
	BOOL noViewToAttach = (itemDisplayView == nil);

	// NOTE: -[NSView addSuview: nil] results in an exception.
	if (noViewToAttach)
		return;

	BOOL isAlreadyAttached = [[itemDisplayView superview] isEqual: [[self parentItem] supervisorView]];

	/* We don't want to change the subview ordering when we simply switch
	   the visibility */
	if (isAlreadyAttached)
		return;

	[itemDisplayView removeFromSuperview];

	/* Only insert the item view if the layout is a fixed/free layout.
	   TODO: Probably make more explicit the nil layout check. */
	if ([[self layout] isOpaque] == NO)
	{
		[[self setUpSupervisorView] addSubview: itemDisplayView];
	}
}

/** Removes the display view of the given view from the receiver view.

This method is used by -setExposedItems: to manage view removal.
 
See also -handleAttachViewOfItem: and -[ETUIItem displayView]. */
- (void) handleDetachViewOfItem: (ETLayoutItem *)item
{
	if ([item displayView] == nil) /* No view to detach */
		return;

	[[item displayView] removeFromSuperview];
}

- (void) attachItem: (ETLayoutItem *)item
{
	if ([item parentItem] != nil)
	{
		[[item parentItem] removeItem: item];
	}
	[self handleAttachViewOfItem: item];
}

/** <override-dummy />Adjusts the item tree once the item has become a child of 
the receiver. This method is available to be overriden in subclasses that want 
to extend or modify the item insertion behavior.

The default implementation does nothing.

Symetric method to -didDetachItem: */
- (void) didAttachItem:(ETLayoutItem *)item
{

}

- (void) detachItem: (ETLayoutItem *)item
{
	[self handleDetachViewOfItem: item];
}

/** <override-dummy />Adjusts the item tree once the item has been removed from 
the receiver. This method is available to be overriden in subclasses that want 
to extend or modify the item removal behavior.

The default implementation does nothing.

Symetric method to -attachItem: */
- (void) didDetachItem: (ETLayoutItem *)item
{

}

- (BOOL) isCollectionViewpoint: (id)anObject
{
	return ([anObject isCollection]
		&& [anObject conformsToProtocol: @protocol(ETPropertyViewpoint)]);
}

- (Class) viewpointClassForProperty: (NSString *)aKey ofObject: (id)anObject
{
	if ([[anObject valueForKey: aKey] isCollection])
	{
		return [ETCollectionViewpoint class];
	}
	return [super viewpointClassForProperty: aKey ofObject: anObject];
}

/** See -[ETLayoutItemGroup setRepresentedObject:].

If necessary, marks the receiver as having new content to be layouted, otherwise
the layout is told the layout item tree hasn't been mutated. Although this only
holds when the layout item tree is built directly from the represented object by
the mean of ETCollection protocol. */
- (void) setRepresentedObject: (id)model
{
	[[NSNotificationCenter defaultCenter] removeObserver: self
	                                                name: ETCollectionDidUpdateNotification
	                                              object: [self representedObject]];

	[super setRepresentedObject: model];

	if (model != nil)
	{
		[[NSNotificationCenter defaultCenter] addObserver: self
		                                         selector: @selector(representedObjectCollectionDidUpdate:)
		                                             name: ETCollectionDidUpdateNotification
		                                           object: model];
	}
	if ([self usesRepresentedObjectAsProvider])
	{
		[self setHasNewContent: YES];
	}
}

/** Returns YES when the item tree mutation are propagated to the represented
object, otherwise returns NO if it's up to you to reflect structural changes of
the layout item tree onto the model object graph. By default, this method
returns YES.

Mutations are triggered by calling children or collection related methods
like -addItem:, -insertItem:atIndex:, removeItem:, addObject: etc.

<strong>The returned value is meaningful only if the receiver is a base item.
In this case, the value applies to all related descendant items (by being
looked up by descendant items).</strong> */
- (BOOL) shouldMutateRepresentedObject
{
	return _shouldMutateRepresentedObject;
}

/** Sets whether the layout item tree mutation are propagated to the represented
object or not.

<strong>The value set is meaningful only if the receiver is a base item,
otherwise the value is simply ignored.</strong>  */
- (void) setShouldMutateRepresentedObject: (BOOL)flag
{
	_shouldMutateRepresentedObject = flag;
}

/** Returns YES when the child items are automatically generated by wrapping the
elements of the represented object collection into ETLayoutItem or
ETLayoutItemGroup instances.

To use represented objects as providers in the layout item tree connected to
the receiver, you have to set the source of the receiver to be the receiver
itself. The code would be something like <example>
[itemGroupsetSource: itemGroup]</example>. */
- (BOOL) usesRepresentedObjectAsProvider
{
	return ([[[self sourceItem] source] isEqual: [self sourceItem]]);
}

/** Returns the source which provides the content presented by the receiver.

A source implements either ETIndexSource or ETPathSource protocols. If the
receiver handles the layout item tree directly without the help of a source
object, then this method returns nil. */
- (id) source
{
	return [self valueForVariableStorageKey: kETSourceProperty];
}

/** Sets the source which provides the content displayed by the receiver. A
source can be any objects conforming to ETIndexSource or ETPathSource protocol.

So you can write you own data source object by implementing either:
<enum>
<item><list>
<item>-numberOfItemsInItemGroup:</item>
<item>-itemGroup:itemAtIndex:</item>
</list></item>
<item><list>
<item>-itemGroup:numberOfItemsAtPath:</item>
<item>-itemGroup:itemAtPath:</item>
</list></item>
</enum>

Another common solution is to use the receiver itself as a source, in that
case -usesRepresentedObjectAsProvider returns YES. And the receiver will
generate the layout item tree bound to it by retrieving any child objects of the
represented object (through ETCollection protocol) and wrapping them into
ETLayoutItem or ETLayoutItemGroup objects based on whether these childs
implements ETCollection or not.

You can also combine these abilities with an off-the-shelf controller object like
ETController. See -setController to do so. This brings extra flexibility such as:
<list>
<item>template item and item group for the generated layout items</item>
<item>easy to use add, insert and remove actions with template model object and
model group for the represented objects to insert wrapped in layout items</item>
<item>sorting</item>
<item>searching</item>
</list>

Finally when -source returns nil, it's always possible to build and manage a
layout item tree structure in a static fashion by yourself.

When the new source is set, the content is immediately reloaded, and the layout
updated unless the autolayout is disabled. Finally an
ETSourceDidUpdateNotification is posted.

By setting a source, the receiver represented path base is automatically set to
'/' unless another path was set previously. If you pass nil to get rid of a
source, the represented path base isn't reset to nil but keeps its actual value
in order to maintain it as a base item and avoid unpredictable changes to the
event handling logic.

Marks the receiver as needing a layout update. */
- (void) setSource: (id)source
{
	/* By safety, avoids to trigger extra updates */
	if ([self valueForVariableStorageKey: kETSourceProperty] == source)
		return;

	[[NSNotificationCenter defaultCenter]
		removeObserver: self
		          name: ETSourceDidUpdateNotification
			    object: [self valueForVariableStorageKey: kETSourceProperty]];

	[self setValue: source forVariableStorageKey: kETSourceProperty];

	[self tryReloadWithSource: source]; /* Resets any particular state like selection */
	[self setNeedsLayoutUpdate];
	if (source != nil && source != self)
	{
		[[NSNotificationCenter defaultCenter]
			addObserver: self
		       selector: @selector(sourceDidUpdate:)
			       name: ETSourceDidUpdateNotification
		         object: source];
	}
}

- (ETLayoutItemGroup *) sourceItem
{
	return ([self source] != nil ? (ETLayoutItemGroup *)self : [[self parentItem] sourceItem]);
}

/** Returns the delegate associated with the receiver.

See also -setDelegate:. */
- (COObject *) delegate
{
	return [self valueForVariableStorageKey: kETDelegateProperty];
}

/** Sets the delegate associated with the receiver.

A delegate is only useful if the receiver is a base item, otherwise it will
be ignored.

The delegate is retained, unlike what Cocoa/GNUstep usually do.<br />
The delegate is owned by the item and treated as a pluggable aspect to be
released when the item is deallocated.  */
- (void) setDelegate: (COObject *)delegate
{
	[self setValue: delegate forVariableStorageKey: kETDelegateProperty];
}

/** Returns the controller which allows to customize the overall UI interaction
with the receiver item tree.

When the controller is not nil, the receiver is both a base item and the
controller content. */
- (ETController *) controller
{
	return [self valueForVariableStorageKey: kETControllerProperty];
}

/** Sets the controller which allows to customize the overall UI interaction
with the receiver item tree.

When the given controller is not nil, it is inserted as the next responder and
the receiver becomes both a base item and the controller content.

See also -setSource:, -controllerItem and -nextResponder. */
- (void) setController: (ETController *)aController
{
	[self willChangeValueForProperty: kETControllerProperty];

	ETController *newController = aController;
	ETLayoutItemGroup *newControllerOldContent = [newController content];
	ETController *oldController = [self valueForVariableStorageKey: kETControllerProperty];

	[self setValue: newController forVariableStorageKey: kETControllerProperty];

	[oldController didChangeContent: self toContent: nil];
	[newController didChangeContent: newControllerOldContent toContent: self];

	[self didChangeValueForProperty: kETControllerProperty];
}

- (ETLayoutItemGroup *) controllerItem
{
	return ([self controller] != nil ? self : [[self parentItem] controllerItem]);
}

/** Adds the given item to the receiver children. */
- (void) addItem: (ETLayoutItem *)item
{
	//ETDebugLog(@"Add item in %@", self);
	[self handleInsertItem: item atIndex: ETUndeterminedIndex hint: nil moreComing: NO];
}

/** Inserts the given item in the receiver children at a precise index. */
- (void) insertItem: (ETLayoutItem *)item atIndex: (NSUInteger)index
{
	//ETDebuLog(@"Insert item in %@", self);
	[self handleInsertItem: item atIndex: index hint: nil moreComing: NO];
}

/** Removes the given item from the receiver children. */
- (void) removeItem: (ETLayoutItem *)item
{
	//ETDebugLog(@"Remove item in %@", self);
	[self handleRemoveItem: item atIndex: ETUndeterminedIndex hint: nil moreComing: NO];
}

/** Removes the child item at the given index in the receiver children. */
- (void) removeItemAtIndex: (NSUInteger)index
{
	ETLayoutItem *item = [_items objectAtIndex: index];
	[self handleRemoveItem: item atIndex: index hint: nil moreComing: NO];
}

/** Returns the child item at the given index in the receiver children. */
- (ETLayoutItem *) itemAtIndex: (NSInteger)index
{
	return [_items objectAtIndex: index];
}

/** Returns the first receiver child item.

Shortcut method equivalent to [self itemAtIndex: 0].

Similar to -firstObject method for collections (see ETCollection).*/
- (ETLayoutItem *) firstItem
{
	return [_items firstObject];
}

/** Returns the last receiver child item.

Shortcut method equivalent to [self itemAtIndex: [self numberOfItems] - 1].

Similar to -lastObject method for collections (see ETCollection).*/
- (ETLayoutItem *) lastItem
{
	return [_items lastObject];
}

/** Adds the given the items to the receiver children. */
- (void) addItems: (NSArray *)items
{
	//ETDebugLog(@"Add items in %@", self);
	[self handleAddItems: items];
}

/** Removes the given child items from the receiver children. */
- (void) removeItems: (NSArray *)items
{
	//ETDebugLog(@"Remove items in %@", self);
	[self handleRemoveItems: items];
}

/** Removes all the receiver child items. */
- (void) removeAllItems
{
	//ETDebugLog(@"Remove all items in %@", self);
	// FIXME: Temporary solution which is quite slow
	[self handleRemoveItems: [self items]];
}

// FIXME: (id) parameter rather than (ETLayoutItem *) turns off compiler
// conflicts with menu item protocol which also implements this method.
// Fix compiler.

/** Returns the index of the given child item in the receiver children. */
- (NSInteger) indexOfItem: (id)item
{
	return [_items indexOfObject: item];
}

/** Returns whether the given item is a receiver child or not. */
- (BOOL) containsItem: (ETLayoutItem *)item
{
	return ([self indexOfItem: (id)item] != NSNotFound);
}

/** Returns how many child items the receiver includes. */
- (NSInteger) numberOfItems
{
	return [_items count];
}

/** Returns an autoreleased array which contains the receiver child items. */
- (NSArray *) items
{
	return [NSArray arrayWithArray: _items];
}

/** Returns all descendant items of the receiver, including immediate children.

This method collects every item in the layout item subtree (excluding the
receiver) by doing a preorder traversal, the resulting collection is a flat list
of every item in the tree.

If you are interested in collecting descendant items in another traversal order,
you have to implement your own version of this method. */
- (NSArray *) allDescendantItems
{
	// TODO: This code is probably quite slow by being written in a recursive
	// style and allocating/resizing many arrays instead of using a single
	// linked list. Test whether optimization are needed or not really ...
	NSMutableArray *collectedItems = [NSMutableArray array];

	FOREACHI([self items], item)
	{
		[collectedItems addObject: item];

		if ([item isGroup])
			[collectedItems addObjectsFromArray: [item allDescendantItems]];
	}

	return collectedItems;
}

/** Returns whether the item is a receiver descendant item.

This method is a lot more efficient than using -allDescendantItems e.g.
<code>[[self allDescendantItems] containsItem: anItem]</code>. */
- (BOOL) isDescendantItem: (ETLayoutItem *)anItem
{
	if (nil == anItem)
		return NO;

	if ([self isEqual: [anItem parentItem]])
	{
		return YES;
	}
	else
	{
		return [self isDescendantItem: [anItem parentItem]];
	}
}

/** Returns whether the receiver can be reloaded presently with -reload. */
- (BOOL) canReload
{
	BOOL hasSource = ([[self sourceItem] source] != nil);

	return (hasSource && [self isReloading] == NO && [self isMutating] == NO);
}

/** Tries to reload the content of the receiver, but only if it can be reloaded.

Won't reload when the receiver is currently sorted and/or filtered. See
-isSorted and -isFiltered.

This method can be safely called even if the receiver has no source or doesn't
inherit a source from a base item.

Marks the receiver as needing a layout update, if a reload occurs.

See also -reload. */
- (void) reloadIfNeeded
{
	if ([self canReload] && [self isSorted] == NO && [self isFiltered] == NO)
		[self reload];
}

/* Forces the reload whether or not the given source is nil.

When the source is nil, the receiver becomes empty. */
- (void) tryReloadWithSource: (id)aSource
{
	NSParameterAssert([self isReloading] == NO);

	ETDebugLog(@"Try reload %@", self);

	_reloading = YES;

	[self removeAllItems];
	if (nil != aSource)
	{
		[self addItems: [self itemsFromSource]];
	}

	_reloading = NO;
}

/** Reloads the content by removing all existing childrens and requesting all
the receiver immediate children to the base item source.

Will cancel any any sorting and/or filtering currently done on the receiver.
Which means -isFiltered and -isSorted will both return NO.

Marks the receiver as needing a layout update. */
- (void) reload
{
	BOOL hasSource = ([[self sourceItem] source] != nil);

	if (hasSource)
	{
		[self tryReloadWithSource: [[self sourceItem] source]];
	}
	else
	{
		ETLog(@"WARNING: Impossible to reload %@ because the base item miss "
			@"a source %@", self, [[self sourceItem] source]);
	}
}

/* Layout */

- (BOOL) hasNewLayout { return _hasNewLayout; }

- (void) setHasNewLayout: (BOOL)flag { _hasNewLayout = flag; }

/** <override-never />
Tells the receiver the layout has been changed and it should post 
ETLayoutItemLayoutDidChangeNotification. 

This method tries to notify the delegate that might exist with subclasses 
e.g. ETLayoutItemGroup.

You should never use this method unless you write an ETLayoutItem subclass. */
- (void) didChangeLayout: (ETLayout *)oldLayout
{
	[[self layout] syncLayoutViewWithItem: self];
	[self updateScrollableAreaItemVisibility];

	/* We must not let the tool attached to the old layout remain active, 
	   otherwise the layout can be deallocated and this tool remains with an 
	   invalid -layoutOwner. */
	ETTool *oldTool = [oldLayout attachedTool];

	if ([oldTool isEqual: [ETTool activeTool]])
	{
		ETTool *newTool = [[self layout] attachedTool];

		if (newTool == nil)
		{
			newTool = [ETTool mainTool];
		}
		[ETTool setActiveTool: newTool];
		
		ETAssert(newTool == [ETTool mainTool] || [newTool layoutOwner] == [self layout]);
	}
	ETAssert(oldTool == nil || [oldTool layoutOwner] != [self layout]);

	/* Notify the interested parties about the layout change */
	NSNotification *notif = [NSNotification 
		notificationWithName: ETLayoutItemLayoutDidChangeNotification object: self];
	id delegate = [self valueForKey: kETDelegateProperty];

	if ([delegate respondsToSelector: @selector(layoutDidChange:)])
		[delegate layoutDidChange: notif];
	
	[[NSNotificationCenter defaultCenter] postNotification: notif];
}

/** Returns the layout associated with the receiver to present its content. */
- (id) layout
{
	return _layout;
}

/** Sets the layout associated with the receiver to present its content. */
- (void) setLayout: (ETLayout *)layout
{
	if (_layout == layout)
		return;

	//ETDebugLog(@"Modify layout from %@ to %@ in %@", _layout, layout, self);

	ETLayout *oldLayout = _layout;
	
	/* Must precede -willChangeValueForProperty: which resets the context to nil */
	[_layout tearDown];

	[self willChangeValueForProperty: kETLayoutProperty];

    _layout = layout;
    /* We must remove the item views, otherwise they might remain visible as
       subviews (think ETBrowserLayout on GNUstep which has transparent areas),
       because view-based layout won't call -setExposedItems: in -renderWithItems:XXX:. */
    [self setExposedItems: [NSArray array]];
    [self setHasNewLayout: YES];
    // TODO: May be safer to restore the default frame here rather than relying
    // on the next layout update and -resizeItems:toScaleFactor:...
    //[[self items] makeObjectsPerformSelector: @selector(restoreDefaultFrame)];

    /* Will update ETLayout.layoutContext inverse relationship */
	[self didChangeValueForProperty: kETLayoutProperty];

    // NOTE: The remaining code requires ETLayout.layoutContext to be set, so we
    // execute it last
	[_layout setUp: NO];
    [self didChangeLayout: oldLayout];
    [self setNeedsLayoutUpdate];
}

/** Attempts to reload the children items from the source and updates the layout
by asking the first ancestor item with an opaque layout to do so. */
- (void) reloadAndUpdateLayout
{
	[self reload];
	[[self ancestorItemForOpaqueLayout] updateLayout];
}

/** Updates recursively each layout in the item tree owned by the receiver.

Will force the layout to be recomputed to take in account geometry and content
related changes since the last layout update.
 
See -updateLayoutRecursively:. */
- (void) updateLayout
{
	[self updateLayoutRecursively: YES];
}

/** Updates each layout in the immediate children (recursively is NO) or in the
whole item subtree (recursively is YES) owned by the receiver.

When recursively is YES, does a bottom-up layout update, by propagating it first
downwards.<br />
Layout updates start on the terminal descendant items, then are carried upwards
through the tree structure back to the receiver, whose layout is the last
updated.<br />
A bottom-up update is used because a parent layout computation might depend on
child item properties. For example, an item can use a layout which touches its
frame (see -usesFlexibleLayoutFrame). */
- (void) updateLayoutRecursively: (BOOL)recursively
{
	if ([self layout] == nil)
		return;
	
	ETDebugLog(@"Try update layout of %@", self);

	ETAssert([self canUpdateLayout]);
	BOOL isNewLayoutContent = ([self hasNewContent] || [self hasNewLayout]
		|| _hasNewArrangement);

	[ETLayoutItem disablesAutolayout];
	[(ETLayout *)[self layout] render: isNewLayoutContent];
	[ETLayoutItem enablesAutolayout];
	
	BOOL needsSecondPass = [[self layout] isLayoutExecutionItemDependent];

	if (recursively)
	{
		for (ETLayoutItem *item in [self items])
		{
			[item updateLayoutRecursively: YES];
			needsSecondPass |= ([[[item layout] positionalLayout] isContentSizeLayout] && [item isScrollable] == NO);
		}
	}
	
	if (needsSecondPass)
	{
		[ETLayoutItem disablesAutolayout];
		[(ETLayout *)[self layout] render: isNewLayoutContent];
		[ETLayoutItem enablesAutolayout];
	}
	
	[self setNeedsDisplay: YES];
	[self setHasNewContent: NO];
	_hasNewArrangement = NO;
	[self setHasNewLayout: NO];
	[[ETLayoutExecutor sharedInstance] removeItem: (id)self];
}

/* Returns whether -updateLayout can be safely called now. */
- (BOOL) canUpdateLayout
{
	return ([self isReloading] == NO && [[self layout] isRendering] == NO);
}

/** Updates the layouts, previously marked with -setNeedsLayoutUpdate, in the 
entire item tree.

The update won't be limited to the item subtree. */
- (void) updateLayoutIfNeeded
{
	[[ETLayoutExecutor sharedInstance] execute];
}

/** Returns whether the layout is going to be updated in the interval between 
the current and the  next event. */
- (BOOL) needsLayoutUpdate
{
	return [[ETLayoutExecutor sharedInstance] containsItem: self];
}

/** Marks the receiver to have its layout updated and be redisplayed in the 
interval between the current and the next event.

See also +disablesAutolayout. */
- (void) setNeedsLayoutUpdate
{
	if ([ETLayoutItem isAutolayoutEnabled] == NO || _isDeallocating)
		return;

	[[ETLayoutExecutor sharedInstance] addItem: self];
	[self setNeedsDisplay: YES];
}

/* Item scaling */

/** Returns the scale factor applied to each item when the layout supports it.

See also -setItemScaleFactor:. */
- (CGFloat) itemScaleFactor
{
	return [[self valueForVariableStorageKey: kETItemScaleFactorProperty] floatValue];
}

/** Sets the scale factor applied to each item when the layout supports it.

This scale factor only applies to the immediate children.

Updates the layout immediately unlike most methods.

See -[ETLayout setItemSizeConstraintStyle:] and -[ETLayout setConstrainedItemSize:]
to control more precisely how the items get resized per layout. */
- (void) setItemScaleFactor: (CGFloat)aFactor
{
	[self setValue: [NSNumber numberWithFloat: aFactor] forVariableStorageKey: kETItemScaleFactorProperty];
	/* Don't use -setNeedsUpdateLayout, because this method is usually triggered
	   by widget actions, and continuous widgets (such as NSSlider) don't run 
	   the run loop while emitting actions continuously. This would delay the 
	   scaling visibility until the user stops to manipulate the slider. 
	   In the future, -[ETLayoutExecutor execute] could be called by
	   -[ETApp sendAction:from:to:] to support using -setNeedsUpdateLayout here. */
	[self updateLayoutRecursively: NO];
}

/* Rendering */

/* For debugging */
- (void) drawDirtyRectItemMarkerWithRect: (NSRect)dirtyRect
{
	[[[NSColor purpleColor] colorWithAlphaComponent: 0.2] setFill];
	[NSBezierPath fillRect: dirtyRect];
}

/** See -[ETLayoutItem render:dirtyRect:inContext:]. The most important addition of
this method is to manage the drawing of children items by calling this method
recursively on them.
 
The supervisor view or parent item intersects the dirty rect against the 
receiver drawing box just before calling -render:dirtyRect:inContext:. Which 
means the dirty rect needs no adjustments. */
- (void) render: (NSMutableDictionary *)inputValues
      dirtyRect: (NSRect)dirtyRect
      inContext: (id)ctxt
{
	//ETLog(@"Render %@ dirtyRect %@ in %@", self, NSStringFromRect(dirtyRect), ctxt);

	/* Using the drawing box, we limit the redrawn area to the cover style area 
	   or the content bounds in case a decorator is set (we don't want to draw 
	   over the decorators). */
	NSRect drawingBox = [self drawingBox];

	/* Use the display cache when there is one */
	if (nil != _cachedDisplayImage)
	{
		ETBasicItemStyle *basicItemStyle =
			[ETBasicItemStyle sharedInstanceForObjectGraphContext: [self objectGraphContext]];
		
		[basicItemStyle drawImage: _cachedDisplayImage
		                  flipped: [self isFlipped]
		                   inRect: drawingBox];
		return;
	}

	/* Otherwise redisplay the receiver and its descendants recursively */
	if ([self usesFlexibleLayoutFrame] || NSIntersectsRect(dirtyRect, drawingBox))
	{
		/* There is no need to set dirtyRect with -[NSBezierPath setClip]
		   because the right clip rect should have been set by our supervisor
		   view or our parent item (when when we have no decorator) */
		[super render: inputValues dirtyRect: dirtyRect inContext: ctxt];

		/* Render child items (if the layout doesn't handle it) */

		[NSGraphicsContext saveGraphicsState];
		if ([[self layout] isOpaque] == NO)
		{
			NSEnumerator *e = [[self arrangedItems] reverseObjectEnumerator];

			FOREACHE(nil, item, ETLayoutItem *, e)
			{
				if ([item isVisible] == NO)
					continue;

				/* We intersect our dirtyRect with the drawing frame of the item to be
				   drawn, so the child items don't receive the drawing frame of their
				   parent, but their own. Also restricts the dirtyRect so it doesn't
				   encompass any decorators set on the item. */
				NSRect childDirtyRect = [item convertRectFromParent: dirtyRect];
				childDirtyRect = NSIntersectionRect(childDirtyRect, [item drawingBox]);

				/* In case, dirtyRect is only a redraw rect on the parent and not on
				   the entire parent frame, we try to optimize by not redrawing the
				   items that lies outside of the dirtyRect. */
				if (NSEqualRects(childDirtyRect, NSZeroRect))
					continue;

				[self display: inputValues
						 item: item
					dirtyRect: childDirtyRect
					inContext: ctxt];
			}
		}
		[NSGraphicsContext restoreGraphicsState]; /* Restore the receiver clipping rect */

		/* Render the layout-specific tree if needed */

		[self display: inputValues
		         item: [[self layout] layerItem]
		    dirtyRect: dirtyRect
		    inContext: ctxt];
	}
}

/** Displays the given item by adjusting the graphic context for the drawing,
then calling -render:dirtyRect:inContext: on it, and finally restoring the
graphic context.

Take note this method doesn't save and restore the graphics state.

newDirtyRect is expressed in the given item coordinate space.

You should never need to call this method directly. */
- (void) display: (NSMutableDictionary *)inputValues
            item: (ETLayoutItem *)item
       dirtyRect: (NSRect)newDirtyRect
       inContext: (id)ctxt
{
	 /* When the item has a view, it waits to be asked to draw directly by its
	    view before rendering anything.
		To explain it in a more detailed but complex way... If a parent item
		indirectly requests to draw the item by asking us to redraw, we decline
		and wait the control return to the view who initiated the drawing and
		this view asks the item view to draw itself as a subview.
		Hence we only draw child items with no display view (no supervisor view
		as a byproduct).

		FIXME: Verifying the item has no supervisor view isn't enough, because it
		may be enclosed in a view owned by a decorator. In such case, this view
		will be asked to draw by the view hierarchy and overwrite the item
		drawing since it occurs below it (in a superview).

		See also INTERLEAVED_DRAWING in ETView. */

	// NOTE: On GNUstep unlike Cocoa, a nil item  will alter the coordinates
	// when concat/invert is executed. For example, in -render:dirtyRect:inContext:
	// a nil item can be returned by -[ETLayout layerItem].
	BOOL shouldDrawItem = (item != nil && [item displayView] == nil);

	if (shouldDrawItem == NO)
		return;

#ifdef DEBUG_DRAWING
	NSRect itemRect = [item convertRectFromParent: [item frame]];
	[[NSColor yellowColor] set];
	NSFrameRectWithWidth(itemRect, 4.0);
#endif

	NSAffineTransform *transform = [NSAffineTransform transform];

	/* Modify coordinate matrix when the layout item doesn't use a view for
	   drawing. */
	if ([item supervisorView] == nil)
	{
		/* Translate */
		[transform translateXBy: [item x] yBy: [item y]];
	}
	/* Flip if needed */
	if ([self isFlipped] != [item isFlipped]) /* != [NSGraphicContext/renderView isFlipped] */
	{
		[transform translateXBy: 0.0 yBy: [item height]];
		[transform scaleXBy: 1.0 yBy: -1.0];
	}
	[transform concat];

	[[NSBezierPath bezierPathWithRect: newDirtyRect] setClip];
	[item render: inputValues dirtyRect: newDirtyRect inContext: ctxt];
	//[self drawDirtyRectItemMarkerWithRect: newDirtyRect];

	/* Reset the coordinates matrix */
	[transform invert];
	[transform concat];
}

- (void) setCachedDisplayImage: (NSImage *)anImage
{
	_cachedDisplayImage = anImage;

	if (nil != anImage)
	{
		_wasViewHidden = [[[self supervisorView] wrappedView] isHidden];
		[[[self supervisorView] subviews] setValue: [NSNumber numberWithBool: YES]
		                                    forKey: @"hidden"];
		//[[[[self supervisorView] subviews] map] setHidden: YES];
	}
	else
	{
		[[[self supervisorView] subviews] setValue: [NSNumber numberWithBool: NO]
		                                    forKey: @"hidden"];
		//[[[self supervisorView] wrappedView] setHidden: _wasViewHidden];
	}
}

- (NSImage *) cachedDisplayImage
{
	return _cachedDisplayImage;
}


/** Returns the receiver visible child items. */
- (NSArray *) visibleItems
{
	NSMutableArray *visibleItems = [[self exposedItems] mutableCopy];
	[[visibleItems filter] isVisible];
	return visibleItems;
}

/** Returns the receiver laid out child items. */
- (NSArray *) exposedItems
{
	return [self exposedItemsForItems: [self items]];
}

/** Sets the receiver visible laid out items, and mutates the view hierarchy when
some items use a view.
 
Views are inserted or removed to match the item visibility.

This method is invoked by the receiver layout just before 
-[ETLayout renderWithItems:isNewContent:] returns, to adjust the visibility of 
views and update each item 'exposed' property.

You shouldn't need to call this method by yourself. */
- (void) setExposedItems: (NSArray *)exposedItems
{
	return [self setExposedItems: exposedItems forItems: [self items]];
}

/* See -exposedItems. */
- (NSArray *) exposedItemsForItems: (NSArray *)items
{
	NSMutableArray *exposedItems = [NSMutableArray array];

	FOREACH(items, item, ETLayoutItem *)
	{
		if ([item isExposed])
			[exposedItems addObject: item];
	}

	return exposedItems;
}

/* See -setExposedItems:. */
- (void) setExposedItems: (NSArray *)exposedItems forItems: (NSArray *)items
{
	FOREACH(items, item, ETLayoutItem *)
	{
		[item setExposed: [exposedItems containsObject: item]];
	}
}

/* Selection */

/** Returns the index of the first selected item which is an immediate child of
the receiver. If there is none, returns NSNotFound.

Calling this method is equivalent to [[self selectionIndexes] firstIndex].

Take note that -selectionIndexPaths may return one or multiple values when this
method returns NSNotFound. See -selectionIndexes also. */
- (NSUInteger) selectionIndex
{
	return [[self selectionIndexes] firstIndex];
}

/** Sets the selected item identified by index in the receiver and discards any
existing selection index paths previously set.

Posts an ETItemGroupSelectionDidChangeNotification. */
- (void) setSelectionIndex: (NSUInteger)index
{
	ETDebugLog(@"Modify selection index from %d to %d of %@", [self selectionIndex], index, self);

	/* Check new selection validity */
	NSAssert1(index >= 0, @"-setSelectionIndex: parameter must not be a negative value like %lu", (unsigned long)index);

	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];

	if (index != NSNotFound)
		[indexes addIndex: index];

	[self setSelectionIndexes: indexes];
}

/** Returns all indexes matching selected items which are immediate children of
the receiver.

Put in another way, the method returns the first index of all index paths with a
length equal one. */
- (NSMutableIndexSet *) selectionIndexes
{
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];

	FOREACH([self selectionIndexPaths], indexPath, NSIndexPath *)
	{
		if ([indexPath length] == 1)
			[indexes addIndex: [indexPath firstIndex]];
	}

	return indexes;
}

/** Sets the selected items identified by indexes in the receiver and discards
any existing selection index paths previously set.

Posts an ETItemGroupSelectionDidChangeNotification. */
- (void) setSelectionIndexes: (NSIndexSet *)indexes
{
	NSInteger numberOfItems = [[self items] count];
	NSInteger lastSelectionIndex = [[self selectionIndexes] lastIndex];

	ETDebugLog(@"Set selection indexes to %@ in %@", indexes, self);

	if (lastSelectionIndex > (numberOfItems - 1) && lastSelectionIndex != NSNotFound) /* NSNotFound is a big value and not -1 */
	{
		ETLog(@"WARNING: Try to set selection index %ld when %@ only contains %ld items",
			  (long)lastSelectionIndex, self, (long)numberOfItems);
		return;
	}

	/* Update selection */
	[self setSelectionIndexPaths: [indexes indexPaths] recursively: NO];
}

- (void) collectSelectionIndexPaths: (NSMutableArray *)indexPaths
                     relativeToItem: (ETLayoutItemGroup *)pathBaseItem
{
	FOREACHI([self items], item)
	{
		if ([item isSelected])
			[indexPaths addObject: [item indexPathFromItem: pathBaseItem]];

		if ([item isGroup])
			[item collectSelectionIndexPaths: indexPaths relativeToItem: pathBaseItem];
	}
}


/** Returns the index paths of selected items in layout item subtree of the the
receiver. */
- (NSArray *) selectionIndexPaths
{
	NSMutableArray *indexPaths = [NSMutableArray array];

	[self collectSelectionIndexPaths: indexPaths relativeToItem: self];

	return indexPaths;
}

/** Selects every descendant items which match the index paths passed in
parameter and deselects all other descendant items of the receiver.

TODO: This is crude because we deselect everything without taking care of base
items we encounter during the recursive traversal of the subtree... See
-[ETLayout setSelectionIndexPaths:] to understand the issue more thoroughly.
Moreover the method is surely extremly slow if called many times within a short
time interval on a subtree that consists of thousand items or more. */
- (BOOL) applySelectionIndexPaths: (NSMutableArray *)indexPaths
                   relativeToItem: (ETLayoutItemGroup *)baseItem
                      recursively: (BOOL)recursively
{
	BOOL changedSelection = NO;
	BOOL emittedWillChangeSelection = NO;

	FOREACHI([self items], item)
	{
		NSIndexPath *itemIndexPath = [item indexPathFromItem: baseItem];
		BOOL select = [indexPaths containsObject: itemIndexPath];
		
		/* Post notifications on deselection too */
		if (select != [item isSelected] && emittedWillChangeSelection == NO)
		{
			emittedWillChangeSelection = YES;
			// TODO: Perhaps post the same for selectionIndex, selectionIndexes
			// and selectionIndexPaths
			// TODO: Would be better to use -will/DidChangeValueForProperty:
			[self willChangeValueForKey: @"selectedItems"];
			[self willChangeValueForKey: @"selectedItemsInLayout"];
		}

		if (select)
		{
			[item setSelected: YES];
			[indexPaths removeObject: itemIndexPath];
		}
		else
		{
			[item setSelected: NO];
		}
		
		if ([item isGroup] && recursively)
		{
			changedSelection = changedSelection | [item applySelectionIndexPaths: indexPaths
			                                                      relativeToItem: baseItem
			                                                         recursively: recursively];
		}

		if (emittedWillChangeSelection)
		{
			[self didChangeValueForKey: @"selectedItems"];
			[self didChangeValueForKey: @"selectedItemsInLayout"];
			[self didChangeSelection];
			changedSelection = YES;
		}
	}

	return changedSelection;
}

/** Returns YES when a selection change initiated by -setSelectionIndex:,
-setSelectionIndexes: or -setSelectionIndexPaths: is underway,  otherwise
returns NO.

During ETItemGroupSelectionDidChangeNotification and
-[ETLayout didChangeSelectionInLayoutContext] will return YES.

You can use this method in ETLayout subclasses to prevent loops while
synchronizing the selection between a widget and the item tree.<br />
See -[ETWidgetLayout didChangeSelectionInLayoutView].<br />
e.g. Just put a guard clause at the beginning of -didChangeSelectionInLayoutView

<example>
if ([layoutContext isChangingSelection])
	return;
</example> */
- (BOOL) isChangingSelection
{
	return _changingSelection;
}

/* See -[ETLayoutExecutor updateHasNewContentForOpaqueItem:descendantItem:]. */
- (BOOL) hasNewContentForDescendantItem: (ETLayoutItem *)anItem
{
	ETLayoutItemGroup *item = (id)([anItem isGroup] ? anItem : [anItem parentItem]);
	ETLayoutItemGroup *opaqueItem = [self ancestorItemForOpaqueLayout];
	BOOL noOpaqueItem = ([[opaqueItem layout] isOpaque] == NO);

	if (noOpaqueItem)
		return NO;

	while (item != opaqueItem)
	{
		if ([item hasNewContent])
		{
			return YES;
		}
		item = [item parentItem];
	}

	return NO;
}

- (BOOL) hasNewContentForIndexPaths: (NSArray *)indexPaths
{
	if ([self hasNewContent])
		return YES;

	for (NSIndexPath *indexPath in indexPaths)
	{
		ETLayoutItem *item = [self itemAtIndexPath: indexPath];
		
		if ([self hasNewContentForDescendantItem: item])
			return YES;
	}
	return NO;
}

/** Sets the selected items in the item subtree attached to the receiver.

Posts an ETItemGroupSelectionDidChangeNotification for:
 
<list>
<item>each item group whose selection is changed</item>
<item>the controller item</item>
</list>
 
Marks the receiver to be redisplayed.
 
See also -selectionIndexPaths, -setSelectionIndexes:, -setSelectionIndex: and
-controllerItem. */
- (void) setSelectionIndexPaths: (NSArray *)indexPaths
{
	[self setSelectionIndexPaths: indexPaths recursively: YES];
}

- (void) setSelectionIndexPaths: (NSArray *)indexPaths recursively: (BOOL)recursively
{
	_changingSelection = YES;

	BOOL changedSelection =
		[self applySelectionIndexPaths: [NSMutableArray arrayWithArray: indexPaths]
	                    relativeToItem: self
		                   recursively: recursively];

	ETLayoutItemGroup *opaqueItem = [self ancestorItemForOpaqueLayout];

	/* For opaque layouts that may need to keep in sync the selection state of
	   their custom UI. */
	if (changedSelection && [[opaqueItem layout] isChangingSelection] == NO)
	{
		// TODO: Could be better to give up on synchronizing the selection
		// every time the layout needs an update, and rather synchronize the
		// selection just before -renderItems:isNewContent: returns (in opaque layouts).
		if ([self hasNewContentForIndexPaths: indexPaths])
		{
			[opaqueItem updateLayoutRecursively: YES];
		}
		[[opaqueItem layout] selectionDidChangeInLayoutContext: self];
	}

	/* When the receiver is a controller item, the notification gets posted in 
	   -applySelectionIndexPaths:relativeToItem: */
	BOOL hasPostedSelectionChangeForControllerItem = ([self controller] != nil);

	if (changedSelection && hasPostedSelectionChangeForControllerItem == NO)
	{
		[[self controllerItem] didChangeSelection];
	}

	/* Reflect selection change immediately */
	[self setNeedsDisplay: YES];

	_changingSelection = NO;
}

/** Tells the receiver the selection has been changed and it should post
ETItemGroupSelectionDidChangeNotification.

You should never use this method when you use -setSelected: on descendant items
rather than setSelectionXXX: methods on the receiver. */
- (void) didChangeSelection
{
	NSNotification *notif = [NSNotification
		notificationWithName: ETItemGroupSelectionDidChangeNotification object: self];

	if ([[self delegate] respondsToSelector: @selector(itemGroupSelectionDidChange:)])
		[[self delegate] itemGroupSelectionDidChange: notif];

	[[NSNotificationCenter defaultCenter] postNotification: notif];
}

/** Returns the selected child items belonging to the receiver.

The returned collection only includes immediate children, other selected
descendant items below these childrens in the layout item subtree are excluded. */
- (NSArray *) selectedItems
{
	return [[self items] objectsMatchingValue: [NSNumber numberWithBool: YES]
	                                   forKey: @"isSelected"];
}

/** Returns selected descendant items reported by the active layout through
-[ETLayout selectedItems].

You should call this method to obtain the selection in most cases and not
-selectedItems. */
- (NSArray *) selectedItemsInLayout
{
	NSArray *layoutSelectedItems = [[self layout] selectedItems];

	if (layoutSelectedItems != nil)
	{
		return layoutSelectedItems;
	}
	else
	{
		return [self selectedItems];
	}
}

/** Sets the selected items in the layout item subtree attached to the receiver.

Posts an ETItemGroupSelectionDidChangeNotification and marks the receiver to be
redisplayed. */
- (void) setSelectedItems: (NSArray *)items
{
	[self setSelectionIndexPaths: (id)[[items mappedCollection] indexPathFromItem: self]];
}

/* Sorting and Filtering */

- (void) sortWithSortDescriptors: (NSArray *)sortDescriptors recursively: (BOOL)recursively
{
	NSParameterAssert(nil != sortDescriptors);

	/* Create a new sort cache in case -setHasNewContent: invalidated it */
	if (_sortedItems == nil)
	{
		_sortedItems = [[NSMutableArray alloc] initWithArray: _items];
	}

	NSArray *descriptors =
		[[self layout] customSortDescriptorsForSortDescriptors: sortDescriptors];
	BOOL hasValidSortDescriptors = (descriptors != nil && [descriptors isEmpty] == NO);
	if (hasValidSortDescriptors)
	{
		[_sortedItems sortUsingDescriptors: descriptors];
		_arrangedItems = _sortedItems;
		_sorted = YES;
		_filtered = NO;
		_hasNewArrangement = YES;
	}
	else
	{
		// NOTE: -arrangedItems returns a defensive copy, but it could be less
		// expansive to make a single defensive copy here.
		_arrangedItems = _items;
		_sorted = NO;
		_filtered = NO;
		_hasNewArrangement = YES;
	}

	if (recursively)
	{
		FOREACHI(_sortedItems, item)
		{
			if ([item isGroup] == NO)
				continue;

			[(ETLayoutItemGroup *)item sortWithSortDescriptors: descriptors
			                                       recursively: recursively];
		}
	}
}

// TODO: We could improve -[NSArray filterWithPredicate:ignoringObjects:] to
// to support the custom evaluator (here -matchesPredicate:).
- (NSArray *) filteredItemsWithItems: (NSArray *)itemsToFilter
                      usingPredicate: (NSPredicate *)aPredicate
                       ignoringItems: (NSSet *)ignoredItems
{
	NSMutableArray *newArray = [NSMutableArray arrayWithCapacity: [itemsToFilter count]];

	for (ETLayoutItem *item in itemsToFilter)
	{
		if ([ignoredItems containsObject: item] || [item matchesPredicate: aPredicate])
		{
			[newArray addObject: item];
		}
	}

	return newArray;
}

- (void) filterWithPredicate: (NSPredicate *)predicate recursively: (BOOL)recursively
{
	NSArray *itemsToFilter = (_sorted ? _sortedItems : _items);
	BOOL hasValidPredicate = (predicate != nil);
	NSMutableSet *itemsWithMatchingDescendants = [NSMutableSet set];

	/* We traverse the tree structure downwards until we reach the terminal
	   nodes, then we filter each parent children as we walk upwards.
	   When at least one child matches, we prevent its parent to be elimated in
	   the search result (even when it doesn't match) by omitting this parent in
	   the filtering and adding it directly to the search result.
	   We return and repeat the operation at the level above until we reach the
	   item on which the filtering was initiated. */
	if (recursively)
	{
		FOREACHI(itemsToFilter, item)
		{
			if ([item isGroup] == NO)
				continue;

			[(ETLayoutItemGroup *)item filterWithPredicate: predicate
			                                   recursively: recursively];
			BOOL hasSearchResult = ([[item arrangedItems] count] > 0);
			if (hasSearchResult)
			{
				[itemsWithMatchingDescendants addObject: item];
			}
		}
	}

	if (hasValidPredicate)
	{
		_arrangedItems = [self filteredItemsWithItems: itemsToFilter
		                               usingPredicate: predicate
		                                ignoringItems: itemsWithMatchingDescendants];
		_filtered = YES;
		_hasNewArrangement = YES;
	}
	else
	{
		// NOTE: -arrangedItems returns a defensive copy, but it could be less
		// expansive to make a single defensive copy here.
		_arrangedItems = itemsToFilter;
		_filtered = NO;
		_hasNewArrangement = YES;
	}
}

/** Returns whether -arrangedItems are sorted or not.

See also -sortWithSortDescriptors:recursively:. */
- (BOOL) isSorted
{
	return _sorted;
}

/** Returns whether -arrangedItems are filtered or not.

See also -filterWithPredicate:recursively:. */
- (BOOL) isFiltered
{
	return _filtered;
}

/** Returns an array with the child items currently sorted and filtered,
otherwise returns an array identical to -items.

If the receiver has not been sorted or filtered yet, returns a nil array. */
- (NSArray *) arrangedItems
{
	if (_sorted || _filtered)
	{
		return [_arrangedItems copy];
	}
	else
	{
		return [_items copy];
	}
}

/* Actions */

/** Returns the action that can be sent by the action handler, typically on a
double click within the receiver area.

For a double action, the sender will be the receiver. The double clicked item
can be retrieved by calling -doubleClickedItem on the sender in your action
method. */
- (void) setDoubleAction: (SEL)selector
{
	_doubleAction = selector;
	[[self layout] syncLayoutViewWithItem: self];
}

/** Sets the action that can be sent by the action handler, typically on a
double click within the receiver area.

See also -setDoubleAction:. */
- (SEL) doubleAction
{
	return _doubleAction;
}

/** Returns the last child item on which a double click occurs. */
- (ETLayoutItem *) doubleClickedItem
{
	return [self valueForVariableStorageKey: kETDoubleClickedItemProperty];
}

/** <override-dummy />
Returns whether the tools should hit test the children which intersect the
area that lies outside the receiver frame but inside its bounding box.

By default, returns NO.

You can override this method to implement control points external to the
receiver area as ETHandleGroup do. */
- (BOOL) acceptsActionsForItemsOutsideOfFrame
{
	return NO;
}

/** Returns the next responder in the responder chain.

When a controller is set, the next responder is the controller rather than the
parent item. The enclosing item becomes the next responder of the controller.
See -[ETController nextResponder]. */
- (id) nextResponder
{
	ETController *controller = [self controller];

	if (nil != controller)
		return controller;

	return [super nextResponder];
}

/* Collection Protocol */

- (BOOL) isOrdered
{
	return YES;
}

- (BOOL) isEmpty
{
	return ([self numberOfItems] == 0);
}

- (NSUInteger) count
{
	return [self numberOfItems];
}

- (id) content
{
	return [self items];
}

- (NSArray *) contentArray
{
	return [self items];
}

/** Adds object to the child items of the receiver, eventually autoboxing the
	object if needed.
	If the object is a layout item, it is added directly to the layout items as
	it would be by calling -addItem:. If the object isn't an instance of some
	ETLayoutItem subclass, it gets autoboxed into a layout item that is then
	added to the child items.
	Autoboxing means the object is set as the represented object (or value) of
	the item to be added. If the object replies YES to -isGroup, an
	ETLayoutItemGroup instance is created instead of instantiating a simple
	ETLayoutItem.
	Also if the receiver or the base item bound to it has a container, the
	instantiated item could also be either a deep copy of -templateItem or
	-templateItemGroup when such template are available (not nil). -templateItem
	is retrieved when object returns NO to -isGroup, otherwise
	-templateItemGroup is retrieved (-isGroup returns YES). */
- (void) addObject: (id)object
{
	[self insertObject: object atIndex: ETUndeterminedIndex hint: nil boxingForced: NO];
}

- (void) insertObject: (id)object atIndex: (NSUInteger)index hint: (id)hint
{
	[self insertObject: object atIndex: index hint: hint boxingForced: NO];
}

- (ETLayoutItem *) insertObject: (id)object atIndex: (NSUInteger)index hint: (id)hint boxingForced: (BOOL)boxingForced
{
	id insertedItem = [self boxObject: object forced: boxingForced];
	[self handleInsertItem: insertedItem atIndex: index hint: hint moreComing: NO];
	return insertedItem;
}

/** Removes object from the child items of the receiver, eventually trying to
	remove items with represented objects matching the object. */
- (void) removeObject: (id)object atIndex: (NSUInteger)index hint: (id)hint
{
	/* Try to remove object by matching it against child items */
	if ([object isLayoutItem] && [self containsItem: object])
	{
		[self handleRemoveItem: object atIndex: index hint: hint moreComing: NO];
	}
	else
	{
		// TODO: Belongs to ETLayoutItemGroup+Mutation. Needs to be reworked.

		/* Remove items with boxed object matching the object to remove */
		NSArray *itemsMatchedByRepObject = nil;

		itemsMatchedByRepObject = [[self items]
			objectsMatchingValue: object forKey: @"representedObject"];
		[self removeItems: itemsMatchedByRepObject];

		itemsMatchedByRepObject = [[self items]
			objectsMatchingValue: object forKey: @"value"];
		[self removeItems: itemsMatchedByRepObject];
	}
}

/* ETLayoutingContext */

/** Inserts the given layout view into the supervisor view. */
- (void) setLayoutView: (NSView *)aView
{
	NSView *superview = [aView superview];

	if (aView != nil)
	{
		[self setUpSupervisorView];
	}
	NSAssert(nil == superview || [superview isEqual: supervisorView],
		@"A layout view should never have another superview than the layout "
		 "context supervisor view or nil.");

	[aView removeFromSuperview];
	[supervisorView setTemporaryView: aView];
}

/* ETLayoutingContext scroll view related methods */

/* -documentVisibleRect size */
- (NSSize) visibleContentSize
{
	return [self visibleContentBounds].size;
}

/** This method is only exposed to be used internally by EtoileUI.
 
Returns whether the frame can be resized by the layout bound to the receiver. */
- (BOOL) usesFlexibleLayoutFrame
{
	return ([[_layout positionalLayout] isContentSizeLayout] && [self isScrollable] == NO);
}

/* Framework Private */

/** Returns whether the receiver is a layer item encaspulated in a layout and
invisible in the main layout item tree. */
- (BOOL) isLayerItem
{
	return _isLayerItem;
}

/** Asks the delegate to provide a window item, otherwise returns a basic window item. */
- (ETWindowItem *) provideWindowItem
{
	ETWindowItem *windowItem = [[[self delegate] ifResponds] provideWindowItemForItemGroup: self];
	
	return (windowItem != nil ? windowItem : [super provideWindowItem]);
}

@end
