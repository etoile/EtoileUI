/**
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2014
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <CoreObject/COObject.h>

@interface ETObservation : COObject

@property (nonatomic, retain) COObject *object;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign) SEL selector;

@end