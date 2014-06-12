/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObject.h>
#import "ETTool+CoreObject.h"
#import "ETActionHandler.h"


@implementation ETSelectTool (CoreObject)

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];

	ETActionHandler *actionHandler =
		AUTORELEASE([[ETActionHandler alloc] initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]]);

	ASSIGN(_actionHandlerPrototype, actionHandler);
}

@end