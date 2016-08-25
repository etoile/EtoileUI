/**
	Copyright (C) 2013 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETModelDescriptionRenderer.h>
#import <EtoileUI/ETObjectValueFormatter.h>

@class ETModelDescriptionRepository;
@class ETItemValueTransformer;

@protocol ETModelBuilderEditionCoordinator
@property (nonatomic, readonly) ETModelDescriptionRepository *repository;
@end

@interface ETModelBuilderController : ETController <ETModelBuilderEditionCoordinator, ETObjectValueFormatterDelegate>
{
	@private
	ETItemValueTransformer *_relationshipValueTransformer;
}

/** @taskunit Editing */

/** Returns a value transformer that searches model element descriptions inside 
-repository. */
@property (nonatomic, readonly) ETItemValueTransformer *relationshipValueTransformer;
/** Returns a new value transformer that searches model element descriptions 
inside the repository bound to the edited item controller. 
 
The edited item controller must conform to ETModelBuilderController. */
+ (ETItemValueTransformer *) newRelationshipValueTransformer;

@end

@interface ETModelBuilderRelationshipController : ETPropertyCollectionController
- (IBAction) edit: (id)sender;
@end

