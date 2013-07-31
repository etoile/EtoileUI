/*  <title>ETCompositeLayout</title>

	ETCompositeLayout.m

	<abstract>A layout subclass that formalizes and simplifies the 
	composition of layouts.</abstract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
 */

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/Macros.h>
#import "ETCompositeLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem.h"
#import "EtoileUIProperties.h"
#import "ETOutlineLayout.h"
#import "ETTableLayout.h"
#import "ETLayoutItemFactory.h"
#import "ETCompatibility.h"

@interface ETCompositeLayout (Private)
- (ETLayoutItemGroup *) firstDescendantGroupForItem: (ETLayoutItemGroup *)itemGroup;
@end


@implementation ETCompositeLayout

- (id) init
{
	return [self initWithRootItem: AUTORELEASE([[ETLayoutItemGroup alloc] init])
	        firstPresentationItem: nil];
}

- (id) initWithRootItem: (ETLayoutItemGroup *)itemGroup
{
	return [self initWithRootItem: itemGroup 
	        firstPresentationItem: [self firstDescendantGroupForItem: itemGroup]];
}

- (ETLayoutItemGroup *) firstDescendantGroupForItem: (ETLayoutItemGroup *)itemGroup
{
	NSArray *descendants = [itemGroup allDescendantItems];

	FOREACHI(descendants, item)
	{
		if ([item isGroup])
			return item;
	}

	return  nil;
}

/** The target item must be part of the descendent items of rootItem, otherwise 
    an exception will be thrown. */
//- (id) initWithRootItem: (ETLayoutItemGroup *)itemGroup targetIndexPath: (NSIndexPath *)indexPath
- (id) initWithRootItem: (ETLayoutItemGroup *)rootItem 
  firstPresentationItem: (ETLayoutItemGroup *)targetItem

{
	self = [super initWithObjectGraphContext: nil];
	if (self == nil)
		return nil;

	if (nil != rootItem)
	{
		[self setRootItem: rootItem];
	}
	else
	{
		[self setRootItem: [[ETLayoutItemFactory factory] itemGroup]];
	}
	[self setFirstPresentationItem: targetItem];

	return self;
}

- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	return [self init];
}

DEALLOC(DESTROY(_rootItem); DESTROY(_targetItem));

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETCompositeLayout *newLayout = [super copyWithZone: aZone layoutContext: ctxt];
	newLayout->_rootItem = [_rootItem copyWithZone: aZone];
	return newLayout;
}

/** Returns the holder item. */
- (ETLayoutItemGroup *) proposedParentItemForFirstPresentationItem
{
	return [self holderItem];
}

/** Returns NO. */
- (BOOL) isScrollable
{
	return NO;
}

/** Returns the root item to which items that makes up the composite layout 
belong to. 

See also -setRootItem:. */
- (ETLayoutItemGroup *) rootItem
{
	return _rootItem;
}

/** Sets the root item to which items that makes up the composite layout belong 
to. 

The first presentation item will be reset to nil. You should usually update it 
immediately.

This method removes the action handler on the root item.

You must not call this method when the layout is currently in use, otherwise 
an NSInternalInconsistencyException will be raised. */
- (void) setRootItem: (ETLayoutItemGroup *)anItem
{
	NSParameterAssert(_layoutContext == nil);

	[self setFirstPresentationItem: nil];
	[anItem setActionHandler: nil];
	ASSIGN(_rootItem, anItem);
}

/** <override-never />
Returns the item that currently hold the items that were initially attached 
to the receiver root item.

The holder item is either:
<list>
<item>the layout context when the layout is active</item>
<item>the receiver root item otherwise</item>
</list> */
- (ETLayoutItemGroup *) holderItem
{
	BOOL isLayoutActive = (_layoutContext != nil);
	// FIXME: Ugly cast
	return isLayoutActive ? (ETLayoutItemGroup *)_layoutContext : [self rootItem];
}

/** Returns the layout item to which the layout context content can be routed. */
- (id) firstPresentationItem
{
	return _targetItem;
}

/** Sets the layout item to which the layout context content can be routed. 

If the given item has no parent item, it will be added to the root item (or 
the layout context when the layout is in use). 

Both represented object and source will be reset to nil on the given item. */
- (void) setFirstPresentationItem: (ETLayoutItemGroup *)targetItem
{
	// TODO: Verify that the item has the layout context or the root item as 
	// ancestor, otherwise raise an exception.
	if (targetItem != nil && [targetItem parentItem] == nil)
	{
		[[self proposedParentItemForFirstPresentationItem] addItem: targetItem];
	}

	ASSIGN(_targetItem, targetItem);
}

/** Returns whether the receiver routes the layout context content to the first 
presentation item. */
- (BOOL) isContentRouted
{
	return ([self firstPresentationItem] != nil);
}

/** Returns a new autoreleased presentation proxy which can be used as the first 
presentation item. */
+ (id) defaultPresentationProxyWithFrame: (NSRect)aRect
{
	ETLayoutItemGroup *presentationProxy = [[ETLayoutItemFactory factory] itemGroupWithFrame: aRect];
	[presentationProxy setLayout: [ETOutlineLayout layoutWithObjectGraphContext: [presentationProxy objectGraphContext]]];
	[presentationProxy setAutoresizingMask: NSViewWidthSizable];
	return presentationProxy;
}

- (BOOL) isStaticItem: (ETLayoutItemGroup *)anItem
{
	return ([anItem source] == nil && [anItem representedObject] == nil);
}

- (void) makeItemStatic: (ETLayoutItemGroup *)anItem
{
	[anItem setRepresentedObject: nil];
	[anItem setSource: nil];
}

/* We must be sure that 'item' and 'dest' have no source or represented object when 
they get mutated, otherwise it can result in a source or represented object 
mutation.

Not so obvious border case example:

- A (ancestor and base item)
	- B (the layout context) + represented object

We suppose the composite layout was set previously on B. Now we restore B as it 
was initially with  [self moveContentFromItem: [self rootItem] toItem: B]. When 
A is base item, [[B baseItem] shouldMutateRepresentedObject:] will return YE 
in -handleAddXXX which will then invoke [[B representedObject] addObject: bla]. */
- (void) moveContentFromItem: (ETLayoutItemGroup *)item
                      toItem: (ETLayoutItemGroup *)dest
{
	NSParameterAssert([dest source] == nil);
	NSParameterAssert([dest representedObject] == nil);

	[dest removeAllItems];

	if ([self isStaticItem: item])
	{
		[dest addItems: [item items]];
	}
	else
	{
		// TODO: We could optimize that by moving the children instead of 
		// letting -setSource: triggers a reloading. We could do:
		// [dest setSource: dest or [item source]];
		// [dest presentItems: [item items];
		// [dest setHasNewContent: NO];
		[dest setRepresentedObject: [item representedObject]];
        if ([item usesRepresentedObjectAsProvider])
        {
            [dest setSource: dest];
        }
        else
        {
            [dest setSource: [item source]];
        }

		[self makeItemStatic: item];
		[item removeAllItems];
	}

	NSParameterAssert([item source] == nil);
	NSParameterAssert([item representedObject] == nil);
	NSParameterAssert([item isEmpty]);
}

- (void) saveInitialContextState: (NSSet *)properties
{
	if ([properties containsObject: @"items"])
	{
		[_layoutContext setDefaultValue: [_layoutContext items] 
		                    forProperty: @"items"];
	}
	if ([properties containsObject: kETSourceProperty] 
	 && [_layoutContext source] != nil)
	{
		[_layoutContext setDefaultValue: [_layoutContext source] 
							forProperty: kETSourceProperty];
	}
	if ([properties containsObject: kETRepresentedObjectProperty] 
	 && [_layoutContext representedObject] != nil)
	{
		[_layoutContext setDefaultValue: [_layoutContext representedObject] 
							forProperty: kETRepresentedObjectProperty];
	}
	if ([properties containsObject: kETFlippedProperty])
	{
		BOOL isFlipped = [_layoutContext isFlipped];
		[_layoutContext setDefaultValue: [NSNumber numberWithBool: isFlipped] 
	                        forProperty: kETFlippedProperty];
	}
}

- (void) prepareNewContextState
{
	if ([self firstPresentationItem] != nil)
	{
		[self makeItemStatic: [self firstPresentationItem]];
		[self moveContentFromItem: _layoutContext toItem: [self firstPresentationItem]];
	}
	else
	{
		[self makeItemStatic: _layoutContext];
	}

	[[self rootItem] setSize: [_layoutContext size]];
	[_layoutContext setFlipped: [[self rootItem] isFlipped]];	
	[self moveContentFromItem: [self rootItem] toItem: _layoutContext];
}

- (NSMutableSet *) initialStateProperties
{
	NSMutableSet *properties = [NSMutableSet setWithObject: kETFlippedProperty];

	/* When the content is routed to a presentation proxy, -items and -source 
	   must not be restored with -restoreInitialContextState: because 
	   -restoreContextState: will have done it. */
	if ([self isContentRouted] == NO)
	{
		[properties addObjectsFromArray: 
			A(@"items", kETRepresentedObjectProperty, kETSourceProperty)];
	}

	return properties;
}

- (void) restoreInitialContextState: (NSSet *)properties
{
	if ([properties containsObject: @"items"])
	{
		[_layoutContext addItems: [_layoutContext defaultValueForProperty: @"items"]];
	} 
	if ([properties containsObject: kETSourceProperty])
	{
		[_layoutContext setSource: [_layoutContext defaultValueForProperty: kETSourceProperty]];
	}
	if ([properties containsObject: kETRepresentedObjectProperty])
	{
		[_layoutContext setRepresentedObject: [_layoutContext defaultValueForProperty: kETRepresentedObjectProperty]];
	}
	if ([properties containsObject: kETFlippedProperty])
	{
		[_layoutContext setFlipped: 
			[[_layoutContext defaultValueForProperty: kETFlippedProperty] boolValue]];	
	}
}

- (void) restoreContextState
{
	[self moveContentFromItem: _layoutContext toItem: [self rootItem]];

	if ([self firstPresentationItem] == nil)
		return;

	[self moveContentFromItem: [self firstPresentationItem] toItem: _layoutContext];
	/* We keep the represented path base on the layout context in 
	   -prepareNewContextState (-makeItemStatic: lets the property as is), hence 
	   the previous line won't nullify it on the presentation proxy. 
	   To reset the represented path base to nil isn't required though. We do it  
	   to restore the presentation proxy exactly as it was initially. */
	//[[self firstPresentationItem] setRepresentedPathBase: nil];
}

/* Layouting */

/* We must not invoke -saveInitialContextState and -prepareNewContextState 
because both our initial and current context state are transparently copied (by 
the copying support in ETLayoutItemGroup and ETCompositeLayout/ETLayout). */
- (void) setUpCopyWithZone: (NSZone *)aZone 
                  original: (ETCompositeLayout *)layoutOriginal
{
	/* We figure out the first presentation item index path in the original to 
	   look up the same item in the copy. */
	NSIndexPath *indexPath = [[layoutOriginal proposedParentItemForFirstPresentationItem] 
		indexPathForItem: [layoutOriginal firstPresentationItem]];
	ETLayoutItem *firstPresentationItemCopy = 
		[[self proposedParentItemForFirstPresentationItem] itemAtIndexPath: indexPath];

	// TODO: May be ETAssert([firstPresententionItemCopy isGroup])
	ASSIGN(_targetItem, (ETLayoutItemGroup *)firstPresentationItemCopy);

	/* When the content is not routed, both the original 'items' are 'source'
	   are stored in the default values. However -[ETLayoutItem copyWithZone:] 
	   invoked on the layout context only makes a shallow copy, therefore the 
	   initial items must be deeply copied since they cannot be shared between 
	   an original layout and its copy (bad things would happen when their 
	   context states get both restored). */
	if ([self isContentRouted] == NO)
	{
		NSArray *initialItemTree = [layoutOriginal->_layoutContext defaultValueForProperty: @"items"];
		NSArray *initialItemTreeAlias = [_layoutContext defaultValueForProperty: @"items"];

		NSParameterAssert([initialItemTree isEqual: initialItemTreeAlias]);

		// FIXME: Pass the current copier
		NSArray *initialItemTreeCopy = [[initialItemTree mappedCollection] deepCopyWithCopier: [ETCopier copier]];			
		[_layoutContext setDefaultValue: initialItemTreeCopy
		                    forProperty: @"items"];
		RELEASE(initialItemTree);
	}

	[super setUp];
}

- (void) setUp
{
	[self saveInitialContextState: [self initialStateProperties]];

	[super setUp];

	[self prepareNewContextState];

	[_layoutContext setVisibleItems: [_layoutContext items]];
}

- (void) tearDown
{
	[super tearDown];

	[self restoreContextState];
	[self restoreInitialContextState: [self initialStateProperties]];

	[_layoutContext setVisibleItems: [_layoutContext items]];
}

- (void) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	ETLayoutItemGroup *presentationProxy = [self firstPresentationItem];

	/* Triggers the refresh of everything including the items to be routed 
	   from the target layout to another child item of the root item. For 
	   example, if an item is selected in the target layout in a master-detail
	   interface. The target item is the master UI, when another child of the
	   root item plays the role of the detail UI. */
	if ([presentationProxy canReload])
	{
		[presentationProxy reloadAndUpdateLayout];
	}
	else
	{
		[presentationProxy updateLayout];
	}
}

@end
