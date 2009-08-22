/*  <title>ETCompositeLayout</title>

	ETCompositeLayout.m

	<abstract>A layout subclass that formalizes and simplifies the 
	composition of layouts.</abstract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
 */

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/Macros.h>
#import "ETCompositeLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem.h"
#import "EtoileUIProperties.h"
#import "ETOutlineLayout.h"
#import "ETTableLayout.h"
#import "ETUIItemFactory.h"
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
	NSArray *descendants = [itemGroup itemsIncludingAllDescendants];

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
	self = [super initWithLayoutView: nil];

	if (self == nil)
		return nil;

	if (nil != rootItem)
	{
		[self setRootItem: rootItem];
	}
	else
	{
		[self setRootItem: [[ETUIItemFactory factory] itemGroup]];
	}
	[self setFirstPresentationItem: targetItem];

	return self;
}

DEALLOC(DESTROY(_rootItem); DESTROY(_targetItem));

/** Returns NO. */
- (BOOL) isScrollable
{
	return NO;
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
		BOOL isLayoutActive = (_layoutContext != nil);

		if (isLayoutActive)
		{
			// FIXME: Ugly cast
			[(ETLayoutItemGroup *)_layoutContext addItem: targetItem];
		}
		else
		{
			[[self rootItem] addItem: targetItem];
		}
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
	ETLayoutItemGroup *presentationProxy = [[ETUIItemFactory factory] itemGroupWithFrame: aRect];
	[presentationProxy setLayout: [ETOutlineLayout layout]];
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
		[dest setRepresentedPathBase: [item representedPathBase]];
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
		[properties addObjectsFromArray: A(@"items", kETSourceProperty)];
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
}

/* Layouting */

- (void) setUp
{
	[super setUp];

	[self saveInitialContextState: [self initialStateProperties]];
	[self prepareNewContextState];

	[_layoutContext setVisibleItems: [_layoutContext items]];
}

- (void) tearDown
{
	[super tearDown];

	[ETLayoutItemGroup disablesAutolayout];

	[self restoreContextState];
	[self restoreInitialContextState: [self initialStateProperties]];

	[_layoutContext setVisibleItems: [_layoutContext items]];

	[ETLayoutItemGroup enablesAutolayout];
}

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
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
