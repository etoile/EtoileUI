/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */
 
#import "PhotoViewController.h"
#import <EtoileUI/ETUIItemIntegration.h>

#define USE_IMG_VIEW

@implementation PhotoViewController

- (id) init
{
	self = [super initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
	if (self == nil)
		return nil;

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
	[photoViewItem setLayout: [self configureLayout:
		[ETColumnLayout layoutWithObjectGraphContext: [photoViewItem objectGraphContext]]]];
	[photoViewItem setHasVerticalScroller: YES];
	[photoViewItem setHasHorizontalScroller: YES];

	/* Declare pick and drop rules based on UTI types */

	// FIXME: Move into an EtoileUI plist loaded by ETUTI
	[ETUTI registerTypeWithString: @"org.etoile-project.objc.class.NSImage"
	                  description: @"Objective-C Class"
	             supertypeStrings: A(@"public.image")
	                     typeTags: nil];

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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [op beginSheetForDirectory: nil file: nil types: nil 
                modalForWindow: [photoView window] 
                 modalDelegate: self 
                didEndSelector: @selector(selectPicturesPanelDidEnd:returnCode:contextInfo:)
                   contextInfo: nil];
#pragma clang diagnostic pop
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
	
	id layoutObject = AUTORELEASE([[layoutClass alloc]
		initWithObjectGraphContext: [photoViewItem objectGraphContext]]);

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
		[layoutObject setDisplayName: @"Type" forProperty: @"type"];
		[layoutObject setDisplayName: @"Size" forProperty: @"size"];
		[layoutObject setDisplayName: @"Modification Date" forProperty: @"modificationDate"];
	}
	if ([layoutObject isKindOfClass: [ETComputedLayout class]])
	{
		[layoutObject setAttachedTool: [ETSelectTool toolWithObjectGraphContext: [layoutObject objectGraphContext]]];
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
    
    FOREACH([panel URLs], URL, NSURL *)
    {
		NSString *path = [URL path];
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

- (PhotoAsset *)photoAssetWithImage: (NSImage *)img
{
	PhotoAsset *asset = AUTORELEASE([PhotoAsset new]);
	NSString *appName = nil;
	NSString *type = nil;
	
	[[NSWorkspace sharedWorkspace] getInfoForFile: [img name]
	                                  application: &appName
	                                         type: &type];

	NSDictionary *info =
		[[NSFileManager defaultManager] attributesOfItemAtPath: [img name]
	                                                     error: NULL];
	
	[asset setName: [[img name] lastPathComponent]];
	[asset setModificationDate: [info objectForKey: NSFileModificationDate]];
	[asset setType: type];
	[asset setImage: img];

	return asset;
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
		ETLayoutItem *item =
			[[ETLayoutItemFactory factory] itemWithView: [self imageViewForImage: img]];

		 /* Use the image as the item model
		 
		    Property values set on the item itself (with -setImage:, -setIcon:, 
			-setName: etc.) won't be visible at the UI level, because property 
			values are retrieved through -[ETLayoutItem valueForProperty:] which 
			only looks them up on the represented object when one is set. */
		[item setRepresentedObject: [self photoAssetWithImage: img]];

		[imageItems addObject: item];
	}

	/* Remove all the items added previously */
	[photoViewItem removeAllItems];
	[photoViewItem addItems: imageItems];
}

- (NSImageView *) imageViewForImage: (NSImage *)image
{
#ifdef USE_IMG_VIEW
	if (image == nil)
		return nil;

	NSImageView *view = AUTORELEASE([[NSImageView alloc] 
		initWithFrame: ETMakeRect(NSZeroPoint, [image size])]);
	
	[view setImage: image];

	return view;
#else
	return nil;
#endif
}

/* ETLayoutItemGroup Source Protocol as a variant to -setUpLayoutItemsDirectly. 

   Will be called back in reaction to -reloadXXX when [photoViewItem source] is 
   not nil, see -selectPicturePanelDidEnd:XXX and -switchUsesSource:. */

- (int) baseItem: (ETLayoutItemGroup *)baseItem numberOfItemsInItemGroup: (ETLayoutItemGroup *)itemGroup
{
	ETLog(@"Returns %d as number of items in %@", (int)[images count], baseItem);

	return [images count];
}

/* Both baseItem and itemGroup are the same because the base item is photo view 
   item which only presents images. For example, it doesn't support to group the images. */
- (ETLayoutItem *) baseItem: (ETLayoutItemGroup *)baseItem 
                itemAtIndex: (NSUInteger)index 
                inItemGroup: (ETLayoutItemGroup *)itemGroup
{
	NSImage *img = [images objectAtIndex: index];
	ETLayoutItem *imageItem =
		[[ETLayoutItemFactory factory] itemWithView: [self imageViewForImage: img]];

	//ETLog(@"Returns %@ as item in %@", imageItem, baseItem);

	[imageItem setRepresentedObject: [self photoAssetWithImage: img]];
	[imageItem setSubtype: [ETUTI typeWithString: @"public.image"]];

	return imageItem;
}

- (NSArray *) displayedItemPropertiesInItemGroup: (ETLayoutItemGroup *)baseItem
{
	return A(@"icon", @"name", @"size", @"type", @"modificationDate");
}

@end


@implementation PhotoAsset

- (NSArray *) propertyNames
{
	return [[super propertyNames]
		arrayByAddingObjectsFromArray: A(@"name", @"size", @"type", @"modificationDate")];
}

/* -[ETBasicItemStyle imageForItem:] returns -icon and not -image by default, 
because all objects implement -icon, see -[NSObject icon].
 
You could override -[ETBasicItemStyle imageForItem:] to return -image in a 
subclass, but it's easier to just override -icon in PhotoAsset here. */
- (NSImage *) icon
{
	return [self image];
}

- (NSSize) size
{
	return [[self image] size];
}

@end
