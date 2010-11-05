/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */
 
 #import "PhotoViewController.h"


@implementation PhotoViewController

- (id) init
{
	SUPERINIT
	images = [[NSMutableArray alloc] init];
	return self;
}

- (void) dealloc
{
	DESTROY(photoView);
	DESTROY(itemMarginSlider);
	DESTROY(images);
	
	[super dealloc];
}

/* Invoked when the application is going to finish to launch because 
the receiver is set as the application's delegate in the nib. */
- (void) applicationWillFinishLaunching: (NSNotification *)notif
{
	/* Will turn the nib views and windows into layout item trees */
	[ETApp rebuildMainNib];
	photoViewItem = [photoView owningItem];

	/* Set up the the photo view UI */

	[photoViewItem setController: self];
	[photoViewItem setSource: self];
	[photoViewItem setLayout: [self configureLayout: [ETColumnLayout layout]]];
	[photoViewItem setHasVerticalScroller: YES];
	[photoViewItem setHasHorizontalScroller: YES];

	/* Declare pick and drop rules based on UTI types */

	// FIXME: Move into an EtoileUI plist loaded by ETUTI
	[ETUTI registerTypeWithString: @"org.etoile-project.objc.class.NSImage"
	                  description: @"Objective-C Class"
	             supertypeStrings: A(@"public.image")];

	[self setAutomaticallyRearrangesObjects: YES]; /* Enable automatic sorting */
	[self setAllowedPickTypes: A([ETUTI typeWithString: @"public.image"])];
	[self setAllowedDropTypes: A([ETUTI typeWithString: @"public.image"])
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
                modalForWindow: [photoView window] 
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
		ETLayoutItem *imgViewItem = [[ETLayoutItemFactory factory] itemWithView: 
			AUTORELEASE([[NSImageView alloc] init])];
		
		[layoutObject setStyle: imgViewItem forProperty: @"icon"];
		[layoutObject setEditable: YES forProperty: @"name"];

		[layoutObject setDisplayName: @"" forProperty: @"icon"];
		[layoutObject setDisplayName: @"Name" forProperty: @"name"];
		[layoutObject setDisplayName: @"Type" forProperty: @"imgType"];
		[layoutObject setDisplayName: @"Size" forProperty: @"size"];
		[layoutObject setDisplayName: @"Modification Date" forProperty: @"modificationdate"];
	}
	if ([layoutObject isKindOfClass: [ETComputedLayout class]])
	{
		[layoutObject setAttachedTool: [ETSelectTool tool]];
		[layoutObject setItemMargin: [itemMarginSlider floatValue]];
		[layoutObject setBorderMargin: [itemMarginSlider floatValue]];

		/* We override some extra settings even if the defaults defined by EtoileUI 
		   would work for a photo viewer (see ETFlowLayout, ETLineLayout and 
		   ETColumnLayout).
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
		[photoViewItem setScrollable: YES];
		//[photoViewItem setHasVerticalScroller: YES];
		//[photoViewItem setHasHorizontalScroller: YES];
	}
	else if ([sender state] == NSOffState)
	{
		[photoViewItem setScrollable: NO];
		// NOTE: Testing related lines
		//[photoViewItem setHasVerticalScroller: NO];
		//[photoViewItem setHasHorizontalScroller: NO];
	}
	
	[photoViewItem updateLayout]; 
}

- (IBAction) scale: (id)sender
{
	[photoViewItem setItemScaleFactor: [sender floatValue] / 100];
}

- (IBAction) changeItemMargin: (id)sender
{
	id layout = [photoViewItem layout];
	
	if ([layout isComposite])
		layout = [layout positionalLayout];

	if ([layout isComputedLayout])
		[(ETComputedLayout *)layout setItemMargin: [sender floatValue]];
}

- (IBAction) changeBorderMargin: (id)sender
{
	id layout = [photoViewItem layout];
	
	if ([layout isComposite])
		layout = [layout positionalLayout];

	if ([layout isComputedLayout])
		[(ETComputedLayout *)layout setBorderMargin: [sender floatValue]];
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
-baseItem:itemAtIndex:inItemGroup:.

See -switchUsesSource: action which toggles how the photo view item content 
is provided. The content is provided either by this method or the source 
protocol methods. */
- (void) setUpLayoutItemsDirectly
{
	NSMutableArray *imageItems = [NSMutableArray array];
	
	ETLog(@"Set up layout items directly...");
	
	FOREACH(images, img, NSImage *)
	{
		ETLayoutItem *item = [[ETLayoutItemFactory factory] itemWithView: [self imageViewForImage: img]];

		 /* Use the image as the item model
		 
		    Property values set on the item itself (with -setImage:, -setIcon:, 
			-setName: etc.) won't be visible at the UI level, because property 
			values are retrieved through -[ETLayoutItem valueForProperty:] which 
			only looks them up on the represented object when one is set. */
		[item setRepresentedObject: img];

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

/* ETLayoutItemGroup Source Protocol as a variant to -setUpLayoutItemsDirectly. 

   Will be called back in reaction to -reloadXXX when [photoViewItem source] is 
   not nil, see -selectPicturePanelDidEnd:XXX and -switchUsesSource:. */

- (int) baseItem: (ETLayoutItemGroup *)baseItem numberOfItemsInItemGroup: (ETLayoutItemGroup *)itemGroup
{
	ETLog(@"Returns %d as number of items in %@", [images count], baseItem);

	return [images count];
}

/* Both baseItem and itemGroup are the same because the base item is photo view 
   item which only presents images. For example, it doesn't support to group the images. */
- (ETLayoutItem *) baseItem: (ETLayoutItemGroup *)baseItem 
                itemAtIndex: (int)index 
                inItemGroup: (ETLayoutItemGroup *)itemGroup
{
	NSImage *img = [images objectAtIndex: index];
	ETLayoutItem *imageItem = [[ETLayoutItemFactory factory] itemWithView: [self imageViewForImage: img]];
	NSWorkspace *wk = [NSWorkspace sharedWorkspace];
	NSString *appName = nil;
	NSString *type = nil;

	[wk getInfoForFile: [img name] application: &appName type: &type];

	/* We can set property values on the layout item itself, because no 
	   represented object has been set and -[ETLayoutItem valueForProperty:] 
	   will thus look them up in the item. */
	[imageItem setName: [[img name] lastPathComponent]];
	[imageItem setIcon: [wk iconForFile: [img name]] ];		
	[imageItem setValue: type forProperty: @"imgType"];
	[imageItem setSubtype: [ETUTI typeWithString: @"public.image"]];
	
	//ETLog(@"Returns %@ as item in %@", imageItem, baseItem);

	return imageItem;
}

- (NSArray *) displayedItemPropertiesInItemGroup: (ETLayoutItemGroup *)baseItem
{
	return A(@"icon", @"name", @"size", @"imgType", @"modificationdate");
}

@end
