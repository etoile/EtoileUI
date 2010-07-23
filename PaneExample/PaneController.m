#import "PaneController.h"


@implementation PaneController

/* Invoked when the application is going to finish its launch because 
the receiver is set as the application's delegate in the nib. */
- (void) applicationWillFinishLaunching: (NSNotification *)notif
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItem *paneItem = nil;

	paneItem = [[ETEtoileUIBuilder builder] renderView: paneView1];
	[paneItem setName: @"Funky"];
	[paneItem setIcon: [NSImage imageNamed: @"NSApplicationIcon"]];
	[paneItem setImage: [NSImage imageNamed: @"NSApplicationIcon"]];
	[paneItemGroup addItem: paneItem];

	paneItem = [itemFactory itemWithView: paneView2];
	[paneItem setName: @"Edgy"];
	[paneItem setIcon: [NSImage imageNamed: @"NSApplicationIcon"]];
	[paneItem setImage: [NSImage imageNamed: @"NSApplicationIcon"]];
	[paneItemGroup addItem: paneItem];

	[ETApp rebuildMainNib];

// FIXME: The gorm loading code won't instantiate the custom class (ETView) sets 
// on the custom view.
#ifndef GNUSTEP
	/* The item can be retrieved with -owningItem too */
	paneItem = [paneView3 layoutItem];
	[paneItem setName: @"Groovy"];
	[paneItem setIcon: [NSImage imageNamed: @"NSApplicationIcon"]];
	[paneItem setImage: [NSImage imageNamed: @"NSApplicationIcon"]];
	[paneItemGroup addItem: paneItem];
#endif

	[paneItemGroup setLayout: [ETPaneLayout masterDetailLayout]];
}

- (IBAction) changeLayout: (id)sender
{
	Class layoutClass = nil;
	id layoutObject = nil;

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
			layoutObject = [ETPaneLayout masterDetailLayout];
			break;
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}

	if (layoutObject == nil)
	{
		layoutObject = AUTORELEASE([[layoutClass alloc] init]);
	}
	
	/*[layoutObject setUsesConstrainedItemSize: YES];
	[layoutObject setConstrainedItemSize: NSMakeSize(150, 150)];*/
	[paneItemGroup setLayout: layoutObject];
}

- (IBAction) changeContentLayout: (id)sender
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
			layoutClass = [ETPaneLayout class];
			break;
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	id layoutObject = AUTORELEASE([[layoutClass alloc] init]);
	
	[[(ETPaneLayout *)[paneItemGroup layout] contentItem] setLayout: layoutObject];
}

- (IBAction) changeSwitcherLayout: (id)sender
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
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	id layoutObject = AUTORELEASE([[layoutClass alloc] init]);
	
	[[[paneItemGroup layout] barItem] setLayout: layoutObject];
}

- (IBAction) changeSwitcherPosition: (id)sender
{
	ETPanePosition position = 1;
	
	switch ([[sender selectedItem] tag])
	{
		case 0:
			position = 1;
			break;
		case 1:
			position = 3;
			break;
		case 2:
			position = 2;
			break;
		case 3:
			position = 4;
			break;
		default:
			NSLog(@"Unsupported switcher position or unknown popup menu selection");
	}
	
	[[paneItemGroup layout] setBarPosition: position];
}

- (IBAction) scale: (id)sender
{
	[paneItemGroup setItemScaleFactor: [sender floatValue] / 100];
}

@end
