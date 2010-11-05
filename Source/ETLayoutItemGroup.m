/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import <EtoileFoundation/NSIndexSet+Etoile.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/Macros.h>
#import "ETLayoutItemGroup.h"
#import "ETBasicItemStyle.h"
#import "ETController.h"
#import "ETFixedLayout.h"
#import "ETLayoutItemGroup+Mutation.h"
#import "ETLayoutItem+Scrollable.h"
#import "EtoileUIProperties.h"
#import "ETView.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

/* Notifications */
NSString * const ETItemGroupSelectionDidChangeNotification = @"ETItemGroupSelectionDidChangeNotification";
NSString * const ETSourceDidUpdateNotification = @"ETSourceDidUpdateNotification";

@interface ETLayoutItem (SubclassVisibility)
- (ETView *) setUpSupervisorViewWithFrame: (NSRect)aFrame;
@end

@interface ETLayoutItemGroup (Private)
- (void) tryReloadWithSource: (id)aSource;
- (void) assignLayout: (ETLayout *)aLayout;
- (BOOL) hasNewLayout;
- (void) setHasNewLayout: (BOOL)flag;
- (void) collectSelectionIndexPaths: (NSMutableArray *)indexPaths
					 relativeToItem: (ETLayoutItemGroup *)pathBaseItem;
- (void) applySelectionIndexPaths: (NSMutableArray *)indexPaths
                   relativeToItem: (ETLayoutItemGroup *)pathBaseItem;
- (void) didChangeSelection;
- (void) display: (NSMutableDictionary *)inputValues 
            item: (ETLayoutItem *)item 
       dirtyRect: (NSRect)dirtyRect 
       inContext: (id)ctxt;
@end


@implementation ETLayoutItemGroup

/* Ugly hacks to shut down the compiler (GCC 4.1.3 on Linux) so it doesn't 
pretend we don't fully implement ETLayoutingContext protocol. */
- (void) setNeedsDisplay: (BOOL)now { [super setNeedsDisplay: now]; }
- (BOOL) isFlipped { return [super isFlipped]; }
- (ETView *) supervisorView { return [super supervisorView]; }
- (BOOL) isScrollViewShown { return [super isScrollViewShown]; }
- (void) setContentSize: (NSSize)size { [super setContentSize: size]; }
- (NSSize) size { return [super size]; }
- (void) setSize: (NSSize)size { [super setSize: size]; }
- (NSView *) view { return [super view]; }

static BOOL globalAutolayoutEnabled = YES;

/** Returns YES if mutating the content of layout items by calling -addItem:, 
-insertItem:atIndex:, -removeItem: etc. triggers a layout update and a 
redisplay, otherwise returns NO when you must call -updateLayout by yourself 
after mutating the content. 
	
By default, returns YES, hence there is usually no need to call -updateLayout 
and marks child items or their parent item for redisplay. */
+ (BOOL) isAutolayoutEnabled;
{
	return globalAutolayoutEnabled;
}

/** Enables automatic layout update and redisplay when mutating the content of 
layout items by calling -addItem:, -insertItem:atIndex:, -removeItem: etc.

If you need to add, remove or insert a large set of child items, in order to 
only recompute the layout once and also avoid a lot of extra redisplay, you 
should disable the autolayout, and restore it later when mutating the layout 
item to which the children belong to is finished. 

Take note that enabling the autolayout doesn't trigger a layout update, so 
-updateLayout must be called when autolayout is disabled or was just restored. */
+ (void) enablesAutolayout;
{
	globalAutolayoutEnabled = YES;
}

/** Disables automatic layout update and redisplay when mutating layout item
content by calling -addItem:, -insertItem:atIndex:, -removeItem: etc. 

See also +enablesAutolayout. */
+ (void) disablesAutolayout
{
	globalAutolayoutEnabled = NO;
}

/* Initialization */

/** <init />
You must use -[ETLayoutItemFactory itemGroupXXX] methods rather than this method.

Initializes and returns a layout item groups with the given child items, view, 
value object and represented object. 

Any of the arguments can be nil.

See also -[ETLayoutItem initWithView:value:representedObject:]. */
- (id) initWithItems: (NSArray *)layoutItems view: (NSView *)view 
	value: (id)value representedObject: (id)repObject
{
    self = [super initWithView: view value: value representedObject: repObject];
	if (nil == self)
		return nil;

	_layoutItems = [[NSMutableArray alloc] init];
	_sortedItems = nil;
	_arrangedItems = nil;
	if (layoutItems != nil)
	{
		[self addItems: layoutItems];
	}

	[self assignLayout: [ETFixedLayout layout]];
	_autolayout = YES;
	_usesLayoutBasedFrame = NO;
	_hasNewLayout = NO;
	_hasNewContent = NO; /* Private accessors in ETMutationHandler category */
	_hasNewArrangement = NO;
	[self setItemScaleFactor: 1.0];
	
	_shouldMutateRepresentedObject = YES;

    return self;
}

/* Overriden ETLayoutItem designated initializer */
- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
{
	return [self initWithItems: nil view: view value: value representedObject: repObject];
}

/** Initializes and returns a root item to be encaspulated in a layout.

You should never need to use this method.

See also -isLayoutOwnedRootItem. */
- (id) initAsLayoutOwnedRootItem
{
	_isLayoutOwnedRootItem = YES;

	self = [self initWithItems: nil view: nil value: nil representedObject: nil];
	[self setActionHandler: nil];
	[self setCoverStyle: nil];

	return self;
}

- (void) dealloc
{
	[self stopKVOObservationIfNeeded];

	DESTROY(_cachedDisplayImage);
	DESTROY(_layout);
	/* Arranged and sorted items are always a children subset, we don't 
	   have to worry about nullifying weak references their element might have. */
	DESTROY(_arrangedItems);
	DESTROY(_sortedItems);
	/* We now nullify the weak references our children hold. 
	   We don't use FOREACH to avoid -objectEnumerator which would retain the 
	   children and make the memory management more complex to test in the tree 
	   structure since the returned enumerator is autoreleased and won't 
	   release the children before the autorelease pool is popped. */
	int n = [_layoutItems count];
	for (int i = 0; i < n; i++)
	{
		ETLayoutItem *child = [_layoutItems objectAtIndex: i];
		/* We bypass -setParentItem: to be sure we won't be trigger a KVO 
		   notification that would retain/release us in a change dictionary. */
		child->_parentItem = nil;
	}
	DESTROY(_layoutItems);
	[self setSource: nil]; /* Tear down the receiver as a source observer */

	[super dealloc];
}

static unsigned int copyDepth = 0;

/** Returns a copy of the receiver.

The layout and its tool are always copied (they cannot be shared).

The returned copy is mutable because ETLayoutItemGroup cannot be immutable. */ 
- (id) copyWithZone: (NSZone *)aZone
{
	BOOL isDeepCopy = (copyDepth > 0);
	// FIXME: NSParameterAssert([childItems isMutableCollection]);

	ETLayoutItemGroup *item = [super copyWithZone: aZone];

	item->_layout = [_layout copyWithZone: aZone layoutContext: item];
	if (NO == isDeepCopy)
	{
		[item->_layout setUpCopyWithZone: aZone original: _layout];
	}

	/* We copy all primitive ivars except _reloading and _changingSelection */

	item->_doubleClickAction = _doubleClickAction;
	/* Must follow -setLayout: to ensure autolayout is disabled in the copy when -setLayout: is called */
	item->_autolayout = _autolayout;
	item->_usesLayoutBasedFrame = _usesLayoutBasedFrame;
	item->_hasNewContent = ([item->_layoutItems isEmpty] == NO);
	item->_hasNewArrangement = YES; // FIXME: Copy the arranged items
	item->_hasNewLayout = YES;
	item->_shouldMutateRepresentedObject = _shouldMutateRepresentedObject;
	item->_sorted = _sorted;
	item->_filtered = _filtered;

	/* We copy all object ivars except _layoutItems whose copying is delegated 
	   to -deepCopyWithZone:, but we create an empty array in case we are not 
	   called by -deepCopyWithZone:. */

	item->_layoutItems = [[NSMutableArray alloc] init];
	
	id source =  GET_PROPERTY(kETSourceProperty);
	id sourceCopy = ([self usesRepresentedObjectAsProvider] ? (id)item : source);

	SET_OBJECT_PROPERTY(item, sourceCopy, kETSourceProperty);
	/* Set up an observer as -setSource: does */
	[[NSNotificationCenter defaultCenter] 
		   addObserver: item
	          selector: @selector(sourceDidUpdate:)
		          name: ETSourceDidUpdateNotification 
			    object: sourceCopy];

	ETController *controller = GET_PROPERTY(kETControllerProperty);
	ETLayoutItemGroup *contentCopy = (isDeepCopy ? (ETLayoutItemGroup *)nil : item);
	ETController *controllerCopy = [controller copyWithZone: aZone content: contentCopy];

	if (nil != controllerCopy)
	{
		[[self objectReferencesForCopy] setObject: controllerCopy forKey: controller];
	}
	SET_OBJECT_PROPERTY_AND_RELEASE(item, controllerCopy, kETControllerProperty);

	/* We copy all variables properties */

	id delegate = GET_PROPERTY(kETDelegateProperty);
	id delegateCopy = [[self objectReferencesForCopy] objectForKey: delegate];

	if (nil == delegateCopy)
	{
		delegateCopy = delegate;
	}

	SET_OBJECT_PROPERTY(item, GET_PROPERTY(kETRepresentedPathBaseProperty), kETRepresentedPathBaseProperty);
	SET_OBJECT_PROPERTY(item, GET_PROPERTY(kETItemScaleFactorProperty), kETItemScaleFactorProperty);
	SET_OBJECT_PROPERTY(item, delegateCopy, kETDelegateProperty);

	return item;
}

- (void) beginDeepCopy
{
	copyDepth++;
}

- (void) endDeepCopy
{
	copyDepth--;

	BOOL isCopyFinished = (0 == copyDepth);

	if (isCopyFinished)
	{
		[[self objectReferencesForCopy] removeAllObjects];
	}
}

- (id) deepCopyWithZone: (NSZone *)aZone
{
	[self beginDeepCopy]; /* Marks the copy starts with us */

	/* Copy Receiver */

	ETLayoutItemGroup *itemCopy = [self copyWithZone: aZone];
	DESTROY(itemCopy->_layoutItems); // TODO: a bit crude

	/* Copy & Assign Children */

	NSMutableArray *childrenCopy = [[NSMutableArray alloc] initWithCapacity: [_layoutItems count]];
	NSMapTable *objectRefsForCopy = [self objectReferencesForCopy];

	FOREACH(_layoutItems, child, ETLayoutItem *)
	{
		ETLayoutItem *childCopy = [child deepCopyWithZone: aZone];

		[childrenCopy addObject: childCopy];
		childCopy->_parentItem = itemCopy; /* Weak reference */
		[objectRefsForCopy setObject: childCopy forKey: child];
	}
	[childrenCopy makeObjectsPerformSelector: @selector(release)];

	ASSIGN(itemCopy->_layoutItems, childrenCopy);
	RELEASE(childrenCopy);

	/* Finish Copy Layout and Controller */

	[itemCopy->_layout setUpCopyWithZone: aZone original: _layout];

	ETController *controller = GET_PROPERTY(kETControllerProperty);
	ETController *controllerCopy = GET_OBJECT_PROPERTY(itemCopy, kETControllerProperty);

	[controller finishDeepCopy: controllerCopy withZone: aZone content: itemCopy];

	/* We need to update the layout to have the content reloaded in widget layouts
	   Which means the item copy will then receive a layout update even in case 
	   the receiver had received none until now.  */
	if ([[itemCopy layout] isWidget])
	{
		[itemCopy updateLayout]; // TODO: Should be setNeedsUpdateLayout:
	}
	else if ([[itemCopy layout] isOpaque] == NO) /* We don't need a true layout update */
	{
		// NOTE: Might be better to iterate over the visible items backed by a
		// supervisor view and do [[item supervisorView] addSubview: childSupervisorView]
		[itemCopy setVisibleItems: [itemCopy visibleItemsForItems: childrenCopy]
		                 forItems: childrenCopy];
	}

	[self endDeepCopy]; /* Reset the context if the copy started with us */
	
	//ETLog(@"Make deep copy %@ + %@ of %@ + %@ at depth %i", itemCopy, 
	//	[itemCopy controller], self, [self controller], copyDepth);

	return itemCopy;
}

/* Property Value Coding */

- (NSArray *) properties
{
	NSArray *properties = A(kETSourceProperty, kETDelegateProperty, 
		kETItemScaleFactorProperty, kETDoubleClickedItemProperty);

	return [[super properties] arrayByAddingObjectsFromArray: properties];
}

/** Returns YES. An ETLayoutItemGroup is always a group and a collection by 
default. */
- (BOOL) isGroup
{
	return YES;
}

/* Traversing Layout Item Tree */

/** Returns the layout item child identified by the index path paremeter 
interpreted as relative to the receiver. */
- (ETLayoutItem *) itemAtIndexPath: (NSIndexPath *)path
{
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

/** Returns the layout item child identified by the path paremeter interpreted 
as relative to the receiver. 

Whether the path begins by '/' or not doesn't modify the result. */
- (ETLayoutItem *) itemAtPath: (NSString *)path
{
	NSArray *pathComponents = [path pathComponents];
	ETLayoutItem *item = self;
	
	FOREACH(pathComponents, pathComp, NSString *)
	{
		if (pathComp == nil || [pathComp isEqualToString: @"/"] || [pathComp isEqualToString: @""])
			continue;
	
		if ([item isGroup])
		{
			NSArray *childItems = [(ETLayoutItemGroup *)item items];
			item = [childItems firstObjectMatchingValue: pathComp 
			                                     forKey: kETIdentifierProperty];
		}
		else
		{
			item = nil;
			break;
		}
	}

	return item;
}

/** Sets the represented path base associated with the receiver. When a valid 
represented base is set, the receiver becomes a base item. See also -isBaseItem, 
-baseItem, -representedPath and -representedPathBase in ETLayoutItem.

The represented path base should be a navigational path into the model whose 
content is currently presented by the receiver. In that way, it is useful to 
keep track of your location inside the model currently browsed. Tree-related 
methods implemented by a data source are passed paths which are subpaths of this 
path base.

A path base is only critical when a source is used, otherwise it's up to the 
developer to track the level of navigation inside the tree structure. 

You should use paths like '/', '/blabla/myModelObjectName'. You cannot pass an 
empty string to this method or it will throw an invalid argument exception. If 
you want no represented path base, use nil. 

Without a source, you can use -setRepresentedPathBase: as a conveniency to 
remember the represented object location within the model graph that is 
presented by the receiver. */
- (void) setRepresentedPathBase: (NSString *)aPath
{
	if ([aPath isEqual: @""])
	{
		[NSException raise: NSInvalidArgumentException format: @"For %@ "
			@"-setRepresentedPathBase: argument must never be an empty string", self];
		
	}

	SET_PROPERTY(aPath, kETRepresentedPathBaseProperty);
}

/* Manipulating Layout Item Tree */

/** Handles the view visibility of child items with a role similar to 
-setVisibleItems: that is called by layouts. 

This method is called when you insert an item in an item group with a layout 
which doesn't require an update in that case, otherwise the view insertion is 
managed by requesting a layout update which ultimately calls back 
-setVisibleItems:. 

NOTE: Having a null layout class may be a solution to get rid of 
-handleAttachViewOfItem: and -handleDetachViewOfItem:. */
- (void) handleAttachViewOfItem: (ETLayoutItem *)item
{
	ETView *itemDisplayView = [item displayView];

	// NOTE: -[NSView addSuview: nil] results in an exception.
	if (itemDisplayView == nil || [item isVisible] == NO) /* No view to attach */
		return;

	BOOL isAlreadyAttached = [[itemDisplayView superview] isEqual: [_parentItem supervisorView]];

	/* We don't want to change the subview ordering when we simply switch 
	   the visibility */
	if (isAlreadyAttached)
		return;

	[itemDisplayView removeFromSuperview];

	/* Only insert the item view if the layout is a fixed/free layout. 
	   TODO: Probably make more explicit the nil layout check. */
	if ([[self layout] isOpaque] == NO)
	{
		[[self setUpSupervisorViewWithFrame: [self frame]] addSubview: itemDisplayView];
	}
}

/** Symetric method to -handleAttachViewOfItem: */
- (void) handleDetachViewOfItem: (ETLayoutItem *)item
{
	if ([item displayView] == nil) /* No view to detach */
		return;

	[[item displayView] removeFromSuperview];
}

/** <override-dummy />Handles any necessary adjustments to be done right before
item is made a child item of the receiver. This method is available to be
overriden in subclasses that want to extend or modify the item insertion
behavior.

The default implementation takes to care to remove item from any existing parent 
item, then updates the parent item reference to be the receiver.<br />
You must always call the superclass implementation.

Symetric method to -handleDetachItem: */
- (void) handleAttachItem: (ETLayoutItem *)item
{
	RETAIN(item);
	if ([item parentItem] != nil)
	{
		[[item parentItem] removeItem: item];
	}
	[item setParentItem: self];
	RELEASE(item);
	[self handleAttachViewOfItem: item];
}

/** <override-dummy />Handles any necessary adjustments to be done right before
item is removed as a child item from the receiver. This method is available to
be overriden in subclasses that want to extend or modify the item removal
behavior.

The default implementation only updates the parent item reference to be nil. <br />
You must always call the superclass implementation.

Symetric method to -handleAttachItem: */
- (void) handleDetachItem: (ETLayoutItem *)item
{
	[item setParentItem: nil];
	[self handleDetachViewOfItem: item];
}

/** See -[ETLayoutItemGroup setRepresentedObject:].

If necessary, marks the receiver as having new content to be layouted, otherwise
the layout is told the layout item tree hasn't been mutated. Although this only
holds when the layout item tree is built directly from the represented object by
the mean of ETCollection protocol. */
- (void) setRepresentedObject: (id)model
{
	[super setRepresentedObject: model];
	if ([self usesRepresentedObjectAsProvider])
		[self setHasNewContent: YES];
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
	return ([[[self baseItem] source] isEqual: [self baseItem]]);
}

/** Returns the source which provides the content presented by the receiver.

A source implements either ETIndexSource or ETPathSource protocols. If the
receiver handles the layout item tree directly without the help of a source
object, then this method returns nil. */
- (id) source
{
	return GET_PROPERTY(kETSourceProperty);
}

- (void) makeBaseItemIfNeeded
{
	if ([self isBaseItem])
		return;

	[self setRepresentedPathBase: @"/"];
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
event handling logic. */
- (void) setSource: (id)source
{
	/* By safety, avoids to trigger extra updates */
	if (GET_PROPERTY(kETSourceProperty) == source)
		return;

	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
		          name: ETSourceDidUpdateNotification 
			    object: GET_PROPERTY(kETSourceProperty)];

	SET_PROPERTY(source, kETSourceProperty);

	if (source != nil)
		[self makeBaseItemIfNeeded];

	[self tryReloadWithSource: source]; /* Resets any particular state like selection */
	if ([self canUpdateLayout])
		[self updateLayout];

	[[NSNotificationCenter defaultCenter] 
		   addObserver: self
	          selector: @selector(sourceDidUpdate:)
		          name: ETSourceDidUpdateNotification 
			    object: source];
}

/** Returns the delegate associated with the receiver. 

See also -setDelegate:. */
- (id) delegate
{
	return GET_PROPERTY(kETDelegateProperty);
}

/** Sets the delegate associated with the receiver. 

A delegate is only useful if the receiver is a base item, otherwise it will  
be ignored.

The delegate is retained, unlike what Cocoa/GNUstep usually do.<br />
The delegate is owned by the item and treated as a pluggable aspect to be 
released when the item is deallocated.  */
- (void) setDelegate: (id)delegate
{
	SET_PROPERTY(delegate, kETDelegateProperty);
}

/** Returns the controller which allows to customize the overall UI interaction 
with the receiver item tree.

When the controller is not nil, the receiver is both a base item and the 
controller content. */
- (ETController *) controller
{
	return GET_PROPERTY(kETControllerProperty);
}

/** Sets the controller which allows to customize the overall UI interaction 
with the receiver item tree.

When the given controller is not nil, it is inserted as the next responder and 
the receiver becomes both a base item and the controller content.

See also -setSource:, -isBaseItem and -nextResponder. */
- (void) setController: (ETController *)aController
{
	SET_PROPERTY(aController, kETControllerProperty);
	[aController setContent: self];

	if (aController != nil)
	{
		[self makeBaseItemIfNeeded];
	}
}

/** Adds the given item to the receiver children. */
- (void) addItem: (ETLayoutItem *)item
{
	//ETDebugLog(@"Add item in %@", self);
	[self handleAdd: nil item: item];
}

/** Inserts the given item in the receiver children at a precise index. */
- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index
{
	//ETDebuLog(@"Insert item in %@", self);
	[self handleInsert: nil item: item atIndex: index];
}

/** Removes the given item from the receiver children. */
- (void) removeItem: (ETLayoutItem *)item
{
	//ETDebugLog(@"Remove item in %@", self);
	[self handleRemove: nil item: item];
}

/** Removes the child item at the given index in the receiver children. */
- (void) removeItemAtIndex: (int)index
{
	ETLayoutItem *item = [_layoutItems objectAtIndex: index];
	[self removeItem: item];
}

/** Returns the child item at the given index in the receiver children. */
- (ETLayoutItem *) itemAtIndex: (int)index
{
	return [_layoutItems objectAtIndex: index];
}

/** Returns the first receiver child item.

Shortcut method equivalent to [self itemAtIndex: 0].

Similar to -firstObject method for collections (see ETCollection).*/
- (ETLayoutItem *) firstItem
{
	return [_layoutItems firstObject];
}

/** Returns the last receiver child item.

Shortcut method equivalent to [self itemAtIndex: [self numberOfItems] - 1].
	
Similar to -lastObject method for collections (see ETCollection).*/
- (ETLayoutItem *) lastItem
{
	return [_layoutItems lastObject];
}

/** Adds the given the items to the receiver children. */
- (void) addItems: (NSArray *)items
{
	//ETDebugLog(@"Add items in %@", self);
	[self handleAdd: nil items: items];
}

/** Removes the given child items from the receiver children. */
- (void) removeItems: (NSArray *)items
{
	//ETDebugLog(@"Remove items in %@", self);
	[self handleRemove: nil items: items];
}

/** Removes all the receiver child items. */
- (void) removeAllItems
{
	//ETDebugLog(@"Remove all items in %@", self);
	// FIXME: Temporary solution which is quite slow
	[self handleRemove: nil items: [self items]];
}

// FIXME: (id) parameter rather than (ETLayoutItem *) turns off compiler 
// conflicts with menu item protocol which also implements this method. 
// Fix compiler.

/** Returns the index of the given child item in the receiver children. */
- (int) indexOfItem: (id)item
{
	return [_layoutItems indexOfObject: item];
}

/** Returns whether the given item is a receiver child or not. */
- (BOOL) containsItem: (ETLayoutItem *)item
{
	return ([self indexOfItem: (id)item] != NSNotFound);
}

/** Returns how many child items the receiver includes. */
- (int) numberOfItems
{
	return [_layoutItems count];
}

/** Returns an autoreleased array which contains the receiver child items. */
- (NSArray *) items
{
	return [NSArray arrayWithArray: _layoutItems];
}

/** Returns all children items under the control of the receiver. 

An item is said to be under the control of an item group, when you can traverse
the branch leading to the item without crossing a parent item declared as a base 
item. An item group becomes a base item when a represented path base is set, in
other words when -representedPathBase doesn't return nil. See also -isBaseItem.

This method collects every items the layout item subtree (excluding the
receiver) by doing a preorder traversal, the resulting collection is a flat list
of every items in the tree.

If you are interested by collecting descendant items in another traversal order, 
you have to implement your own version of this method. */
- (NSArray *) itemsIncludingRelatedDescendants
{
	// TODO: This code is probably quite slow by being written in a recursive 
	// style and allocating/resizing many arrays instead of using a single 
	// linked list. Test whether optimization are needed or not really...
	NSMutableArray *collectedItems = [NSMutableArray array];

	FOREACHI([self items], item)
	{
		[collectedItems addObject: item];

		if ([item isGroup] && [item hasValidRepresentedPathBase] == NO)
			[collectedItems addObjectsFromArray: [item itemsIncludingRelatedDescendants]];
	}

	return collectedItems;
}

/** Returns all descendant items of the receiver, including immediate children.

This method collects every items the layout item subtree (excluding the
receiver) by doing a preorder traversal, the resulting collection is a flat list
of every items in the tree. 

If you are interested in collecting descendant items in another traversal order,
you have to implement your own version of this method. */
- (NSArray *) itemsIncludingAllDescendants
{
	// TODO: This code is probably quite slow by being written in a recursive 
	// style and allocating/resizing many arrays instead of using a single 
	// linked list. Test whether optimization are needed or not really ...
	NSMutableArray *collectedItems = [NSMutableArray array];

	FOREACHI([self items], item)
	{
		[collectedItems addObject: item];

		if ([item isGroup])
			[collectedItems addObjectsFromArray: [item itemsIncludingAllDescendants]];
	}

	return collectedItems;
}

/** Returns whether the receiver can be reloaded presently with -reload. */
- (BOOL) canReload
{
	BOOL hasSource = ([[self baseItem] source] != nil);

	return hasSource && ![self isReloading];
}

/** Tries to reload the content of the receiver, but only if it can be reloaded. 

Won't reload when the receiver is currently sorted and/or filtered. See 
-isSorted and -isFiltered.

This method can be safely called even if the receiver has no source or doesn't 
inherit a source from a base item. */
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

	BOOL wasAutolayoutEnabled = [self isAutolayout];

	_reloading = YES;
	[self setAutolayout: NO];

	[self removeAllItems];
	if (nil != aSource)
	{
		[self addItems: [self itemsFromSource]];
	}

	[self setAutolayout: wasAutolayoutEnabled];
	_reloading = NO;
}

/** Reloads the content by removing all existing childrens and requesting all
the receiver immediate children to the base item source.

Will cancel any any sorting and/or filtering currently done on the receiver. 
Which means -isFiltered and -isSorted will both return NO. */
- (void) reload
{
	BOOL hasSource = ([[self baseItem] source] != nil);

	if (hasSource)
	{
		[self tryReloadWithSource: [[self baseItem] source]];
	}
	else
	{
		ETLog(@"WARNING: Impossible to reload %@ because the base item miss " 
			@"a source %@", self, [[self baseItem] source]);
	}
}

/* Layout */

- (BOOL) hasNewLayout { return _hasNewLayout; }

- (void) setHasNewLayout: (BOOL)flag { _hasNewLayout = flag; }

/** Returns the layout associated with the receiver to present its content. */
- (id) layout
{
	return _layout;
}

- (void) assignLayout: (ETLayout *)aLayout
{
	[_layout setLayoutContext: nil]; /* Ensures -[ETLayout tearDown] is called */
	ASSIGN(_layout, aLayout);
	/* We must remove the item views, otherwise they might remain visible as 
	   subviews (think ETBrowserLayout on GNUstep which has transparent areas),  
	   because view-based layout won't call -setVisibleItems: in -renderWithLayoutItems:XXX:. */
	[self setVisibleItems: [NSArray array]];	
	[self setHasNewLayout: YES];
	[aLayout setLayoutContext: self];
}

/** Sets the layout associated with the receiver to present its content. */
- (void) setLayout: (ETLayout *)layout
{
	if (_layout == layout)
		return;

	//ETDebugLog(@"Modify layout from %@ to %@ in %@", _layout, layout, self);
	
	ETLayout *oldLayout = RETAIN(_layout);
	BOOL wasAutolayoutEnabled = [self isAutolayout];
	
	/* Disable autolayout to avoid spurious updates triggered by stuff like
	   view/container frame modification on layout view insertion */
	[self setAutolayout: NO];
	
	[self assignLayout: layout];
	[self didChangeLayout: oldLayout];
	RELEASE(oldLayout);
	
	[self setAutolayout: wasAutolayoutEnabled];
	if ([self canUpdateLayout])
		[self updateLayout];
}

/** Attempts to reload the children items from the source and updates the layout 
by asking the first ancestor item with an opaque layout to do so. */
- (void) reloadAndUpdateLayout
{
	[self reload];
	[[self ancestorItemForOpaqueLayout] updateLayout];
}

/** Updates recursively each layout in the item tree owned by the receiver.

The layout update starts on the leaf descendant items, is carried upward 
through the tree structure back to the receiver itself, whose layout is the last 
updated. This postorder processing is necessary because a parent layout 
computation might depend on one or several child item properties which are 
dynamically computed. For example, an item can use a layout which alters its 
frame (see -usesLayoutBasedFrame). */
- (void) updateLayout
{
	if ([self layout] == nil)
		return;

	ETDebugLog(@"Try update layout of %@", self);
	
	BOOL isNewLayoutContent = ([self hasNewContent] || [self hasNewLayout] 
		|| _hasNewArrangement);
	
	[[self items] makeObjectsPerformSelector: @selector(updateLayout)];
	
	/* Delegate layout rendering to custom layout object */
	[[self layout] render: nil isNewContent: isNewLayoutContent];

	[self setNeedsDisplay: YES];

	/* Unset needs layout flags */
	[self setHasNewContent: NO];
	_hasNewArrangement = NO;
	[self setHasNewLayout: NO];
}

/** Returns whether -updateLayout can be safely called now. */
- (BOOL) canUpdateLayout
{
	return globalAutolayoutEnabled && [self isAutolayout] && ![self isReloading] && ![[self layout] isRendering];
}

/** Returns YES if mutating the receiver content by calling -addItem:, 
    -insertItem:atIndex:, -removeItem: etc. triggers a layout update and a 
	redisplay, otherwise returns NO when you must call -updateLayout by yourself 
	after mutating the receiver content. 
	By default, returns YES, hence there is usually no need to call 
	-updateLayout and marks the receiver or a parent item for redisplay. */
- (BOOL) isAutolayout
{
	return _autolayout;
}

/** Sets whether mutating the receiver content by calling -addItem:, 
    -insertItem:atIndex:, -removeItem: etc. triggers a layout update and a 
	redisplay.
	If you need to add, remove or insert a large set of child items, in order 
	to only recompute the layout once and also avoid a lot of extra redisplay, 
	you should disable the autolayout, and restore it later after mutating 
	the receiver children in meantime. Take note that enabling the autolayout 
	doesn't trigger a layout update, so -updateLayout must be called when 
	autolayout is disabled or was just restored. */
- (void) setAutolayout: (BOOL)flag
{
	_autolayout = flag;
}

/** Returns YES if the item frame may vary with the layout of the child items 
    that makes up the content, otherwise returns NO if the frame is static and 
	will always remain identical after updating the layout. By default, returns 
	NO.
	This method is used by the drawing code of the layout item tree to know 
	if the whole receiver content must be redrawn subsequently to a layout 
	change. */
- (BOOL) usesLayoutBasedFrame
{
	return _usesLayoutBasedFrame;
}

/** Sets to YES to indicate that the item frame may vary with the layout of the 
    child items that makes up the content, otherwise sets to NO if the frame is 
	static and will always remain identical after updating the layout.
	You rarely need to invoke this method unless you write a layout that alter 
	the frame of its layout context. */
- (void) setUsesLayoutBasedFrame: (BOOL)flag
{
	_usesLayoutBasedFrame = flag;
}

/* Item scaling */

/** Returns the scale factor applied to each item when the layout supports it. 

See also -setItemScaleFactor:. */
- (float) itemScaleFactor
{
	return [GET_PROPERTY(kETItemScaleFactorProperty) floatValue];
}

/** Sets the scale factor applied to each item when the layout supports it.

This scale factor only applies to the immediate children.

See -[ETLayout setItemSizeConstraintStyle:] and -[ETLayout setConstrainedItemSize:] 
to control more precisely how the items get resized per layout. */
- (void) setItemScaleFactor: (float)aFactor
{
	SET_PROPERTY([NSNumber numberWithFloat: aFactor], kETItemScaleFactorProperty);
	if ([self canUpdateLayout])
		[self updateLayout];
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
recursively on them. */
- (void) render: (NSMutableDictionary *)inputValues 
      dirtyRect: (NSRect)dirtyRect 
      inContext: (id)ctxt
{
	//ETLog(@"Render %@ dirtyRect %@ in %@", self, NSStringFromRect(dirtyRect), ctxt);

	NSRect contentDrawingBox = [self contentDrawingBox];

	/* Use the display cache when there is one */
	if (nil != _cachedDisplayImage)
	{
		[[ETBasicItemStyle sharedInstance] drawImage: _cachedDisplayImage 
		                                     flipped: [self isFlipped]
		                                      inRect: contentDrawingBox];
		return;
	}

	/* Otherwise redisplay the receiver and its descendants recursively */
	if ([self usesLayoutBasedFrame] || NSIntersectsRect(dirtyRect, contentDrawingBox))
	{
	   /* We limit the redrawn area to the content bounds. We don't want to 
	      draw over the decorators. */
		NSRect realDirtyRect = NSIntersectionRect(dirtyRect, contentDrawingBox);

		/* There is no need to set realDirtyRect with -[NSBezierPath setClip] 
		   because the right clip rect should have been set by our supervisor 
		   view or our parent item (when when we have no decorator). */
		   	
		[super render: inputValues dirtyRect: realDirtyRect inContext: ctxt];

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
				NSRect childDirtyRect = [item convertRectFromParent: realDirtyRect];
				childDirtyRect = NSIntersectionRect(childDirtyRect, [item drawingBox]);

				/* In case, dirtyRect is only a redraw rect on the parent and not on 
				   the entire parent frame, we try to optimize by not redrawing the 
				   items that lies outside of the dirtyRect. */
				if (NSEqualRects(childDirtyRect, NSZeroRect))
					continue;

				[self display: inputValues 
						 item: item 
					dirtyRect: childDirtyRect 
					inContext: ctxt];;
			}
		}
		[NSGraphicsContext restoreGraphicsState]; /* Restore the receiver clipping rect */
	
		/* Render the layout-specific tree if needed */

		[self display: inputValues 
		         item: [[self layout] rootItem] 
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
	// a nil item can be returned by -[ETLayout rootItem].
	BOOL shouldDrawItem = (item != nil && [item displayView] == nil);
			
	if (shouldDrawItem == NO)
		return;

#ifdef DEBUG_DRAWING		
	NSRect itemRect = [item convertRectFromParent: [item frame]];
	[[NSColor yellowColor] set];
	[NSBezierPath setDefaultLineWidth: 4.0];
	[NSBezierPath strokeRect: itemRect];
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
	ASSIGN(_cachedDisplayImage, anImage);

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

/** Returns the visible child items of the receiver.

This is a shortcut method for -visibleItemsForItems:. */
- (NSArray *) visibleItems
{
	return [self visibleItemsForItems: [self items]];
}

/** Sets the visible child items of the receiver, by taking care of inserting
and removing the item display views based on the visibility of the layout items.

This is a shortcut method for -visibleItemsForItems:. */
- (void) setVisibleItems: (NSArray *)visibleItems
{
	return [self setVisibleItems: visibleItems forItems: [self items]];
}

/** Returns the visible child items of the receiver.

You shouldn't need to call this method by yourself, unless you write an
ETCompositeLayout subclass which usually requires the receiver displays layout
items, that don't belong to it, as children. */
- (NSArray *) visibleItemsForItems: (NSArray *)items
{
	NSMutableArray *visibleItems = [NSMutableArray array];

	FOREACH(items, item, ETLayoutItem *)
	{
		if ([item isVisible])
			[visibleItems addObject: item];
	}

	return visibleItems;
}

/** Sets the visible child items of the receiver, by taking care of inserting
and removing the item display views based on the visibility of the layout items.

This method is typically called by the layout of the receiver once the layout 
rendering is finished, in order to adjust the visibility of views and update the 
visible property of the child items. You shouldn't need to call this method by 
yourself (see -visibleItemsForItems:). */
- (void) setVisibleItems: (NSArray *)visibleItems forItems: (NSArray *)items
{
	FOREACH(items, item, ETLayoutItem *)
	{
		[item setVisible: [visibleItems containsObject: item]];
	}
}

/* Selection */

/** Returns the index of the first selected item which is an immediate child of 
the receiver. If there is none, returns NSNotFound. 

Calling this method is equivalent to [[self selectionIndexes] firstIndex].

Take note that -selectionIndexPaths may return one or multiple values when this
method returns NSNotFound. See -selectionIndexes also. */
- (unsigned int) selectionIndex
{
	return [[self selectionIndexes] firstIndex];
}

/** Sets the selected item identified by index in the receiver and discards any 
existing selection index paths previously set.

Posts an ETItemGroupSelectionDidChangeNotification. */
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
	int numberOfItems = [[self items] count];
	int lastSelectionIndex = [[self selectionIndexes] lastIndex];

	ETDebugLog(@"Set selection indexes to %@ in %@", indexes, self);

	if (lastSelectionIndex > (numberOfItems - 1) && lastSelectionIndex != NSNotFound) /* NSNotFound is a big value and not -1 */
	{
		ETLog(@"WARNING: Try to set selection index %d when %@ only contains %d items",
			  lastSelectionIndex, self, numberOfItems);
		return;
	}

	/* Update selection */
	[self setSelectionIndexPaths: [indexes indexPaths]];
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
- (void) applySelectionIndexPaths: (NSMutableArray *)indexPaths 
                   relativeToItem: (ETLayoutItemGroup *)pathBaseItem
{
	FOREACHI([self items], item)
	{
		NSIndexPath *itemIndexPath = [item indexPathFromItem: pathBaseItem];
		if ([indexPaths containsObject: itemIndexPath])
		{
			[item setSelected: YES];
			[indexPaths removeObject: itemIndexPath];
		}
		else
		{
			[item setSelected: NO];
		}
		if ([item isGroup])
			[item applySelectionIndexPaths: indexPaths relativeToItem: pathBaseItem];
	}
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

/** Sets the selected items in the layout item subtree attached to the receiver. 

Posts an ETItemGroupSelectionDidChangeNotification and marks the receiver to be 
redisplayed. */
- (void) setSelectionIndexPaths: (NSArray *)indexPaths
{
	_changingSelection = YES;

	[self applySelectionIndexPaths: [NSMutableArray arrayWithArray: indexPaths] 
	                relativeToItem: self];

	/* For opaque layouts that may need to keep in sync the selection state of 
	   their custom UI. */
	if ([[self layout] isChangingSelection] == NO)
	{
		[[self layout] selectionDidChangeInLayoutContext: self];
	}
	[self didChangeSelection];

	/* Reflect selection change immediately */
	[self setNeedsDisplay: YES];

	_changingSelection = NO;
}

/* Tells the receiver the selection has been changed and it should post 
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

/** You should rarely need to invoke this method. */
- (NSArray *) selectedItemsIncludingRelatedDescendants
{
	NSArray *descendantItems = [self itemsIncludingRelatedDescendants];

	return [descendantItems objectsMatchingValue: [NSNumber numberWithBool: YES] 
	                                      forKey: @"isSelected"];
}

/** You should rarely need to invoke this method. */
- (NSArray *) selectedItemsIncludingAllDescendants
{
	NSArray *descendantItems = [self itemsIncludingAllDescendants];

	return [descendantItems objectsMatchingValue: [NSNumber numberWithBool: YES] 
	                                      forKey: @"isSelected"];
}

/* Sorting and Filtering */

- (void) sortWithSortDescriptors: (NSArray *)sortDescriptors recursively: (BOOL)recursively
{
	NSParameterAssert(nil != sortDescriptors);

	/* Create a new sort cache in case -setHasNewContent: invalidated it */
	if (_sortedItems == nil)
	{
		_sortedItems = [_layoutItems mutableCopy];
	}

	NSArray *descriptors = 
		[[self layout] customSortDescriptorsForSortDescriptors: sortDescriptors];
	BOOL hasValidSortDescriptors = (descriptors != nil && [descriptors isEmpty] == NO);
	if (hasValidSortDescriptors)
	{
		[_sortedItems sortUsingDescriptors: descriptors];
		ASSIGN(_arrangedItems, _sortedItems);
		_sorted = YES;
		_filtered = NO;
		_hasNewArrangement = YES;
	}
	else
	{
		// NOTE: -arrangedItems returns a defensive copy, but it could be less 
		// expansive to make a single defensive copy here.
		ASSIGN(_arrangedItems, _layoutItems);
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

- (void) filterWithPredicate: (NSPredicate *)predicate recursively: (BOOL)recursively
{
	NSArray *itemsToFilter = (_sorted ? _sortedItems : _layoutItems);
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
		ASSIGN(_arrangedItems, [itemsToFilter filteredArrayUsingPredicate: predicate
		                                                  ignoringObjects: itemsWithMatchingDescendants]);
		_filtered = YES;
		_hasNewArrangement = YES;
	}
	else
	{
		// NOTE: -arrangedItems returns a defensive copy, but it could be less 
		// expansive to make a single defensive copy here.
		ASSIGN(_arrangedItems, itemsToFilter);
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
		return AUTORELEASE([_arrangedItems copy]);
	}
	else
	{
		return AUTORELEASE([_layoutItems copy]);
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
	_doubleClickAction = selector;
	[[self layout] syncLayoutViewWithItem: self];
}

/** Sets the action that can be sent by the action handler, typically on a 
double click within the receiver area. 

See also -setDoubleAction:. */
- (SEL) doubleAction
{
	return _doubleClickAction;
}

/** Returns the last child item on which a double click occurs. */
- (ETLayoutItem *) doubleClickedItem
{
	return GET_PROPERTY(kETDoubleClickedItemProperty);
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

/* Stacking */

/** Returns whether the receiver is currently a stack.

TODO: Implement */
- (BOOL) isStack
{
	return NO;
}

/** Returns YES when the receiver is a collapsed stack, otherwise returns NO.

TODO: Implement */
- (BOOL) isStacked
{
	return NO;
}

/** Collapses the receiver as a stack.

TODO: Implement and may be rename -collapse or -collapseStack */
- (void) stack
{

}

/** Expands the receiver as a stack.

TODO: Implement and may be rename -expand or -expandStack */
- (void) unstack
{

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
	id item = [object isLayoutItem] ? object : [self itemWithObject: object isValue: [object isCommonObjectValue]];
	
	if ([object isLayoutItem] == NO)
	{
		ETDebugLog(@"Boxed object %@ in item %@ to be added to %@", object, item, self);
	}

	[self addItem: item];
}

- (void) insertObject: (id)object atIndex: (unsigned int)index
{
	id item = [object isLayoutItem] ? object : [self itemWithObject: object isValue: [object isCommonObjectValue]];
	
	if ([object isLayoutItem] == NO)
	{
		ETDebugLog(@"Boxed object %@ in item %@ to be inserted in %@", object, item, self);
	}

	[self insertItem: item atIndex: index];
}

/** Removes object from the child items of the receiver, eventually trying to 
	remove items with represented objects matching the object. */
- (void) removeObject: (id)object
{
	/* Try to remove object by matching it against child items */
	if ([object isLayoutItem] && [self containsItem: object])
	{
		[self removeItem: object];
	}
	else
	{
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
	[self setUpSupervisorViewWithFrame: [self frame]];

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

/* Live Development */

- (void) beginEditingUI
{
	/* Notify view and decorator item chain */
	[super beginEditingUI];
	
	/* Notify children */
	[[self items] makeObjectsPerformSelector: @selector(beginEditingUI)];
}

/* Framework Private */

/** Returns whether the receiver is a root item encaspulated in a layout and 
invisible in the main layout item tree. */
- (BOOL) isLayoutOwnedRootItem
{
	return _isLayoutOwnedRootItem;
}

@end
