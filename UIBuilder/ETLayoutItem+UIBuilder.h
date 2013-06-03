/** <title>ETLayoutItem+UIBuilder</title>

	<abstract>ETLayoutItem UI building additions to support live development.</abstract>

	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  January 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>

@interface ETLayoutItem (UIBuilder)

- (NSString *) UIBuilderAction;
- (void) setUIBuilderAction: (NSString *)aString;


- (void)setUIBuilderModel: (NSString *)aModel;
- (NSString *)UIBuilderModel;
- (void)setUIBuilderController: (NSString *)aController;
- (NSString *)UIBuilderController;

@end

@interface ETUIObject (UIBuilder)
- (NSString *) instantiatedAspectName;
- (void) setInstantiatedAspectName: (NSString *)aName;
@end
