/*
	Copyright (C) 2011 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  February 2011
	License:  Modified BSD (see COPYING)
 */

#import "AppController.h"
#import "MarkupEditorItemFactory.h"


@implementation AppController

- (NSArray *) supportedTypes
{
#ifdef GNUSTEP
	return A([ETUTI typeWithFileExtension: @"plist"];
#else
	return A([ETUTI typeWithFileExtension: @"plist"], [ETUTI typeWithFileExtension: @"xml"]);
#endif
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	MarkupEditorItemFactory *itemFactory = [MarkupEditorItemFactory factory];

	[ETLayout registerLayout: [itemFactory editorLayout]];

	// TODO: plist and svg should be included in EtoileFoundation UTIDefinitions.plist surely
	[ETUTI registerTypeWithString: @"com.apple.property-list" description: @"Property List" supertypeStrings: [NSArray array] typeTags: D(A(@"plist"), kETUTITagClassFileExtension)];
	//[ETUTI registerTypeWithString: @"public.svg-image" description: @"Scalable Vector Graphics" supertypeStrings: A(@"public.image", @"public.xml") typeTags: D(A(@"svg"), kETUTITagClassFileExtension)];
										 
	[self setTemplate: [PListItemTemplate templateWithItem: [itemFactory editor] objectClass: [NSMutableDictionary class]]
	          forType: [ETUTI typeWithFileExtension: @"plist"]];
	/* Because we use UTIs, the line below means we can also open XML documents 
	   whose extensions is not 'xml' such as 'svg'.

	   Note: if we remove the plist item template set above, the plist files 
	   saved with the PList XML format should be openable with XMLItemTemplate. */
#ifndef GNUSTEP
	[self setTemplate: [XMLItemTemplate templateWithItem: [itemFactory editor] objectClass: [NSXMLDocument class]]
	          forType: [ETUTI typeWithFileExtension: @"xml"]];
#endif

	/* Set the type of the documented to be created by default with 'New' in the menu */
	[self setCurrentObjectType: [ETUTI typeWithFileExtension: @"plist"]];
	[[itemFactory windowGroup] setController: self];
	
	[self newDocument: nil];
	[self showEditorLayoutExample];
	[[ETPickboard localPickboard] showPickPalette];
}

- (IBAction) newWorkspace: (id)sender
{
	MarkupEditorItemFactory *itemFactory = [MarkupEditorItemFactory factory];

	[[itemFactory windowGroup] addItem: [itemFactory workspaceWithControllerPrototype: self]];
}

- (void) showEditorLayoutExample
{
	MarkupEditorItemFactory *itemFactory = [MarkupEditorItemFactory factory];
	ETLayoutItemGroup *item = [itemFactory itemGroupWithRepresentedObject: A(A(@"A", A(@"B")), A(@"C", @"D"))];

	[item setName: @"Editor Layout as a Pluggable Aspect Example"];
	[item setSource: item];
	/* Let us simulate a live switch */
	[item setLayout: [ETTableLayout layoutWithObjectGraphContext: [item objectGraphContext]]];

	[[itemFactory windowGroup] addItem: item];

	[item setLayout: [itemFactory editorLayout]];
	[item setSize: NSMakeSize(500, 400)];
}

@end


@implementation PListItemTemplate

- (ETLayoutItem *) contentItem
{
	return [(ETLayoutItemGroup *)[self item] itemForIdentifier: @"documentContent"];
}

- (ETLayoutItem *) newItemReadFromURL: (NSURL *)URL options: (NSDictionary *)options
{
	NSData *plistData = nil;
	id plistNode = nil;
	NSPropertyListFormat format;
    
	plistData = [NSData dataWithContentsOfURL: URL];
	plistNode = [NSPropertyListSerialization propertyListFromData: plistData
		mutabilityOption: NSPropertyListMutableContainersAndLeaves 
		format: &format errorDescription: NULL];
	
	return [self newItemWithRepresentedObject: plistNode URL: URL options: options];
}

@end


@implementation XMLItemTemplate

- (ETLayoutItem *) contentItem
{
	return [(ETLayoutItemGroup *)[self item] itemForIdentifier: @"documentContent"];
}

- (ETLayoutItem *) newItemReadFromURL: (NSURL *)URL options: (NSDictionary *)options
{
	id xmlNode = AUTORELEASE([[NSXMLDocument alloc] 
		initWithContentsOfURL: URL options: NSXMLDocumentTidyXML error: NULL]);
	
	return [self newItemWithRepresentedObject: xmlNode URL: URL options: options];
}

@end

@interface NSXMLNode (ETCollection) <ETCollection>
- (BOOL) isOrdered;
- (BOOL) isEmpty;
- (id) content;
- (NSArray *) contentArray;
- (NSUInteger) count;
@end

@interface NSXMLElement (ETCollectionMutation) <ETCollectionMutation>
- (void) addObject: (id)object;
- (void) insertObject: (id)object atIndex: (unsigned int)index;
- (void) removeObject: (id)object;
@end

@implementation NSXMLNode (ETCollection)

- (BOOL) isOrdered { return YES; }

- (BOOL) isEmpty { return ([self count] == 0); }

- (id) content { return [self children]; }

- (NSArray *) contentArray { return [self content]; }

- (NSUInteger) count { return [self childCount]; }

@end

@implementation NSXMLElement (ETCollectionMutation)

- (void) addObject: (id)object 
{ 
	[self addChild: object];
}

- (void) insertObject: (id)object atIndex: (unsigned int)index
{ 
	[self insertChild: object atIndex: index];
}

- (void) removeObject: (id)object
{
	/* Next line is similar to [(NSXMLNode *)object detach] */
	[self removeChildAtIndex: [(NSXMLNode *)object index]];
}

@end
