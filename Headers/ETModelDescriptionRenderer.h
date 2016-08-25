/** <title>ETModelDescriptionRenderer</title>
	
	<abstract>Layout item builder class that generate a UI from a model description.</abstract>
 
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
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

+ (instancetype) renderer;

/** @taskunit Model Description Repository */

@property (nonatomic, readonly, strong) ETModelDescriptionRepository *repository;

/** @taskunit Providing UI Templates */

- (void) setTemplateItem: (ETLayoutItem *)anItem forIdentifier: (NSString *)anIdentifier;
- (id) templateItemForIdentifier: (NSString *)anIdentifier;
@property (nonatomic, readonly, copy) NSArray *templateItems;
- (void) setTemplateIdentifier: (NSString *)anIdentifier forRoleClass: (Class)aClass;
- (NSString *) templateIdentifierForRoleClass: (Class)aClass;

- (NSSize) defaultItemSize;
@property (nonatomic) NSSize itemSize;

/** @taskunit Customizing Generated UI */

- (ETFormLayout *) defaultFormLayout;

@property (nonatomic, strong) ETLayout *entityLayout;
@property (nonatomic) NSRect entityItemFrame;
@property (nonatomic) BOOL usesContentSizeLayout;

@property (nonatomic, copy) NSArray *renderedPropertyNames;
@property (nonatomic, copy) NSString *groupingKeyPath;

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
