/**
	Copyright (C) 2013 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/ETEntityDescription.h>
#import <EtoileFoundation/ETPropertyDescription.h>
#import <EtoileFoundation/ETModelElementDescription.h>

@class ETLayoutItemGroup;

@interface ETModelElementDescription (ETModelBuilder)
- (ETLayoutItemGroup *) itemRepresentation;
- (void) view: (id)sender;
@end

@interface ETEntityDescription (ETModelBuilder)
- (ETLayoutItemGroup *) itemRepresentation;
- (void) view: (id)sender;
@end
