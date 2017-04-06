//
//  BNRIndeterminateTransformer.m
//  RanchForecast
//
//  Created by Valeriano Della Longa on 3/31/17.
//  Copyright © 2017 Valeriano Della Longa. All rights reserved.
//

#import "BNRIndeterminateTransformer.h"

@implementation BNRIndeterminateTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    NSNumber *transformed = @NO;
    if ([value respondsToSelector:@selector(state)]) {
        if ([value state] == NSURLSessionTaskStateRunning) {
            transformed = @YES;
        }
    } else if (value == nil) {
        return @YES;
    }
    return transformed;
}

@end
