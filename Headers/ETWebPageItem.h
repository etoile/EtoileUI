/**  <title>ETWebPageItem</title>
 
 <abstract>ETLayoutItem subclass which displays a web page (specified by
 providing an NSURL instance as the ETWebPageItem's represented object)
 </abstract>
 
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  August 2009
 License:  Modified BSD  (see COPYING)
 */

#import <EtoileUI/ETLayoutItem.h>
#import <WebKit/WebKit.h>

@interface ETWebPageItem : ETLayoutItem
{
}

/* Private */

- (WebView *)webView;

@end

@interface WebView (Etoile)

- (BOOL) isWidget;

@end
