/*
	Copyright (C) 2011 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  February 2011
	License:  Modified BSD (see COPYING)
 */

#import "AppController.h"
#import "MarkupEditorItemFactory.h"


@implementation AppController

- (void) showEditorLayoutExample
{
	MarkupEditorItemFactory *itemFactory = [MarkupEditorItemFactory factory];
	ETLayoutItemGroup *item = [itemFactory itemGroupWithRepresentedObject: A(A(@"A", A(@"B")), A(@"C", @"D"))];

	[item setName: @"Editor Layout as a Pluggable Aspect Example"];
	[item setSource: item];
	/* Let us simulate a live switch */
	[item setLayout: [ETTableLayout layout]];

	[[itemFactory windowGroup] addItem: item];

	[item setLayout: [itemFactory editorLayout]];
	[item setSize: NSMakeSize(500, 400)];
	
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	MarkupEditorItemFactory *itemFactory = [MarkupEditorItemFactory factory];

	[ETLayout registerLayout: [itemFactory editorLayout]];

	// TODO: plist should be included in EtoileFoundation UTIDefinitions.plist surely
	[ETUTI registerTypeWithString: @"com.apple.property-list" description: @"Property List" supertypeStrings: [NSArray array] typeTags: D(A(@"plist"), kETUTITagClassFileExtension)];
										 
	[self setTemplate: [PListItemTemplate templateWithItem: [itemFactory editor] objectClass: [NSMutableDictionary class]]
	          forType: [ETUTI typeWithFileExtension: @"plist"]];
	/* Because we use UTIs, the line below means we can also open XML documents 
	   whose extensions is not 'xml' such as 'svg'.

	   Note: if we remove the plist item template set above, the plist files 
	   saved with the PList XML format should be openable with XMLItemTemplate. */
	/*[self setTemplate: [XMLItemTemplate templateWithItem: [itemFactory editor] objectClass: [NSMutableDictionary class]]
	          forType: [ETUTI typeWithFileExtension: @"xml"]];*/

	/* Set the type of the documented to be created by default with 'New' in the menu */
	[self setCurrentObjectType: [ETUTI typeWithFileExtension: @"plist"]];
	[[itemFactory windowGroup] setController: self];
	
	[self newDocument: nil];
	[self showEditorLayoutExample];
	[[ETPickboard localPickboard] showPickPalette];
}

//#define OUTLINE_LAYOUT_WORKSPACE

- (IBAction) newWorkspace: (id)sender
{
	MarkupEditorItemFactory *itemFactory = [MarkupEditorItemFactory factory];
	ETController *controller = [self copy];
	ETLayoutItemGroup *workspace = [itemFactory itemGroupWithFrame: NSMakeRect(50, 100, 1000, 700)];

#ifdef OUTLINE_LAYOUT_WORKSPACE
	[workspace setLayout: [ETOutlineLayout layout]];
	[workspace setController: controller;
#else
	[workspace setLayout: [ETPaneLayout masterDetailLayout]];
	[[workspace layout] setBarThickness: 200];
	[[workspace layout] setBarPosition: ETPanePositionLeft];
	[[workspace layout] setEnsuresContentFillsVisibleArea: YES];
	//[[[workspace layout] barItem] setLayout: [ETFlowLayout layout]];
	[[[workspace layout] barItem] setController: controller];
#endif

	[[itemFactory windowGroup] addItem: workspace];
}

- (IBAction) changeLayout: (id)sender
{
	Class layoutClass = nil;
	
	switch ([[sender selectedItem] tag])
	{
		case 0:
			layoutClass = [ETColumnLayout class];
			break;
		case 1:
			layoutClass = [ETLineLayout class];
			break;
		case 2:
			layoutClass = [ETFlowLayout class];
			break;
		case 3:
			layoutClass = [ETTableLayout class];
			break;
		case 4:
			layoutClass = [ETOutlineLayout class];
			break;
		case 5:
			layoutClass = [ETBrowserLayout class];
			break;
		case 6:
			layoutClass = [ETTextEditorLayout class];
			break;
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	[[MarkupEditorItemFactory factory] setUpLayoutOfClass: layoutClass];
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
		mutabilityOption: kCFPropertyListMutableContainersAndLeaves 
		format: &format errorDescription: NULL];
	
	return [self newItemWithRepresentedObject: plistNode URL: URL options: options];
}

@end


@implementation XMLItemTemplate

- (ETLayoutItem *) newItemReadFromURL: (NSURL *)URL options: (NSDictionary *)options
{
	id xmlNode = AUTORELEASE([[NSXMLDocument alloc] 
		initWithContentsOfURL: URL options: NSXMLDocumentTidyXML error: NULL]);
	
	return [self newItemWithRepresentedObject: xmlNode URL: URL options: options];
}

@end

#ifndef GNUSTEP

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

#endif
