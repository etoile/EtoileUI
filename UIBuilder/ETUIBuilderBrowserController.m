/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETUIBuilderBrowserController.h"
#import "ETLayoutItemGroup.h"

@implementation ETUIBuilderBrowserController

- (ETUIBuilderController *) parentController
{
	return (ETUIBuilderController *)[[[[self content] parentItem] controllerItem] controller];
}

- (id <ETUIBuilderEditionCoordinator>) editionCoordinator
{
	return (id)[self parentController];
}

- (void) subjectDidBeginEditingForItem: (ETLayoutItem *)anItem property: (NSString *)aKey
{
	[(id)[self editionCoordinator] subjectDidBeginEditingForItem: anItem property: aKey];
}

- (void) subjectDidChangeValueForItem: (ETLayoutItem *)anItem property: (NSString *)aKey
{
	[(id)[self editionCoordinator] subjectDidChangeValueForItem: anItem property: aKey];
}

- (void) subjectDidEndEditingForItem: (ETLayoutItem *)anItem property: (NSString *)aKey
{
	[[self parentController] subjectDidEndEditingForItem: anItem property: aKey];
}

@end
