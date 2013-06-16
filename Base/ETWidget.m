/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Trait.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETWidget.h"
#import "ETLayoutItem.h"
#import "EtoileUIProperties.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

// TODO: Update model description and test persistency for properties set on the item

@implementation ETLayoutItem (ETWidgetProxy)

#if 0
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
#endif

- (id) objectValue
{
	if ([self view] != nil)
	{
		return ([[self view] isWidget] ? [(id <ETWidget>)[self view] objectValue] : nil);
	}
	else
	{
		id value = [self value];
		return (value != nil ? value : [super objectValue]);
	}
}

- (void) setObjectValue: (id)aValue
{
	if ([self view] != nil)
	{
		if ([[self view] isWidget] == NO)
			return;

		[(id <ETWidget>)[self view] setObjectValue: aValue];
	}
	else
	{
		[self setValue: aValue];
	}
}

- (void) takeObjectValueFrom: (id)sender
{
	[self setObjectValue: [sender objectValue]];
}

- (id) formatter
{
	if ([self view] != nil)
	{
		return ([[self view] isWidget] ? [(id <ETWidget>)[self view] formatter] : nil);
	}
	else
	{
		return [self primitiveValueForKey: @"formatter"];
	}
}

- (void) setFormatter: (NSFormatter *)aFormatter
{
	if ([self view] != nil)
	{
		if ([[self view] isWidget] == NO)
			return;

		[self willChangeValueForProperty: kETViewProperty];
		[(id <ETWidget>)[self view] setFormatter: aFormatter];
		[self didChangeValueForProperty: kETViewProperty];
	}
	else
	{
		[self willChangeValueForProperty: @"formatter"];
		[self setPrimitiveValue: aFormatter forKey: @"formatter"];
		[self didChangeValueForProperty: @"formatter"];
	}
}

- (NSActionCell *) cell
{
	return ([[self view] isWidget] ? [(id <ETWidget>)[self view] cell] : nil);
}

- (NSString *) title
{
	return ([self view] != nil ? [[[self view] ifResponds] title] : [self name]);
}

- (void) setTitle: (NSString *)aTitle
{
	if ([self view] != nil)
	{
		[self willChangeValueForProperty: kETViewProperty];
		[[[self view] ifResponds] setTitle: aTitle];
		if (aTitle == nil || [aTitle isEqual: @""])
		{
			[[[self view] ifResponds] setImagePosition: NSImageOnly];
		}
		[self didChangeValueForProperty: kETViewProperty];
	}
	else
	{
		[self setName: aTitle];
	}
}

- (double) minValue
{
	if ([self view] != nil)
	{
		return [[[self view] ifResponds] minValue];
	}
	else
	{
		return [[self primitiveValueForKey: @"minValue"] doubleValue];
	}
}

- (void) setMinValue: (double)aValue
{
	if ([self view] != nil)
	{
		return [[[self view] ifResponds] setMinValue: aValue];
	}
	else
	{
		[self willChangeValueForProperty: @"minValue"];
		[self setPrimitiveValue: [NSNumber numberWithDouble: aValue] forKey: @"minValue"];
		[self didChangeValueForProperty: @"minValue"];
	}
}

- (double) maxValue
{
	if ([self view] != nil)
	{
		return [[[self view] ifResponds] maxValue];
	}
	else
	{
		return [[self primitiveValueForKey: @"maxValue"] doubleValue];
	}
}

- (void) setMaxValue: (double)aValue
{
	if ([self view] != nil)
	{
		return [[[self view] ifResponds] setMaxValue: aValue];
	}
	else
	{
		[self willChangeValueForProperty: @"maxValue"];
		[self setPrimitiveValue: [NSNumber numberWithDouble: aValue] forKey: @"maxValue"];
		[self didChangeValueForProperty: @"maxValue"];
	}
}

- (void) setDoubleValue: (double)aValue
{
	
}

@end

