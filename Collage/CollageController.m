/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import "CollageController.h"


@implementation CollageController

- (NSImage *) appImage
{
	NSImage *appImg = [NSImage imageNamed: @"NSApplicationIcon"];
	[appImg setScalesWhenResized: YES];	
	[appImg setSize: NSMakeSize(32, 32)];
	return appImg;
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	[self prepareMenus];
	[self prepareUI];
}

- (void) prepareMenus
{
	/* Shows the graphics editing related menu which contains commands like 
	   'group', 'ungroup', 'send backward' etc. */
	[[ETApp mainMenu] addItem: [ETApp arrangeMenuItem]];
	/* Show the development menu, so we can play a bit */
	[ETApp toggleDevelopmentMenu: nil];
}

- (void) prepareUI
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItem *collageItem =
		[[ETApp UIStateRestoration] provideItemForName: [self collagePersistentUIName]];

	/* Show the main collage item (restored from the CoreObject store if the UI 
	   has been edited in a previous application use) */
	[[itemFactory windowGroup] addItem: collageItem];
	
	/* Clone the collage item */
	//[[itemFactory windowGroup] addItem: [[self collageItem] deepCopy]];

	/* Put a simple slider in a window */
	[[itemFactory windowGroup] addItem: [itemFactory horizontalSlider]];

	/* Open an inspector that allows us to easily switch the tool and the 
	   layout in use */
	[[itemFactory windowGroup] setController: [ETController new]];
	[[itemFactory windowGroup] inspectUI: nil];
}

- (id) UIStateRestoration: (ETUIStateRestoration *)restoration
       provideItemForName: (NSString *)aName
{
	if ([aName isEqual: [self collagePersistentUIName]])
	{
		return [self collageItem];
	}
	return nil;
}

- (id) UIStateRestoration: (ETUIStateRestoration *)restoration
          loadItemForUUID: (ETUUID *)aUUID
{
	return [[[ETUIBuilderItemFactory factory] editingContext] objectWithUUID: aUUID]; 
}

- (void) UIStateRestoration: (ETUIStateRestoration *)restoration
                didLoadItem: (id)anItem
{
	ETLog(@"Restored UI %@ for %@", anItem, [anItem persistentUIName]);
}

- (NSString *) collagePersistentUIName
{
	return @"collage";
}

- (ETLayoutItemGroup *) collageItem
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	
	[itemFactory beginRootObject];

	ETLayoutItemGroup *mainItem = [itemFactory itemGroup];
	
	[mainItem setPersistentUIName: [self collagePersistentUIName]];

	/* Set up main item to behave like a very basic compound document editor */

	// NOTE: Uncomment next line to test the example with a content coordinate 
	// base located in the bottom left.
	//[mainItem setFlipped: NO];
	[mainItem setSize: NSMakeSize(500, 400)];
	[mainItem setLayout: [ETFreeLayout layoutWithObjectGraphContext: [itemFactory objectGraphContext]]];

	/* Make mainItem visible by inserting it inside the window layer */

	[[itemFactory windowGroup] addItem: mainItem];
	
	/* Insert a bit of everything as content (widgets and shapes) */

	ETLayoutItem *imageItem = [itemFactory itemWithRepresentedObject: [self appImage]];
	ETLayoutItem *buttonItem = [itemFactory buttonWithImage: [self appImage] 
	                                                 target: self 
	                                                 action: @selector(bing:)];
	ETLayoutItem *popUpItem = [itemFactory popUpMenuWithItemTitles: A(@"Tap", @"Tip", @"Top") 
	                                            representedObjects: nil 
	                                                        target: nil
	                                                        action: NULL];

	[mainItem addItem: [itemFactory horizontalSlider]];
	[mainItem addItem: [itemFactory textField]];
#if 0
	[mainItem addItem: [itemFactory labelWithTitle: @"Hello World!"]];
	[mainItem addItem: [itemFactory button]];
	[[mainItem lastItem] setSize: NSMakeSize(200, 150)];
	//[[mainItem lastItem] setDecoratorItem: [ETTitleBarItem item]];
	[mainItem addItem: [itemFactory rectangle]];
	//[[mainItem lastItem] setDecoratorItem: [ETTitleBarItem item]];
	[mainItem addItem: [itemFactory oval]];
	[mainItem addItem: [itemFactory barElementFromItem: [itemFactory button] 
	                                         withLabel: @"Useless"]];
	[mainItem addItem: [itemFactory barElementFromItem: imageItem
	                                         withLabel: @"Useless"]];
	[mainItem addItem: [itemFactory barElementFromItem: buttonItem
	                                         withLabel: @"Useful"]];
	[mainItem addItem: [itemFactory barElementFromItem: popUpItem
	                                         withLabel: @"Hm"]];
	/* Selection rubber-band is a layout item too, which means we can use it 
	   in the same way than other shape-based items... */
	[mainItem addItem: AUTORELEASE([[ETSelectionAreaItem alloc] init])];
#endif
	/* ... A less useless use case would be to replace the shape bound to it or 
	   alter its shape as below. */

	ETSelectTool *tool = [[mainItem layout] attachedTool];
	[[[tool selectionAreaItem] style] setStrokeColor: [NSColor orangeColor]];

	/* Give grid-like positions to items initially */

	ETFlowLayout *flow = [ETFlowLayout layoutWithObjectGraphContext: [itemFactory objectGraphContext]];
	[flow setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
	[[mainItem layout] resetItemPersistentFramesWithLayout: flow];
	
	[itemFactory endRootObject];
	
	return mainItem;
}

- (void) bing: (id)sender
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert runModal];
	RELEASE(alert);
}

@end
