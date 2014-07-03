/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObject.h>
#import <CoreObject/COObjectGraphContext.h>
#import "ETController+CoreObject.h"
#import "ETObservation.h"

@implementation ETController (CoreObject)

- (void) recreateObservations
{
    for (ETObservation *observation in _observations)
    {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: [observation selector]
                                                     name: [observation name]
	                                               object: [observation object]];
    }
}

- (void) awakeFromDeserialization
{
    _hasNewSortDescriptors = (NO == [_sortDescriptors isEmpty]);
    _hasNewFilterPredicate = (nil != _filterPredicate);
    _hasNewContent = NO;
}

- (void) didLoadObjectGraph
{
    [self recreateObservations];
}

@end

@implementation ETItemTemplate (CoreObject)
@end
