#import "ContainerController.h"


@implementation ContainerController

- (void) dealloc
{
	DESTROY(images);
	
	[super dealloc];
}

- (void) awakeFromNib
{
	images = [[NSMutableArray alloc] init];

	[viewContainer setAllowsMultipleSelection: YES];
	[viewContainer setAllowsEmptySelection: YES];
	[viewContainer setSource: self];
	[viewContainer setLayout: [self configureLayout: [ETStackLayout layout]]];
	[viewContainer setHasVerticalScroller: YES];
	[viewContainer setHasHorizontalScroller: YES];
	
	//[[viewContainer window] setAcceptsMouseMovedEvents: YES];
	
	[[ETPickboard localPickboard] showPickPalette];
}

- (IBAction)choosePicturesAndLayout:(id)sender
{
    NSOpenPanel *op = [NSOpenPanel openPanel];
    
    [op setAllowsMultipleSelection: YES];
    [op setCanCreateDirectories: YES];
    //[op setAllowedFileTypes: nil];
    
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
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	id layoutObject = AUTORELEASE([[layoutClass alloc] init]);
	
	[viewContainer setLayout: [self configureLayout: layoutObject]];
}

- (id) configureLayout: (id)layoutObject
{
	/* Adjust some common settings of these layout to match what can be
	   expected at UI level for a photo viewer. */
	
	if ([layoutObject isKindOfClass: [ETTableLayout class]])
	{
		NSCell *iconCell = [[NSImageCell alloc] initImageCell: nil];
		
		[layoutObject setStyle: AUTORELEASE(iconCell) forProperty: @"icon"];
		[layoutObject setDisplayName: @"" forProperty: @"icon"];
		[layoutObject setDisplayName: @"Name" forProperty: @"name"];
		[layoutObject setDisplayName: @"Type" forProperty: @"imgType"];
		[layoutObject setDisplayName: @"Size" forProperty: @"size"];
		[layoutObject setDisplayName: @"Modification Date" forProperty: @"modificationdate"];
	}
	if ([layoutObject isKindOfClass: [ETComputedLayout class]])
	{
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
		[viewContainer setSource: self];
	}
	else if ([sender state] == NSOffState)
	{
		[viewContainer setSource: nil];
		[self setUpLayoutItemsDirectly];
	}
	
	[viewContainer reloadAndUpdateLayout];
    
    /* Flow autolayout manager doesn't take care of trigerring or updating the display. */
    [viewContainer setNeedsDisplay: YES];  
}

- (IBAction) switchUsesScrollView: (id)sender
{
	if ([sender state] == NSOnState)
	{
		[viewContainer setShowsScrollView: YES];
		//[viewContainer setHasVerticalScroller: YES];
		//[viewContainer setHasHorizontalScroller: YES];
	}
	else if ([sender state] == NSOffState)
	{
		[viewContainer setShowsScrollView: NO];
		// NOTE: Testing related lines
		//[viewContainer setHasVerticalScroller: NO];
		//[viewContainer setHasHorizontalScroller: NO];
	}
	
	[viewContainer updateLayout];
    
    /* Flow autolayout manager doesn't take care of trigerring or updating the display. */
    [viewContainer setNeedsDisplay: YES];  
}

- (IBAction) scale: (id)sender
{
	[viewContainer setItemScaleFactor: [sender floatValue] / 100];
	[viewContainer display];
}

- (IBAction) changeItemMargin: (id)sender
{
	id layout = [viewContainer layout];
	
	if ([layout isComposite])
		layout = [layout positionalLayout];

	if ([layout isComputedLayout])
		[(ETComputedLayout *)layout setItemMargin: [sender floatValue]];
}

- (void)selectPicturesPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
    NSArray *paths = [panel filenames];
    NSEnumerator *e = [paths objectEnumerator];
    NSString *path = nil;
    
    //NSLog(@"Pictures selected: %@\n", paths);
	
	[images removeAllObjects];
    
    while ((path = [e nextObject]) != nil)
    {
        NSImage *image = AUTORELEASE([[NSImage alloc] initWithContentsOfFile: path]);
		
		if (image != nil)
		{
			//NSLog(@"New image loaded: %@\n", image);
			
			// NOTE: NSImage retains image on -setName:
			if ([NSImage imageNamed: path] != nil)
			{
				/* Reuse already registered image */
				[images addObject: [NSImage imageNamed: path]];
			}
			else 
			{
				if ([image setName: path])
				{
					[images addObject: image];
				}
				else
				{
					NSLog(@"Impossible to register image for name %@", path);
				}
			}
		}
    }        
	
	if ([viewContainer source] == nil)
		[self setUpLayoutItemsDirectly];
    [viewContainer reloadAndUpdateLayout];
    
    /* Flow autolayout manager doesn't take care of trigerring or updating the display. */
    [viewContainer setNeedsDisplay: YES];  
}

/* This method generates layout items and adds them to the container. Useful 
   when no source is set.  */
- (void) setUpLayoutItemsDirectly
{
	NSMutableArray *imageLayoutItems = [NSMutableArray array];
	NSEnumerator *e = [images objectEnumerator];
	NSImage *img = nil;
	
	NSLog(@"Set up layout items directly");
	
	while ((img = [e nextObject]) != nil)
	{
		#ifdef USE_IMG_VIEW
		NSImageView *imgView = [self imageViewForImage: img];
		#else
		NSImageView *imgView = nil;
		#endif
		ETLayoutItem *item = [ETLayoutItem layoutItemWithView: imgView];
		
		[item setValue: [[img name] lastPathComponent] forProperty: @"name"];
		[item setValue: img forProperty: @"icon"];	
		[item setImage: img];/* Only useful if no imgView exists */	
		[imageLayoutItems addObject: item];
	}
	
	[viewContainer removeAllItems]; // Remove all views added the last time	
	[viewContainer addItems: imageLayoutItems];
}

- (NSArray *) imageViewsForImages: (NSArray *)imgs
{
    NSEnumerator *e = [imgs objectEnumerator];
    NSImage *image = nil;
    NSMutableArray *views = [NSMutableArray array];
    
    while ((image = [e nextObject]) != nil)
    {
		NSImageView *imageView = [self imageViewForImage: image];
		
		if (imageView != nil)
			[views addObject: imageView];
    }

    NSLog(@"New image views list: %@\n", views);

    return views;
}

- (NSImageView *) imageViewForImage: (NSImage *)image
{
	if (image != nil)
    {
        NSImageView *view = [[NSImageView alloc] 
            initWithFrame: NSMakeRect(0, 0, [image size].width, [image size].height)];
        
        [view setImage: image];
		return (NSImageView *)AUTORELEASE(view);
    }

    return nil;
}

/* ETContainerSource informal protocol */

- (int) numberOfItemsInItemGroup: (ETLayoutItemGroup *)baseItem
{
	NSLog(@"Returns %d as number of items in container %@", [images count], [baseItem supervisorView]);
	
	return [images count];
}

- (ETLayoutItem *) itemGroup: (ETLayoutItemGroup *)baseItem itemAtIndex: (int)index
{
	NSImage *img = [images objectAtIndex: index];
	ETLayoutItem *imageItem = [ETLayoutItem layoutItemWithView: [self imageViewForImage: img]];
	//ETLayoutItem *imageItem = [[ETLayoutItem alloc] initWithValue: img];
	NSWorkspace *wk = [NSWorkspace sharedWorkspace];
	NSValue *size = [NSValue valueWithSize: [img size]];
	NSString *type = nil;
	NSString *appName = nil;

	[wk getInfoForFile: [img name] application: &appName type: &type];
	
	[imageItem setValue: img forProperty: @"icon"];
	//[imageItem setValue: [wk iconForFile: [img name]] forProperty: @"icon"];
	[imageItem setValue: [[img name] lastPathComponent] forProperty: @"name"];
	// 'type' is defined by NSObject(Model) so we have to use another property 
	// name unless we add the possibility to override the inherited property 
	// instead of updating it with -setValue:forKey:. -addValue:forProperty: 
	// would add a property or override the inherited value if the property is
	// already declared in a parent.
	//[imageItem addValue: type forProperty: @"type"];
	[imageItem setValue: type forProperty: @"imgType"];
// FIXME: GNUstep doesn't handle common structs like NSSize, NSRect etc. which 
// can be boxed in a NSValue object. GSObjCSetVal() have to be improved.
#ifndef GNUSTEP
	[imageItem setValue: size forProperty: @"size"];
#endif
	//[imageItem setValue: date forProperty	: @"modificationdate"];
	
	//NSLog(@"Returns %@ as layout item in container %@", imageItem, container);
	
	//AUTORELEASE(imageItem);

	return imageItem;
}

- (NSArray *) displayedItemPropertiesInItemGroup: (ETLayoutItemGroup *)baseItem
{
	return [NSArray arrayWithObjects: @"icon", @"name", @"size", @"imgType", @"modificationdate", nil];
}

//- (NSFormatter *) container: (ETContainer *)container formaterForDisplayItemProperty:

@end
