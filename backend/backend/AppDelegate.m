#import "AppDelegate.h"

#import <CoreData/CoreData.h>

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong, nonnull) CRServer* server;



@property NSPersistentContainer* persistentContainer; //from apple code

@property NSManagedObjectContext* objectContext; //seems to be necessart from apple code

@end

@implementation AppDelegate


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


//Must call [self initializeDatabase] before calling this
-(void)addPropertyToDatabase:(NSString*)propertyName
            withMaxOccupancy:(uint16)maxOccupancy
                       error:(NSError**)error
{
    NSManagedObject* newOne = [NSEntityDescription insertNewObjectForEntityForName:@"H4IRentalProperty"
                                                            inManagedObjectContext:self.objectContext];
    [newOne setValue:propertyName forKey:@"name"];
    NSNumber* copy = [NSNumber numberWithInteger:maxOccupancy];
    [newOne setValue:copy forKey:@"max_occupancy"];
    [self.objectContext save:error];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.server = [[CRHTTPServer alloc] init];
    
    
    [self initializeDatabase]; 
    NSError* addError = nil;
    [self addPropertyToDatabase:@"my mansion" withMaxOccupancy:20 error:&addError
     ];
    if (addError)
        NSLog(addError.description);
    
    
    NSError *error = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"H4IRentalProperty"];
    NSArray *results = [self.objectContext executeFetchRequest:request error:&error];
    NSLog(results.description);
    if (!results) {
        NSLog(@"Error fetching Employee objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    
    
    
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:[NSBundle mainBundle].bundleIdentifier forHTTPHeaderField:@"Server"];
        completionHandler();
    }];
    
    /*[self.server get:@"/" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response sendString:@"Hello world!"];
        completionHandler();
    }];*/
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
    
        NSString* serve = [NSString stringWithContentsOfFile:@"/Users/valence/Desktop/index.html" encoding:NSUTF8StringEncoding error:nil];
        
        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response setValue:@(serve.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendString:serve];
        completionHandler();
    } forPath:@"/" HTTPMethod:CRHTTPMethodGet];
    
    
    
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        
        NSString* last = request.query[@"lastname"];
        NSString* serve = [NSString stringWithFormat:@"lastname was %@", last];
        
        [response sendString:serve];
        completionHandler();
    } forPath:@"/result" HTTPMethod:CRHTTPMethodGet];

    
    
    
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSUInteger statusCode = request.response.statusCode;
        NSString* contentLength = [request.response valueForHTTPHeaderField:@"Content-Length"];
        NSString* userAgent = request.env[@"HTTP_USER_AGENT"];
        NSString* remoteAddress = request.connection.remoteAddress;
        NSLog(@"%@ %@ - %lu %@ - %@", remoteAddress, request, statusCode, contentLength ? : @"-", userAgent);
        completionHandler();
    }];
    
    [self.server startListening];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
