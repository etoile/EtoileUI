/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2008
	License:  Modified BSD (see COPYING)
 */
 
#import "TestCommon.h"
#import "ETColumnLayout.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutExecutor.h"
#import "ETTableLayout.h"
#import "ETCompatibility.h"

@interface ETLayout (Private)
+ (NSString *) stripClassName;
+ (NSString *) displayName;
+ (NSString *) aspectName;
@end

@interface ETLayout (UnitKitTests) <UKTest>
@end

/* Dummy class for testing */
@interface WXYBirdTableBirdBird : ETLayout
@end

@implementation WXYBirdTableBirdBird
+ (NSString *) typePrefix {	return @"WXY"; }
+ (NSString *) baseClassName { return @"Bird"; }
@end


@implementation ETLayout (UnitKitTests)

+ (void) testDisplayName
{
	UKStringsEqual(@"Layout", [self displayName]);
	UKStringsEqual(@"Table Layout", [ETTableLayout displayName]);
	UKStringsEqual(@"Bird Table Bird Bird", [WXYBirdTableBirdBird displayName]);
}

+ (void) testStripClassName
{
	UKStringsEqual(@"Layout", [self stripClassName]);
	UKStringsEqual(@"Table", [ETTableLayout stripClassName]);
	UKStringsEqual(@"BirdTableBird", [WXYBirdTableBirdBird stripClassName]);
}

+ (void) testAspectName
{
	UKStringsEqual(@"layout", [self aspectName]);
	UKStringsEqual(@"table", [ETTableLayout aspectName]);
	UKStringsEqual(@"birdTableBird", [WXYBirdTableBirdBird aspectName]);
}

@end


@interface TestPositionalLayout : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItemGroup *itemGroup;
	ETLayoutItem *item;
}

@end

@implementation  TestPositionalLayout

- (id) init
{
	[[ETLayoutExecutor sharedInstance] removeAllItems];
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(itemGroup, [itemFactory itemGroup]);
	ASSIGN(item, [itemFactory item]);
	return self;
}

- (void) dealloc
{
	DESTROY(itemFactory);
	DESTROY(itemGroup);
	DESTROY(item);
	[super dealloc];
}

- (void) testUpsizedItemForContentSizeLayout
{
	ETColumnLayout *layout = [ETColumnLayout layoutWithObjectGraphContext: [itemGroup objectGraphContext]];
	
	[[layout positionalLayout] setIsContentSizeLayout: YES];
	[itemGroup setLayout: layout];

	ETLayoutItem *textItem = [itemFactory textField];

	[item setWidth: 700];
	[textItem setHeight: 500];

	CGFloat width = MAX([item width], [textItem width]);
	CGFloat height = [item height] + [textItem height];
	NSSize contentSize = NSMakeSize(width, height);

	[itemGroup addItems: A(item, textItem)];
	
	[[ETLayoutExecutor sharedInstance] execute];

	UKSizesEqual(contentSize, [layout layoutSize]);
	UKSizesEqual(contentSize, [itemGroup size]);
}

- (void) testDownsizedItemForContentSizeLayout
{
	ASSIGN(itemGroup, [itemFactory itemGroupWithSize: NSMakeSize(10000, 10000)]);
	[self testUpsizedItemForContentSizeLayout];
}

@end
