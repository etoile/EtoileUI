/**
	<abstract>A place to regroup aspect categories.</abstract>

	Copyright (C) 20010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2010
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETAspectCategory.h>
#import <EtoileUI/ETActionHandler.h>

/** @group Aspect Repository

An aspect repository regroups various aspect categories together.

An aspect repository is technically a special aspect category where the allowed 
aspects are restricted ETAspectCategory objects.

You shouldn't use the superclass API to interact with a repository. */
@interface ETAspectRepository : ETAspectCategory
{

}
/** @taskunit Initialization */

+ (id) mainRepository;

/** @taskunit Accessing and Managing Categories */

- (id) aspectCategoryNamed: (NSString *)aName;
- (void) addAspectCategory: (ETAspectCategory *)aCategory;
- (void) removeAspectCategory: (ETAspectCategory *)aCategory;
- (NSArray *) categoryNames;

@end


@interface ETAspectTemplateActionHandler : ETActionHandler
@end
