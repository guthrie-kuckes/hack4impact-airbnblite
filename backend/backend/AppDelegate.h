//
//  AppDelegate.h
//  HelloWorld
//
//  Created by Cătălin Stan on 07/03/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

#import <CoreData/CoreData.h>


@interface AppDelegate : NSObject <CRApplicationDelegate>

@property (nonatomic, strong, nonnull) CRServer* server;


///A high level object in the CoreData stack--think the stack might
///get mad if I don't keep a reference but otherwise unused
@property NSPersistentContainer* persistentContainer;

@property NSManagedObjectContext* objectContext;

///The path all of the html files reside at in the bundle
///(path to the copy of the front folder from this project
///that is copied to the bundle during compilation).
@property NSString* pathToHTML;

///Full html text to display a message for thanking the
///user for listing a property
@property NSString* thanksForListingHTML;

///HTML for what would display if there were no search results
@property NSString* emptyRentalResultsHTML;

///HTML for displaying an individual rental search result (individual_property_listing.html)
@property NSString* individualResultHTML;



///Unique IDs are sequential: this is initialized when the application starts up;
@property unsigned long lastUniqueID;

@end
