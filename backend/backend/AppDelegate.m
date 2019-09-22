#import "AppDelegate.h"

#import <CoreData/CoreData.h>

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong, nonnull) CRServer* server;

@property NSPersistentContainer* persistentContainer;

@property NSManagedObjectContext* objectContext;


@end

@implementation AppDelegate

+(void)logProperty:(NSManagedObject*)property
{
    NSString* name = [property valueForKey:@"name"];
    NSNumber* max_occupancy = [property valueForKey:@"max_occupancy"];
    NSNumber* max_days = [property valueForKey:@"max_days"];
    NSNumber* nightly_cost = [property valueForKey:@"nightly_cost"];
    NSString* reservedString = [property valueForKey:@"reserved"] ? @"true" : @"false";
    
    NSString* formatted = [NSString stringWithFormat:@"name: \"%@\", max_occupancy: %@, max_days: %@, nightly_cost: %@ cents, reserved: %@",
                           name, max_occupancy, max_days, nightly_cost, reservedString];
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
    
    [self.objectContext save:error];
}


///Does all necessary setup for my application to run,
///including initializing the database
-(void)serverSetup
{
    self.server = [[CRHTTPServer alloc] init];
    
    [self initializeDatabase];
    
    //[self deleteDatabase];
    [self logWholeDatabase];
    
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:[NSBundle mainBundle].bundleIdentifier forHTTPHeaderField:@"Server"];
        completionHandler();
    }];
}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    //does most of the needed setup, initializes instance variables and the database
    [self serverSetup];
    
    //Tells the server to fetch all resources which can be statically served
    NSString* frontPath = [[NSBundle mainBundle].resourcePath stringByAppendingString:@"/front"];
    [self.server mountStaticDirectoryAtPath:frontPath forPath:@"/"];
    
    NSError* setupError = nil;
    NSString* thanksForListingPath = [frontPath stringByAppendingString:@"/list_property_display.html"];
    NSString* thanksForListingStatic = [NSString stringWithContentsOfFile:thanksForListingPath
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:&setupError];
    if(setupError)
    {
        NSLog(setupError.description);
        abort();
    }

    
    
    
    //Tells the server how to dynamically generate rental search results
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
    
        NSString* serve = @"stuff"; //[NSString stringWithContentsOfFile:@"/Users/valence/Documents/google_drive/ofCodrs/hack4impact/airbnb_lite/front/index.html" encoding:NSUTF8StringEncoding error:nil];
        
        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response setValue:@(serve.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendString:serve];
        completionHandler();
    } forPath:@"/generate_rental_results" HTTPMethod:CRHTTPMethodGet];
    
    
    //Tells the server how to deal with posting a property to rent
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        
        NSString* serve = thanksForListingStatic;
        
        //when there are spaces in the name, the url encodes them as +
        NSString* name = [request.query[@"property_name"] stringByReplacingOccurrencesOfString: @"+" withString:@" "];
        
        //use this!
        NSString* description = request.query[@"description"];
        
        NSInteger max_nights = [request.query[@"max_nights"] integerValue];
        //comes back from the server in dollars
        NSInteger nightlyCost = [request.query[@"cost_per_night"] integerValue] * 100;
        [self addPropertyToDatabase:name withMaxOccupancy:0 maxDaysForRental:max_nights nightlyCost:nightlyCost error:nil];
        NSLog(request.query.description);
        
        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response setValue:@(serve.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendString:serve];
        completionHandler();
    } forPath:@"/dynamic_list_property" HTTPMethod:CRHTTPMethodGet];

    
    
    
    
    /*
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        
        NSString* last = request.query[@"lastname"];
        NSString* serve = [NSString stringWithFormat:@"lastname was %@", last];
        
        [response sendString:serve];
        completionHandler();
    } forPath:@"/result" HTTPMethod:CRHTTPMethodGet];*/

    
    //Logs all requests to the serevr
    /*
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSUInteger statusCode = request.response.statusCode;
        NSString* contentLength = [request.response valueForHTTPHeaderField:@"Content-Length"];
        NSString* userAgent = request.env[@"HTTP_USER_AGENT"];
        NSString* remoteAddress = request.connection.remoteAddress;
        NSLog(@"%@ %@ - %lu %@ - %@", remoteAddress, request, statusCode, contentLength ? : @"-", userAgent);
        completionHandler();
    }];*/
    
    [self.server startListening];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
