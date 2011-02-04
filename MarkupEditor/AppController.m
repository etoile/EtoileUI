/*
	Copyright (C) 2011 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  February 2011
	License:  Modified BSD (see COPYING)
 */

#import "AppController.h"
#import "MarkupEditorItemFactory.h"


@implementation AppController

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	MarkupEditorItemFactory *itemFactory = [MarkupEditorItemFactory factory];

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

#define WINDOWGROUP_DOCUMENT_CONTROLLER
#ifdef WINDOWGROUP_DOCUMENT_CONTROLLER
	[[itemFactory windowGroup] setController: self];
#else
	ETLayoutItemGroup *workspace = [itemFactory itemGroupWithFrame: NSMakeRect(50, 100, 1000, 700)];
	[[itemFactory windowGroup] addItem: workspace];
#ifdef OUTLINE_LAYOUT
	[workspace setLayout: [ETOutlineLayout layout]];
	[workspace setController: self];
#else
	[workspace setLayout: [ETPaneLayout masterDetailLayout]];
	[[workspace layout] setBarThickness: 125];
	[[workspace layout] setBarPosition: ETPanePositionLeft];
	[[workspace layout] setEnsuresContentFillsVisibleArea: YES];
	//[[[workspace layout] barItem] setLayout: [ETFlowLayout layout]];
	[[[workspace layout] barItem] setController: self];
#endif
#endif
	[self newDocument: nil];
	
	//[[ETPickboard localPickboard] showPickPalette];
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
	
	return [self newItemWithRepresentedObject: plistNode options: options];
}

@end


@implementation XMLItemTemplate

- (ETLayoutItem *) newItemReadFromURL: (NSURL *)URL options: (NSDictionary *)options
{
	id xmlNode = AUTORELEASE([[NSXMLDocument alloc] 
		initWithContentsOfURL: URL options: NSXMLDocumentTidyXML error: NULL]);
	
	return [self newItemWithRepresentedObject: xmlNode options: options];
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
