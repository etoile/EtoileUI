/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObject.h>
#import "ETController+CoreObject.h"

@implementation ETController (CoreObject)

- (void) didLoadObjectGraph
{
	// TODO: We probably want to recreate the observations here (but we need to
	// declare them in the metamodel and serialize them). For now, it is the
	// developer responsability to use serialization setters that call the
	// setters using -stopObserveObjectForNotificationName: and
	// -startObserveObject:forNotificationName:selector:
}

@end

@implementation ETItemTemplate (CoreObject)
@end
