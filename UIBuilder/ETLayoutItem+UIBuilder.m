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

- (ETLayoutItem *)representedItem
{
	return [self representedObject];
}

- (id)UIBuilderWidgetElement
{
	ETLayoutItem *representedItem = [self representedObject];
	return ([representedItem view] != nil ? [representedItem view] : representedItem);
}

- (void)setUIBuilderName: (NSString *)aName
{
	id widget = [self UIBuilderWidgetElement];

	if ([widget respondsToSelector: @selector(setName:)])
	{
		[(ETLayoutItem *)widget setName: aName];
	}
	else if ([widget respondsToSelector: @selector(setTitle:)])
	{
		[widget setTitle: aName];
	}
	[[self representedItem] commit];
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
	[[self representedItem] commit];
}

- (NSString *)UIBuilderAction
{
	return NSStringFromSelector([[self UIBuilderWidgetElement] action]);
}

- (void)setUIBuilderTarget: (NSString *)aTargetId
{
	id target = [[[self representedItem] controllerItem] itemForIdentifier: aTargetId];

	if (target == nil)
	{
		NSLog(@"WARNING: Found no target for identifier %@ under controller item %@",
			aTargetId, [self controllerItem]);
		return;
	}

	[[self UIBuilderWidgetElement] setTarget: target];
	[[self representedItem] commit];
}

- (NSString *)UIBuilderTarget
{
	id target = [[self UIBuilderWidgetElement] target];
	id widgetElement = ([target isLayoutItem] ? target : [[target ifResponds] owningItem]);

	if (widgetElement == nil)
	{
		NSLog(@"WARNING: Found no identifier for target %@", target);
		return nil;
	}
	return [widgetElement identifier];
}


- (void)setUIBuilderModel: (NSString *)aModel
{
	id repObject = [[NSClassFromString(aModel) new] autorelease];

	[[self representedItem] setRepresentedObject: repObject];
	[[self representedItem] commit];
}

- (NSString *)UIBuilderModel
{
	return [[[self representedItem] representedObject] className];
}

- (void)setUIBuilderController: (NSString *)aController
{
	if ([[self representedItem] isGroup] == NO)
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
	
	[(ETLayoutItemGroup *)[self representedItem] setController: controller];
	[[self representedItem] commit];
}

- (NSString *)UIBuilderController
{
	return [[[[self representedItem] ifResponds] controller] className];
}

@end
