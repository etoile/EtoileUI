//
//  FSBrowserCell.h
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
//
//  FSBrowserCell knows how to display file system info obtained from an FSNodeInfo object.

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface FSBrowserCell : NSBrowserCell 
{ 
@private
    NSImage *iconImage;
}

- (void) setIconImage: (NSImage *)image;
- (NSImage *) iconImage;

@end

