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
#import "ETLayoutItemFactory.h"
#import "ETTool.h"

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


@class ETTool;

@interface TestCommon : NSObject
{
	ETLayoutItemFactory *itemFactory;
	ETTool *previousActiveTool;
}

@end


/** Use EVT() to create an event with a point expressed in the main item coordinates. 
The main item is the window content. */
#define CLICK_EVT(x, y, clicks) (id)[self createEventAtContentPoint: NSMakePoint(x, y) clickCount: clicks inWindow: [self window]]
#define EVT(x, y) CLICK_EVT(x, y, 1)

@interface TestEvent : TestCommon
{
	ETLayoutItemGroup *mainItem;
	id tool;
}

- (ETEvent *) createEventAtPoint: (NSPoint)loc clickCount: (NSUInteger)clickCount inWindow: (NSWindow *)win;
- (ETEvent *) createEventAtContentPoint: (NSPoint)loc clickCount: (NSUInteger)clickCount inWindow: (NSWindow *)win;
- (NSWindow *) window;
- (ETEvent *) createEventAtScreenPoint: (NSPoint)loc isFlipped: (BOOL)flip;

@end


@interface ETTool (ETToolTestAdditions)
+ (id) tool;
@end
