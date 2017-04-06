//
//  BNRCoursesFetcher.m
//  RanchForecast
//
//  Created by Valeriano Della Longa on 3/31/17.
//  Copyright © 2017 Valeriano Della Longa. All rights reserved.
//

#import "BNRCoursesFetcher.h"
#import "ActiveCourse.h"
#import "ScheduledClass.h"
#import <SecurityInterface/SFCertificatePanel.h>

NSString *const BNRURLForCoursesJSON = @"https://bookapi.bignerdranch.com/courses.json";

@interface BNRCoursesFetcher () <NSURLSessionDelegate, NSURLSessionTaskDelegate>
{
    NSMutableArray *_courses;
    BOOL _acceptSelfSignedCert;
}

@property (strong, nonatomic, readwrite) NSArray <ActiveCourse *> *courses;
@property (assign, getter=isFetching, readwrite) BOOL fetching;
@property (strong, readwrite) NSURLResponse *lastFetchResponse;
@property (strong, readwrite) NSError *error;
@property (strong, readwrite) NSNumber *countToFetch;
@property (strong, readwrite) NSNumber *indexOfFetch;
@property (strong) NSURLSession *session;

@property (strong) NSURL *jsonURL;
@property (strong) NSURLRequest *request;
@property (strong) NSURLSessionDataTask *fetchTask;

@end

@implementation BNRCoursesFetcher

@synthesize courses = _courses;

- (instancetype)init {
    self = [super init];
    if (self) {
        dispatch_queue_t bgQueue  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [queue setUnderlyingQueue:bgQueue];
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:queue];
        _courses = [[NSMutableArray alloc] init];
        _jsonURL = [NSURL URLWithString:BNRURLForCoursesJSON];
        _request = [NSURLRequest requestWithURL:_jsonURL cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:30];
        _fetching = NO;
        _countToFetch = 0;
        _indexOfFetch = 0;
        _acceptSelfSignedCert = NO;
    }
    return self;
}

#pragma mark - KVO courses

- (NSArray <ActiveCourse *> *)courses {
    return [_courses copy];
}

- (void)setCourses:(NSArray <ActiveCourse *> *)courses {
    if (courses != _courses) {
        _courses = [courses mutableCopy];
    }
}

- (void)insertObject:(ActiveCourse *)object inCoursesAtIndex:(NSUInteger)index {
    [_courses insertObject:object atIndex:index];
}

- (void)removeObjectFromCoursesAtIndex:(NSUInteger)index {
    [_courses removeObjectAtIndex:index];
}

- (void)addCoursesObject:(ActiveCourse *)object {
    [_courses insertObject:object atIndex:[_courses count]];
}

- (void)removeCoursesObject:(ActiveCourse *)object {
    NSUInteger found = [_courses indexOfObject:object];
    if (found != NSNotFound) {
        [_courses removeObjectAtIndex:found];
    }
}

- (NSArray <ActiveCourse *> *)coursesAtIndexes:(NSIndexSet *)indexes {
    return [[_courses objectsAtIndexes:indexes] copy];
}

- (void)replaceCoursesAtIndexes:(NSIndexSet *)indexes withCourses:(NSArray <ActiveCourse *> *)array {
    [_courses replaceObjectsAtIndexes:indexes withObjects:array];
}

#pragma mark - Actions
- (void)toggleFetch:(id _Nullable)sender {
    if (self.isFetching) {
        [self fetch];
    } else {
        [self stopFetching];
    }
}

#pragma mark - helpers

- (void)fetch {
    if (_fetchTask != nil) {
        [self.fetchTask cancel];
    }
    self.lastFetchResponse = nil;
    self.error = nil;
    self.courses = @[];
    
    __weak id weakSelf = self;
    
    self.fetchTask = [_session dataTaskWithRequest:_request completionHandler:^(NSData *sessionData, NSURLResponse *sessionResponse, NSError *error){
        
        __strong id strongSelf = weakSelf;
        dispatch_queue_t mainQ = dispatch_get_main_queue();
    
        dispatch_async(mainQ, ^{
            [strongSelf setValue:sessionResponse forKey:@"lastFetchResponse"];
            [strongSelf setValue:error forKey:@"error"];
        });
        
        if (!sessionData) {
            // No data! set fetching state then return.
            dispatch_async(mainQ, ^{
                [strongSelf setValue:@NO forKey:@"fetching"];
            });
            return;
        }
        // We got data, let's parse the JSON…
        NSError *parseError = nil;
        NSDictionary *dicts = [NSJSONSerialization JSONObjectWithData:sessionData options:0 error:&parseError];
        
        if (parseError) {
            // parsing JSON failed, set error then return.
            dispatch_async(mainQ, ^{
                [strongSelf setError:parseError];
                [strongSelf setValue:@NO forKey:@"fetching"];
            });
            return;
        }
        
        // Prepare factory for ActiveCourse objects:
        NSArray *coursesDicts = [dicts objectForKey:@"courses"];
        NSUInteger countOfCoursesToParse = [coursesDicts count];
        NSUInteger indexOfParsing = 1;
        dispatch_async(mainQ, ^{
            [strongSelf setValue:@(countOfCoursesToParse) forKey:@"countToFetch"];
            [strongSelf setValue:@(0) forKey:@"indexOfFetch"];
        });
        
        // Factory of dictionaries into ActiveCourse objects:
        for (id aDict in coursesDicts) {
            dispatch_async(mainQ, ^{
                [strongSelf setValue:@(indexOfParsing) forKey:@"indexOfFetch"];
            });
            if ([aDict isKindOfClass:[NSDictionary class]]) {
                ActiveCourse *newCourse = [[ActiveCourse alloc] initWithDictionary:aDict];
                dispatch_async(mainQ, ^{
                    [strongSelf addCoursesObject:newCourse];
                });
            }
            indexOfParsing++;
            // delay a bit execution to see UI changes
            [NSThread sleepForTimeInterval: 0.5];
            if ([strongSelf isFetching] == NO) {
                break;
            }
        }
    
        dispatch_async(mainQ, ^{
            [strongSelf setValue:@NO forKey:@"fetching"];
        });
    }];
    
    [self.fetchTask resume];
}

- (void)stopFetching {
    if (_fetchTask && _fetchTask.state == NSURLSessionTaskStateRunning) {
        [self.fetchTask cancel];
        self.fetchTask = nil;
    }
    self.fetching = NO;
}

#pragma mark- NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    NSLog(@"URLSession:task:didReceiveChallenge: was called");
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
     __block NSURLCredential *credential = nil;
    
    SecTrustRef trust = [challenge.protectionSpace serverTrust];
    OSStatus err;
    BOOL allowConnection = NO;
    SecTrustResultType trustResult;
    err = SecTrustEvaluate(trust, &trustResult);
    NSError *newError;
    if (err == noErr) {
        allowConnection = (trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified);
    } else {
        NSLog(@"error evalutaing trust: %d", (int)err);
        NSMutableDictionary *newUserInfo = [NSMutableDictionary dictionary];
        if (self.error) {
            [newUserInfo setObject:self.error forKey:NSUnderlyingErrorKey];
        }
        [newUserInfo setObject:NSLocalizedString(@"Not able to evaluate trust for server certificate", @"") forKey:NSLocalizedDescriptionKey];
        NSString *locStringFailure = [NSString stringWithFormat:@"Got %d error while attempting to evaluate the server certificate.", (int)err];
        [newUserInfo setObject:NSLocalizedString(locStringFailure, @"") forKey:NSLocalizedFailureReasonErrorKey];
        newError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:newUserInfo];
        
    }
    switch (trustResult) {
        case kSecTrustResultProceed:
        case kSecTrustResultUnspecified:
            allowConnection = YES;
            break;
        case kSecTrustResultRecoverableTrustFailure:
        {
            // Iterate through trust certificate chain in look for
            // a certificate which is in the system's anchors:
            CFArrayRef systemCertsRef;
            SecTrustCopyAnchorCertificates(&systemCertsRef);
            NSArray *systemCerts = CFBridgingRelease(systemCertsRef);
            CFIndex countOfTrustCerts = SecTrustGetCertificateCount(trust);
            CFIndex indexOfTrustCert;
            BOOL found = NO;
            for (indexOfTrustCert = 0; indexOfTrustCert < countOfTrustCerts; indexOfTrustCert++) {
                SecCertificateRef thisCert = SecTrustGetCertificateAtIndex(trust, indexOfTrustCert);
                found = [systemCerts containsObject:(__bridge id _Nonnull)(thisCert)];
                if (found) {
                    break;
                }
            }
            if (found && _acceptSelfSignedCert) {
                SecCertificateRef newAnchor = SecTrustGetCertificateAtIndex(trust, indexOfTrustCert);
                SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)@[(__bridge id)newAnchor]);
                SecTrustSetAnchorCertificatesOnly(trust, YES);
                allowConnection = YES;
            } else if (!found) {
                newError = [NSError errorWithDomain:NSURLErrorDomain code:unimpErr userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Server root certificate is invalid", @""), NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Root certificate of server is not a valid one, hence connection cannot be established.", @""), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"This is a severe security error. Plase contact the server administrator and ask them to use a valid root certificate, or install their root certificate in your system (at your own risk).", @"")}];
            }
        }
            break;
        default:
            allowConnection = NO;
            break;
    }
    if (allowConnection) {
        disposition = NSURLSessionAuthChallengeUseCredential;
        credential = [NSURLCredential credentialForTrust:trust];
    } else if (newError) {
        [self performSelectorOnMainThread:@selector(setError:) withObject:newError waitUntilDone:NO];
    }
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

#pragma mark - NSErrorRecoveryAttempting
- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex {
    NSLog(@"Error recovery attempter got called!\nOptions index: %lu", recoveryOptionIndex);
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorServerCertificateUntrusted) {
        switch (recoveryOptionIndex) {
            case 2:
            {
                // user decided to trust the certificate…
                _acceptSelfSignedCert = YES;
                [self setFetching:YES];
                [self toggleFetch:nil];
                return YES;
            }
            break;
            case 1:
            {
                [[SFCertificatePanel sharedCertificatePanel] runModalForCertificates:[error.userInfo objectForKey:@"NSErrorPeerCertificateChainKey"] showGroup:YES];
                return NO;
            }
            break;
            default:
            {
                _acceptSelfSignedCert = NO;
                return NO;
            }
                break;
        }
    }

    return NO;
}
- (void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(void *)contextInfo {
    BOOL success = NO;
    NSError *err;
    NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:didRecoverSelector]];
    [invoke setSelector:didRecoverSelector];
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorServerCertificateUntrusted) {
        switch (recoveryOptionIndex) {
            case 2:
            {
                // user decided to trust the certificate…
                _acceptSelfSignedCert = YES;
                //[self stopFetching];
                [self setFetching:YES];
                [self toggleFetch:nil];
                success = self.error ? YES : NO;
                err = self.error;
            }
                break;
            case 1:
            {
                id certChain = [error.userInfo objectForKey:@"NSErrorPeerCertificateChainKey"];
                if (certChain) {
                    [invoke setArgument:&certChain atIndex:3];
                } else {
                    err = [NSError errorWithDomain:NSURLErrorDomain code:unimpErr userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Couldn't find certificate!", @"")}];
                }
                success = NO;
            }
                break;
            default:
            {
                _acceptSelfSignedCert = NO;
                err = error;
                success = NO;
            }
                
                break;
        }
    }
    if (err) {
        [invoke setArgument:&err atIndex:3];
    }
    [invoke invokeWithTarget:delegate];
}

@end
