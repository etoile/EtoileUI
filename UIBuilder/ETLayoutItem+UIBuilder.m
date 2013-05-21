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

- (id)UIBuilderWidgetElement
{
	return ([self view] != nil ? [self view] : self);
}

- (void)setUIBuilderName: (NSString *)aName
{
	id widget = [self UIBuilderWidgetElement];

	if ([widget respondsToSelector: @selector(setName:)])
	{
		[(ETLayoutItem *)widget setName: aName];
		[self didChangeValueForProperty: kETNameProperty];
	}
	else if ([widget respondsToSelector: @selector(setTitle:)])
	{
		[widget setTitle: aName];
		[self didChangeValueForProperty: kETViewProperty];
	}
	[self commit];
}

- (NSString *)UIBuilderName
{
	id widget = [self UIBuilderWidgetElement];

	if ([widget respondsToSelector: @selector(name)])
	{
		return [(ETLayoutItem *)widget name];
	}
	else if ([widget respondsToSelector: @selector(title)])
	{
		return [widget title];
	}
	return nil;
}

- (void)setUIBuilderAction: (NSString *)anAction
{
	[[self UIBuilderWidgetElement] setAction: NSSelectorFromString(anAction)];
	if ([[self UIBuilderWidgetElement] isView])
	{
		[self didChangeValueForProperty: kETViewProperty];
	}
	[self commit];
}

- (NSString *)UIBuilderAction
{
	return NSStringFromSelector([[[self UIBuilderWidgetElement] ifResponds] action]);
}

- (void)setUIBuilderTarget: (NSString *)aTargetId
{
	return;

	id target = [[self controllerItem] itemForIdentifier: aTargetId];

	if (target == nil)
	{
		NSLog(@"WARNING: Found no target for identifier %@ under controller item %@",
			aTargetId, [self controllerItem]);
		return;
	}

	[[self UIBuilderWidgetElement] setTarget: target];
	if ([[self UIBuilderWidgetElement] isView])
	{
		[self didChangeValueForProperty: @"viewTargetId"];
	}
	[self commit];
}

- (NSString *)UIBuilderTarget
{
	return nil;

	id target = [[[self UIBuilderWidgetElement] ifResponds] target];

	if (target == nil)
		return nil;

	ETLayoutItem *targetItem = ([target isLayoutItem] ? target : [[target ifResponds] owningItem]);

	NSLog(@"Found target %@", target);

	if (targetItem == nil)
	{
		NSLog(@"WARNING: Found no identifier for target %@", targetItem);
		return nil;
	}
	return [targetItem identifier];
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
