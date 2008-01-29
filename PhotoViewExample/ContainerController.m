#import "ContainerController.h"


@implementation ContainerController

- (void) dealloc
{
	DESTROY(images);
	
	[super dealloc];
}

- (void) awakeFromNib
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	images = [[NSMutableArray alloc] init];
    
    /*[nc addObserver: self 
           selector: @selector(viewContainerDidResize:) 
               name: NSViewFrameDidChangeNotification 
             object: viewContainer];*/
	
	[viewContainer setAllowsMultipleSelection: YES];
	[viewContainer setAllowsEmptySelection: YES];
	[viewContainer setSource: self];
	[viewContainer setLayout: AUTORELEASE([[ETStackLayout alloc] init])];
	[viewContainer setHasVerticalScroller: YES];
	[viewContainer setHasHorizontalScroller: YES];
	
	[[ETPickboard localPickboard] showPickPalette];
}

- (void) viewContainerDidResize: (NSNotification *)notif
{
    [viewContainer updateLayout];
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
	
	[viewContainer setLayout: layoutObject];
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
		[viewContainer setHasVerticalScroller: YES];
		[viewContainer setHasHorizontalScroller: YES];
	}
	else if ([sender state] == NSOffState)
	{
		[viewContainer setScrollView: nil];
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
		NSImageView *imgView = [self imageViewForImage: img];
		ETLayoutItem *item = [ETLayoutItem layoutItemWithView: imgView];
		
		[item setValue: [[img name] lastPathComponent] forProperty: @"name"];
		[item setValue: img forProperty: @"icon"];		
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

- (int) numberOfItemsInContainer: (ETContainer *)container
{
	NSLog(@"Returns %d as number of items in container %@", [images count], container);
	
	return [images count];
}

- (ETLayoutItem *) container: (ETContainer *)container itemAtIndex: (int)index
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
	[imageItem setValue: size forProperty: @"size"];
	//[imageItem setValue: date forProperty	: @"modificationdate"];
	
	//NSLog(@"Returns %@ as layout item in container %@", imageItem, container);
	
	//AUTORELEASE(imageItem);

	return imageItem;
}

- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container
{
	return [NSArray arrayWithObjects: @"icon", @"name", @"size", @"imgType", @"modificationdate", nil];
}

//- (NSFormatter *) container: (ETContainer *)container formaterForDisplayItemProperty:

@end
