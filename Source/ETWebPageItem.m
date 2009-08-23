/*
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  August 2009
 License:  Modified BSD  (see COPYING)
 */

#import <WebKit/WebKit.h>
#import <EtoileUI/ETCompatibility.h>
#import <EtoileFoundation/Macros.h>
#import "ETWebPageItem.h"

/**
 * Layout item which displays a web page.
 *
 * The represented object is the NSURL of the web page to display.
 */
@implementation ETWebPageItem

- (id) init
{
	self = [super initWithView: AUTORELEASE([[WebView alloc] init])];
	if (nil == self)
		return nil;
	
	[[self webView] setFrameLoadDelegate: self];
	
	return self;
}

- (WebView *) webView
{
	return (WebView *)[self view];
}

- (void) setRepresentedObject: (id)object
{
	[super setRepresentedObject: object];
	if ([object isKindOfClass: [NSURL class]])
	{
		[[[self webView] mainFrame] loadRequest: [NSURLRequest requestWithURL: object]];
	}
}

/**
 * Return a string representation of the URL being displayed.
 *
 * This will cause the URL to be part of the reciever's represented path.
 */
- (NSString *) identifier
{
	return [[self representedObject] absoluteString];
}

/* WebKit FrameLoadDelegate methods */

- (void) webView: (WebView *)sender didStartProvisionalLoadForFrame: (WebFrame *)frame
{
    if (frame == [sender mainFrame])
	{
        [super setRepresentedObject: [[[frame provisionalDataSource] request] URL]];
    }
}

- (void) webView: (WebView *)sender didReceiveTitle: (NSString *)title forFrame: (WebFrame *)frame
{
    if (frame == [sender mainFrame])
	{
		[self setName: title];
    }
}

@end



@implementation WebView (Etoile)

- (BOOL) isWidget
{
	return YES;
}

@end