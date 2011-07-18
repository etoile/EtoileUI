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
#import "ETLayout+CoreObject.h"


@implementation ETLayout (CoreObject)

- (void) becomePersistentInContext: (COEditingContext *)aContext rootObject: (COObject *)aRootObject
{
	[super becomePersistentInContext: aContext rootObject: aRootObject];

	// TODO: Leverage the model description rather than hardcoding the aspects
	// TODO: Implement some strategy to recover in the case these aspects 
	// are already used as embedded objects in another root object. 
	//ETAssert([[self dropIndicator] isPersistent] == NO || [[self dropIndicator] isRoot]);
	//[[self dropIndicator] becomePersistentInContext: aContext rootObject: aRootObject];
}

@end

#endif
