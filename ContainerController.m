#import "ContainerController.h"
#import "ETLayoutItem.h"
#import "ETStackLayout.h"
#import "ETFlowLayout.h"
#import "ETLineLayout.h"
#import "ETTableLayout.h"
#import "GNUstep.h"


@implementation ContainerController

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

- (void)selectPicturesPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
    NSArray *paths = [panel filenames];
    NSEnumerator *e = [paths objectEnumerator];
    NSString *path = nil;
    NSMutableArray *images = [NSMutableArray array];
	NSMutableArray *imageLayoutItems = [NSMutableArray array];
    
    NSLog(@"Pictures selected: %@\n", paths);
    
    while ((path = [e nextObject]) != nil)
    {
        NSImage *image = [[NSImage alloc] initWithContentsOfFile: path];
		NSImageView *imageView = [self imageViewForImage: image];
        
        if (imageView != nil)
        {
			ETLayoutItem *item = [ETLayoutItem layoutItemWithView: imageView];
			
			[[item properties] setObject: path forKey: @"name"];
			[imageLayoutItems addObject: item];
            NSLog(@"New image loaded: %@\n", image);
            [images addObject: image];
        }
    }        
    
	
	[viewContainer removeAllItems]; // Remove all views added the last time
	//[viewContainer addViews: views];
	[viewContainer addItems: imageLayoutItems];
    [viewContainer updateLayout];
    
    /* Flow autolayout manager doesn't take care of trigerring or updating the display. */
    [viewContainer setNeedsDisplay: YES];  
}

- (NSArray *) imageViewsForImages: (NSArray *)images
{
    NSEnumerator *e = [images objectEnumerator];
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

@end
