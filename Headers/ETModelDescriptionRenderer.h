/** <title>ETModelDescriptionRenderer</title>
	
	<abstract>Layout item builder class that generate a UI from a model description.</abstract>
 
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "ETController.h"

@class ETPropertyDescription;
@class ETFormLayout, ETLayout, ETLayoutItem, ETLayoutItemFactory;

@interface ETModelDescriptionRenderer : NSObject
{
	@private
	ETModelDescriptionRepository *_repository;
	ETLayoutItemFactory *_itemFactory;
	NSMutableDictionary *_templateItems;
	NSMutableDictionary *_additionalTemplateIdentifiers;
	ETLayout *_entityLayout;
	NSString *_groupingKeyPath;
}

/** @taskunit Initialization */

+ (id) renderer;

/** @taskunit Providing UI Templates */

- (void) setTemplateItem: (ETLayoutItem *)anItem forIdentifier: (NSString *)anIdentifier;
- (ETLayoutItem *) templateItemForIdentifier: (NSString *)anIdentifier;
- (void) setTemplateIdentifier: (NSString *)anIdentifier forRoleClass: (Class)aClass;
- (NSString *) templateIdentifierForRoleClass: (Class)aClass;

/** @taskunit Customizing Generated UI */

- (ETFormLayout *) defaultFormLayout;

- (void) setEntityLayout: (ETLayout *)aLayout;
- (ETLayout *) entityLayout;

- (void) setGroupingKeyPath: (NSString *)aKeyPath;
- (NSString *) groupingKeyPath;

/** @taskunit Generating Form UI */

- (id) renderObject: (id)anObject;

@end

@interface ETEntityDescription (EtoileUI)
- (void) view: (id)sender;
@end

@interface ETPropertyCollectionController : ETController
- (IBAction) edit: (id)sender;
@end
