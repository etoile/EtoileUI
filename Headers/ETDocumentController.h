/** <title>ETDocumentController</title>
	
	<abstract>A controller to manage a collection of documents.</abstract>
 
	Copyright (C) 2010 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  October 2010
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETController.h>

@class ETLayoutItem, ETLayoutItemGroup, ETUTI;

/** ETDocumentController provides a generic editor/viewer controller to manage 
the items getting edited or viewed, where each item represents a content unit 
(a web page, an image, a mail, a compound document etc.).<br />
A content unit is usually a document.

ETDocumentController might include unrelated items in its content. For example, 
the controller bound to -[ETLayoutItemFactory windowGroup] will include 
non-document windows such as inspectors, palettes etc. when other windows are 
visible. You can use -documentItems to retrieve the items marked as 
<em>document</em>. See also -itemForTypes: and itemsForURL: to retrieve a 
document.
 
For the AppKit backend, it is designed as a NSDocumentController replacement.
Unlike NSDocumentController, it can manage multiple documents at any level of 
the UI, in the sense it doesn't require to have a window per document, and 
support NSController rich behavior (pick and drop, sorting, filtering, nib 
integration etc.) without having to resort to another API. */
@interface ETDocumentController : ETController
{
	@private
	NSError *_error;
	NSInteger _numberOfUntitledDocuments;
}

/** @taskunit Querying Controller Content */

- (NSArray *) itemsForType: (ETUTI *)aUTI;
- (NSArray *) itemsForURL: (NSURL *)aURL;
- (NSArray *) documentItems;
- (id) activeItem;
- (NSUInteger) numberOfUntitledDocuments;

/** @taskunit Insertion */

- (ETLayoutItem *) openItemWithURL: (NSURL *)aURL options: (NSDictionary *)options;
- (BOOL) allowsMultipleInstancesForURL: (NSURL *)aURL;

/** @taskunit Type Determination */

+ (ETUTI *) typeForURL: (NSURL *)aURL;
- (ETUTI *) typeForWritingItem: (ETLayoutItem *)anItem;

/** @taskunit Notifications */

- (void) didOpenDocumentItem: (ETLayoutItem *)anItem;
- (void) didCreateDocumentItem: (ETLayoutItem *)anItem;
- (void) willCloseDocumentItem: (ETLayoutItem *)anItem;

/** @taskunit Creation Actions */

- (IBAction) newDocument: (id)sender;
- (IBAction) newDocumentFromTemplate: (id)sender;
- (IBAction) newDocumentCopy: (id)sender;

/** @taskunit Opening Actions */

- (IBAction) openDocument: (id)sender;
- (IBAction) openSelection: (id)sender;

/** @taskunit History Actions */

- (IBAction) saveDocument: (id)sender;
- (IBAction) markDocumentVersion: (id)sender;
- (IBAction) revertDocumentTo: (id)sender;
- (IBAction) browseDocumentHistory: (id)sender;

/** @taskunit Other Actions */

- (IBAction) close: (id)sender;
- (IBAction) exportDocument: (id)sender;
- (IBAction) showDocumentInfos: (id)sender;

/** @taskunit Error Reporting */

- (NSError *) error;

@end

