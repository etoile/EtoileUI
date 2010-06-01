/** <title>ETModelDescriptionRenderer</title>
	
	<abstract>Layout item builder class that generate a UI from a model description.</abstract>
 
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/ETTransform.h>
#import <EtoileFoundation/ETEntityDescription.h>

@class ETPropertyDescription;
@class ETLayout, ETLayoutItem;

@interface ETModelDescriptionRenderer : ETTransform
{
	@private
	NSMutableDictionary *_templateItems;
}

+ (id) renderer;

- (void) setTemplateItem: (ETLayoutItem *)anItem forIdentifier: (NSString *)anIdentifier;
- (ETLayoutItem *) templateItemForIdentifier: (NSString *)anIdentifier;

- (id) makeItemForIdentifier: (NSString *)anIdentifier isGroupRequired: (BOOL)mustBeGroup;

- (id) renderModel: (id)anObject;
- (id) renderModel: (id)anObject description: (ETEntityDescription *)entityDesc;
 
- (id) renderProperties: (NSArray *)properties
            description: (ETEntityDescription *)entityDesc  
                ofModel: (id)anObject;
- (id) renderProperty: (NSString *)aProperty
          description: (ETEntityDescription *)entityDesc  
              ofModel: (id)anObject;

//- (id) renderModelObject: (id)anObject 
//            inLayoutItem: (ETLayoutItem *)anItem 
//              withLayout: (ETLayout *)aLayout;

- (id) renderEntityDescription: (ETEntityDescription *)aDescription;
- (id) renderPropertyDescription: (ETPropertyDescription *)aDescription;

/* There is no need to support an explicit method like:
-setInlineModel:(BOOL)forProperty:ofDescription:

because this can be achieved by rebinding the item identifier for the given 
property of a description with a method like:
-setCustomIdentifier: @"table" forProperty: "name" ofDescription:  person
By using 'table', an item group will be generated based on the entity 
description rather than a leaf item based on the attribute or relationship 
description. */

@end

@interface ETEntityDescription (EtoileUI)
- (void) view: (id)sender;
@end
