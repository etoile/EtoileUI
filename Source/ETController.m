/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETUTI.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETController.h"
#import "ETUTITuple.h"
#import "ETEventProcessor.h"
#import "ETItemTemplate.h"
#import "ETLayoutItemBuilder.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup+Mutation.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem.h"
#import "ETObservation.h"
#import "ETPickDropActionHandler.h" /* For ETUndeterminedIndex */
#import "ETResponder.h"
#import "ETTool.h" /* For -editedItem */
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"

#pragma GCC diagnostic ignored "-Wprotocol"

@implementation ETController

+ (void) initialize
{
	if ([ETController class] == self) 
	{
		[self applyTraitFromClass: [ETResponderTrait class]];
	
		kETTemplateObjectType = [ETUTI registerTypeWithString: @"org.etoile-project.etoileui.template-object"
		                                          description: @"EtoileUI Template Object Type (see ETController)"
		                                     supertypeStrings: [NSArray array]
		                                             typeTags: nil];
		kETTemplateGroupType = [ETUTI registerTypeWithString: @"org.etoile-project.etoileui.template-group"
		                                         description: @"EtoileUI Template Group Type (see ETController)"
		                                    supertypeStrings: [NSArray array]
		                                            typeTags: nil];
	}
}

- (void)prepareTransientState
{
	_editedItems = [[NSMutableArray alloc] init];
	_editableProperties = [[NSMutableArray alloc] init];
	_hasNewSortDescriptors = (NO == [_sortDescriptors isEmpty]);
	_hasNewFilterPredicate = (nil != _filterPredicate);
	_hasNewContent = NO;
}

/** <init />
Initializes and returns a new controller which automatically rearrange objects.

For the Nib name and bundle arguments, see -[ETNibOwner initWithNibName:bundle:].

Automatically registers basic templates for -currentObjectType and 
-currentGroupType. See -setTemplate:forType: and -templateForType:.

You can also use it -init to create a controller. See -[ETNibOwner init]. */
- (id) initWithNibName: (NSString *)aNibName
                bundle: (NSBundle *)aBundle
    objectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithNibName: aNibName bundle: aBundle objectGraphContext: aContext];
	if (nil == self)
		return nil;

	_observations = [[NSMutableSet alloc] init];
	_templates = [[NSMutableDictionary alloc] init];
	ASSIGN(_currentObjectType, kETTemplateObjectType);
	[self setSortDescriptors: nil];
	_allowedPickTypes = [[NSArray alloc] init];
	_allowedDropTypes = [[NSMutableDictionary alloc] init];
	_automaticallyRearrangesObjects = YES;
	_clearsFilterPredicateOnInsertion = YES;
	_selectsInsertedObjects = YES;

	/* If the controller instantiation is done inside an object graph context 
	   in the framework user code, the controller can become persistent because 
	   the template items use no shared aspects. */
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factoryWithObjectGraphContext: aContext];
	ETItemTemplate *objectTemplate = [ETItemTemplate templateWithItem: [itemFactory item]
	                                                      objectClass: Nil
	                                               objectGraphContext: aContext];
	ETItemTemplate *groupTemplate = [ETItemTemplate templateWithItem: [itemFactory itemGroup]
	                                                     objectClass: Nil
	                                              objectGraphContext: aContext];

	[self setTemplate: objectTemplate forType: kETTemplateObjectType];
	[self setTemplate: groupTemplate forType: kETTemplateGroupType];

	[self prepareTransientState];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
	 	   selector: @selector(didProcessEvent:)
		       name: ETEventProcessorDidProcessEventNotification
		     object: nil];

	return self;
}

- (void) stopObservation
{
	NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];

	FOREACH(_observations, observation, ETObservation *)
	{
		[notifCenter removeObserver: [observation object]];
	}
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) willDiscard
{
    [self stopObservation];
}

- (void) dealloc
{
	DESTROY(_observations);
	DESTROY(nibMainContent);
	DESTROY(_templates);
	DESTROY(_currentObjectType);
	DESTROY(_persistentObjectContext);
	DESTROY(_initialFocusedItem);
	DESTROY(_sortDescriptors);
	DESTROY(_filterPredicate);
	DESTROY(_allowedPickTypes);
	DESTROY(_allowedDropTypes);
	DESTROY(_editedItems);
	DESTROY(_editableProperties);
	
	[super dealloc];
}

- (BOOL) respondsToSelector: (SEL)aSelector
{
	if ([super respondsToSelector: aSelector])
		return YES;
	
	return [[ETActionHandler sharedFallbackResponder] respondsToSelector: aSelector];
}

- (id) forwardingTargetForSelector:(SEL)aSelector
{
	return [ETActionHandler sharedFallbackResponder];
}

/* Nib Support */

- (id) rebuiltObjectForObject: (id)anObject builder: (id)aBuilder
{
	if ([anObject isLayoutItem] == NO && [anObject isView] == NO)
		return anObject;
	
	id newObject = [super rebuiltObjectForObject: anObject builder: aBuilder];

	if ([anObject isEqual: [self nibMainContent]])
	{
		ETAssert([newObject isLayoutItem]);

		[newObject setController: self];
		[self setNibMainContent: nil];
	}
	return newObject;
}

/** Returns the Nib top level object (e.g. a window or a view) that provides the 
item group expected to become the controller content and owner when 
-loadNibAndReturnContent is invoked. 

You shouldn't need to use this method. See -setNibMainContent:.*/
- (id) nibMainContent
{
	return nibMainContent;
}

/** Sets the Nib top level object (e.g. a window or a view) that provides the 
item group expected to become the controller content and owner when 
-loadNibAndReturnContent is invoked.

When no item can be retrieved, -loadNibAndReturnContent renders the Nib main 
content with -builder and uses the resulting item as the controller content.

You usally don't use this method but set the related outlet in IB/Gorm. */
- (void) setNibMainContent: (id)anObject
{
	if ([anObject isLayoutItem])
	{
		NSParameterAssert([anObject isGroup]);
	}
	ASSIGN(nibMainContent, anObject);
}

/** <override-dummy />
Renders view hierarchies reachable from the top level objects of the Nib into a 
layout item tree with -builder.

Are considered traversable the top level objects which returns YES to 
-isLayoutItem or -isView.

You can override this method to disable this behavior or extend the current one. */
- (void) didLoadNib
{
	[self rebuildTopLevelObjectsWithBuilder: [self builder]];
}

/** Don't use this method but -loadNibAndReturnContent.

Raises an exception. */
- (BOOL) loadNib
{
	[self doesNotRecognizeSelector: _cmd];
	return NO;
}

/** Loads the Nib file with the receiver as the File's Owner and returns the new 
controller content on success, otherwise returns nil and logs a failure message.

You must retain the returned item which owns the receiver once the method has 
returned. Later this item can be released to release the controller.<br />
During the Nib loading phase, the controller owns the Nib (precisely the top 
level objects), but just before returning it transfers the ownership back to 
the returned content (identical to -content) and releases the top level objects.
Which means every top level objects have to inserted into the item tree in 
-didLoadNib or retained with outlets (if you write a subclass).

Raises an exception if the bundle or the Nib itself cannot be found.<br />
Also raises an exception when the new controller content cannot be determined,  
-nibMainContent or -content returns nil. */
- (ETLayoutItemGroup *) loadNibAndReturnContent
{
	BOOL nibLoaded = [super loadNib];

	if (NO == nibLoaded)
		return nil;

	if ([self nibMainContent] == nil && [self content] == nil)
	{
		[NSException raise: NSInternalInconsistencyException 
		            format: @"%@ must have a valid -nibMainContent or -content to load a Nib", self];
		return nil;
	}
	/* Either the nibMainContent was not rebuilt to produce a new content or 
	   the content outlet was not set. */
	if ([self content] == nil)
	{
		return nil;
	}

	ETAssert([[self content] isLayoutItem] && [[self content] isGroup]);

	/* Give the ownership back to the content (see also -rebuiltObjectForObject:builder:) */
	RETAIN([self content]);
	[[self topLevelObjects] removeObject: [self content]];

	return AUTORELEASE([self content]);
}

/** Returns the content object which is either a layout item group or nil.

Can be overriden to return a descendant item of the originally set content. 
For example:

<example>
- (ETLayoutItemGroup *) content
{
	return [[super content] itemForIdentifier: @"theChildItemWhichWeMutateSortAndFilter"];
}
</example>

See also -[ETLayoutItemGroup controller] and -nextResponder.*/
- (ETLayoutItemGroup *) content
{
	return [self valueForVariableStorageKey: @"content"];
}

/** <override-dummy />
Tells the receiver the item group that owns the controller has changed.

You can override this method in subclasses to adjust controller to the new 
content. A common use case is to reset the observation using 
-stopObserveObject:forNotificationName: for some object in the old content and 
-startObserveObject:forNotificationName:selector: for the some object in the new 
content.

<example>
if (oldContent != nil)
{
	[self stopObserveObject: [oldContent itemForIdentifier: @"browser"]
		forNotificationName: ETItemGroupSelectionDidChangeNotification];
}
if (newContent != nil)
{
	[self startObserveObject: [newContent itemForIdentifier: @"browser"]
		 forNotificationName: ETItemGroupSelectionDidChangeNotification
					selector: @selector(browserSelectionDidChange:)];
}
</example>
 
You must not access -content directly in this method. */
- (void) didChangeContent: (ETLayoutItemGroup *)oldContent
                toContent: (ETLayoutItemGroup *)newContent
{
	
}

/* AppKit to EtoileUI Conversion */

/** Returns the AppKit to EtoileUI builder that converts AppKit windows, views 
etc. to items when a nib is loaded.

By default, returns an ETEtoileUIBuilder instance. */
- (ETLayoutItemBuilder *) builder
{
	return [ETEtoileUIBuilder builderWithObjectGraphContext: [self objectGraphContext]];
}

/* Observation */

/** Adds the receiver as an observer on the given object and notification name 
combination to the default notification center.
 
The method bound to the given selector on the receiver will be called back, 
when the observed object posts a notification whose name matches aName.

Pass nil as the notification name, if you want to receive all notifications 
posted by the observed object.

The observed object must not be nil, the selector must not be NULL either. */
- (void) startObserveObject: (COObject *)anObject
        forNotificationName: (NSString *)aName 
                   selector: (SEL)aSelector
{
	NILARG_EXCEPTION_TEST(anObject);
    INVALIDARG_EXCEPTION_TEST(aSelector, aSelector != NULL);

    ETObservation *observation = AUTORELEASE([[ETObservation alloc]
        initWithObjectGraphContext: [self objectGraphContext]]);

    [observation setObject: anObject];
    [observation setName: aName];
    [observation setSelector: aSelector];

	[_observations addObject: observation];

	[[NSNotificationCenter defaultCenter] addObserver: self
	                                         selector: aSelector
	                                             name: aName
	                                           object: anObject];
}

/** Removes the receiver as an observer on the given object and notification 
name combination from the default notification center.
 
Pass nil as the notification name, if you want to stop to receive any 
notification posted by the observed object.

The observed object must not be nil. */ 
- (void) stopObserveObject: (COObject *)anObject forNotificationName: (NSString *)aName
{
	NILARG_EXCEPTION_TEST(anObject);

	NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
	BOOL removeAll = (nil == aName);

	FOREACH([NSSet setWithSet: _observations], observation, ETObservation *)
	{
		COObject *object = [observation object];

		if (object != anObject)
			continue;

		if ([[observation name] isEqual: aName] || removeAll)
		{
			[_observations removeObject: observation];
			[notifCenter removeObserver: self name: aName object: anObject];
		}
	}
}

/* Templates */

/** Returns the type of the template to be instantiated on -add: and -insert:.
 
By default, returns kETTemplateObjectType.<br />

Can be overriden to return a custom type based on a use case or a user setting.

See also -setCurrentObjectType: and -setTemplate:forType:. */
- (ETUTI *) currentObjectType
{
	return _currentObjectType;
}

/** Sets the type of the template to be instantiated on -add: and -insert:.
 
See also -setTemplate:forType:. */
- (void) setCurrentObjectType: (ETUTI *)aUTI
{
	ASSIGN(_currentObjectType, aUTI);
}

/** Returns the type of the template to be instantiated on -addNewGroup: and 
-insertNewGroup:.
 
By default, returns kETTemplateGroupType.<br />

Can be overriden to return a custom type based on a use case or a user setting.

See also -setTemplate:forType:. */
- (ETUTI *) currentGroupType
{
	return kETTemplateGroupType;
}

/** Returns the template to create the right UI and model to view or edit the 
given element type.

If no template matches the UTI exactly, looks up a template based on the UTI 
supertypes. The supertypes are -[EUTI allSupertypes] and are tested in the 
same order. When a template was previously bound to a supertype by calling 
-setTemplate:forType:, this method returns it.<br />
In case all supertypes have been tried without success, nil is returned.<br />
This lookup mechanism is named supercasting.

See -newItemWithURL:ofType:options and ETItemTemplate. */
- (ETItemTemplate *) templateForType: (ETUTI *)aUTI
{
	ETItemTemplate *template = [_templates objectForKey: [aUTI stringValue]];

	if (nil != template)
		return template;

	/* Supercasting */
	FOREACH([aUTI allSupertypes], supertype, ETUTI *)
	{
		template = [_templates objectForKey: [supertype stringValue]];
		if (nil != template)
			break;
	}

	return template;
}

/** Sets the template to create the right UI and model to view or edit the given 
element type. 

See -newItemWithURL:ofType:options and ETItemTemplate. */
- (void) setTemplate: (ETItemTemplate *)aTemplate forType: (ETUTI *)aUTI
{
	[_templates setObject: aTemplate forKey: [aUTI stringValue]];
}

/** Returns the object that manages persistency.

The returned context is usually either a COPersistentRoot for inserting new 
inner objects inside a given persistent root, or a COEditingContext for 
inserting new root objects along their persistent roots. 
 
Can be overriden to return the right context based on the circumstances. For 
example, based on the current selection (a persistent object vs no selection), 
a persistent root or the editing context could be returned. */
- (id <COPersistentObjectContext>) persistentObjectContext
{
	return _persistentObjectContext;
}

/** <override-dummy />
Returns the undo track to record user actions in
-[ETUIObject commitWithIdentifier:metadata:].

By default, returns the parent controller undo track.<br />
The parent controller is the controller attached to 
<code>[[self content] controllerItem]</code>.
 
Can be overriden to return the right undo track based on the circumstances. For 
example, based on the current selection or active item, the main undo track 
or some more specialized track (e.g. an Undo view) could be returned. */
- (COUndoTrack *) undoTrack
{
	ETController *candidateController = [[[self content] controllerItem] controller];
	
	return (candidateController != self ? [candidateController undoTrack] : nil);
}

/** Sets the object that manages persistency.
 
If the given object doesn't conform to the protocol, raises an 
NSInvalidArgumentException.
 
If the controller is persistent and this property points to a persistent 
COObjectGraphContext, then this property is persisted. In all other cases, 
the property is set to nil, when the receiver is reloaded.

See -persistentObjectContext for more details. */
- (void) setPersistentObjectContext: (id <COPersistentObjectContext>)aContext
{
    if (aContext != nil)
    {
        INVALIDARG_EXCEPTION_TEST(aContext, [(id <NSObject>)aContext conformsToProtocol: NSProtocolFromString(@"COPersistentObjectContext")]);
    }
    [self willChangeValueForProperty: @"persistentObjectContext"];
	ASSIGN(_persistentObjectContext, aContext);
    [self didChangeValueForProperty: @"persistentObjectContext"];
}

/** Creates a new object by calling -newItemWithURL:ofType:options: and adds it to the content. */
- (void) add: (id)sender
{
	ETLayoutItem *item = AUTORELEASE([self newItemWithURL: nil
	                                               ofType: [self  currentObjectType]
	                                              options: [self defaultOptions]]);
	[self insertItem: item atIndexPath: [self additionIndexPath]];
}

/** Creates a new object group by calling -newItemWithURL:ofType:options: and adds it to the content. */
- (void) addNewGroup: (id)sender
{
	ETLayoutItem *item = AUTORELEASE([self newItemWithURL: nil
	                                               ofType: kETTemplateGroupType
	                                              options: [self defaultOptions]]);
	[self insertItem: item atIndexPath: [self additionIndexPath]];
}

/** Creates a new object by calling -newItemWithURL:ofType:options: and inserts it into the content at 
-insertionIndex. */
- (void) insert: (id)sender
{
	ETLayoutItem *item = AUTORELEASE([self newItemWithURL: nil
	                                               ofType: [self  currentObjectType]
	                                              options: [self defaultOptions]]);
	[self insertItem: item atIndexPath: [self insertionIndexPath]];
}

/** Creates a new object group by calling -newItemWithURL:ofType:options: and inserts it into the 
content at -insertionIndex. */
- (void) insertNewGroup: (id)sender
{
	ETLayoutItem *item = AUTORELEASE([self newItemWithURL: nil
	                                               ofType: kETTemplateGroupType
	                                              options: [self defaultOptions]]);
	[self insertItem: item atIndexPath: [self insertionIndexPath]];
}

/** Removes all selected objects in the content. Selected objects are retrieved 
by calling -selectedItemsInLayout on the content. */
- (void) remove: (id)sender
{
	NSArray *selectedItems = [[self content] selectedItemsInLayout];

	//ETLog(@"Will remove selected items %@", selectedItems);
	/* Removed items are temporarily retained by the array returned by 
	   -selectedItemsInLayout, therefore we can be sure we won't trigger the 
	   release of an already deallocated item. The typical case would be 
	   removing an item from a parent that was also selected and already got 
	   removed from the layout item tree. */
	[selectedItems makeObjectsPerformSelector: @selector(removeFromParent)];
}

/** Returns the next responder in the responder chain. 

The next responder is the enclosing item of the item to which the controller 
is bound to.

You can override this method in a subclass, although it should rarely be needed. */
- (id) nextResponder
{
	return [[self content] enclosingItem];
}

/** Returns the initial focused item.

If the controller content is a first responder sharing area without a focused 
item, and on the way to become visible, the content decorator item that conforms 
to ETFirstResponderSharingArea protocol gives the focus to the initial focused 
item.

If the decorator item that represents the first responder sharing area is higher 
in the item tree (not set on the controller content), the receiver initial 
focused item is ignored.

If the item is not a controller content descendant item, an 
NSInternalInconsistencyException is raised.

By default, returns nil. */
- (ETLayoutItem *) initialFocusedItem
{
	if (_initialFocusedItem != nil
	 && [[[self content] allDescendantItems] containsObject: _initialFocusedItem] == NO)
	{
		[NSException raise: NSInternalInconsistencyException
		            format: @"Initial focused item %@ must be a content descendant item",
					        _initialFocusedItem];
	}
	return _initialFocusedItem;
}

/** Sets the initial focused item.

See -initialFocusedItem. */
- (void) setInitialFocusedItem: (ETLayoutItem *)anItem
{
	// NOTE: We don't raise a NSInvalidArgumentException similar to the one in
	// -initialFocusedItem, to let the user call -setInitialFocusedItem: without
	// a content. Item factories use a top-down recursive UI construction, so 
	// the content is not set until all the descendant items are built.
	ASSIGN(_initialFocusedItem, anItem);
}

/* Insertion */

/** Returns a new retained ETLayoutItem or ETLayoutItemGroup object for the 
given URL and options.

The template to which the item instantiation is delegated is looked up based 
on the UTI argument and the registered item templates.<br />
See -setTemplate:forType: to register new templates.

If the given URL is nil, the user action is a 'New' and not 'Open'.

This method is used by -add: and -insert: actions to generate the object to be 
inserted into the content of the controller.<br />
You must use this method in any 'add' or 'insert' action methods to mutate the 
controller content.

Raises an NSInvalidArgumentException if the given type is nil.

The returned object is retained.

See also ETItemTemplate. */
- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL ofType: (ETUTI *)aUTI options: (NSDictionary *)options
{
	NILARG_EXCEPTION_TEST(aUTI);
	return [[self templateForType: aUTI] newItemWithURL: aURL options: options];
}

- (NSString *) insertionKeyForCollection: (id <ETKeyedCollection>)aCollection
{
	NSString *key = [self insertionKey];
	NSString *uniqueKey = key;
	NSUInteger counter = 0;
	BOOL isUsed = NO;

	do
	{
		if (counter > 0)
		{
			uniqueKey = [NSString stringWithFormat: @"%@ %lu", key, (unsigned long)counter];
		}
		// TODO: Remove the content call once -objectForKey: is included in ETKeyedCollection
		isUsed = ([[aCollection content] objectForKey: uniqueKey] != nil);
		counter++;
	} while (isUsed);

	return uniqueKey;
}

/** Returns the current options that controls the content mutation.

A common option is kETTemplateOptionPersistentObjectContext (bound to 
-persistentObjectContext). Another one is 
kETTemplateOptionModelDescriptionRepository that is retrieved against the 
persistent object context.
 
When calling methods that includes a <em>options</em> argument such as 
-newItemWithURL:ofType:options:, you must use -defaultOptions for the argument. 

Extra options can be added to the returned dictionary. */
- (NSDictionary *)defaultOptions
{
	NSMutableDictionary *options = [NSMutableDictionary dictionary];
	ETModelDescriptionRepository *repo = [ETModelDescriptionRepository mainRepository];

	if ([self persistentObjectContext] != nil)
	{
		repo = [[[self persistentObjectContext] editingContext] modelDescriptionRepository];
	}
	
	id representedObject = [[self content] representedObject];

	if ([self persistentObjectContext] != nil)
	{
		[options setObject: [self persistentObjectContext]
		            forKey: kETTemplateOptionPersistentObjectContext];
	}
	if (repo != nil)
	{
		[options setObject: repo forKey: kETTemplateOptionModelDescriptionRepository];
	}
	if ([representedObject isCollection] && [(id <ETCollection>)representedObject isKeyed])
	{
		[options setObject: [self insertionKeyForCollection: representedObject]
		            forKey: kETTemplateOptionKeyValuePairKey];
	}
	if (representedObject != nil && [[self content] usesRepresentedObjectAsProvider])
	{
		[options setObject: representedObject forKey: kETTemplateOptionParentRepresentedObject];
	}

	return AUTORELEASE([options copy]);
}

/** Returns whether remove, add and insert actions are possible.

By default, returns -isContentMutable value.

This method is invoked by -add:, -addNewGroup:, -insertGroup:, -insert: and 
-remove:. You must call it in new mutation action methods you implement. For 
example, if you implement - (IBAction) addNewMailbox: (id)sender, the code 
should look like:

<example>
if ([self canMutate])
{
	id mailboxItem = [[self templateForType: mailboxUTI] newItemWithURL: nil options: [self defaultOptions]];
	[self insertItem: mailboxItem atIndex: ETUndeterminedIndex];
}
</example>

If you want to change the return value of -canMutate based on the type of object 
you insert, then you can implement a related method. For the example above:

<example>
- (BOOL) canMutateForMailbox
{
	return [self canMutate] &amp;&amp; otherCondition;
}

- (IBAction) addNewMailbox
{
	if ([self canMutateForMailbox])
	{
		id mailboxItem = [[self templateForType: mailboxUTI] newItemWithURL: nil options: [self defaultOptions]];
...
</example>

More specialized methods per operation could be implemented. For example:
<list>
<item>-insertNewMailbox: would use -canInsertMailbox</item>
<item>-addNewMailbox: woul use -canAddMailbox</item>
<item>-removeCurrentMailbox: would use -canRemoveMailbox</item>
</list>
Alternatively -insertMailbox: and -addNewMailbox could both use -canInsertMailbox. */
- (BOOL) canMutate
{
	return [self isContentMutable];
}

/** Returns whether the content item group can be mutated.

When the content represented object is not a mutable collection, returns NO, 
otherwise returns YES.

You shouldn't use this method but rather -canMutate. */
- (BOOL) isContentMutable
{
	if ([[self content] representedObject] != nil)
	{
		return [[[self content] representedObject] isMutableCollection];
	}

	/* Same as [[self content] isMutableCollection] */
	return YES;
}

/** <override-dummy />
Returns the insertion key used for a keyed collection content.

If the representedObject bound to the controller content returns YES to -isKeyed, 
the insertion key is included in -defaultOptions, and passed to 
-[ETItemTemplate newItemWithURL:options:]. The new item then usually uses a 
ETKeyValuePair object as its represented object.

By default, returns <em>Unknown</em>.

Can be overriden to return a custom value but must not return nil.
 
See kETTemplateOptionKeyValuePairKey. */
- (NSString *) insertionKey
{
	return _(@"Unknown");
}

/** Returns the position in the content, at which -insert: and -insertGroup: 
will insert the object they create.<br />
The returned value is the last selection index + 1 in the content, or the 
content count (no selection).

No selection means that -selectionIndexes on the content returns an empty set.

This method can be overriden to return a custom index. */
- (NSInteger) insertionIndex
{
	NSInteger index = [[[self content] selectionIndexes] lastIndex];

	/* No selection or no items */
	return (index != NSNotFound ? index + 1 : [[self content] numberOfItems]);
}

/** Returns the index path into the content, at which insert: and insertGroup:
will insert the object they create.

The returned value is the next sibling of the selected index in the content,
or the content count (no selection).

The selected index path for this method is the last selected item in the content. */
- (NSIndexPath *) insertionIndexPath
{
	NSIndexPath *resultPath;
	NSArray *indexPaths = [[self content] selectionIndexPaths];

	//ETLog(@"selectionIndexPaths = %@", [indexPaths descriptionWithLocale: nil]);

	if ([indexPaths count] > 0)
	{
		NSIndexPath *selectionPath = [indexPaths lastObject];

		int lastIndex = [selectionPath indexAtPosition: [selectionPath length] - 1];
		selectionPath = [selectionPath indexPathByRemovingLastIndex];
		resultPath = [selectionPath indexPathByAddingIndex: lastIndex + 1];
		
	}
	else
	{
		resultPath = [NSIndexPath indexPathWithIndex: [[self content] numberOfItems]];
	}

	//ETLog(@"insertionIndexPath = %@", resultPath);
	return resultPath;
}

/** Returns the index path into the content, at which add: and addNewGroup:
will insert the object they create.

The returned value is the last child of the selected index in the content,
the next sibling (when the selected index path is a leaf node),
or the content count (no selection).

The selected index path for this method is the last selected item in the content. */
- (NSIndexPath *) additionIndexPath
{
	NSIndexPath *resultPath = [self insertionIndexPath];
	NSArray *indexPaths = [[self content] selectionIndexPaths];
	NSIndexPath *selectionPath = [indexPaths lastObject];
	ETLayoutItem *selectionItem = [[self content] itemAtIndexPath: selectionPath];

	// Add as a child if the selected item is a layout item group. Otherwise,
	// we just add as the next sibling to the selected layout item.	
	if ([selectionItem isGroup])
	{

		int lastChildIndexInSelectedItem = [(ETLayoutItemGroup *)selectionItem numberOfItems];
		resultPath = [selectionPath indexPathByAddingIndex: lastChildIndexInSelectedItem];
	}

	//ETLog(@"additionIndexPath = %@", resultPath);
	return resultPath;
}

/** Removes the filtering if -clearsFilterPredicateOnInsertion is YES, inserts 
the item at the given index and selects the inserted item if 
-selectsInsertedObjects is YES. 

You must use this method to mutate the content in new or overriden insertion 
action methods (e.g. -add: or -insertNewGroup:).

Although the inserted object is usually an ETLayoutItem or ETLayoutItemGroup 
instance, you can pass an arbitrary object, it will get automatically boxed into 
a layout item based on the receiver template.

You can pass ETUndeterminedIndex to trigger -[ETLayoutItemGroup addObject:] on 
the content rather than -[ETLayoutItemGroup insertObject:atIndex:].  */
- (void) insertItem: (ETLayoutItem *)anItem atIndex: (NSUInteger)anIndex
{
	ETAssert(nil != [self content]);

	if ([self clearsFilterPredicateOnInsertion])
	{
		[self setFilterPredicate: nil];
	}

	if (ETUndeterminedIndex == anIndex)
	{
		[[self content] addObject: anItem];
	}
	else
	{
		[[self content] insertObject: anItem atIndex: anIndex];
	}
	ETAssert(nil != [anItem parentItem]);

	if ([self selectsInsertedObjects])
	{
		NSUInteger selectionIndex = anIndex;
		if (ETUndeterminedIndex == selectionIndex)
		{
			selectionIndex = [[self content] indexOfItem: anItem];
		}
		[[self content] setSelectionIndex: selectionIndex];
	}
}

/** Removes the filtering if -clearsFilterPredicateOnInsertion is YES, inserts 
the item at the given index path and selects the inserted item if 
-selectsInsertedObjects is YES. 

You must use this method to mutate the content in new or overriden insertion 
action methods (e.g. -add: or -insertNewGroup:).

Although the inserted object is usually an ETLayoutItem or ETLayoutItemGroup 
instance, you can pass an arbitrary object, it will get automatically boxed into 
a layout item based on the receiver template.

You can pass nil to trigger -[ETLayoutItemGroup addObject:] on 
the content rather than -[ETLayoutItemGroup insertObject:atIndex:].  */
- (void) insertItem: (ETLayoutItem *)anItem atIndexPath: (NSIndexPath *)anIndexPath
{
	NSIndexPath *selectionIndexPath = anIndexPath;

	ETAssert(nil != [self content]);

	if ([self clearsFilterPredicateOnInsertion])
	{
		[self setFilterPredicate: nil];
	}

	if (nil == anIndexPath)
	{
		[[self content] addObject: anItem];
		selectionIndexPath = [NSIndexPath indexPathWithIndex: [[self content] count] - 1]; 
	}
	else
	{
		ETLayoutItemGroup *parentItem = (ETLayoutItemGroup *)[[self content]
			itemAtIndexPath: [anIndexPath indexPathByRemovingLastIndex]];
		NSUInteger index = [anIndexPath indexAtPosition: [anIndexPath length] - 1];

		if (nil == parentItem)
		{
			parentItem = [self content];
		}

		ETAssert([parentItem isGroup]);
		
		if (NSNotFound == index)
		{
			ETAssert([anIndexPath length] == 0);
			// This can only occur if [anIndexPath length] == 0,
			// therefore this is a top-level index path
			index = [parentItem count];
			selectionIndexPath = [NSIndexPath indexPathWithIndex: index];
		}
		
		[parentItem insertObject: anItem atIndex: index];
	}

	ETAssert(nil != [anItem parentItem]);

	if ([self selectsInsertedObjects])
	{
		[[self content] setSelectionIndexPaths: A(selectionIndexPath)];
	}
}

/** Returns whether the filter predicate should be discarded when a new 
item is inserted.

By default, return YES. */
- (BOOL) clearsFilterPredicateOnInsertion
{
	return _clearsFilterPredicateOnInsertion;
}

/** Sets whether the filter predicate should be discarded when a new 
item is inserted. */
- (void) setClearsFilterPredicateOnInsertion: (BOOL)clear
{
	_clearsFilterPredicateOnInsertion = YES;
}

/** Returns whether new items should be selected on insertion.

By default, returns YES. */
- (BOOL) selectsInsertedObjects
{
	return _selectsInsertedObjects;
}

/** Sets whether new items should be selected on insertion. */
- (void) setSelectsInsertedObjects: (BOOL)select
{
	_selectsInsertedObjects = select;
}

/** Returns the sort descriptors used to sort the content associated with the 
receiver.

By default, returns an empty array. */
- (NSArray *) sortDescriptors
{
	return AUTORELEASE([_sortDescriptors copy]);
}

/** Set the sort descriptors used to sort the content associated with the 
receiver. */
- (void) setSortDescriptors: (NSArray *)sortDescriptors
{
	if (sortDescriptors != nil)
	{
		ASSIGNCOPY(_sortDescriptors, sortDescriptors);
	}
	else
	{
		_sortDescriptors = [[NSArray alloc] init];
	}
	_hasNewSortDescriptors = YES;
	if ([self automaticallyRearrangesObjects])
		[self rearrangeObjects];
}

/** Returns the search predicate to filter the controller content. */
- (NSPredicate *) filterPredicate
{
	return _filterPredicate;
}

/** Sets the search predicate to filter the controller content. */
- (void) setFilterPredicate: (NSPredicate *)searchPredicate
{
	ASSIGN(_filterPredicate, searchPredicate);
	_hasNewFilterPredicate = YES;
	if ([self automaticallyRearrangesObjects])
		[self rearrangeObjects];
}

/** Arranges the objects in the content by sorting them, then filtering them 
with -filterPredicate if the returned predicate is not nil. 

If the content is a tree structure, the entire tree is rearranged recursively 
by sorting and filtering each item group that get traversed.

You can override this method to implement another sort and filter strategy than 
the default one based on 
-[ETLayoutItemGroup sortWithSortDescriptors:recursively:], -sortDescriptors, 
-[ETLayoutItemGroup filterWithPredicate:recursively:] and -filterPredicate . */
- (void) rearrangeObjects
{
	if (_hasNewContent || _hasNewSortDescriptors)
		[[self content] sortWithSortDescriptors: [self sortDescriptors] recursively: YES];

	if (_hasNewContent || _hasNewFilterPredicate)
		[[self content] filterWithPredicate: [self filterPredicate] recursively: YES];

	if (_hasNewContent || _hasNewSortDescriptors || _hasNewFilterPredicate)
	{
		// FIXME: Looks -setNeedsUpdateLayout doesn't work here. In
		// ObjectManagerExample, the layout are not updated in ETIconLayout and
		// and in ETTableLayout there is a crash because the table view still
		// presents -item rather than -arrangedItems. Wierdly we also lost
		// the focus in the search field.
		//[[self content] setNeedsLayoutUpdate];
		[[self content] updateLayoutRecursively: YES];
	}
}

/** Returns whether -rearrangeObjects should be automatically called when 
-setFilterPredicate: is called.

Returns YES by default. */
- (BOOL) automaticallyRearrangesObjects
{
	return _automaticallyRearrangesObjects;
}

/** Sets whether -rearrangeObjects should be automatically called when 
-setFilterPredicate: is called. */
- (void) setAutomaticallyRearrangesObjects: (BOOL)flag
{
	_automaticallyRearrangesObjects = flag;
}

/* Pick and Drop */

- (NSArray *) allowedPickTypes
{
	return _allowedPickTypes;
}

- (void) setAllowedPickTypes: (NSArray *)UTIs
{
	NILARG_EXCEPTION_TEST(UTIs);

    [self willChangeValueForProperty: @"allowedPickTypes"
                           atIndexes: [NSIndexSet indexSet]
                         withObjects: A(UTIs)
                        mutationKind: ETCollectionMutationKindReplacement];

	ASSIGN(_allowedPickTypes, UTIs);

    [self didChangeValueForProperty: @"allowedPickTypes"
                           atIndexes: [NSIndexSet indexSet]
                         withObjects: A(UTIs)
                        mutationKind: ETCollectionMutationKindReplacement];
}

/* -allowedDropTypesForTargetType: can be rewritten with HOM. Not sure it won't
too slow given that the method tends to be invoked repeatedly.

	NSArray *matchedTargetTypes = [[[_allowedDropTypes allKeys] filter] conformsToType: targetType];
	NSArray *matchedDropTypeArrays = [_allowedDropTypes objectsForKeys: matchedTargetTypes
	                                                    notFoundMarker: [NSNull null]];

	return [matchedDropTypeArrays flattenedCollection]; */

- (NSArray *) allowedDropTypesForTargetType: (ETUTI *)aUTI
{
	NILARG_EXCEPTION_TEST(aUTI);
	NSMutableArray *matchedDropTypes = [NSMutableArray arrayWithCapacity: 100];
	
	for (NSString *target in _allowedDropTypes)
	{
		ETUTI *targetType = [ETUTI typeWithString: target];

		if ([aUTI conformsToType: targetType])
		{
            ETUTITuple *UTITuple = [_allowedDropTypes objectForKey: target];

			[matchedDropTypes addObjectsFromArray: [UTITuple content]];
		}
	}

	return matchedDropTypes;
}

- (void) setAllowedDropTypes: (NSArray *)UTIs forTargetType: (ETUTI *)targetUTI
{
	NILARG_EXCEPTION_TEST(targetUTI);
	NILARG_EXCEPTION_TEST(UTIs);

    [self willChangeValueForProperty: @"allowedDropTypes"
                           atIndexes: [NSIndexSet indexSet]
                         withObjects: A(UTIs)
                        mutationKind: ETCollectionMutationKindReplacement];

	ETUTITuple *UTITuples = [_allowedDropTypes objectForKey: [targetUTI stringValue]];

    if (UTITuples == nil)
    {
        UTITuples = [[ETUTITuple alloc] initWithObjectGraphContext: [self objectGraphContext]];
    }
    [UTITuples setContent: UTIs];

    [_allowedDropTypes setObject: UTITuples
                          forKey: [targetUTI stringValue]];

    [self didChangeValueForProperty: @"allowedDropTypes"
                          atIndexes: [NSIndexSet indexSet]
                        withObjects: A(UTIs)
                       mutationKind: ETCollectionMutationKindReplacement];
}

/* Editing */

/** Returns YES when one or several edited items are registered, otherwise NO.

See -allEditedItems. */
- (BOOL) isEditing
{
	return ([_editedItems isEmpty] == NO);
}

/** Tries to commit all the pending changes existing for the current edited 
items that were previously registered with 
-subjectDidBeginEditingForItem:property:.

When all pending changes have been committed and all editors have been 
unregistered returns YES, otherwise returns NO. */
- (BOOL) commitEditing
{
	FOREACH(_editedItems, item, ETLayoutItem *)
	{
		if ([item commitEditing] == NO)
		{
			return NO;
		}
		[_editedItems removeObject: item];
		[_editableProperties removeObjectAtIndex: [_editedItems indexOfObject: item]];
	}
	return YES;
}

/** Discards all the pending changes existing the current edited items that 
were previously registered with -subjectDidBeginEditingForItem:property:.

All the edited items get unregistered. */
- (void) discardEditing
{
	[[_editedItems mappedCollection] discardEditing];
	[_editedItems removeAllObjects];
	[_editableProperties removeAllObjects];
}

/** Notifies the controller the given item has begun to be edited.
 
For text editing, -subjectDidBeginEditingForItem:property is called only if the 
user types something. If the focus changes before the user has typed anything, 
-subjectDidEndEditingForItem:property: is sent (and no 
-subjectDidBeginEditingForItem:property: is ever sent).

You should never need to invoke this method.<br />
See instead -[ETLayoutItem subjectDidBeginEditingForProperty:fieldEditorItem:]. */
- (void) subjectDidBeginEditingForItem: (ETLayoutItem *)anItem
                              property: (NSString *)aKey
{
	NSParameterAssert([aKey isKindOfClass: [NSString class]]);
	ETLog(@" ---> Begin editing for %@ - %@ ", [anItem shortDescription], aKey);
	[_editedItems addObject: anItem];
	[_editableProperties addObject: aKey];
}

- (void) subjectDidChangeValueForItem: (ETLayoutItem *)anItem
                             property: (NSString *)aKey
{
	NSParameterAssert([aKey isKindOfClass: [NSString class]]);
	ETLog(@"Change value for %@ - %@", [anItem shortDescription], aKey);
}

/** Notifies the controller the editing which was underway in the given item 
has ended.

You should never need to invoke this method.<br />
See instead -[ETLayoutItem subjectDidEndEditingForProperty:]. */
- (void) subjectDidEndEditingForItem: (ETLayoutItem *)anItem
                            property: (NSString *)aKey
{
	NSParameterAssert([aKey isKindOfClass: [NSString class]]);
	ETLog(@" <--- End editing for %@ - %@ ", [anItem shortDescription], aKey);
	[_editedItems removeObject: anItem];
	[_editableProperties removeObject: aKey];
}

/** Returns the current edited layout item.

If the edited item doesn't belong to this controller, returns nil. This happens 
if the focus is in a first responder sharing area that is managed by another 
controller (either a controller bound to a descendant item or a controller in 
located elsewhere in the item tree).
 
You can use this method in action or delegate methods implemented in your
controller subclass.
 
The edited item is not the same as the editor item. If the editing is not 
managed entirely by the widget backend (in other words was initiated by using 
-[ETActionHandler beginEditingItem:property:inRect:]), the editor item can be 
retrieved through
<code>[[self editedItem] firstResponderSharingArea] activeFieldEditorItem]</code>.*/
- (id) editedItem
{
	ETLayoutItem *editedItem = [[self firstResponderSharingArea] editedItem];

	return ([_editedItems containsObject: editedItem] ? editedItem : nil);
}

/** Returns the current edited property for -editedItem.
 
If the edited item is nil, returns nil too.

You can use this method in action or delegate methods implemented in your 
controller subclass. */
- (NSString *) editedProperty
{
	ETLayoutItem *editedItem = [[self firstResponderSharingArea] editedItem];

	if ([_editedItems containsObject: editedItem] == NO)
		return nil;

	return [[self allEditedProperties] objectAtIndex: [_editedItems indexOfObject: editedItem]];
}

/** <override-never />
Returns the edited items for all the first responder sharing areas managed
by this controller.
 
In most cases, returns a single item, because the controller is located inside a 
first responder sharing area or is at the same level (which means there is a 
single focused item that translates into a single edited item).
First responder sharing areas cannot be nested. 
 
A controller bound to -[ETLayoutItemGroup windowGroup] is going to manage 
multiple edited items for all windows (aka first responder sharing areas) that 
don't have a controller bound to them.
 
Edited items are not the same editor items, see the explanations in -editedItem. */
- (NSArray *) allEditedItems
{
	return AUTORELEASE([_editedItems copy]);
}

/** <override-never />
Returns the edited properties for all the first responder sharing areas
managed by this controller.
 
The explanations concerning the number of returned objects for -allEditedItems 
apply to -allEditedProperties in the same way. */
- (NSArray *) allEditedProperties
{
	return AUTORELEASE([_editableProperties copy]);
}

/** <overidde-dummy />
Returns the items to be validated by -validateItems.

The returned items must be look using -[ETLayoutItemGroup itemForIdentifier:] or 
a property set on your ETController subclass, but never using an index e.g. 
-[ETLayoutItemGroup itemAtIndex:].

The returned items must be limited to descendant items. For example, returning 
an item such as <code>[[[controller content] parentItem] itemForIdentifier: someId]</code> 
in another item tree part or an ancestor item is not supported. */
- (NSSet *) validatableItems
{
	return [NSSet set];
}

/** Tells the receiver to enable and disable -validatableItems by using 
-validateItem:.

This method is automatically called by EtoileUI each time an event is processed, 
so you should rarely to call it. See -[ETEventProcessor runUpdatePhases]. */
- (void) validateItems
{
	for (ETLayoutItem *item in [self validatableItems])
	{
		[[[item view] ifResponds] setEnabled: [self validateItem: item]];
	}
}

/** <override-dummy />
Returns whether the item should be enabled or disabled now.

Can be overriden to indicate enabled items among -validatableItems. Items must 
be matched based on their identifier or their action. For unknow item, the 
superclass implementation must be called. For example:

<example>
if ([[anItem identifier] isEqual: @"add"])
{
	return [self canAdd];
}
else if (sel_isEqual([anItem action], @selector(print:))
{
	return [self isContentPrintable];
}
else
{
	return [super validateItem: anItem];
}
</example> */
- (BOOL) validateItem: (ETLayoutItem *)anItem
{
	return YES;
}

- (void) didProcessEvent: (NSNotification *)aNotif
{
	[self validateItems];
}

- (ETLayoutItem *) candidateFocusedItem
{
	return nil;
}

/* Framework Private */

/** This method is only exposed to be used internally by EtoileUI. 

Returns a shared and immutable template provider in which basic templates are 
registered for -currentObjectType and -currentGroupType. */
+ (id <ETTemplateProvider>) basicTemplateProviderForObjectGraphContext: (COObjectGraphContext *)aContext
{
	// NOTE: Must not be instantiated in +initialize otherwise several
	// ETUIObject subclass instances are initialized before all the model
	// descriptions are registered.
	return [self sharedInstanceForObjectGraphContext: aContext];
}

@end

ETUTI * kETTemplateObjectType = nil;
ETUTI * kETTemplateGroupType = nil;
