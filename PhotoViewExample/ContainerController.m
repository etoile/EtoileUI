/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */
 
 #import "ContainerController.h"


@implementation ContainerController

- (void) dealloc
{
	DESTROY(viewContainer);
	DESTROY(itemMarginSlider);
	DESTROY(photoViewItem);
	DESTROY(images);
	
	[super dealloc];
}

- (void) awakeFromNib
{
	images = [[NSMutableArray alloc] init];
	ASSIGN(photoViewItem, [viewContainer layoutItem]);

	[photoViewItem setSource: self];
	[photoViewItem setLayout: [self configureLayout: [ETStackLayout layout]]];
	[photoViewItem setHasVerticalScroller: YES];

	// FIXME: Move into an EtoileUI plist loaded by ETUTI
	[ETUTI registerTypeWithString: @"org.etoile-project.objc.class.NSImage"
	                  description: @"Objective-C Class"
	             supertypeStrings: A(@"public.image")];

	[self setContent: photoViewItem];
	[self setAutomaticallyRearrangesObjects: YES]; /* Enable automatic sorting */
	[self setAllowedPickType: [ETUTI typeWithString: @"public.image"]];
	[self setAllowedDropType: [ETUTI typeWithString: @"public.image"]
	           forTargetType: [ETUTI typeWithClass: [ETLayoutItemGroup class]]];
	
	[[ETPickboard localPickboard] showPickPalette]; /* Just to show it */
}

- (IBAction) choosePicturesAndLayout:(id)sender
{
    NSOpenPanel *op = [NSOpenPanel openPanel];
    
    [op setAllowsMultipleSelection: YES];
    [op setCanCreateDirectories: YES];
    // TODO: Specify image file types... [op setAllowedFileTypes: nil];
    
    [op beginSheetForDirectory: nil file: nil types: nil 
                modalForWindow: [viewContainer window] 
                 modalDelegate: self 
                didEndSelector: @selector(selectPicturesPanelDidEnd:returnCode:contextInfo:)
                   contextInfo: nil];
}

- (IBAction) changeLayout: (id)sender
{
	Class layoutClass = nil;
	
	switch ([[sender selectedItem] tag])
	{
		case 0:
			layoutClass = [ETStackLayout class];
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
			layoutClass = [ETFreeLayout class];
			break;
		default:
			ETLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	id layoutObject = AUTORELEASE([[layoutClass alloc] init]);

	[photoViewItem setLayout: [self configureLayout: layoutObject]];
}

/* Adjust some common settings of these layout to match what can be expected at 
UI level for a photo viewer. */
- (id) configureLayout: (id)layoutObject
{
	if ([layoutObject isKindOfClass: [ETTableLayout class]])
	{
		NSCell *iconCell = [[NSImageCell alloc] initImageCell: nil];
		
		[layoutObject setStyle: AUTORELEASE(iconCell) forProperty: @"icon"];
		[layoutObject setEditable: YES forProperty: @"name"];

		[layoutObject setDisplayName: @"" forProperty: @"icon"];
		[layoutObject setDisplayName: @"Name" forProperty: @"name"];
		[layoutObject setDisplayName: @"Type" forProperty: @"imgType"];
		[layoutObject setDisplayName: @"Size" forProperty: @"size"];
		[layoutObject setDisplayName: @"Modification Date" forProperty: @"modificationdate"];
	}
	if ([layoutObject isKindOfClass: [ETComputedLayout class]])
	{
		[layoutObject setAttachedInstrument: [ETSelectTool instrument]];
		[layoutObject setItemMargin: [itemMarginSlider floatValue]];

		/* We override some extra settings even if the defaults defined by EtoileUI 
		   would work for a photo viewer (see ETFlowLayout, ETLineLayout and 
		   ETStackLayout).
		   You can compare the effects of these by testing ObjectManagerExample 
		   which doesn't override anything. */
		
		/* Specify a max size for the items */
		[layoutObject setConstrainedItemSize: NSMakeSize(300, 300)];
		/* Indicate that max size should be consulted for both width and height of each item */
		[layoutObject setItemSizeConstraintStyle: ETSizeConstraintStyleVerticalHorizontal];
	}
	
	return layoutObject;
}

- (IBAction) switchUsesSource: (id)sender
{
	if ([sender state] == NSOnState)
	{
		[photoViewItem setSource: self];
	}
	else if ([sender state] == NSOffState)
	{
		[photoViewItem setSource: nil];
		[self setUpLayoutItemsDirectly];
	}
	
	[photoViewItem reloadAndUpdateLayout];
}

- (IBAction) switchUsesScrollView: (id)sender
{
	if ([sender state] == NSOnState)
	{
		[photoViewItem setShowsScrollView: YES];
		//[photoViewItem setHasVerticalScroller: YES];
		//[photoViewItem setHasHorizontalScroller: YES];
	}
	else if ([sender state] == NSOffState)
	{
		[photoViewItem setShowsScrollView: NO];
		// NOTE: Testing related lines
		//[photoViewItem setHasVerticalScroller: NO];
		//[photoViewItem setHasHorizontalScroller: NO];
	}
	
	[photoViewItem updateLayout]; 
}

- (IBAction) scale: (id)sender
{
	// FIXME: Should be...
	//[photoViewItem or layout setItemScaleFactor: [sender floatValue] / 100];
	[viewContainer setItemScaleFactor: [sender floatValue] / 100];
}

- (IBAction) changeItemMargin: (id)sender
{
	id layout = [photoViewItem layout];
	
	if ([layout isComposite])
		layout = [layout positionalLayout];

	if ([layout isComputedLayout])
		[(ETComputedLayout *)layout setItemMargin: [sender floatValue]];
}

- (void) selectPicturesPanelDidEnd: (NSOpenPanel *)panel 
                        returnCode: (int)returnCode
                       contextInfo: (void  *)contextInfo
{
    //ETLog(@"Pictures selected: %@\n", paths);
	
	[images removeAllObjects];
    
    FOREACH([panel filenames], path, NSString *)
    {
        NSImage *image = AUTORELEASE([[NSImage alloc] initWithContentsOfFile: path]);
		
		if (image == nil)
			continue;

		//ETLog(@"New image loaded: %@\n", image);
		
		// NOTE: NSImage retains image on -setName:
		if ([NSImage imageNamed: path] != nil)
		{
			/* Reuse already registered image */
			[images addObject: [NSImage imageNamed: path]];
		}
		else /* Register image */
		{
			if ([image setName: path])
			{
				[images addObject: image];
			}
			else
			{
				ETLog(@"Impossible to register image for name %@", path);
			}
		}
    }        
	
	if ([photoViewItem source] == nil)
	{
		[self setUpLayoutItemsDirectly];
	}

	/* Whether or not we use a source, we reload everything now */
    [photoViewItem reloadAndUpdateLayout];
}

/* When no source is set, this method is called by -selectPicturePanelDidEnd:XXX 
to build layout items and adds them to the photo view directly.

This method sets less properties on the returned items unlike 
-itemGroup:itemAtIndex:.

See -switchUsesSource: action which toggles how the photo view item content 
is provided. The content is provided either by this method or the source 
protocol methods. */
- (void) setUpLayoutItemsDirectly
{
	NSMutableArray *imageItems = [NSMutableArray array];
	
	ETLog(@"Set up layout items directly...");
	
	FOREACH(images, img, NSImage *)
	{
		ETLayoutItem *item = [ETLayoutItem layoutItemWithView: [self imageViewForImage: img]];

		[item setRepresentedObject: img]; /* Use the image as the item model */
		[item setImage: img]; /* Only useful if no imgView exists */	
		[item setName: [[img name] lastPathComponent]];
		[item setIcon: img];	

		[imageItems addObject: item];
	}
	
	[photoViewItem removeAllItems]; /* Remove all the items added previously */
	[photoViewItem addItems: imageItems];
}

- (NSImageView *) imageViewForImage: (NSImage *)image
{
#ifdef USE_IMG_VIEW
	return nil;
#endif

	if (image == nil)
		return nil;

	NSImageView *view = AUTORELEASE([[NSImageView alloc] 
		initWithFrame: ETMakeRect(NSZeroPoint, [image size])]);
	
	[view setImage: image];

	return view;
}

/* ETLayoutItemGroup informal flat source protocol as a variant to 
   -setUpLayoutItemsDirectly. 

   Will be called back in reaction to -reloadXXX when [photoViewItem source] is 
   not nil, see -selectPicturePanelDidEnd:XXX and -switchUsesSource:. */

- (int) numberOfItemsInItemGroup: (ETLayoutItemGroup *)baseItem
{
	ETLog(@"Returns %d as number of items in %@", [images count], baseItem);

	return [images count];
}

- (ETLayoutItem *) itemGroup: (ETLayoutItemGroup *)baseItem itemAtIndex: (int)index
{
	NSImage *img = [images objectAtIndex: index];
	ETLayoutItem *imageItem = [ETLayoutItem itemWithView: [self imageViewForImage: img]];
	NSWorkspace *wk = [NSWorkspace sharedWorkspace];
	NSString *appName = nil;
	NSString *type = nil;

	[wk getInfoForFile: [img name] application: &appName type: &type];

	[imageItem setRepresentedObject: img]; /* Use the image as the item model */	
	[imageItem setName: [[img name] lastPathComponent]];
	[imageItem setIcon: [wk iconForFile: [img name]] ];		
	[imageItem setValue: type forProperty: @"imgType"];
	
	//ETLog(@"Returns %@ as item in %@", imageItem, baseItem);

	return imageItem;
}

- (NSArray *) displayedItemPropertiesInItemGroup: (ETLayoutItemGroup *)baseItem
{
	return A(@"icon", @"name", @"size", @"imgType", @"modificationdate");
}

// TODO: - (NSFormatter *) container: (ETContainer *)container formaterForDisplayItemProperty:

@end
