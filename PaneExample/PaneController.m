#import "PaneController.h"
#import "ETLayoutItem.h"
#import "ETColumnLayout.h"
#import "ETFlowLayout.h"
#import "ETLineLayout.h"
#import "ETTableLayout.h"
#import "ETPaneSwitcherLayout.h"
#import "ETPaneLayout.h"
#import "GNUstep.h"


@implementation PaneController

- (void) dealloc
{
	DESTROY(paneItems);
	
	[super dealloc];
}

- (void) awakeFromNib
{
	ETLayoutItem *paneItem = nil;
	
	paneItems = [[NSMutableArray alloc] init];
	
	paneItem = [ETLayoutItem layoutItemWithView: paneView1];
	[paneItem setRepresentedObject: [NSMutableDictionary dictionary]];
	//[paneItem setName: @"Funky"];
	[paneItem setValue: @"Funky" forProperty: @"name"];
	[paneItem setValue: [NSImage imageNamed: @"NSApplicationIcon"] forProperty: @"icon"];
	[paneItem setValue: [NSImage imageNamed: @"NSApplicationIcon"] forProperty: @"image"];
	[paneItems addObject: paneItem];
	
	paneItem = [ETLayoutItem layoutItemWithView: paneView2];
	[paneItem setRepresentedObject: [NSMutableDictionary dictionary]];
	//[paneItem setName: @"Edgy"];
	[paneItem setValue: @"Edgy" forProperty: @"name"];
	[paneItem setValue: [NSImage imageNamed: @"NSApplicationIcon"] forProperty: @"icon"];
	[paneItem setValue: [NSImage imageNamed: @"NSApplicationIcon"] forProperty: @"image"];
	[paneItems addObject: paneItem];
	
	paneItem = [ETLayoutItem layoutItemWithView: paneView3];
	[paneItem setRepresentedObject: [NSMutableDictionary dictionary]];
	//[paneItem setName: @"Groovy"];
	[paneItem setValue: @"Groovy" forProperty: @"name"];
	[paneItem setValue: [NSImage imageNamed: @"NSApplicationIcon"] forProperty: @"icon"];
	[paneItem setValue: [NSImage imageNamed: @"NSApplicationIcon"] forProperty: @"image"];
	[paneItems addObject: paneItem];
	
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver: self 
           selector: @selector(viewContainerDidResize:) 
               name: NSViewFrameDidChangeNotification 
             object: viewContainer];
	
	//[viewContainer setSource: self];
	[viewContainer setLayout: AUTORELEASE([[ETPaneSwitcherLayout alloc] init])];
	[viewContainer addItems: paneItems];
}

- (void) viewContainerDidResize: (NSNotification *)notif
{
    [viewContainer updateLayout];
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
			layoutClass = [ETPaneSwitcherLayout class];
			break;
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	id layoutObject = AUTORELEASE([[layoutClass alloc] init]);
	
	/*[layoutObject setUsesConstrainedItemSize: YES];
	[layoutObject setConstrainedItemSize: NSMakeSize(150, 150)];*/
	[viewContainer setLayout: layoutObject];
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
	
	[(ETPaneSwitcherLayout *)[viewContainer layout] setContentLayout: layoutObject];
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
	
	[(ETPaneSwitcherLayout *)[viewContainer layout] setSwitcherLayout: layoutObject];
}

- (IBAction) changeSwitcherPosition: (id)sender
{
	int position = 1;
	
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
	
	[(ETPaneSwitcherLayout *)[viewContainer layout] setSwitcherPosition: position];
}

- (IBAction) switchUsesSource: (id)sender
{
	if ([sender state] == NSOnState)
	{
		[viewContainer setSource: self];
	}
	else if ([sender state] == NSOffState)
	{
		[viewContainer setSource: nil];
		[viewContainer addItems: paneItems];
	}
    
    /* Flow autolayout manager doesn't take care of trigerring or updating the display. */
    [viewContainer setNeedsDisplay: YES];  
}

- (IBAction) scale: (id)sender
{
	[[viewContainer layoutItem] setItemScaleFactor: [sender floatValue] / 100];
}

/* ETContainerSource informal protocol */

- (int) numberOfItemsInItemGroup: (ETLayoutItemGroup *)baseItem
{
	NSLog(@"Returns %d as number of items in container %@", 3, container);
	
	return 3;
}

- (ETLayoutItem *) itemGroup: (ETLayoutItemGroup *)baseItem itemAtIndex: (int)index
{
	ETLayoutItem *paneItem = [paneItems objectAtIndex: index];
	
	NSLog(@"Returns %@ as layout item in container %@", paneItem, [baseItem supervisorView]);

	return paneItem;
}

@end
