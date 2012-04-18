/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"

#ifdef COREOBJECT

#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObject.h>
#import "ETStyle+CoreObject.h"


@implementation ETStyleGroup (CoreObject)

- (void) becomePersistentInContext: (COEditingContext *)aContext rootObject: (COObject *)aRootObject
{
	if ([self isPersistent])
		return;

	[super becomePersistentInContext: aContext rootObject: aRootObject];

	// TODO: Leverage the model description rather than hardcoding the aspects
	// TODO: Implement some strategy to recover in the case these aspects 
	// are already used as embedded objects in another root object. 
	for (ETStyle *style in _styles)
	{
		ETAssert([style isShared] || [style isPersistent] == NO || [style isRoot]);
		[style becomePersistentInContext: aContext rootObject: aRootObject];
	}

}

@end

@implementation ETShape (CoreObject)

- (NSValue *) serializedPathResizeSelector
{
	SEL sel = [self pathResizeSelector];
	return [NSValue valueWithBytes: &sel objCType: @encode(SEL)];
}

- (void) setSerializedPathResizeSelector: (NSValue *)value
{
	[self setPathResizeSelector: (SEL)[value pointerValue]];
}

@end

#endif
