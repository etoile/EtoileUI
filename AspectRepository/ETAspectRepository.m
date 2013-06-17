/*
	Copyright (C) 20010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2010
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ETAspectRepository.h"
#import "EtoileUIProperties.h"
#import "ETPickDropCoordinator.h"
#import "ETCompatibility.h"


@implementation ETAspectRepository

static ETAspectRepository *mainRepo = nil;

/** Returns the main aspect repository persistent and shared between processes (not yet). */
+ (id) mainRepository
{
	if (mainRepo == nil)
	{
		mainRepo = [[[self class] alloc] initWithName: _(@"Main")];
	}
	return mainRepo;
}

- (NSString *) displayName
{
	return [NSString stringWithFormat: @"%@ %@", [self name], _(@"Aspect Repository")];
}

/** Returns the category kown by the given name. */
- (id) aspectCategoryNamed: (NSString *)aName
{
	return [self aspectForKey: aName];
}

/** Adds the given category as a repository aspect.

The category name is used as the aspect key. */
- (void) addAspectCategory: (ETAspectCategory *)aCategory
{
	[self setAspect: aCategory forKey: [aCategory name]];
}

/** Removes the given category as a repository aspect.

The category name is used as the aspect key to lookup the category to be removed. */
- (void) removeAspectCategory: (ETAspectCategory *)aCategory
{
	[self removeAspectForKey: [aCategory name]];
}

/** Returns the names of all the categories. */
- (NSArray *) categoryNames
{
	return [self aspectKeys];
}

/** Returns NO.
 
This ensures the aspect repository doesn't return the aspect categories wrapped 
into key-value pairs bound to -[ETLayoutItemGroup items] (if the aspect 
repository is the item group represented object). */
- (BOOL) isKeyed
{
	return NO;
}

@end


@implementation ETAspectTemplateActionHandler

- (unsigned int) dragOperationMaskForDestinationItem: (ETLayoutItem *)item
                                         coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
	BOOL isDragInsideSource = (item != nil && [[item baseItem] isEqual: [aPickCoordinator dragSource]]);
	
	if (isDragInsideSource)
	{
		return NSDragOperationMove;
	}
	return NSDragOperationCopy;
}

- (BOOL) boxingForcedForDroppedItem: (ETLayoutItem *)droppedItem
                           metadata: (NSDictionary *)metadata
{
	return [[metadata objectForKey: kETPickMetadataWasUsedAsRepresentedObject] boolValue];
}

@end
