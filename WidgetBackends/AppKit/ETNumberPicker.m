/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETNumberPicker.h"

static const NSInteger textFieldTag = 1;
static const NSInteger stepperTag = 2;

@implementation ETNumberPicker

- (id) initWithFrame: (NSRect)frameRect textFieldHeight: (CGFloat)aFieldHeight
{
	self = [super initWithFrame: frameRect];
	if (self == nil)
		return nil;

	NSStepper *stepper = [[NSStepper alloc] initWithFrame: frameRect];
	NSTextField *textField = [[NSTextField alloc] initWithFrame: frameRect];

	[stepper sizeToFit];

	CGFloat margin = 2;

	[textField setWidth: [textField width] - margin - [stepper width]];
	[textField setHeight: aFieldHeight];
	[textField setY: (frameRect.size.height - aFieldHeight) / 2];
	[stepper setX: [textField width] + margin];

	[self addSubview: textField];
	[self addSubview: stepper];

	return self;
}

- (BOOL) acceptsFirstResponder
{
	return NO;
}

- (NSTextField *) textField
{
	return [self viewWithTag: textFieldTag];
}

- (NSStepper *) stepper
{
	return [self viewWithTag: stepperTag];
}

- (id) target
{
	return [[self textField] target];
}

- (void) setTarget: (id)aTarget
{
	[[self textField] setTarget: aTarget];
}

- (SEL) action
{
	return [[self textField] action];
}

- (void) setAction: (SEL)aSelector
{
	[[self textField] setAction: aSelector];
}

- (id) objectValue
{
	return [[self textField] objectValue];
}

- (void) setObjectValue: (id)aValue
{
	[[self textField] setObjectValue: aValue];
}

- (NSActionCell *) cell
{
	return [[self textField] cell];
}

@end
