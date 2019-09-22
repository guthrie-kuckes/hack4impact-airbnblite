//
//  AppDelegate+AppDelegate_DatabaseInteractions.m
//  airbnblite-backend
//
//  Created by Guthrie Kuckes on 9/22/19.
//  Copyright © 2019 Criollo.io. All rights reserved.
//

#import "AppDelegate+AppDelegate_DatabaseInteractions.h"
#import <CoreData/CoreData.h>

@implementation AppDelegate (DatabaseInteractions)

+(void)logProperty:(NSManagedObject*)property
{
    NSString* name = [property valueForKey:@"name"];
    NSNumber* max_occupancy = [property valueForKey:@"max_occupancy"];
    NSNumber* max_days = [property valueForKey:@"max_days"];
    NSNumber* nightly_cost = [property valueForKey:@"nightly_cost"];
    NSString* reservedString = [property valueForKey:@"reserved"] ? @"true" : @"false";
    NSNumber* unique_id = [property valueForKey:@"unique_id"];
    
    NSString* formatted = [NSString stringWithFormat:@"name: \"%@\", max_occupancy: %@, max_days: %@, nightly_cost: %@ cents, reserved: %@, unique_id: %@",
                           name, max_occupancy, max_days, nightly_cost, reservedString, unique_id];
    NSLog(formatted);
}

-(void)logWholeDatabase
{
    NSError *error = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"H4IRentalProperty"];
    NSArray *results = [self.objectContext executeFetchRequest:request error:&error];
    for (NSManagedObject* obj in results)
    {
        [AppDelegate logProperty:obj];
    }
    if (!results) {
        NSLog(@"Error fetching Employee objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
}


//encapsulates mostly apple code
-(void)initializeDatabase
{
    self.persistentContainer = [[NSPersistentContainer alloc] initWithName:@"DataModel"];
    [self.persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *description, NSError *error) {
        if (error != nil) {
            NSLog(@"Failed to load Core Data stack: %@", error);
            abort();
        }
        //callback();
    }];
    self.objectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.objectContext.persistentStoreCoordinator = self.persistentContainer.persistentStoreCoordinator;
}

-(void)deleteDatabase
{
    NSError *error = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"H4IRentalProperty"];
    NSArray *results = [self.objectContext executeFetchRequest:request error:&error];
    for (NSManagedObject* obj in results)
    {
        [self.objectContext deleteObject:obj];
    }
    if (!results) {
        NSLog(@"Error fetching Employee objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
}

-(void)addPropertyToDatabase:(NSString*)propertyName
            withMaxOccupancy:(uint16)maxOccupancy
            maxDaysForRental:(uint16)maxDays
                 nightlyCost:(uint16)cost
                       error:(NSError**)error
{
    NSManagedObject* newOne = [NSEntityDescription insertNewObjectForEntityForName:@"H4IRentalProperty"
                                                            inManagedObjectContext:self.objectContext];
    [newOne setValue:propertyName forKey:@"name"];
    NSNumber* copy = [NSNumber numberWithInteger:maxOccupancy];
    [newOne setValue:copy forKey:@"max_occupancy"];
    
    copy = [NSNumber numberWithInteger:maxDays];
    [newOne setValue:copy forKey:@"max_days"];
    
    copy = [NSNumber numberWithInteger:cost];
    [newOne setValue:copy forKey:@"nightly_cost"];
    
    [newOne setValue:FALSE forKey:@"reserved"];
    
    self.lastUniqueID++;
    [newOne setValue:[NSNumber numberWithLong:self.lastUniqueID]
              forKey:@"unique_id"];
    
    [self.objectContext save:error];
}

@end
