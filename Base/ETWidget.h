/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


/** @group Base
@abstract Widget Proxy Protocol

See -[ETLayoutItem widget]. */
@protocol ETWidget
- (id) target;
- (void) setTarget: (id)aTarget;
- (SEL) action;
- (void) setAction: (SEL)aSelector;
- (id) objectValue;
- (void) setObjectValue: (id)aValue;
- (id) formatter;
- (void) setFormatter: (NSFormatter *)aFormatter;
- (NSActionCell *) cell;
@optional
- (double) minValue;
- (void) setMinValue: (double)aValue;
- (double) maxValue;
- (void) setMaxValue: (double)aValue;
- (void) setDoubleValue: (double)aValue;
@end
