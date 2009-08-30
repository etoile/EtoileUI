/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2009
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/ETUTI.h>
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

- (NSArray *) nonCheckablePropertiesForAnyObject
{
	NSArray *rootObjectProperties = [(NSObject *)AUTORELEASE([[NSObject alloc] init]) properties];
	return [rootObjectProperties arrayByRemovingObjectsInArray:
		A(kETNameProperty, kETDisplayNameProperty, kETIconProperty)];
}

- (NSArray *) checkablePropertiesForItem: (ETUIItem *)anItem
{
	NSArray *excludedProperties = [self nonCheckablePropertiesForAnyObject];
	return [[anItem properties] arrayByRemovingObjectsInArray: excludedProperties];
}

- (void) checkViewCopy: (ETView *)newView ofView: (ETView *)aView
{
	NSArray *equalProperties = A(@"x", @"y", @"width", @"height", @"tag", 
		@"hidden", @"autoresizingMask", @"autoresizesSubviews", @"flipped", 
		@"frame", @"frameRotation", @"bounds", @"boundsRotation", 
		@"isRotatedFromBase", @"isRotatedOrScaledFromBase", 
		@"postsFrameChangedNotifications", @"postsBoundsChangedNotifications", 
		@"visibleRect", @"opaque", @"needsPanelToBecomeKey"); 

	FOREACH(equalProperties, property, NSString *)
	{
		/* We could use -valueForKey: as well */
		id value = [aView valueForProperty: property];
		id copiedValue = [newView valueForProperty: property];
		if ([value isEqual: copiedValue] == NO)
		{
			NSLog(@"Fail!!!");
		}
		UKObjectsEqual(value, copiedValue);
	}
}

- (void) testBasicItemCopy
{
	NSArray *properties = [self checkablePropertiesForItem: item];
	NSArray *nilProperties = A(kETNameProperty, kETIconProperty, kETImageProperty,
		kETRepresentedObjectProperty, kETRepresentedPathBaseProperty, 
		kETSubtypeProperty, kETActionProperty, kETTargetProperty);
	NSArray *nonEqualProperties = A(kETDisplayNameProperty, 
		kETDecoratorItemProperty, kETDecoratedItemProperty, @"firstDecoratedItem", 
		@"lastDecoratorItem", @"enclosingItem", @"supervisorView", kETViewProperty,
		kETParentItemProperty, kETStyleGroupProperty, kETLayoutProperty);
	NSArray *equalProperties = [properties arrayByRemovingObjectsInArray: 
		[nonEqualProperties arrayByAddingObjectsFromArray: nilProperties]];

	ETLayoutItem *newItem = [item copy];

	FOREACH(equalProperties, property, NSString *)
	{
		/* We could use -valueForKey: as well, see -testItemCopy */
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
	[item setName: @"Whatever"];
	[item setImage: [NSImage imageNamed: @"NSApplicationIcon"]];
	[item setIcon: [[NSWorkspace sharedWorkspace] iconForFile: @"/"]];
	[item setRepresentedObject: [NSSet set]];
	//[item setRepresentedPathBase: @"/my/model/path"];
	[item setSubtype: [ETUTI typeWithClass: [NSSet class]]];
	//[item setController: AUTORELEASE([[ETController alloc] init])];
	[item setTarget: self];
	[item setAction: @selector(wibble:)];
	[item setView: AUTORELEASE([[NSButton alloc] init])];

	NSArray *properties = [self checkablePropertiesForItem: item];
	NSArray *nilProperties = A(kETRepresentedPathBaseProperty);
	NSArray *nonEqualProperties = A(kETDisplayNameProperty, 
		kETDecoratorItemProperty, kETDecoratedItemProperty, @"firstDecoratedItem", 
		@"lastDecoratorItem", @"enclosingItem", @"supervisorView", kETViewProperty,
		kETParentItemProperty, kETStyleGroupProperty, kETLayoutProperty);
	NSArray *equalProperties = [properties arrayByRemovingObjectsInArray: 
		[nonEqualProperties arrayByAddingObjectsFromArray: nilProperties]];

	ETLayoutItem *newItem = [item copy];

	FOREACH(equalProperties, property, NSString *)
	{
		/* We don't want to check the properties on the represented object but 
		   on the item itself, so we must use -valueForKey: which has no custom 
		   lookup policy on the represented object unlike -valueForProperty:. */
		id value = [item valueForKey: property];
		id copiedValue = [newItem valueForKey: property];

		if ([value isEqual: copiedValue] == NO)
		{
			NSLog(@"Fail!!!");
		}
		UKObjectsEqual(value, copiedValue);
	}

	UKNil([newItem decoratorItem]);
	UKNil([newItem decoratedItem]);
	UKObjectsEqual([[newItem supervisorView] class], [[item supervisorView] class]);
	UKNil([newItem parentItem]);
	// TODO: Set a layout and UKNotNil([newItem layout]);
	UKObjectsEqual([[newItem view] class], [[item view] class]);

	[self checkViewCopy: [newItem supervisorView] ofView: [item supervisorView]];
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
