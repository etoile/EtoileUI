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
@class ETFormLayout, ETLayout, ETLayoutItem, ETLayoutItemFactory;

@interface ETModelDescriptionRenderer : NSObject
{
	@private
	ETModelDescriptionRepository *_repository;
	ETLayoutItemFactory *_itemFactory;
	NSMutableDictionary *_templateItems;
	NSMutableDictionary *_additionalTemplateIdentifiers;
	NSMutableDictionary *_formattersByType;
	ETLayout *_entityLayout;
	NSRect _entityItemFrame;
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
- (ETLayoutItem *) templateItemForIdentifier: (NSString *)anIdentifier;
- (NSArray *) templateItems;
- (void) setTemplateIdentifier: (NSString *)anIdentifier forRoleClass: (Class)aClass;
- (NSString *) templateIdentifierForRoleClass: (Class)aClass;

/** @taskunit Customizing Generated UI */

- (ETFormLayout *) defaultFormLayout;

- (void) setEntityLayout: (ETLayout *)aLayout;
- (ETLayout *) entityLayout;
- (void) setEntityItemFrame: (NSRect)aRect;
- (NSRect) entityItemFrame;

- (void) setRenderedPropertyNames: (NSArray *)propertyNames;
- (NSArray *) renderedPropertyNames;
- (void) setGroupingKeyPath: (NSString *)aKeyPath;
- (NSString *) groupingKeyPath;

/** @taskunit Customizing Value Editing */

- (NSFormatter *) formatterForType: (ETEntityDescription *)aType;
- (void) setFormatter: (NSFormatter *)aFormatter forType: (ETEntityDescription *)aType;

/** @taskunit Generating Form UI */

- (id) renderObject: (id)anObject;
- (id) renderObject: (id)anObject displayName: (NSString *)aName
	propertyDescriptions: (NSArray *)propertyDescs;

@end

@interface ETEntityDescription (EtoileUI)
- (void) view: (id)sender;
@end

@interface ETPropertyCollectionController : ETController
- (IBAction) edit: (id)sender;
@end

@interface ETFormatter : NSFormatter
@end

/** ETObjectValueFormatter doesn't turn strings into their object 
representations immediately, but just validates the string value to ensure it 
can be converted into an object representation later.
 
ETObjectValueFormatter is usually used together with a dedicated 
ETItemValueTransformer that know how to convert string values into object 
representations and vice-versa.
 
ETObjectValueFormatter is optional, it just improves the UI feedback because it 
prevents the user to leave a text field if the string value is not a valid 
object type (or some other object identifier).
 
A formatter cannot be used as a value transformer, because the validation 
happens multiple times during the editing, and the end of the editing doesn't 
trigger a final validation (that would be distinct from the incremental 
validation during the editing). ETItemValueTransformer are in charge of this 
final validation at the UI level before updating the model (and possibly 
resulting in a validation at the model level too).<br />
In addition, formatters are attached to -[ETLayoutItem widget] and 
-[ETWidget setObjectValue:] method copies objects passed to it, this prevents 
non-primitive object values to be edited directly (by being attached to the 
widget proxy). */
@interface ETObjectValueFormatter : NSFormatter
{
	@private
	id _delegate;
}

@property (assign, nonatomic) id delegate;

@end

@interface NSObject (ETObjectValueFormatterDelegate)
- (NSString *) formatter: (ETObjectValueFormatter *)aFormatter stringForObjectValue: (id)aValue;
- (id) formatter: (ETObjectValueFormatter *)aFormatter stringValueForString: (NSString *)aString;
@end
