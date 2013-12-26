/**
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETWidgetLayout.h>

// FIXME: Don't expose NSBrowser in the public API.
@class NSBrowser;


@interface ETBrowserLayout : ETWidgetLayout
{

}

- (NSBrowser *) browser;

@end
