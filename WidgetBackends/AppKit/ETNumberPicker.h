/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETWidget.h>

/** @group AppKit Widget Backend
 
@abstract A number picker that combines a text field and a stepper at the rigth. */
@interface ETNumberPicker : NSView <ETWidget>
{

}

- (instancetype) initWithFrame: (NSRect)frameRect textFieldHeight: (CGFloat)aFieldHeight NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) NSTextField *textField;
@property (nonatomic, readonly) NSStepper *stepper;

@property (nonatomic) double minValue;
@property (nonatomic) double maxValue;

- (void) setDoubleValue: (double)aValue;

@end
