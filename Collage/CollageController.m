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
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];

	/* Shows the graphics editing related menu which contains commands like 
	   'group', 'ungroup', 'send backward' etc. */
	[[ETApp mainMenu] addItem: [ETApp arrangeMenuItem]];
	/* Show the development menu, so we can play a bit */
	[ETApp toggleDevelopmentMenu: nil];

	mainItem = [itemFactory itemGroup];
	
	/* Set up main item to behave like a very basic compound document editor */

	// NOTE: Uncomment next line to test the example with a content coordinate 
	// base located in the bottom left.
	//[mainItem setFlipped: NO];
	[mainItem setSize: NSMakeSize(500, 400)];
	[mainItem setLayout: [ETFreeLayout layout]];

	/* Make mainItem visible by inserting it inside the window layer */

	[[itemFactory windowGroup] addItem: mainItem];
	
	/* Insert a bit of everything as content (widgets and shapes) */

	ETLayoutItem *imageItem = [itemFactory itemWithValue: [self appImage]];
	ETLayoutItem *buttonItem = [itemFactory buttonWithImage: [self appImage] 
	                                                 target: self 
	                                                 action: @selector(bing:)];
	ETLayoutItem *popUpItem = [itemFactory popUpMenuWithItemTitles: A(@"Tap", @"Tip", @"Top") 
	                                            representedObjects: nil 
	                                                        target: nil
	                                                        action: NULL];

	[mainItem addItem: [itemFactory horizontalSlider]];
	[mainItem addItem: [itemFactory textField]];
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

	/* ... A less useless use case would be to replace the shape bound to it or 
	   alter its shape as below. */

	ETSelectTool *tool = [[mainItem layout] attachedTool];
	[[[tool selectionAreaItem] style] setStrokeColor: [NSColor orangeColor]];

	/* Give grid-like positions to items initially */

	ETFlowLayout *flow = [ETFlowLayout layout];
	[flow setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
	[[mainItem layout] resetItemPersistentFramesWithLayout: flow];
	
	/* Clone the main item */
	[[itemFactory windowGroup] addItem: [mainItem deepCopy]];

	/* Put a simple slider in a window */
	[[itemFactory windowGroup] addItem: [itemFactory horizontalSlider]];

	/* Open an inspector that allows us to easily switch the tool and the 
	   layout in use */
	[[itemFactory windowGroup] inspect: nil];
	
	// FIXME: [ETApp explore: nil];
}

- (void) bing: (id)sender
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert runModal];
	RELEASE(alert);
}

@end
