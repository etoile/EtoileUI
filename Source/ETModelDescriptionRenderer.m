/*
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h> 
#import "ETModelDescriptionRenderer.h"
#import "ETTemplateItemLayout.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Factory.h"
#import "ETLayoutItemGroup.h"
#import "ETCompatibility.h"


@implementation ETModelDescriptionRenderer

+ (id) renderer
{
	return AUTORELEASE([[self alloc] init]);
}

- (id) renderModelObject: (id)anObject 
{
	return [self renderModelObject: anObject inLayoutItem: nil withLayout: nil];
}

- (id) renderModelObject: (id)anObject 
            inLayoutItem: (ETLayoutItem *)anItem 
              withLayout: (ETLayout *)aLayout;
{
	// FIXME: lookup description for anObject
	ETEntityDescription *desc = nil;
	ETLayoutItem *builtItem = (anItem != nil ? anItem : [self render: desc]);
	ETLayout *layout = (aLayout != nil ? aLayout : [ETFormLayout layout]);

	if ([builtItem isGroup])
		[(ETLayoutItemGroup *)builtItem setLayout: layout];

	return builtItem;
}

- (id) renderEntityDescription: (ETEntityDescription *)aDescription
{
	ETLayoutItemGroup *entityItem = [ETLayoutItem itemGroup];

	FOREACHI([aDescription propertyDescriptions], propertyDescription)
	{
		[entityItem addItem: [self render: propertyDescription]];
	}	
	[entityItem setName: [aDescription name]];

	return entityItem;
}

- (id) renderPropertyDescription: (ETPropertyDescription *)aDescription
{
	// TODO: we need a mapping from UTI to "layout item for editing that type"

	ETLayoutItem *item = [ETLayoutItem textField];
	[item setName: [aDescription name]];
	return item;
}

/** Returns a dictionary mapping value classes to editor object prototypes. 
	These editor objects are UI elements like NSSlider, NSStepper, NSTextField, 
	NSButton. */
- (NSDictionary *) editorObjects
{
	/*NSButton *checkBox = [[NSButton alloc] ini

	return [NSDictionary dictionaryWithObjectsAndKeys: 
		[NS*/
	return nil;
}

@end


@implementation ETEntityDescription (EtoileUI)

- (void) view: (id)sender
{
	ETLayoutItem *entityItem = [[ETModelDescriptionRenderer renderer] renderModelObject: self];
	[[ETLayoutItem windowGroup] addItem: entityItem];
}

@end
