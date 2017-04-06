//
//  AppDelegate.m
//  RanchForecast
//
//  Created by Valeriano Della Longa on 3/30/17.
//  Copyright © 2017 Valeriano Della Longa. All rights reserved.
//

#import "AppDelegate.h"
#import "ActiveCourse.h"
#import "BNRCoursesFetcher.h"
#import <SecurityInterface/SFCertificatePanel.h>

@interface AppDelegate () 

@property (weak) IBOutlet NSWindow *window;
@property (strong) IBOutlet BNRCoursesFetcher *courseFetcher;

@end

@implementation AppDelegate

#pragma NSAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_courseFetcher addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionOld context:NULL];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [_courseFetcher removeObserver:self forKeyPath:@"error"];
}

#pragma mark - Actions
- (IBAction)openInBrowser:(id)sender {
    if ([sender isKindOfClass:[NSTableView class]] && [sender dataSource] != nil) {
        id ds = [sender dataSource];
        id theSelectionObj = nil;
        if ([ds respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)]) {
            theSelectionObj = [ds tableView:sender objectValueForTableColumn:nil row:[sender selectedRow]];
        } else if ([ds respondsToSelector:@selector(selection)]) {
            theSelectionObj = [ds selection];
        }
        if (theSelectionObj) {
            id theUrl = [theSelectionObj valueForKey:@"url"];
            if ([theUrl isKindOfClass:[NSURL class]]) {
                [[NSWorkspace sharedWorkspace] openURL:theUrl];
            } 
        }
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isEqual:_courseFetcher] && [keyPath isEqualToString:@"error"]) {
        if (_courseFetcher.error) {
            //[[NSApplication sharedApplication] presentError:_courseFetcher.error];
            [[NSApplication sharedApplication] presentError:_courseFetcher.error modalForWindow:self.window delegate:self didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:NULL];
        }
    }
}

#pragma mark - Error handiling and presentation
- (NSError *)application:(NSApplication *)application willPresentError:(NSError *)error {
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorServerCertificateUntrusted) {
        NSMutableDictionary *newUserInfo = [[NSMutableDictionary dictionaryWithDictionary:error.userInfo] mutableCopy];
        [newUserInfo setObject:@[NSLocalizedString(@"Cancel", @""), NSLocalizedString(@"View certificate details", @""), NSLocalizedString(@"Trust certificate", @"")] forKey:NSLocalizedRecoveryOptionsErrorKey];
        [newUserInfo setObject:_courseFetcher forKey:NSRecoveryAttempterErrorKey];
        NSError *recoverableError = [NSError errorWithDomain:error.domain code:error.code userInfo:newUserInfo];
        return recoverableError;
    }
    return error;
}

- (void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo {
    id info = (__bridge id)(contextInfo);
    if (didRecover) {
        NSLog(@"Successfully recovered!\ncontextInfo: %@", info);
    } else {
        if ([info isKindOfClass:[NSError class]]) {
            [NSAlert alertWithError:info];
        } else if ([info isKindOfClass:[NSArray class]]) {
            NSError *err;
            @try {
                [[SFCertificatePanel sharedCertificatePanel] runModalForCertificates:info showGroup:YES];
            } @catch (NSException *exception) {
                err = [NSError errorWithDomain:NSURLErrorDomain code:unimpErr userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(exception.name, @""), NSLocalizedFailureReasonErrorKey: NSLocalizedString(exception.reason, @"")}];
            } @finally {
                if (err) {
                    [NSAlert alertWithError:err];
                }
            }
        }
    }
}

@end
