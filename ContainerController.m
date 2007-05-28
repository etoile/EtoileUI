#import "ContainerController.h"
#import "ETStackLayout.h"
#import "ETFlowLayout.h"
#import "ETLineLayout.h"
#import "GNUstep.h"


@implementation ContainerController

- (void) awakeFromNib
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver: self 
           selector: @selector(viewContainerDidResize:) 
               name: NSViewFrameDidChangeNotification 
             object: viewContainer];
			 
	[viewContainer setLayout: AUTORELEASE([[ETLineLayout alloc] init])];
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

- (void)selectPicturesPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
    NSArray *paths = [panel filenames];
    NSEnumerator *e = [paths objectEnumerator];
    NSString *path = nil;
    NSMutableArray *images = [NSMutableArray array];
    
    NSLog(@"Pictures selected: %@\n", paths);
    
    while ((path = [e nextObject]) != nil)
    {
        NSImage *image = [[NSImage alloc] initWithContentsOfFile: path];
        
        if (image != nil)
        {
            NSLog(@"New image loaded: %@\n", image);
            [images addObject: image];
        }
    }        
    
    NSArray *views = [self imageViewsForImages: images];
    
	[viewContainer removeAllItems]; // Remove all views added the last time
	[viewContainer addViews: views];
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
        NSImageView *view = [[NSImageView alloc] 
            initWithFrame: NSMakeRect(0, 0, [image size].width, [image size].height)];
        
        [view setImage: image];
        [views addObject: view];
        RELEASE(view);
    }

    NSLog(@"New image views list: %@\n", views);

    return views;
}

@end
