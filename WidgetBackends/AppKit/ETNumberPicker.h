/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/NSView+Etoile.h>

/** @group AppKit Widget Backend
 
@abstract A number picker that combines a text field and a stepper at the rigth. */
@interface ETNumberPicker : NSView <ETWidget>
{

}

- (id) initWithFrame: (NSRect)frameRect textFieldHeight: (CGFloat)aFieldHeight;

- (NSTextField *) textField;
- (NSStepper *) stepper;

- (double) minValue;
- (void) setMinValue: (double)aValue;
- (double) maxValue;
- (void) setMaxValue: (double)aValue;
- (void) setDoubleValue: (double)aValue;

@end
