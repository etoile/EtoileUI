/*
	Copyright (C) 2013 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  January 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/NSString+Etoile.h>
#import <EtoileFoundation/Macros.h>
#import "ETLayoutItem+UIBuilder.h"
#import "EtoileUIProperties.h"
#import "ETController.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETView.h"
#import "NSObject+EtoileUI.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"


@implementation ETLayoutItem (UIBuilder)

- (NSString *) UIBuilderAction
{
	return NSStringFromSelector([self action]);
}

- (void) setUIBuilderAction: (NSString *)aString
{
	[self setAction: NSSelectorFromString(aString)];
}

- (id)UIBuilderWidgetElement
{
	return ([self view] != nil ? [self view] : self);
}

- (void)setUIBuilderModel: (NSString *)aModel
{
	id repObject = [[NSClassFromString(aModel) new] autorelease];

	[self setRepresentedObject: repObject];
	[self commit];
}

- (NSString *)UIBuilderModel
{
	return [[self representedObject] className];
}

- (void)setUIBuilderController: (NSString *)aController
{
	if ([self isGroup] == NO)
	{
		NSLog(@"WARNING: Item must be a ETLayoutItemGroup to have a controller %@", aController);
		return;
	}

	Class controllerClass = NSClassFromString(aController);

	if ([controllerClass isSubclassOfClass: [ETController class]] == NO)
	{
		NSLog(@"WARNING: Controller %@ must be a ETController subclass", aController);
		return;
	}
	ETController *controller = [[controllerClass new] autorelease];
	
	[(ETLayoutItemGroup *)self setController: controller];
	[self commit];
}

- (NSString *)UIBuilderController
{
	return [[[self ifResponds] controller] className];
}

@end

@implementation ETUIObject (UIBuilder)

- (NSString *) instantiatedAspectName
{
	return nil;
}

- (void) setInstantiatedAspectName: (NSString *)aName
{
	
}

@end
