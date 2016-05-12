//
//  Storage.m
//  sample-users
//
//  Created by Quickblox Team on 6/11/15.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "Storage.h"

@implementation Storage

+ (instancetype)instance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
		NSLog(@"%s", __PRETTY_FUNCTION__);
        instance = [[self class] new];
    });
    
    return instance;
}

- (instancetype)init
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [super init];
    if (self) {
        self.users = [NSMutableArray array];
    }
    return self;
}

@end
