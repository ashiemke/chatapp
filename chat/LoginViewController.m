//
//  ViewController.m
//  chat
//
//  Created by Adam Shiemke on 11/5/14.
//  Copyright (c) 2014 Adam Shiemke. All rights reserved.
//

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "SVProgressHUD.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIButton *signupBtn;
@property (weak, nonatomic) IBOutlet UITextField *passwordTxtField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTxtField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTxtField;

// Some constraints for easy amination
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *confirmPasswordHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loginBtnHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *orLblHeightConstraint;



@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // On login button press, attempt to validate the user. If the user is valid, dismiss the login screen and show the messages screen.
    [_loginBtn bk_addEventHandler:^(id sender) {
        [SVProgressHUD showWithStatus:@"Logging in..." maskType:SVProgressHUDMaskTypeGradient];
        [PFUser logInWithUsernameInBackground:self.usernameTxtField.text password:self.passwordTxtField.text block:^(PFUser *user, NSError *error) {
            if (error){
                [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
            }
            else if (user){
                [self dismissViewControllerAnimated:YES completion:^{
                    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"Logged in as %@", user.username]];
                }];
            }
            else {
                [SVProgressHUD showErrorWithStatus:@"No user found"];
            }
        }];
    } forControlEvents:UIControlEventTouchUpInside];
    
    // On signup button press, unhide the confirm password field and hide the other text.
    [_signupBtn bk_addEventHandler:^(id sender) {
        // Hide the login button
        if (!self.loginBtn.hidden){
            [UIView animateWithDuration:0.5 animations:^{
                self.confirmPasswordHeightConstraint.constant = 30;
                self.loginBtnHeightConstraint.constant = 0;
                self.orLblHeightConstraint.constant = 0;
                self.loginBtn.hidden = YES;
                [self.view layoutIfNeeded];
            }];
        }
        else {
            // Presenting issues one at a time to the user isn't optimal UX; given more time, I'd do inline validation on the text fields
            if (![self.passwordTxtField.text isEqualToString:self.confirmPasswordTxtField.text]){
                [SVProgressHUD showErrorWithStatus:@"Passwords do not match"];
            }
            else if (self.usernameTxtField.text.length < 3 ){
                [SVProgressHUD showErrorWithStatus:@"Username should be at least 4 characters"];
            }
            else if (self.passwordTxtField.text.length < 3){
                [SVProgressHUD showErrorWithStatus:@"Password should be at least 4 characters"];
            }
            else{ // If we hit this, the username and password are probably OK
                PFUser *newUser = [PFUser user];
                newUser.username = self.usernameTxtField.text;
                newUser.password = self.passwordTxtField.text;
                [SVProgressHUD showWithStatus:@"Creating User..." maskType:SVProgressHUDMaskTypeGradient];
                [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [PFUser becomeInBackground:newUser.sessionToken block:^(PFUser *user, NSError *error) {
                        [self dismissViewControllerAnimated:YES completion:^{ // Return control to messages view controller
                            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"Logged in as %@", newUser.username]];
                        }];
                    }];
                }];
            }
        }
    } forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
