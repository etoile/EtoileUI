//
//  ETPaneView.h
//  Container
//
//  Created by Quentin Mathé on 06/06/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ETContainer.h"


@interface ETPaneView : ETContainer 
{

}

/** Returns the container where pane view are displayed */
- (NSView *) contentView;
- (ETViewLayout *) contentLayout;
- (void) setContentLayout: (ETViewLayout *)layout;
- (void) restoreDefaultContentLayout;

- setSourceView: (
- setSourceViewVisible: (BOOL)visible;
- (BOOL) isSourceViewVisible;

- back
- forward

@end
