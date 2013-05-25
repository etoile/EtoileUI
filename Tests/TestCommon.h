/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>

#define SA(x) [NSSet setWithArray: x]

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))
#define UKSizesNotEqual(x, y) UKFalse(NSEqualSizes(x, y))

/* A simple model object for testing purpose */
@interface Person : NSObject
{
	NSString *_name;
	NSDictionary *_emails;
	NSArray *_groupNames;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, copy) NSDictionary *emails;
@property (nonatomic, retain) NSArray *groupNames;
@end
