#import "ContainerController.h"
#import "ETLayoutItem.h"
#import "ETStackLayout.h"
#import "ETFlowLayout.h"
#import "ETLineLayout.h"
#import "ETTableLayout.h"
#import "GNUstep.h"


@implementation ContainerController

- (void) dealloc
{
	DESTROY(images);
	
	[super dealloc];
}

- (void) awakeFromNib
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver: self 
           selector: @selector(viewContainerDidResize:) 
               name: NSViewFrameDidChangeNotification 
             object: viewContainer];
			 
	[viewContainer setLayout: AUTORELEASE([[ETStackLayout alloc] init])];
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
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	[viewContainer setLayout: (ETViewLayout *)AUTORELEASE([[layoutClass alloc] init])];
}

- (IBAction) switchUsesSource: (id)sender
{
	if ([sender boolValue])
	{
		[viewContainer setSource: self];
	}
	else
	{
		[viewContainer setSource: nil];
	}
	
	[viewContainer updateLayout];
    
    /* Flow autolayout manager doesn't take care of trigerring or updating the display. */
    [viewContainer setNeedsDisplay: YES];  
}

- (IBAction) switchUsesScrollView: (id)sender
{

}

- (IBAction) scale: (id)sender
{

}

- (void)selectPicturesPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
    NSArray *paths = [panel filenames];
    NSEnumerator *e = [paths objectEnumerator];
    NSString *path = nil;
    
    NSLog(@"Pictures selected: %@\n", paths);
	
	ASSIGN(images, [NSMutableArray array]);
    
    while ((path = [e nextObject]) != nil)
    {
        NSImage *image = [[NSImage alloc] initWithContentsOfFile: path];
		
		if (image != nil)
		{
			NSLog(@"New image loaded: %@\n", image);
			
			[image setName: path];
			[images addObject: image];
		}
    }        
	
	[self setUpLayoutItemsDirectly];
    [viewContainer updateLayout];
    
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
	
	while ((img = [e nextObject]) != nil)
	{
		NSImageView *imgView = [self imageViewForImage: img];
		ETLayoutItem *item = [ETLayoutItem layoutItemWithView: imgView];
				
		[item setValue: [img name] forProperty: @"name"];
		[imageLayoutItems addObject: item];
	}
	
	[viewContainer removeAllItems]; // Remove all views added the last time
	/* We could have added views directly with [viewContainer addViews: views] */
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
	return [images count];
}

- (ETLayoutItem *) itemAtIndex: (int)index inContainer: (ETContainer *)container
{
	NSImage *img = [images objectAtIndex: index];
	ETLayoutItem *imageItem = [ETLayoutItem layoutItemWithView: [self imageViewForImage: img]];
	NSWorkspace *wk = [NSWorkspace sharedWorkspace];
	NSString *sizeStr = NSStringFromSize([img size]);
	NSString *type = nil;
	
	[wk getInfoForFile: [img name] application: NULL type: &type];
	
	[imageItem setValue: [[img name] lastPathComponent] forProperty: @"name"];
	//[imageItem setValue: [wk iconForFile: [image name]] forProperty: @"icon"];
	[imageItem setValue: sizeStr forProperty: @"size"];
	[imageItem setValue: type forProperty: @"type"];
	//[imageItem setValue: date forProperty: @"modificationdate"];
	
	return imageItem;
}

- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container
{
	return [NSArray arrayWithObjects: @"name", @"size", @"type", @"modificationdate", nil];
}

@end
