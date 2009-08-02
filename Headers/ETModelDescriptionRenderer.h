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

}

+ (id) renderer;

- (id) renderModelObject: (id)anObject;
- (id) renderModelObject: (id)anObject 
            inLayoutItem: (ETLayoutItem *)anItem 
              withLayout: (ETLayout *)aLayout;

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
