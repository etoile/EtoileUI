/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"

#ifdef OBJECTMERGING

#import <ObjectMerging/COEditingContext.h>
#import <ObjectMerging/COObject.h>
#import "ETController+CoreObject.h"


@implementation ETController (CoreObject)

- (void) becomePersistentInContext: (COEditingContext *)aContext rootObject: (COObject *)aRootObject
{
	[super becomePersistentInContext: aContext rootObject: aRootObject];

	// TODO: Support item template persistency
	// TODO: Implement some strategy to recover in the case these items or aspects
	// are already used as embedded objects in another root object.
}

@end

#endif
