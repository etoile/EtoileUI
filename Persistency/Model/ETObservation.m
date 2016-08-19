/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2014
	License: Modified BSD (see COPYING)
 */

#import "ETObservation.h"
#import "ETCompatibility.h"

@interface ETCompositePropertyDescription : ETPropertyDescription
@end

@interface ETObservation ()
@property (nonatomic, retain) NSString *selectorName;
@end

@implementation ETObservation

@dynamic object, name, selectorName;

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add the 
	// property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETObservation className]] == NO)
		return entity;

	[entity setLocalizedDescription: _(@"Observation")];

	ETPropertyDescription *object =
        [ETCompositePropertyDescription descriptionWithName: @"object" typeName: @"COObject"];
    ETPropertyDescription *name =
        [ETPropertyDescription descriptionWithName: @"name" typeName: @"NSString"];
    ETPropertyDescription *selector =
        [ETPropertyDescription descriptionWithName: @"selector" typeName: @"SEL"];
    [selector setDerived: YES];
    ETPropertyDescription *selectorName =
        [ETPropertyDescription descriptionWithName: @"selectorName" typeName: @"NSString"];

    NSArray *persistentProperties = A(object, name, selectorName);
    NSArray *transientProperties = A(selector);

    [[persistentProperties mappedCollection] setPersistent: YES];

	[entity setPropertyDescriptions:
        [persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

/* At deserialization time, this ensures objects observing ETObservation.selector 
are notified. */
+ (NSSet *) keyPathsForValuesAffectingSelector
{
	return S(@"selectorName");
}

- (SEL) selector
{
    return NSSelectorFromString([self selectorName]);
}

- (void) setSelector: (SEL)aSelector
{
    [self willChangeValueForProperty: @"selector"];
    [self setSelectorName: NSStringFromSelector(aSelector)];
    [self didChangeValueForProperty: @"selector"];
}

@end
