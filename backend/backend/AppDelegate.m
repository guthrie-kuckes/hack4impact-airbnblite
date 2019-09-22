#import "AppDelegate.h"

#import "AppDelegate+AppDelegate_DatabaseInteractions.h"

#import <CoreData/CoreData.h>

@interface AppDelegate () <CRServerDelegate>



@end

@implementation AppDelegate



///Returns the html code for displaying an individual search result
///filled out with the correct information from one property retrieved from the database
///(The managed object must be of the correct entity type)
-(NSString*)fillOutPropertyBlockWithProperty:(NSManagedObject*)property
{
    NSString* copy = [self.individualResultHTML copy];
    copy = [copy stringByReplacingOccurrencesOfString:@"${property_name}"
                                           withString:[property valueForKey:@"name"]];
    return copy;
}


///Does all necessary setup for my application to run,
///including initializing the database
-(void)serverSetup
{
    self.server = [[CRHTTPServer alloc] init];
    self.pathToHTML = [[NSBundle mainBundle].resourcePath stringByAppendingString:@"/front"];
    
    
    NSError* setupError = nil;
    NSString* thanksForListingPath = [self.pathToHTML stringByAppendingString:@"/list_property_display.html"];
    self.thanksForListingHTML = [NSString stringWithContentsOfFile:thanksForListingPath
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:&setupError];
    
    NSString* rentalDisplayPath = [self.pathToHTML stringByAppendingString:@"/property_search_display.html"];
    self.emptyRentalResultsHTML = [NSString stringWithContentsOfFile:rentalDisplayPath
                                                           encoding:NSUTF8StringEncoding
                                                              error:&setupError];
    
    NSString* individualResultPath = [self.pathToHTML stringByAppendingString:@"/individual_property_listing.html"];
    self.individualResultHTML = [NSString stringWithContentsOfFile:individualResultPath
                                                          encoding:NSUTF8StringEncoding
                                                             error:&setupError];
    if(setupError)
    {
        NSLog(setupError.description);
        abort();
    }
    
    [self initializeDatabase];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"H4IRentalProperty"];
    NSArray *results = [self.objectContext executeFetchRequest:request error:nil];
    self.lastUniqueID = 0;
    for (NSManagedObject* obj in results)
    {
        NSNumber* toCompare = [obj valueForKey:@"unique_id"];
        if (toCompare.unsignedLongValue >  self.lastUniqueID)
            self.lastUniqueID = toCompare.unsignedLongValue;
    }

    
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
    [self.server mountStaticDirectoryAtPath:self.pathToHTML forPath:@"/" options: CRStaticDirectoryServingOptionsAutoIndex];
    
    
    
    //Tells the server how to dynamically generate rental search results
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
    
        NSMutableString* serve = [[self emptyRentalResultsHTML] mutableCopy];
        
        NSError *error = nil;
        NSFetchRequest *allRequest = [NSFetchRequest fetchRequestWithEntityName:@"H4IRentalProperty"];
        NSArray *results = [self.objectContext executeFetchRequest:allRequest error:&error];
        if (!results) {
            NSLog(@"Error fetching rental property objects: %@\n%@", [error localizedDescription], [error userInfo]);
            abort();
        }

        
        serve = [serve stringByReplacingOccurrencesOfString:@"${num_search_results}"
                                                 withString:[NSString stringWithFormat:@"%lu", results.count]];
        
        
        NSRange range = [serve rangeOfString:@"<!-- property listings go here -->"];
        for (NSManagedObject* obj in results)
        {
            id isReservedID = [obj valueForKey:@"reserved"];
            BOOL isReserved = [(NSNumber*)(isReservedID) boolValue];
            if (!isReserved)
            {
                NSString* formatted = [self fillOutPropertyBlockWithProperty:obj];
                [serve insertString:formatted atIndex:range.location];
            }
        }
        
        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response setValue:@(serve.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendString:serve];
        completionHandler();
    } forPath:@"/generate_rental_results" HTTPMethod:CRHTTPMethodGet];
    
    
    //Tells the server how to deal with posting a property to rent
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        
        NSString* serve = self.thanksForListingHTML;
        
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
