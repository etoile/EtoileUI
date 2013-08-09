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
@end

@implementation ETShape (CoreObject)

- (NSString *) serializedPathResizeSelector
{
	return NSStringFromSelector([self pathResizeSelector]);
}

- (void) setSerializedPathResizeSelector: (NSString *)aSelString
{
	[self setPathResizeSelector: NSSelectorFromString(aSelString)];
}

@end

#endif
