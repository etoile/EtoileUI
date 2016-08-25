/** <title>ETController</title>
	
	<abstract>A generic controller layer interfaced with the layout item tree.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETNibOwner.h>
#import <EtoileUI/ETResponder.h>

@protocol COPersistentObjectContext;
@class COUndoTrack;
@class ETItemTemplate, ETLayoutItem, ETLayoutItemBuilder, ETLayoutItemGroup, ETUTI;

/** This protocol is only exposed to be used internally by EtoileUI.

See +[ETController basicTemplateProviderForObjectGraphContext:]. */
@protocol ETTemplateProvider <NSObject>
/** See -[ETUIObject objectGraphContext]. */
@property (nonatomic, readonly, weak) COObjectGraphContext *objectGraphContext;
/** See -[ETController templateForType:]. */
- (ETItemTemplate *) templateForType: (ETUTI *)aUTI;
/** See -[ETController currentObjectType:]. */
- (ETUTI *)currentObjectType;
/** See -[ETController currentGroupType:]. */
- (ETUTI *)currentGroupType;
@end

// TODO: Think about the selection marker stuff and implement it if it makes senses.

/** ETController provides a generic controller layer, usually to be used a 
replacement for both NSArrayController and NSTreeController. 

This reusable controller fills the same purpose than the previously mentionned 
NSController subclasses. The difference lies in the fact the tree structure is 
already abstracted in the layout item tree, as such there is no need for a 
special tree controller class with EtoileUI. The mediation with a collection of 
model objects is also abstracted in ETLayoutItemGroup class, whose instances 
play the role of lightweight mediators between View and Model in MVC term, hence 
NSArrayController isn't really needed either.

ETController extends the traditional facilities of NSController subclasses 
by allowing to make a distinction between Object class and Group class 
(leaf vs branches) as very often needed by applications in the Object Manager 
style (see also CoreObject) at both UI and model levels.<br />
For the UI, you can specify items templates to be cloned when a new element 
has to be inserted/added. On the model side, you can specify the class of 
the model objects to be instantiated.

This whole facility can be used at any levels of the UI.<br />
For example, for  supporting multiple windows in a file manager, you can create 
an ETLayoutItemGroup instance, that encapsulates a layout item tree which is the 
file manager UI. Then by simply setting this item group as an item group 
template on the window layer, and wiring <em>File->New Window...</em> to -add: 
action of this controller, new file manager windows will be created when 
<em>New Window...</em>is clicked in the menu.<br />
If you want your file managers to automatically open on a default directory, a 
model class can be set on the on the controller (-setGroupClass:) or 
alternatively a model instance can be set on the template item group (by 
calling -[ETLayoutItem setRepresentedObject:]). 

That ability to clone entire UI is detailed in -deepCopy of ETLayoutItem class 
and subclasses.

When a controller is set, it's very important to ensure its layout item is a 
base item, otherwise the wrong template items may be look up in the ancestor 
layout item instead of using the one declared in the controller bound to the container. 

ETController directly sorts object of the content and doesn't maintain arranged 
objects as a collection distinct from the content. */
@interface ETController : ETNibOwner <ETTemplateProvider, ETResponder>
{
	@private
	NSMutableSet *_observations;
 	IBOutlet id nibMainContent;
	NSMutableDictionary *_templates;
	ETUTI *_currentObjectType;
	id <COPersistentObjectContext> _persistentObjectContext;
	ETUUID *_persistentObjectContextUUID;
	ETLayoutItem *_initialFocusedItem;
	NSMutableArray *_sortDescriptors;
	NSPredicate *_filterPredicate;
	NSMutableArray *_allowedPickTypes;
	NSMutableDictionary *_allowedDropTypes; /* Allowed drop UTIs by drop target UTIs */
	NSMutableArray *_editedItems;
	NSMutableArray *_editableProperties;
	BOOL _automaticallyRearrangesObjects;
	BOOL _hasNewSortDescriptors;
	BOOL _hasNewFilterPredicate;
	BOOL _hasNewContent;
	BOOL _clearsFilterPredicateOnInsertion;
	BOOL _selectsInsertedObjects;
}

@property (nonatomic, readonly, weak) ETLayoutItemGroup *content;

- (void) didChangeContent: (ETLayoutItemGroup *)oldContent
                toContent: (ETLayoutItemGroup *)newContent;

/* Nib Support */

@property (nonatomic, strong) id nibMainContent;
@property (nonatomic, readonly) ETLayoutItemBuilder *builder;

- (ETLayoutItemGroup *) loadNibAndReturnContent;

/* Observation */

- (void) startObserveObject: (COObject *)anObject
        forNotificationName: (NSString *)aName 
                   selector: (SEL)aSelector;
- (void) stopObserveObject: (COObject *)anObject forNotificationName: (NSString *)aName;

/* Templates */

- (ETItemTemplate *) templateForType: (ETUTI *)aUTI;
- (void) setTemplate: (ETItemTemplate *)aTemplate forType: (ETUTI *)aUTI;

@property (nonatomic, copy) ETUTI *currentObjectType;
@property (nonatomic, readonly) ETUTI *currentGroupType;

/** @taskunit Persistent Object Context */

@property (nonatomic, strong) id<COPersistentObjectContext> persistentObjectContext;
@property (nonatomic, readonly) COUndoTrack *undoTrack;

/* Actions */

- (void) add: (id)sender;
- (void) addNewGroup: (id)sender;
- (void) insert: (id)sender;
- (void) insertNewGroup: (id)sender;
- (void) remove: (id)sender;

@property (nonatomic, readonly) id nextResponder;
@property (nonatomic, strong) ETLayoutItem *initialFocusedItem;

/* Insertion */

- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL 
                           ofType: (ETUTI *)aUTI 
                          options: (NSDictionary *)options;
- (NSDictionary *) defaultOptions;

@property (nonatomic, readonly) BOOL canMutate;
@property (nonatomic, readonly) BOOL isContentMutable;
@property (nonatomic, readonly) NSInteger insertionIndex;
@property (nonatomic, readonly) NSIndexPath *insertionIndexPath;
@property (nonatomic, readonly) NSIndexPath *additionIndexPath;
@property (nonatomic, readonly) NSString *insertionKey;

- (void) insertItem: (ETLayoutItem *)anItem atIndex: (NSUInteger)index;
- (void) insertItem: (ETLayoutItem *)anItem atIndexPath: (NSIndexPath *)anIndexPath;

@property (nonatomic) BOOL clearsFilterPredicateOnInsertion;
@property (nonatomic) BOOL selectsInsertedObjects;

/* Sorting and Filtering */

@property (nonatomic, copy) NSArray *sortDescriptors;
@property (nonatomic, copy) NSPredicate *filterPredicate;
@property (nonatomic) BOOL automaticallyRearrangesObjects;

- (void) rearrangeObjects;

/* Pick and Drop */

@property (nonatomic, copy) NSArray *allowedPickTypes;

- (NSArray *) allowedDropTypesForTargetType: (ETUTI *)aUTI;
- (void) setAllowedDropTypes: (NSArray *)UTIs forTargetType: (ETUTI *)targetUTI;

/* Editing */

@property (nonatomic, getter=isEditing, readonly) BOOL editing;

- (BOOL) commitEditing;
- (void) discardEditing;
- (void) subjectDidBeginEditingForItem: (ETLayoutItem *)anItem
                              property: (NSString *)aKey;
- (void) subjectDidChangeValueForItem: (ETLayoutItem *)anItem
                             property: (NSString *)aKey;
- (void) subjectDidEndEditingForItem: (ETLayoutItem *)anItem
                            property: (NSString *)aKey;

@property (nonatomic, readonly) id editedItem;
@property (nonatomic, readonly) NSString *editedProperty;
@property (nonatomic, readonly) NSArray *allEditedItems;
@property (nonatomic, readonly) NSArray *allEditedProperties;

/* Enabling and Disabling Items */

@property (nonatomic, readonly) NSSet *validatableItems;

- (void) validateItems;
- (BOOL) validateItem: (ETLayoutItem *)anItem;

/* Framework Private */

+ (id <ETTemplateProvider>) basicTemplateProviderForObjectGraphContext: (COObjectGraphContext *)aContext;
- (void) stopObservation;

@end

extern ETUTI * kETTemplateObjectType;
extern ETUTI * kETTemplateGroupType;
