/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObject.h>
#import "ETStyle+CoreObject.h"


@implementation ETStyleGroup (CoreObject)
@end

@implementation ETShape (CoreObject)

- (NSString *) serializedPathResizeSelector
{
	return NSStringFromSelector(_resizeSelector);
}

- (void) setSerializedPathResizeSelector: (NSString *)aSelString
{
	_resizeSelector = NSSelectorFromString(aSelString);
}

@end
