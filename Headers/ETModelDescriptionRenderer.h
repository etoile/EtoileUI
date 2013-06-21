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

@class ETPropertyDescription, ETEntityDescription;
@class ETFormLayout, ETLayout, ETLayoutItem, ETLayoutItemFactory, ETItemValueTransformer;

@interface ETModelDescriptionRenderer : NSObject
{
	@private
	ETModelDescriptionRepository *_repository;
	ETLayoutItemFactory *_itemFactory;
	NSMutableDictionary *_templateItems;
	NSMutableDictionary *_additionalTemplateIdentifiers;
	NSMutableDictionary *_formattersByType;
	NSMutableDictionary *_valueTransformersByType;
	ETLayout *_entityLayout;
	NSRect _entityItemFrame;
	NSSize _itemSize;
	NSArray *_renderedPropertyNames;
	NSString *_groupingKeyPath;
	BOOL _usesContentSizeLayout;
}

/** @taskunit Initialization */

+ (id) renderer;

/** @taskunit Model Description Repository */

- (ETModelDescriptionRepository *) repository;

/** @taskunit Providing UI Templates */

- (void) setTemplateItem: (ETLayoutItem *)anItem forIdentifier: (NSString *)anIdentifier;
- (id) templateItemForIdentifier: (NSString *)anIdentifier;
- (NSArray *) templateItems;
- (void) setTemplateIdentifier: (NSString *)anIdentifier forRoleClass: (Class)aClass;
- (NSString *) templateIdentifierForRoleClass: (Class)aClass;

- (NSSize) defaultItemSize;
- (NSSize) itemSize;
- (void) setItemSize: (NSSize)aSize;

/** @taskunit Customizing Generated UI */

- (ETFormLayout *) defaultFormLayout;

- (void) setEntityLayout: (ETLayout *)aLayout;
- (ETLayout *) entityLayout;
- (void) setEntityItemFrame: (NSRect)aRect;
- (NSRect) entityItemFrame;
- (BOOL) usesContentSizeLayout;
- (void) setUsesContentSizeLayout: (BOOL)isContentSizeLayout;

- (void) setRenderedPropertyNames: (NSArray *)propertyNames;
- (NSArray *) renderedPropertyNames;
- (void) setGroupingKeyPath: (NSString *)aKeyPath;
- (NSString *) groupingKeyPath;

/** @taskunit Customizing Value Editing */

- (id) formatterForType: (ETEntityDescription *)aType;
- (void) setFormatter: (NSFormatter *)aFormatter forType: (ETEntityDescription *)aType;
- (ETItemValueTransformer *) valueTransformerForType: (ETEntityDescription *)aType;
- (void) setValueTransformer: (ETItemValueTransformer *)aTransformer
                     forType: (ETEntityDescription *)aType;

/** @taskunit Generating Form UI */

- (id) renderObject: (id)anObject;
- (id) renderObject: (id)anObject displayName: (NSString *)aName
	propertyDescriptions: (NSArray *)propertyDescs;

@end

@interface ETPropertyCollectionController : ETController
{
	@private
	ETModelDescriptionRepository *_modelDescriptionRepository;
}

@property (nonatomic, retain) ETModelDescriptionRepository *modelDescriptionRepository;

- (IBAction) edit: (id)sender;

@end
