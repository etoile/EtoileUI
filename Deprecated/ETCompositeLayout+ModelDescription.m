/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETLayout.h"
#import "ETCompositeLayout.h"
#import "ETPaneLayout.h"
// FIXME: Move related code to the Appkit widget backend (perhaps in a category)
#import "ETWidgetBackend.h"

@interface ETCompositeLayout (ModelDescription)
@end

@interface ETPaneLayout (ModelDescription)
@end
@interface ETCompositePropertyDescription : ETPropertyDescription
@end

@implementation ETCompositePropertyDescription

- (BOOL) isComposite
{
    return YES;
}

@end

@implementation ETCompositeLayout (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETCompositeLayout className]] == NO)
		return entity;

    // FIXME: Support 'composite' behavior without ETCompositePropertyDescription.
	ETPropertyDescription *rootItem =
		[ETCompositePropertyDescription descriptionWithName: @"rootItem" type: (id)@"ETLayoutItemGroup"];
    ETPropertyDescription *firstPresentationItem =
        [ETPropertyDescription descriptionWithName: @"firstPresentationItem" type: (id)@"ETLayoutItemGroup"];
    ETPropertyDescription *isContentRouted =
        [ETPropertyDescription descriptionWithName: @"isContentRouted" type: (id)@"BOOL"];
    [isContentRouted setDerived: YES];
    ETPropertyDescription *holderItem =
        [ETPropertyDescription descriptionWithName: @"holderItem" type: (id)@"ETLayoutItemGroup"];
    [holderItem setDerived: YES];

	NSArray *persistentProperties = A(rootItem, firstPresentationItem);
    NSArray *transientProperties = A(isContentRouted, holderItem);

	[entity setUIBuilderPropertyNames: (id)[[persistentProperties mappedCollection] name]];
	
	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions:
        [persistentProperties arrayByAddingObjectsFromArray: transientProperties]];
	
	return entity;
}

@end


@implementation ETPaneLayout (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
    ETEntityDescription *entity = [self newBasicEntityDescription];
    
    // For subclasses that don't override -newEntityDescription, we must not add
    // the property descriptions that we will inherit through the parent
    if ([[entity name] isEqual: [ETPaneLayout className]] == NO)
        return entity;
    
    ETPropertyDescription *contentItem =
        [ETPropertyDescription descriptionWithName: @"contentItem" type: (id)@"ETLayoutItemGroup"];
    ETPropertyDescription *barItem =
        [ETPropertyDescription descriptionWithName: @"barItem" type: (id)@"ETLayoutItemGroup"];
    ETPropertyDescription *currentItem =
        [ETPropertyDescription descriptionWithName: @"currentItem" type: (id)@"ETLayoutItem"];
    ETPropertyDescription *barPosition =
        [ETPropertyDescription descriptionWithName: @"barPosition" type: (id)@"NSUInteger"];
    ETPropertyDescription *barThickness =
        [ETPropertyDescription descriptionWithName: @"barThickness" type: (id)@"CGFloat"];
    ETPropertyDescription *ensuresContentFillsVisibleArea =
        [ETPropertyDescription descriptionWithName: @"ensuresContentFillsVisibleArea" type: (id)@"BOOL"];
    ETPropertyDescription *backItem =
        [ETPropertyDescription descriptionWithName: @"backItem" type: (id)@"ETLayoutItem"];
    [backItem setDerived: YES];
    ETPropertyDescription *forwardItem =
        [ETPropertyDescription descriptionWithName: @"forwardItem" type: (id)@"ETLayoutItem"];
    [forwardItem setDerived: YES];

    NSArray *persistentProperties = A(contentItem, barItem, currentItem,
        barPosition, barThickness, ensuresContentFillsVisibleArea);
    NSArray *transientProperties = A(backItem, forwardItem);
    
    [entity setUIBuilderPropertyNames: (id)[[persistentProperties mappedCollection] name]];
    
    [[persistentProperties mappedCollection] setPersistent: YES];
    [entity setPropertyDescriptions:
        [persistentProperties arrayByAddingObjectsFromArray: transientProperties]];
    
    return entity;
}

@end
