/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2008
	License:  Modified BSD (see COPYING)
 */
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import "ETLayout.h"
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
	UKStringsEqual(@"", [self displayName]);
	UKStringsEqual(@"Table", [ETTableLayout displayName]);
	UKStringsEqual(@"Bird Table Bird", [WXYBirdTableBirdBird displayName]);
}

+ (void) testStripClassName
{
	UKStringsEqual(@"", [self stripClassName]);
	UKStringsEqual(@"Table", [ETTableLayout stripClassName]);
	UKStringsEqual(@"BirdTableBird", [WXYBirdTableBirdBird stripClassName]);
}

+ (void) testAspectName
{
	UKStringsEqual(@"", [self aspectName]);
	UKStringsEqual(@"table", [ETTableLayout aspectName]);
	UKStringsEqual(@"birdTableBird", [WXYBirdTableBirdBird aspectName]);
}

@end
