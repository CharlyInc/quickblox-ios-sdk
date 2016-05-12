//
//  SignUpTableViewController.m
//  sample-users
//
//  Created by Quickblox Team on 8/27/15.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "SignUpTableViewController.h"
#import <Quickblox/Quickblox.h>
#import <SVProgressHUD.h>

@interface QBRequest(debug)
- (NSString *)debugDescription;
@end
@implementation QBRequest(debug)
- (NSString *)debugDescription
{
	NSString *s = [super debugDescription];
	return [s stringByAppendingFormat:@"%@ cancelled, headers: %@, parameters: %@", self.canceled ? @"Not " : @"", self.headers, self.parameters];
}
@end


@interface SignUpTableViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *loginTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UITextField *confirmationTextField;

@end

@implementation SignUpTableViewController

- (BOOL)isPasswordConfirmed
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
    BOOL confirmed;
    if (self.passwordTextField.text == nil || self.passwordTextField.text.length == 0) {
        confirmed = NO;
    } else if (self.confirmationTextField.text == nil || self.confirmationTextField.text.length == 0) {
        confirmed = NO;
    } else {
        confirmed = [self.passwordTextField.text isEqualToString:self.confirmationTextField.text];
    }
    
    self.passwordTextField.backgroundColor = confirmed ? [UIColor whiteColor] : [UIColor redColor];
    self.confirmationTextField.backgroundColor = confirmed ? [UIColor whiteColor] : [UIColor redColor];
    
    return confirmed;
}

- (BOOL)isLoginTextValid
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
    BOOL loginValid = (self.loginTextField.text != nil && self.loginTextField.text.length > 0);
    self.loginTextField.backgroundColor = loginValid ? [UIColor whiteColor] : [UIColor redColor];
    return loginValid;
}

- (IBAction)nextButtonClicked:(id)sender
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.view endEditing:YES];
    
    BOOL confirmed = [self isPasswordConfirmed];
    BOOL nonEmptyLogin = [self isLoginTextValid];

    if (confirmed && nonEmptyLogin) {
        [SVProgressHUD showWithStatus:@"Signing up"];

		NSLog(@"QBUUser");
        QBUUser *user = [QBUUser new];
        user.login = self.loginTextField.text;
        user.password = self.passwordTextField.text;
        
        NSString* password = user.password;

        __weak typeof(self)weakSelf = self;
		QBRequest *r;
		NSLog(@"QBRequest signUp");
        r = [QBRequest signUp:user successBlock:^(QBResponse *response, QBUUser *user) {
			NSLog(@"%s", __PRETTY_FUNCTION__);
			NSLog(@"Created user to log in: %@", response.error.error);
			NSLog(@"======== request is %@", r.debugDescription);
			NSLog(@"QBRequest logInWithUserLogin");
            [QBRequest logInWithUserLogin:user.login password:password successBlock:^(QBResponse *response, QBUUser *user) {
				NSLog(@"%s", __PRETTY_FUNCTION__);
                [SVProgressHUD dismiss];
                
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            } errorBlock:^(QBResponse *response) {
				NSLog(@"%s", __PRETTY_FUNCTION__);
                [SVProgressHUD dismiss];
                
                NSLog(@"Errors=%@", [response.error description]);
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:[response.error  description]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }];
            
        } errorBlock:^(QBResponse *response) {
			NSLog(@"%s", __PRETTY_FUNCTION__);
            [SVProgressHUD dismiss];
			NSLog(@"Unable to create user to log in: %@", response.error.error);
			NSLog(@"======== request is %@", r.debugDescription);

            NSLog(@"Errors=%@", [response.error description]);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[response.error  description]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }];
    }
}

- (IBAction)cancelButtonClicked:(id)sender
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
    textField.backgroundColor = [UIColor whiteColor];
}

@end
