/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import "ETActionHandler.h"
#import "ETSelectTool.h"

@interface ETSelectTool (CoreObject)
@end

@implementation ETSelectTool (CoreObject)

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];

	ETActionHandler *actionHandler =
		AUTORELEASE([[ETActionHandler alloc] initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]]);

	ASSIGN(_actionHandlerPrototype, actionHandler);
}

@end