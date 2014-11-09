/**
	<abstract>Allows to schedule and execute automatic layout updates.</abstract>
 
	Copyright (C) 2011 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  February 2011
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>

@class ETLayoutItemGroup;


@interface ETLayoutExecutor : NSObject
{
	@private
	NSMutableSet *_scheduledItems;
}

/** @taskunit Singleton Access */

+ (id) sharedInstance;

/** @taskunit Scheduling Items */

- (void) addItem: (ETLayoutItemGroup *)anItem;
- (void) removeItem: (ETLayoutItemGroup *)anItem;
- (void) removeItems: (NSSet *)items;
- (void) removeAllItems;
- (BOOL) containsItem: (ETLayoutItemGroup *)anItem;
- (BOOL) isEmpty;

/** @taskunit Executing Layout Updates */

- (void) execute;

@end
