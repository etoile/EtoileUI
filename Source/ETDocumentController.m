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
#import "ETDocumentController.h"
#import "ETItemTemplate.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETPickDropActionHandler.h" /* For ETUndeterminedIndex */
#import "ETTool.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"


@implementation ETDocumentController

- (void) dealloc
{
	DESTROY(_error);
	[super dealloc];
}

/** Returns the items that match the given UTI in the receiver content.

Each item subtype must conform to the given type to be matched.

See -[ETLayoutItem subtype] and -[ETUTI conformsToType:]. */
- (NSArray *) itemsForType: (ETUTI *)aUTI
{
 	NSMutableArray *items = AUTORELEASE([[self content] mutableCopy]); 
	[[(ETLayoutItem *)[items filter] subtype] conformsToType: aUTI];
	return items;
}

/** Returns the items that match the given URL in the receiver content.

Either the item or its represented object must have a URL property to be 
matched.

The returned array usually contains a single item, unless the application allows 
to open multiple instances of the same document (e.g. a web browser). */
- (NSArray *) itemsForURL: (NSURL *)aURL
{
	NSMutableArray *items = AUTORELEASE([[[self content] items] mutableCopy]); 
	[[[items filter] valueForProperty: @"URL"] isEqual: aURL];
	return items;
}

// TODO: Implement
- (NSArray *) documentItems
{
	return nil;
}

// TODO: Implement
- (id) activeItem
{
	if ([[[self content] layout] isKindOfClass: NSClassFromString(@"ETWindowLayout")])
	{
		return [[ETTool activeTool] mainItem];
	}
	else
	{
		return [[self content] itemAtIndex: [[self content] selectionIndex]];
	} 
}

/** Returns a retained ETLayoutItem or ETLayoutItemGroup object that presents the 
content at the given URL.

This method doesn't create the returned item but delegates that to 
-[ETItemTemplate newItemReadFromURL:options:].

This method is used by -openDocument: action to generate the object to be 
inserted into the content of the controller.<br />
You must use this method in any 'open' action methods to open a content unit 
and mutate the controller content.

See -allowsMultipleInstancesForURL: to enable repopening a content unit already 
opened.

The returned object is retained.

Raises a NSInvalidArgumentException if the given URL is nil. */
- (ETLayoutItem *) openItemWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	NILARG_EXCEPTION_TEST(aURL); 

	if (NO == [self allowsMultipleInstancesForURL: aURL]
	 && NO == [[self itemsForURL: aURL] isEmpty])
	{
			ETAssert(1 == [[self itemsForURL: aURL] count]);
			return [[self itemsForURL: aURL] firstObject];
	}

	ETUTI *type = [[self class] typeForURL: aURL];

	return [[self templateForType: type] newItemReadFromURL: aURL 
	                                                options: options];
}

/** Returns whether the same document can appear multiple times on screen for 
the given URL. 

By default, tries to find a template that matches the content type at the given 
URL and delegates -allowsMultipleInstancesForURL: to it. If no template can be 
found, returns NO.

You should usually override -[ETItemTemplate allowsMultipleInstancesForURL:] 
and not this method. */
- (BOOL) allowsMultipleInstancesForURL: (NSURL *)aURL
{
	ETItemTemplate *template = [self templateForType: [[self class] typeForURL: aURL]];

	if (nil != template)
		return [template allowsMultipleInstancesForURL: aURL];

	return NO;
}

/** <override-dummy />
Returns the content types the application can read or write.

By default, returns an array that contains only the current object type.

Can be overriden to return multiple types if the application can view or edit 
more than a single content type. */
- (NSArray *) supportedTypes
{
	return A([self currentObjectType]);
}

/** Returns the UTI that describes the content at the given URL.

Will call -[ETUTI typeWithPath:] to determine the type, can be overriden to 
implement a tailored behavior. */
+ (ETUTI *) typeForURL: (NSURL *)aURL
{
	// TODO: If UTI is nil, set error.
	return [ETUTI typeWithPath: [aURL path]];
}

/** <override-dummy />
Returns the UTI that describes the item (or its content) to be saved or 
written. 

The returned UTI is used to look up the template to which the writing/saving 
is delegated.

By default, returns the item represented object UTI, otherwise the item UTI. */
- (ETUTI *) typeForWritingItem: (ETLayoutItem *)anItem
{
	NSParameterAssert(nil != anItem);
	return [[anItem subject] UTI];
}

- (NSArray *) URLsFromRunningOpenPanel
{
	NSOpenPanel *op = [NSOpenPanel openPanel];

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
	NSArray *types = [[[self supportedTypes] mappedCollection] stringValue];
#endif
	[op setAllowedFileTypes: types];
	[op setAllowsMultipleSelection: YES];
	[op setCanChooseDirectories: YES];

	ETLog(@"Will run open panel for document types %@", [op allowedFileTypes]);

	return ([op runModal] == NSFileHandlingPanelOKButton ? [op URLs] : [NSArray array]);
}

/** Creates a new object of the current object type and adds it to the receiver 
content.

Will call -newInstanceWithURL:ofType:options: to create the new document.

See also -currentObjectType. */
- (IBAction) newDocument: (id)sender
{
	ETLayoutItem *item = AUTORELEASE([self newItemWithURL: nil 
	                                               ofType: [self currentObjectType] 
	                                              options: [NSDictionary dictionary]]);
	[self insertObject: item atIndex: ETUndeterminedIndex];
}

/** Creates one or more objects with the URLs the user has choosen in an open 
panel and adds them to the receiver content.

Will call -openInstanceWithURL:options: to open the document(s).

See also [ETDocumentCreation] protocol. */
- (IBAction) openDocument: (id)sender
{
	NSArray *urls = [self URLsFromRunningOpenPanel];

	if ([urls isEmpty])
		return;

	NSDictionary *options = nil;
	ETLayoutItem *openedItem = nil;

	/* Open each URL content */
	FOREACH(urls, url, NSURL *)
	{
		openedItem = [[self itemsForURL: url] firstObject];

		[self insertObject: AUTORELEASE([self openItemWithURL: url options: options])
		           atIndex: ETUndeterminedIndex];
	}

	/* Highlight or bring to the front the last opened item */
	if (nil != openedItem)
	{
		[[self content] setSelectionIndex: [[self content] indexOfItem: openedItem]];
		return;
	}

}

- (IBAction) saveDocument: (id)sender
{
	ETUTI *type =  [self typeForWritingItem: [self activeItem]]; 
	ETAssert(nil != type);
	ETItemTemplate *template = [self templateForType: type]; 
	ETAssert(nil != template);

	[template writeItem: [self activeItem] toURL: nil options: nil];	
}

/** Returns the last error that was reported to the receiver. */
- (NSError *) error
{
	return _error;
}

@end

