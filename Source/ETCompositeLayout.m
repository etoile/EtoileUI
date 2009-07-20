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
	return nil;
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

	ASSIGN(_rootItem, rootItem);
	[self setFirstPresentationItem: targetItem];

	return self;
}

DEALLOC(DESTROY(_rootItem); DESTROY(_targetItem));

- (id) firstPresentationItem
{
	return _targetItem;
}

- (void) setFirstPresentationItem: (ETLayoutItemGroup *)targetItem
{
	ASSIGN(_targetItem, targetItem);
}

/** Returns a new autoreleased presentation proxy which can be used as the first 
presentation item. */
- (id) defaultPresentationProxyWithFrame: (NSRect)aRect
{
	ETLayoutItemGroup *presentationProxy = [[ETLayoutItemGroup alloc] initWithFrame: aRect];//[[ETUIItemFactory factory] itemGroup];
	[presentationProxy setLayout: [ETOutlineLayout layout]];
	[presentationProxy setAutoresizingMask: NSViewWidthSizable];
	return presentationProxy;
}

- (void) moveContentFromItem: (ETLayoutItemGroup *)item
                      toItem: (ETLayoutItemGroup *)dest
{
	BOOL isStaticItemTree = ([item source] == nil);

	[dest removeAllItems];

	if (isStaticItemTree)
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

	if (nil == presentationProxy)
	{
 		presentationProxy = [self defaultPresentationProxyWithFrame: 
			ETMakeRect(NSZeroPoint, [item size])];
		[[self rootItem] addItem: presentationProxy];
	}

	[self moveContentFromItem: item toItem: presentationProxy];

	return presentationProxy;
}

- (void) restoreItemWithPresentationProxy: (ETLayoutItemGroup *)presentationProxy
{
	[self moveContentFromItem: presentationProxy toItem: _layoutContext];
}

/* Layouting */

- (void) setUp
{
	[super setUp];

	[self setFirstPresentationItem: [self presentationProxyWithItem: _layoutContext]];
	[self moveContentFromItem: [self rootItem] toItem: _layoutContext];
	[_layoutContext setVisibleItems: [_layoutContext items]];
}

- (void) tearDown
{
	[super tearDown];

	[self moveContentFromItem: _layoutContext toItem: [self rootItem]];
	[self restoreItemWithPresentationProxy: [self firstPresentationItem]];
	[_layoutContext setVisibleItems: [_layoutContext items]];
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
