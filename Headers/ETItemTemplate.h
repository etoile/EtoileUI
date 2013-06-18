/** <title>ETItemTemplate</title>
	
	<abstract>A template to instantiate the right UI and model for a URL.</abstract>
 
	Copyright (C) 2010 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  October 2010
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETController.h>
#import <EtoileUI/ETCompatibility.h>
#ifdef COREOBJECT
#import <CoreObject/COEditingContext.h>
#endif
@class ETLayoutItem, ETLayoutItemGroup, ETUTI;

@protocol ETDocumentCreation
/** Initializes and returns a document for the given URL and options based on 
the URL semantics described below.

The receiver is responsible to handle the third URL cases as described:
<item>nil is a 'New' document request</item>
<item>valid is a 'Open' document request</item>
<item>invalid is a 'New' document request to create at a precise URL</item>
</list> */
- (id) initWithURL: (NSURL *)aURL options: (NSDictionary *)options;
@end

/** A template that embeds both an item template and an object class template, 
and can build new items initialized with a represented object for a given URL.

ETItemTemplate allows to support various strategy to open or create documents or 
content units in collaboration with a client object e.g. a ETDocumentController 
instance.<br />
Subclassing is possible to implement new strategies, but in many cases a new 
template with a particular UI and model combination should give you enough 
flexibility.

The client object invokes -newItemWithURL:options: to get a new instance. 
-newItemWithURL:options: in turn uses ETDocumentCreation to delegate the 
model initialization. */
@interface ETItemTemplate : ETUIObject
{
	@private
	Class _objectClass;
	NSString *_entityName;
	ETLayoutItem *_item;
}

/** @taskunit Initialization */

+ (id) templateWithItem: (ETLayoutItem *)anItem objectClass: (Class)aClass;
+ (id) templateWithItem: (ETLayoutItem *)anItem entityName: (NSString *)anEntityName;

- (id) initWithItem: (ETLayoutItem *)anItem
        objectClass: (Class)aClass
         entityName: (NSString *)anEntityName;

/** @taskunit Properties */

- (Class) objectClass;
- (NSString *) entityName;
- (ETLayoutItem *) item;
- (ETLayoutItem *) contentItem;
- (NSString *) baseName;

/** @taskunit Template Instantiation & Saving */

- (Class) objectClassWithOptions: (NSDictionary *)options;
- (ETLayoutItem *) newItemWithRepresentedObject: (id)anObject options: (NSDictionary *)options;
- (ETLayoutItem *) newItemWithRepresentedObject: (id)anObject URL: (NSURL *)aURL options: (NSDictionary *)options;
- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL options: (NSDictionary *)options;
- (ETLayoutItem *) newItemReadFromURL: (NSURL *)aURL options: (NSDictionary *)options;
- (BOOL) writeItem: (ETLayoutItem *)anItem 
             toURL: (NSURL *)aURL 
           options: (NSDictionary *)options;
- (NSArray *) supportedTypes;
- (NSURL *) URLFromRunningSavePanel;
- (BOOL) allowsMultipleInstancesForURL: (NSURL *)aURL;
- (NSString *) nameFromBaseNameAndOptions: (NSDictionary *)options;

@end

extern NSString * const kETTemplateOptionNumberOfUntitledDocuments;
extern NSString * const kETTemplateOptionPersistentObjectContext;
extern NSString * const kETTemplateOptionModelDescriptionRepository;
extern NSString * const kETTemplateOptionKeyValuePairKey;
extern NSString * const kETTemplateOptionParentRepresentedObject;

#ifdef COREOBJECT
/** COObject category to implement ETDocumentCreation and integrate COObject 
instantiation into ETItemTemplate. */
@interface COObject (ETItemTemplate) <ETDocumentCreation>
/** <override-never />
Inserts the receiver into the persistent object context passed among the options.

Based on the context type, the receiver is inserted as a root object (along a 
new persistent root) or as a inner object into the context. 

If the options contains no custom context, does the same than -init. */
- (id) initWithURL: (NSURL *)aURL options: (NSDictionary *)options;
@end
#endif
