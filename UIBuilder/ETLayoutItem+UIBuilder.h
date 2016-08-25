/** <title>ETLayoutItem+UIBuilder</title>

	<abstract>ETLayoutItem UI building additions to support live development.</abstract>

	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  January 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETLayoutItem.h>

@class ETTool;

@interface ETLayoutItem (UIBuilder)

@property (nonatomic, strong) ETTool *attachedTool;

@property (nonatomic, copy) NSString *UIBuilderAction;


@property (nonatomic, copy) NSString *UIBuilderModel;
@property (nonatomic, copy) NSString *UIBuilderController;

@end

@interface ETUIObject (UIBuilder)
@property (nonatomic, copy) NSString *instantiatedAspectName;
@end
