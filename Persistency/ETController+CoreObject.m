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

@implementation ETController (CoreObject)

- (NSSet *) serializedObservations
{
    ETAssert(_observations != nil);
    NSSet *obs = [_observations mappedCollectionWithBlock: ^ (NSDictionary *observation)
    {
        ETUUID *observedUUID = [[observation objectForKey: @"object"] UUID];
        ETAssert(observedUUID != nil);

        return [observation dictionaryByAddingEntriesFromDictionary:
                D([observedUUID stringValue], @"object")];
    }];
    return obs;
 }

- (void) setSerializedObservations: (NSSet *)serializedObservations
{
    RELEASE(_observations);
    _observations = [serializedObservations mutableCopy];
}

- (void) finishDeserializingObservations
{
    [_observations mapWithBlock: ^ (NSDictionary *observation)
    {
        ETUUID *observedUUID = [ETUUID UUIDWithString: [observation objectForKey: @"object"]];
        COObject *observedObject = [[self objectGraphContext] loadedObjectForUUID: observedUUID];
    
        return [observation dictionaryByAddingEntriesFromDictionary: D(observedObject, @"object")];
    }];
}

- (void) recreateObservations
{
    [self finishDeserializingObservations];

    for (NSDictionary *observation in _observations)
    {
        NSString *name = [observation objectForKey: @"name"];
        name = ([name isEqual: [NSNull null]] ? nil : name);
        SEL selector = NSSelectorFromString([observation objectForKey: @"selector"]);
        COObject *object = [observation objectForKey: @"object"];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: selector
                                                     name: name
	                                               object: object];
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
