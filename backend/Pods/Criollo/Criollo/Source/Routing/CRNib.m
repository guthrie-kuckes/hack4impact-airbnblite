//
//  CRNib.m
//  Criollo
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRNib.h"

NS_ASSUME_NONNULL_BEGIN
@interface CRNib ()

@property (nonatomic, readonly, strong) NSMutableDictionary<NSString*, NSData*> *cache;
@property (nonatomic, readonly, strong) dispatch_queue_t isolationQueue;

@end
NS_ASSUME_NONNULL_END

@implementation CRNib

- (NSMutableDictionary*)cache {
    static NSMutableDictionary* cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSMutableDictionary dictionary];
    });
    return cache;
}

- (dispatch_queue_t)isolationQueue {
    static dispatch_queue_t isolationQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isolationQueue = dispatch_queue_create([[NSStringFromClass(self.class) stringByAppendingPathExtension:@"IsolationQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(isolationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    });
    return isolationQueue;
}

- (instancetype)init {
    return [self initWithNibNamed:@"" bundle:nil];
}

- (instancetype)initWithNibNamed:(NSString *)nibName bundle:(NSBundle *)bundle {
    self = [super init];
    if ( self != nil ) {
        _name = nibName;
        if ( bundle == nil ) {
            bundle = [NSBundle mainBundle];
        }
        NSString* path = [bundle pathForResource:self.name ofType:@"html"];
        if ( path != nil ) {
            if ( self.cache[path] != nil ) {
                _data = self.cache[path];
            } else {
                _data = [NSData dataWithContentsOfFile:path options:NSDataReadingMapped error:nil];
                dispatch_async(self.isolationQueue, ^{
                    self.cache[path] = _data;
                });
            }
        }
    }
    return self;
}

@end