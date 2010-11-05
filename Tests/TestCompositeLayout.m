/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import "ETCompositeLayout.h"
#import "ETFixedLayout.h"
#import "ETGeometry.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETPaneLayout.h"
#import "ETTableLayout.h"
#import "ETUIItem.h"
#import "ETLayoutItemFactory.h"
#import "ETCompatibility.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))
#define SA(x) [NSSet setWithArray: x]

@interface TestCompositeLayout : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItemGroup *item;
}

@end


@implementation TestCompositeLayout

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	item = [[ETLayoutItemGroup alloc] init];
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item))

- (NSRect) proxyFrame
{
	return NSMakeRect(0, 0, [item width] / 2, [item height] / 2);
}

- (ETCompositeLayout *) createLayout
{
	ETLayoutItemGroup *proxy = [ETCompositeLayout defaultPresentationProxyWithFrame: [self proxyFrame]];
	ETLayoutItemGroup *rootItem = [itemFactory itemGroup];

	[rootItem setFlipped: NO]; /* We want to test how -isFlipped is sync */

	return AUTORELEASE([[ETCompositeLayout alloc] initWithRootItem: rootItem firstPresentationItem: proxy]);
}

- (void) testSyncFlipped
{
	NSArray *content = A([itemFactory verticalSlider], [itemFactory oval], [itemFactory textField]);
	ETCompositeLayout *compositeLayout = [self createLayout];
	ETLayoutItemGroup *rootItem = [compositeLayout rootItem];

	UKFalse([rootItem isFlipped]);
	UKTrue([item isFlipped]);

	[item addItems: content];
	[item setLayout: compositeLayout];

	UKFalse([rootItem isFlipped]);
	UKFalse([item isFlipped]);

	[item setLayout: [ETFixedLayout layout]];

	UKFalse([rootItem isFlipped]);
	UKTrue([item isFlipped]);
}

- (void) testSetUpCompositeLayout
{
	ETCompositeLayout *layout = [self createLayout];
	ETLayoutItemGroup *proxyItem = [layout firstPresentationItem];
	ETTableLayout *proxyLayout = (ETTableLayout *)[proxyItem layout];
	NSArray *content = A([itemFactory verticalSlider], [itemFactory oval], [itemFactory textField]);

	[item addItems: content];
	[item setLayout: layout];

	UKIntsEqual(3, [[proxyLayout tableView] numberOfRows]);
	UKNotNil([item supervisorView]);
	// TODO: Next line could be UKTrue([[item supervisorView] containsObject: [proxyItem supervisorView]]);
	UKTrue([[[item supervisorView] subviews] containsObject: [proxyItem supervisorView]]);
	UKObjectsEqual([proxyItem supervisorView], [[proxyLayout layoutView] superview]);
}

- (void) testPrepareNewContextStateWithStaticItemTree
{
	NSArray *content = A([itemFactory verticalSlider], [itemFactory oval], [itemFactory textField]);

	[item addItems: content];
	[item setLayout: [self createLayout]];

	ETLayoutItemGroup *proxyItem = [(id)[item layout] firstPresentationItem];
	UKObjectsEqual(proxyItem, [item firstItem]);
	UKObjectsEqual(content, [proxyItem items]);
	UKNil([proxyItem source]);
	UKNil([proxyItem representedObject]);
	UKObjectsEqual(A(proxyItem), [item items]);
	UKNil([item source]);
	UKNil([item representedObject]);
}

- (void) testRestoreContextStateWithStaticItemTree
{
	NSArray *content = A([itemFactory verticalSlider], [itemFactory oval], [itemFactory textField]);
	ETCompositeLayout *compositeLayout = [self createLayout];

	[item addItems: content];
	[item setLayout: compositeLayout];
	[item setLayout: [ETFixedLayout layout]];

	ETLayoutItemGroup *proxyItem = [compositeLayout firstPresentationItem];
	// TODO: May be we should ensure that UKTrue([proxyItem isEmpty]);
	UKNil([proxyItem source]);
	UKNil([proxyItem representedObject]);
	UKObjectsEqual(content, [item items]);
	UKNil([item source]);
	UKNil([item representedObject]);
}

- (id) modelContent
{
	return A(@"Azalea",@"Rudbeckia", @"Camomile");
}

- (void) testPrepareNewContextStateWithRepresentedObjectProvider
{
	[item setRepresentedObject: [self modelContent]];
	[item setSource: item];
	[item setLayout: [self createLayout]];

	ETLayoutItemGroup *proxyItem = [(id)[item layout] firstPresentationItem];
	UKObjectsEqual(proxyItem, [item firstItem]);
	UKObjectsEqual([self modelContent], [[[proxyItem items] mappedCollection] representedObject]);
	UKObjectsEqual(proxyItem, [proxyItem source]);
	UKObjectsEqual([self modelContent], [proxyItem representedObject]);
	UKObjectsEqual(A(proxyItem), [item items]);
	UKNil([item source]);
	UKNil([item representedObject]);
}

- (void) testRestoreContextStateWithRepresentedObjectProvider
{
	ETCompositeLayout *compositeLayout = [self createLayout];

	[item setRepresentedObject: [self modelContent]];
	[item setSource: item];
	[item setLayout: compositeLayout];
	[item setLayout: [ETFixedLayout layout]];

	ETLayoutItemGroup *proxyItem = [compositeLayout firstPresentationItem];
	// TODO: May be we should ensure that UKTrue([proxyItem isEmpty]);
	UKNil([proxyItem source]);
	UKNil([proxyItem representedObject]);
	UKObjectsEqual([self modelContent], [[[item items] mappedCollection] representedObject]);
	UKObjectsEqual(item, [item source]);
	UKObjectsEqual([self modelContent], [item representedObject]);
}

/* We implement a basic index-based source protocol to be able to use 
   TestCompositeLayout instances like that [item setSource: self]. */

- (int) baseItem: (ETLayoutItemGroup *)baseItem numberOfItemsInItemGroup: (ETLayoutItemGroup *)itemGroup
{
	return 3;
}

- (ETLayoutItem *) baseItem: (ETLayoutItemGroup *)baseItem 
                itemAtIndex: (int)index
                inItemGroup: (ETLayoutItemGroup *)itemGroup
{
	return [itemFactory itemWithRepresentedObject: [[self modelContent] objectAtIndex: index]];	
}

- (void) testPrepareNewContextStateWithSourceProvider
{
	[item setRepresentedPathBase: @"/whatever/bla"];
	[item setSource: self];
	[item setLayout: [self createLayout]];

	ETLayoutItemGroup *proxyItem = [(id)[item layout] firstPresentationItem];
	UKObjectsEqual(proxyItem, [item firstItem]);
	UKObjectsEqual([self modelContent], [[[proxyItem items] mappedCollection] representedObject]);
	UKObjectsEqual(self, [proxyItem source]);
	UKNil([proxyItem representedObject]);
	UKStringsEqual(@"/whatever/bla", [proxyItem representedPathBase]);
	UKObjectsEqual(A(proxyItem), [item items]);
	UKNil([item source]);
	UKNil([item representedObject]);
	// NOTE: May be we should have UKNil([item representedPathBase]);
}

- (void) testRestoreContextStateWithSourceProvider
{
	ETCompositeLayout *compositeLayout = [self createLayout];

	[item setRepresentedPathBase: @"/whatever/bla"];
	[item setSource: self];
	[item setLayout: compositeLayout];
	[item setLayout: [ETFixedLayout layout]];

	ETLayoutItemGroup *proxyItem = [compositeLayout firstPresentationItem];
	// TODO: May be we should ensure that UKTrue([proxyItem isEmpty]);
	UKNil([proxyItem source]);
	UKNil([proxyItem representedObject]);
	UKNil([proxyItem representedPathBase]);
	UKObjectsEqual([self modelContent], [[[item items] mappedCollection] representedObject]);
	UKObjectsEqual(self, [item source]);
	UKNil([item representedObject]);
	UKStringsEqual(@"/whatever/bla", [item representedPathBase]);
}

@end


@interface TestPaneLayout : TestCompositeLayout
{
	ETPaneLayout *layout;
	ETLayoutItemGroup *barItem;
	ETLayoutItem *sliderItem;
	ETLayoutItem *textFieldItem;
	ETLayoutItem *ovalItem;
}

@end

@implementation TestPaneLayout

- (id) init
{
	SUPERINIT

	[item setAutolayout: NO];
	ASSIGN(layout, [ETPaneLayout masterDetailLayout]);
	barItem = [layout barItem]; /* layout will retains us */

	return self;	
}

DEALLOC(DESTROY(layout))

- (void) setUpLayout
{
	sliderItem = [itemFactory verticalSlider];
	textFieldItem = [itemFactory textField];
	ovalItem = [itemFactory oval];
	[item addItems: A(sliderItem, textFieldItem, ovalItem)];
	[item setLayout: layout];
}

- (void) testInit
{
	UKObjectsEqual(S(barItem, [layout contentItem]), SA([[layout rootItem] items]));
	UKObjectsEqual([layout firstPresentationItem], barItem);
}

- (void) testSetUp
{
	[self setUpLayout];

	UKTrue([[layout rootItem] isEmpty]);
	UKObjectsEqual(S(barItem, [layout contentItem]), SA([item items]));
	UKObjectsEqual([layout firstPresentationItem], barItem);

	UKIntsEqual(3, [barItem numberOfItems]);
	UKObjectsEqual(barItem, [[barItem firstItem] parentItem]);
	UKTrue([[layout contentItem] isEmpty]);
}

- (void) testUpdateLayout
{
	[self setUpLayout];

	 /* Forces layout update (currently disabled) but only in 'item' and not 
	    'contentItem' and 'barItem' children. Will invoke -goToItem:. */
	[layout render: nil isNewContent: YES];

	UKObjectsEqual(A(sliderItem), [[layout contentItem] items]);
	UKObjectsEqual([layout contentItem], [sliderItem parentItem]);
}

- (void) testVisitingItem
{
	[self setUpLayout];

	ETLayoutItem *sliderItemProxy = [layout beginVisitingItem: sliderItem];

	UKObjectsEqual(sliderItem, [sliderItemProxy representedObject]);
	UKObjectsEqual(A(sliderItemProxy, textFieldItem, ovalItem), [barItem items]);

	[layout endVisitingItem: sliderItemProxy];

	UKObjectsEqual(A(sliderItem, textFieldItem, ovalItem), [barItem items]);
	UKObjectsEqual(barItem, [sliderItem parentItem]);

	ETLayoutItem *ovalItemProxy = [layout beginVisitingItem: ovalItem];

	UKObjectsEqual(ovalItem, [ovalItemProxy representedObject]);
	UKObjectsEqual(A(sliderItem, textFieldItem, ovalItemProxy), [barItem items]);
	UKObjectsEqual(barItem, [ovalItemProxy parentItem]);
}

- (void) testInvalidGoToItem
{
	[self setUpLayout];

	UKTrue([layout goToItem: sliderItem]);
	UKTrue([layout goToItem: sliderItem]);
	UKTrue([layout goToItem: [layout currentItem]]);
	UKFalse([layout goToItem: [itemFactory item]]);
	UKFalse([layout goToItem: nil]);
}

- (void) testGoToItem
{
	[self setUpLayout];

	[layout goToItem: sliderItem];
	ETLayoutItem *sliderItemProxy = [barItem firstItem];

	UKObjectsEqual(sliderItemProxy, [layout currentItem]);
	UKObjectsEqual(A(sliderItem), [[layout contentItem] items]);
	UKObjectsEqual(A(sliderItemProxy, textFieldItem, ovalItem), [barItem items]);

	[layout goToItem: textFieldItem];
	ETLayoutItem *textFieldItemProxy = [barItem itemAtIndex: 1];

	UKObjectsEqual(textFieldItemProxy, [layout currentItem]);
	UKObjectsEqual(A(textFieldItem), [[layout contentItem] items]);
	UKObjectsEqual(A(sliderItem, textFieldItemProxy, ovalItem), [barItem items]);

	[layout goToItem: sliderItem];
	sliderItemProxy = [barItem firstItem];

	UKObjectsEqual(sliderItemProxy, [layout currentItem]);
	UKObjectsEqual(A(sliderItem), [[layout contentItem] items]);
	UKObjectsEqual(A(sliderItemProxy, textFieldItem, ovalItem), [barItem items]);

	[layout goToItem: ovalItem];
	ETLayoutItem *ovalItemProxy = [barItem lastItem];

	UKObjectsEqual(ovalItemProxy, [layout currentItem]);
	UKObjectsEqual(A(ovalItem), [[layout contentItem] items]);
	UKObjectsEqual(A(sliderItem, textFieldItem, ovalItemProxy), [barItem items]);
}

@end
