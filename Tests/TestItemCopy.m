/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2009
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETDecoratorItem.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "EtoileUIProperties.h"
#import "ETScrollableAreaItem.h"
#import "ETUIItem.h"
#import "ETUIItemFactory.h"
#import "ETWindowItem.h"
#import "ETCompatibility.h"


@interface TestItemCopy: NSObject <UKTest>
{
	ETUIItemFactory *itemFactory;
	ETLayoutItem *item;
}

@end

@implementation TestItemCopy

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETUIItemFactory factory]);
	item = [[ETLayoutItem alloc] init];
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item))

- (void) testBasicItemCopy
{
	ETLayoutItem *newItem = [item copy];
	NSArray *rootObjectProperties = [(NSObject *)AUTORELEASE([[NSObject alloc] init]) properties];
	NSArray *excludedProperties = [rootObjectProperties arrayByRemovingObjectsInArray:
		A(kETNameProperty, kETDisplayNameProperty, kETIconProperty)];
	NSArray *properties = [[item properties] arrayByRemovingObjectsInArray: excludedProperties];
	NSArray *nilProperties = A(kETNameProperty, kETIconProperty, kETImageProperty,
		kETRepresentedObjectProperty, kETRepresentedPathBaseProperty, 
		kETSubtypeProperty, kETActionProperty, kETTargetProperty);
	NSArray *nonEqualProperties = A(kETDisplayNameProperty, 
		kETDecoratorItemProperty, kETDecoratedItemProperty, @"firstDecoratedItem", 
		@"lastDecoratorItem", @"enclosingItem", @"supervisorView", kETViewProperty,
		kETParentItemProperty, kETStyleGroupProperty, kETLayoutProperty);
	NSArray *equalProperties = [properties arrayByRemovingObjectsInArray: 
		[nonEqualProperties arrayByAddingObjectsFromArray: nilProperties]];

	FOREACH(equalProperties, property, NSString *)
	{
		id value = [item valueForProperty: property];
		id copiedValue = [newItem valueForProperty: property];

		UKObjectsEqual(value, copiedValue);
	}

	UKNil([newItem decoratorItem]);
	UKNil([newItem decoratedItem]);
	UKNil([newItem supervisorView]);
	UKNil([newItem parentItem]);
	UKNil([newItem layout]);
	UKNil([newItem view]);
}

- (void) testItemCopy
{

}

- (void) testEmptyItemGroupCopy
{

}

- (void) testItemGroupCopy
{

}

- (void) testItemTreeCopy
{

}

@end
