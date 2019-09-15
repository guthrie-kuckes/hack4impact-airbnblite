#import "AppDelegate.h"

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong, nonnull) CRServer* server;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.server = [[CRHTTPServer alloc] init];
    
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
