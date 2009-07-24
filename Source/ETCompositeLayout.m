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
#import "ETUIItemFactory.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETTableLayout.h"
#import "ETOutlineLayout.h"
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

	[self setRootItem: rootItem];
	[self setFirstPresentationItem: targetItem];

	return self;
}

DEALLOC(DESTROY(_rootItem); DESTROY(_targetItem));

/** Sets the root item to which items that makes up the composite layout belong 
to. 

The first presentation item will be reset to nil. You should usually update it 
immediately.

This method removes the action handler on the root item.

You must no call this method when the layout is currently in use, otherwise 
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

/** Returns the layout item to which the layout context content can be routed. 

If the given item has no parent item*/
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

- (BOOL) isStaticItemTree: (ETLayoutItemGroup *)anItem
{
	return ([anItem source] == nil);
}

- (void) moveContentFromItem: (ETLayoutItemGroup *)item
                      toItem: (ETLayoutItemGroup *)dest
{
	[dest removeAllItems];

	if ([self isStaticItemTree: item])
	{
		[dest addItems: [item items]];
	}
	else
	{
		[dest setSource: [item source]];
		[item setSource: nil];

		[item removeAllItems];
	}

	NSParameterAssert([item isEmpty]);
}

/** Returns a new item to which the children of the given item group will be 
routed to inside the receiver. */
- (id) presentationProxyWithItem: (ETLayoutItemGroup *)item
{
	ETLayoutItemGroup *presentationProxy = [self firstPresentationItem];

	if (presentationProxy == nil)
		return nil;
	
	[self moveContentFromItem: item toItem: presentationProxy];

	return presentationProxy;
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
	[self setFirstPresentationItem: [self presentationProxyWithItem: _layoutContext]];
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
