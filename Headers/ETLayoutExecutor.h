/**
	<abstract>Allows to schedule and execute automatic layout updates.</abstract>
 
	Copyright (C) 2011 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  February 2011
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem;


@interface ETLayoutExecutor : NSObject
{
	@private
	NSMutableSet *_scheduledItems;
}

/** @taskunit Singleton Access */

+ (id) sharedInstance;

/** @taskunit Scheduling Items */

- (void) addItem: (ETLayoutItem *)anItem;
- (void) removeItem: (ETLayoutItem *)anItem;
- (void) removeItems: (NSSet *)items;
- (void) removeAllItems;
- (BOOL) isEmpty;

/** @taskunit Executing Layout Updates */

- (void) execute;

@end
