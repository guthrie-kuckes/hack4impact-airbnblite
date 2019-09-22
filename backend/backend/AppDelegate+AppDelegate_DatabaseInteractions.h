//
//  AppDelegate+AppDelegate_DatabaseInteractions.h
//  airbnblite-backend
//
//  Created by Guthrie Kuckes on 9/22/19.
//  Copyright © 2019 Criollo.io. All rights reserved.
//


#import <Foundation/Foundation.h>

@class  NSManagedObject;
#import "AppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate (DatabaseInteractions)

-(void)initializeDatabase;

-(void)deleteDatabase;

-(void)logWholeDatabase;

+(void)logProperty:(NSManagedObject*)property;


///Adds a new property to the database, not reserved
///and with a unique id one greater than the last property
-(void)addPropertyToDatabase:(NSString*)propertyName
            withMaxOccupancy:(uint16)maxOccupancy
            maxDaysForRental:(uint16)maxDays
                 nightlyCost:(uint16)cost
                       error:(NSError**)error;




@end

NS_ASSUME_NONNULL_END
