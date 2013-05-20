/*
	Copyright (C) 20010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2010
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ETAspectRepository.h"
#import "ETCompatibility.h"


@implementation ETAspectRepository

static ETAspectRepository *mainRepo = nil;

+ (void) initialize
{
	if (self != [ETAspectRepository  class])
		return;

	mainRepo = [[[self class] alloc] initWithName: _(@"Main")];
}

/** Returns the main aspect repository persistent and shared between processes (not yet). */
+ (id) mainRepository
{
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

/** Returns NO. */
- (BOOL) isKeyed
{
	return NO;
}

@end
