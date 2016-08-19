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
- (COObjectGraphContext *) objectGraphContext;
/** See -[ETController templateForType:]. */
- (ETItemTemplate *) templateForType: (ETUTI *)aUTI;
/** See -[ETController currentObjectType:]. */
- (ETUTI *) currentObjectType;
/** See -[ETController currentGroupType:]. */
- (ETUTI *) currentGroupType;
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

- (ETLayoutItemGroup *) content;
- (void) didChangeContent: (ETLayoutItemGroup *)oldContent
                toContent: (ETLayoutItemGroup *)newContent;

/* Nib Support */

- (id) nibMainContent;
- (void) setNibMainContent: (id)anObject;
- (ETLayoutItemGroup *) loadNibAndReturnContent;
- (ETLayoutItemBuilder *) builder;

/* Observation */

- (void) startObserveObject: (COObject *)anObject
        forNotificationName: (NSString *)aName 
                   selector: (SEL)aSelector;
- (void) stopObserveObject: (COObject *)anObject forNotificationName: (NSString *)aName;

/* Templates */

- (ETItemTemplate *) templateForType: (ETUTI *)aUTI;
- (void) setTemplate: (ETItemTemplate *)aTemplate forType: (ETUTI *)aUTI;
- (ETUTI *) currentObjectType;
- (void) setCurrentObjectType: (ETUTI *)aUTI;
- (ETUTI *) currentGroupType;

/** @taskunit Persistent Object Context */

- (id <COPersistentObjectContext>) persistentObjectContext;
- (void) setPersistentObjectContext: (id <COPersistentObjectContext>)aContext;
- (COUndoTrack *) undoTrack;

/* Actions */

- (void) add: (id)sender;
- (void) addNewGroup: (id)sender;
- (void) insert: (id)sender;
- (void) insertNewGroup: (id)sender;
- (void) remove: (id)sender;

- (id) nextResponder;

- (ETLayoutItem *) initialFocusedItem;
- (void) setInitialFocusedItem: (ETLayoutItem *)anItem;

/* Insertion */

- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL 
                           ofType: (ETUTI *)aUTI 
                          options: (NSDictionary *)options;
- (NSDictionary *) defaultOptions;
- (BOOL) canMutate;
- (BOOL) isContentMutable;
- (NSInteger) insertionIndex;
- (NSIndexPath *) insertionIndexPath;
- (NSIndexPath *) additionIndexPath;
- (NSString *) insertionKey;
- (void) insertItem: (ETLayoutItem *)anItem atIndex: (NSUInteger)index;
- (void) insertItem: (ETLayoutItem *)anItem atIndexPath: (NSIndexPath *)anIndexPath;
- (BOOL) clearsFilterPredicateOnInsertion;
- (void) setClearsFilterPredicateOnInsertion: (BOOL)clear;
- (BOOL) selectsInsertedObjects;
- (void) setSelectsInsertedObjects: (BOOL)select;

/* Sorting and Filtering */

- (NSArray *) sortDescriptors;
- (void) setSortDescriptors: (NSArray *)sortDescriptors;
- (NSPredicate *) filterPredicate;
- (void) setFilterPredicate: (NSPredicate *)searchPredicate;
- (void) rearrangeObjects;
- (BOOL) automaticallyRearrangesObjects;
- (void) setAutomaticallyRearrangesObjects: (BOOL)flag;

/* Pick and Drop */

- (NSArray *) allowedPickTypes;
- (void) setAllowedPickTypes: (NSArray *)UTIs;
- (NSArray *) allowedDropTypesForTargetType: (ETUTI *)aUTI;
- (void) setAllowedDropTypes: (NSArray *)UTIs forTargetType: (ETUTI *)targetUTI;

/* Editing */

- (BOOL) isEditing;
- (BOOL) commitEditing;
- (void) discardEditing;
- (void) subjectDidBeginEditingForItem: (ETLayoutItem *)anItem
                              property: (NSString *)aKey;
- (void) subjectDidChangeValueForItem: (ETLayoutItem *)anItem
                             property: (NSString *)aKey;
- (void) subjectDidEndEditingForItem: (ETLayoutItem *)anItem
                            property: (NSString *)aKey;
- (id) editedItem;
- (NSString *) editedProperty;
- (NSArray *) allEditedItems;
- (NSArray *) allEditedProperties;

/* Enabling and Disabling Items */

- (NSSet *) validatableItems;
- (void) validateItems;
- (BOOL) validateItem: (ETLayoutItem *)anItem;

/* Framework Private */

+ (id <ETTemplateProvider>) basicTemplateProviderForObjectGraphContext: (COObjectGraphContext *)aContext;

@end

extern ETUTI * kETTemplateObjectType;
extern ETUTI * kETTemplateGroupType;
