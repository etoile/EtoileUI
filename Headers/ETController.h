/** <title>ETController</title>
	
	<abstract>A generic controller layer interfaced with the layout item tree.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETNibOwner.h>

@class ETItemTemplate, ETLayoutItem, ETLayoutItemBuilder, ETLayoutItemGroup, ETUTI;

/** This protocol is only exposed to be used internally by EtoileUI.

See +[ETController basicTemplateProvider]. */
@protocol ETTemplateProvider <NSObject>
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
@interface ETController : ETNibOwner <NSCopying, ETTemplateProvider>
{
	@private
	NSMutableSet *_observations;
	IBOutlet ETLayoutItemGroup *content;
 	IBOutlet id nibMainContent;
	NSMutableDictionary *_templates;
	NSArray *_sortDescriptors;
	NSPredicate *_filterPredicate;
	NSArray *_allowedPickTypes;
	NSMutableDictionary *_allowedDropTypes; /* Allowed drop UTIs by drop target UTIs */
	NSMutableSet *_editorItems;
	BOOL _automaticallyRearrangesObjects;
	BOOL _hasNewSortDescriptors;
	BOOL _hasNewFilterPredicate;
	BOOL _hasNewContent;
	BOOL _clearsFilterPredicateOnInsertion;
	BOOL _selectsInsertedObjects;
}

- (ETLayoutItemGroup *) content;
- (void) setContent: (ETLayoutItemGroup *)anItem;
- (NSArray *) trackedItemPropertyNames;

/* Nib Support */

- (id) nibMainContent;
- (void) setNibMainContent: (id)anObject;
- (ETLayoutItemGroup *) loadNibAndReturnContent;
- (ETLayoutItemBuilder *) builder;

/* Observation */

- (void) startObserveObject: (id)anObject
        forNotificationName: (NSString *)aName 
                   selector: (SEL)aSelector;
- (void) stopObserveObject: (id)anObject forNotificationName: (NSString *)aName;

/* Copying */

- (id) copyWithZone: (NSZone *)aZone content: (ETLayoutItemGroup *)newContent;
- (void) finishDeepCopy: (ETController *)newController 
               withZone: (NSZone *)aZone 
                content: (ETLayoutItemGroup *)newContent;
/* Templates */

- (ETItemTemplate *) templateForType: (ETUTI *)aUTI;
- (void) setTemplate: (ETItemTemplate *)aTemplate forType: (ETUTI *)aUTI;
- (ETUTI *) currentObjectType;
- (ETUTI *) currentGroupType;

/* Actions */

- (void) add: (id)sender;
- (void) addNewGroup: (id)sender;
- (void) insert: (id)sender;
- (void) insertNewGroup: (id)sender;
- (void) remove: (id)sender;

- (id) nextResponder;

/* Insertion */

- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL 
                           ofType: (ETUTI *)aUTI 
                          options: (NSDictionary *)options;
- (BOOL) canMutate;
- (BOOL) isContentMutable;
- (unsigned int) insertionIndex;
- (void) insertObject: (id)anItem atIndex: (NSUInteger)index;
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

/* Editing (NSEditor and NSEditorRegistration Protocols) */

- (BOOL) isEditing;
- (BOOL) commitEditing;
- (void) discardEditing;
- (void) objectDidBeginEditing: (ETLayoutItem *)anItem;
- (void) objectDidEndEditing: (ETLayoutItem *)anItem;

/* Framework Private */

+ (id <ETTemplateProvider>) basicTemplateProvider;

@end

extern ETUTI * kETTemplateObjectType;
extern ETUTI * kETTemplateGroupType;
