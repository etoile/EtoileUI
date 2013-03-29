/*
	Copyright (C) 2010 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  October 2010
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETUTI.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import "ETItemTemplate.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"


@implementation ETItemTemplate

/** Returns a new autoreleased template based on the given item and 
represented object class. */
+ (id) templateWithItem: (ETLayoutItem *)anItem objectClass: (Class)aClass
{
	return AUTORELEASE([[self alloc] initWithItem: anItem objectClass: aClass]);
}

/** <init />
Initializes and returns a new template based on the given item and 
represented object class.

Raises an NSInvalidArgumentException if the item is nil. */
- (id) initWithItem: (ETLayoutItem *)anItem objectClass: (Class)aClass
{
	NILARG_EXCEPTION_TEST(anItem);
	SUPERINIT;
	ASSIGN(_item, anItem);
	ASSIGN(_objectClass, aClass);
	return self;
}

- (void) dealloc
{
	DESTROY(_item);
	DESTROY(_objectClass);
	[super dealloc];
}

/** Returns the represented object template class

Can return Nil. 

See also -newItemWithURL:options:. */
- (Class) objectClass
{
	return _objectClass;
}

/** Returns the template item.

See also -newItemWithRepresentedObject:options:. */
- (ETLayoutItem *) item
{
	return _item;
}

/** <override-dummy />
Returns the item to which the represented object should be attached to.

By default, returns -item.

Can be overriden to return a descendant item. */
- (ETLayoutItem *) contentItem
{
	return [self item];
}

- (NSString *) baseName
{
	return _(@"Untitled");
}

/** Returns a new retained ETLayoutItem or ETLayoutItemGroup object with the 
given represented object and options.

The returned item is a copy of -item.<br />
The represented object will be attached to a copy of -contentItem.

All arguments can be nil.

Can be overriden in subclasses. */
- (ETLayoutItem *) newItemWithRepresentedObject: (id)anObject options: (NSDictionary *)options
{
	NSIndexPath *contentIndexPath = [[self contentItem] indexPathFromItem: [self item]];
	id newItem = [[self item] deepCopy];
	ETLayoutItem *newContentItem = ([newItem isGroup] ? [newItem itemAtIndexPath: contentIndexPath] : newItem);

	/* We don't set the object as model when it is nil, so any existing value 
	   or represented object already provided with the item won't be overwritten 
	   in such case. 
	   Value and represented object are copied when -deepCopy is called on the 
	   template items in -[ETItemTemplate newItemWithRepresentedObject:options]. */
	if (nil != anObject)
	{
		[newContentItem setRepresentedObject: anObject];
	}

	return newItem;
}

- (void) setUp: (id)item withURL: (NSURL *)aURL options: (NSDictionary *)options
{
	if (aURL != nil)
	{
		[(ETLayoutItem *)[item ifResponds] setIcon: [[NSWorkspace sharedWorkspace] iconForFile: [aURL path]]];
		[(ETLayoutItem *)[item ifResponds] setName: [[aURL path] lastPathComponent]];
	}
	else
	{
		// TODO: Support retrieving the item template bound type through the options
		[(ETLayoutItem *)[item ifResponds]  setIcon: [[NSWorkspace sharedWorkspace] iconForFileType: @"plist"]];
		[(ETLayoutItem *)[item ifResponds] setName: [self nameFromBaseNameAndOptions: options]];
	}
}

- (ETLayoutItem *) newItemWithRepresentedObject: (id)anObject URL: (NSURL *)aURL options: (NSDictionary *)options
{
	id newItem = [self newItemWithRepresentedObject: anObject options: options];
	[self setUp: [newItem subject] withURL: aURL options: options];
	return newItem;
}

/** Returns a new retained ETLayoutItem or ETLayoutItemGroup object for the 
given URL and options.

If -objectClass is not Nil, a represented object is instantiated with -init or 
-initWithURL:options: if the object class conforms to ETDocumentCreation protocol.

If the given URL is nil, the user action is a 'New' and not 'Open'.

All arguments can be nil.

Can be overriden in subclasses.

See also -newItemWithRepresentedObject:options:. */
- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	id newInstance = [[self objectClass] alloc];

	if ([newInstance conformsToProtocol: @protocol(ETDocumentCreation)])
	{
		
		newInstance = [newInstance initWithURL: aURL options: options];
	}
	else
	{
		newInstance = [newInstance init];
	}

	return [self newItemWithRepresentedObject: AUTORELEASE(newInstance) URL: aURL options: options];
}

- (ETLayoutItem *) newItemReadFromURL: (NSURL *)aURL options: (NSDictionary *)options
{
	return [self newItemWithURL: aURL options: options];
}

- (BOOL) writeItem: (ETLayoutItem *)anItem 
             toURL: (NSURL *)aURL 
           options: (NSDictionary *)options
{
	return NO;
}

- (NSArray *) supportedTypes
{
	if ([self objectClass] != nil)
	{
		return A([ETUTI typeWithClass: [self objectClass]]);	
	}
	else if ([[self item] representedObject] != nil)
	{
		return A([[[self item] representedObject] UTI]);
	}
	else
	{
		// TODO: Return compound document UTI
		return nil;
	}
}

- (NSURL *) URLFromRunningSavePanel
{
	ETAssert([self supportedTypes] != nil);

	NSSavePanel *sp = [NSSavePanel savePanel];

	// NOTE: GNUstep supports only extensions in NSOpen/SavePanel API unlike 
	// Cocoa which accepts UTI strings.
#ifdef GNUSTEP
	NSArray *fileExtensionArrays = [[[self supportedTypes] mappedCollection] fileExtensions];
	NSMutableArray *types = [NSMutableArray array];

	// TODO: Should be rewritten [[[[self supportedTypes] mappedCollection] fileExtensions] flattenedCollection]
	FOREACH(fileExtensionArrays, extensionArray, NSArray *)
	{
		if ([extensionArray isEqual: [NSNull null]])
			continue;

		[types addObjectsFromArray: extensionArray];
	}
#else
	NSArray *types = (NSArray *)[[[self supportedTypes] mappedCollection] stringValue];
#endif
	[sp setAllowedFileTypes: types];

	return ([sp runModal] == NSFileHandlingPanelOKButton ? [sp URL] : nil);
}

/** <override-dummy />
Returns whether the same document can appear multiple times on screen for 
the given URL. 

By default, returns NO.

Can be overriden in a subclass to implement a web browser for example. */
- (BOOL) allowsMultipleInstancesForURL: (NSURL *)aURL
{
	return NO;
}

- (NSString *) nameFromBaseNameAndOptions: (NSDictionary *)options
{
	/*NSString *customName = [options objectForKey: kETTemplateOptionName];
	
	if (nil != customName)
		return customName;*/

	NSUInteger nbOfVisibleDocs = [[options objectForKey: kETTemplateOptionNumberOfUntitledDocuments] unsignedIntegerValue];

	if (nbOfVisibleDocs == 0)
		return [self baseName];

	return [NSString stringWithFormat: @"%@ %lu", [self baseName], (unsigned long)nbOfVisibleDocs + 1];
}

@end

NSString * const kETTemplateOptionNumberOfUntitledDocuments = @"kETTemplateOptionNumberOfUntitledDocuments";
NSString * const kETTemplateOptionPersistentObjectContext = @"kETTemplateOptionPersistentObjectContext";


#ifdef COREOBJECT
@implementation COObject (ETItemTemplate)

- (id) initWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	self = [self init];
	if (self == nil)
		return nil;

	id <COPersistentObjectContext> context =
	[options objectForKey: kETTemplateOptionPersistentObjectContext];
	
	if (context == nil)
	{
		DESTROY(self);
		return nil;
	}
	
	BOOL isEditingContext =
		[context respondsToSelector: @selector(insertNewPersistentRootWithRootObject:)];
	
	if (isEditingContext)
	{
		[(COEditingContext *)context insertNewPersistentRootWithRootObject: self];
	}
	else
	{
		[self becomePersistentInContext: (COPersistentRoot *)context];
	}
	return self;
}

@end
#endif
