//
//  HRPGMessageViewController.m
//  Habitica
//
//  Created by Phillip Thelen on 24/05/14.
//  Copyright © 2017 HabitRPG Inc. All rights reserved.
//

#import "HRPGMessageViewController.h"
#import "Amplitude.h"
#import "HRPGAppDelegate.h"
#import "HRPGManager.h"

@interface HRPGMessageViewController ()
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *bottomOffsetConstraint;

@end

@implementation HRPGMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.managedObjectContext = [HRPGManager sharedManager].getManagedObjectContext;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChanged:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChanged:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    [eventProperties setValue:@"navigate" forKey:@"eventAction"];
    [eventProperties setValue:@"navigation" forKey:@"eventCategory"];
    [eventProperties setValue:@"pageview" forKey:@"hitType"];
    [eventProperties setValue:NSStringFromClass([self class]) forKey:@"page"];
    [[Amplitude instance] logEvent:@"navigate" withEventProperties:eventProperties];

    [self keyboardChanged:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.presetText) {
        self.messageView.text = self.presetText;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.messageView becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidDisappear:YES];
}

- (void)keyboardChanged:(NSNotification *)notification {
    CGSize keyboardSize =
        [self.view convertRect:[[notification userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue]
                        toView:nil]
            .size;
    self.bottomOffsetConstraint.constant = keyboardSize.height;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem.enabled = ([textView.text length] > 0);
}

@end
