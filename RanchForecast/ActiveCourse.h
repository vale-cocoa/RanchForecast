//
//  ActiveCourse.h
//  RanchForecast
//
//  Created by Valeriano Della Longa on 3/30/17.
//  Copyright © 2017 Valeriano Della Longa. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ScheduledClass;

extern NSString *const BNRActiveCourseTitleKey;
extern NSString *const BNRActiveCourseURLKey;
extern NSString *const BNRActiveCourseUpcomingKey;

@interface ActiveCourse : NSObject <NSCopying, NSCoding>

@property (copy) NSString *title;
@property (copy) NSURL *url;
@property (copy) NSArray <ScheduledClass *> *upcoming;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
