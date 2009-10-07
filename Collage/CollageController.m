/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import "CollageController.h"


@implementation CollageController

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];

	/* Shows the graphics editing related menu which contains commands like 
	   'group', 'ungroup', 'send backward' etc. */
	[[ETApp mainMenu] addItem: [ETApp arrangeMenuItem]];

	mainItem = [itemFactory itemGroup];
	
	/* Set up main item to behave like a very basic compound document editor */

	// NOTE: Uncomment next line to test the example with a content coordinate 
	// base located in the bottom left.
	//[mainItem setFlipped: NO];
	[mainItem setSize: NSMakeSize(500, 400)];
	//[mainItem setLayout: [ETFreeLayout layout]];

	/* Make mainItem visible by inserting it inside the window layer */

	[[itemFactory windowGroup] addItem: mainItem];
	
	/* Insert a bit of everything as content (widgets and shapes) */

	[mainItem addItem: [itemFactory horizontalSlider]];
	[mainItem addItem: [itemFactory textField]];
	[mainItem addItem: [itemFactory labelWithTitle: @"Hello World!"]];
	[mainItem addItem: [itemFactory button]];
	[mainItem addItem: [itemFactory rectangle]];
	[mainItem addItem: [itemFactory oval]];
	/* Selection rubber-band is a layout item too, which means we can use it 
	   in the same way than other shape-based items... */
	[mainItem addItem: AUTORELEASE([[ETSelectionAreaItem alloc] init])];
	[mainItem setLayout: [ETPaneLayout masterDetailLayout]];
	[[mainItem layout] setBarPosition: ETPanePositionRight];

	[[itemFactory windowGroup] addItem: [mainItem deepCopy]];
	return;
	/* ... A less useless use case would be to replace the shape bound to it or 
	   alter its shape as below. */

	ETSelectTool *tool = [[mainItem layout] attachedInstrument];
	[[[tool selectionAreaItem] style] setStrokeColor: [NSColor orangeColor]];

	/* Give grid-like positions to items initially */

	ETFlowLayout *flow = [ETFlowLayout layout];
	[flow setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
	[(ETFreeLayout *)[mainItem layout] resetItemPersistentFramesWithLayout: flow];

	/* Open an inspector that allows us to easily switch the instrument and the 
	   layout in use */

	[[itemFactory windowGroup] inspect: nil];
	
	// FIXME: [ETApp explore: nil];
}

@end
