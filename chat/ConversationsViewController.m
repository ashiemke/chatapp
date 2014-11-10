//
//  ConversationsViewController.m
//  chat
//
//  Created by Adam Shiemke on 11/5/14.
//  Copyright (c) 2014 Adam Shiemke. All rights reserved.
//

#import <Parse/Parse.h>
#import <BlocksKit+UIKit.h>
#import <SVProgressHUD.h>

#import "ConversationsViewController.h"

#import "Conversation.h"
#import "MessagesViewController.h"
#import "ConversationTableViewCell.h"
#import "Message.h"
#import "LoginViewController.h"

@interface ConversationsViewController ()

@property (nonatomic, strong) NSMutableArray *conversations;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation ConversationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addConversationPressed)];
    
    self.title = @"Conversations";
    
    if (![PFUser currentUser]){
        return;
    }
    
    // Add a pull-to-refresh thingy
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(loadConversations) forControlEvents:UIControlEventValueChanged];
    
}

- (void)viewDidAppear:(BOOL)animated{
    if (![PFUser currentUser]){
        LoginViewController *login = [LoginViewController new];
        [self presentViewController:login animated:NO completion:nil];
    }
    else {
        [self loadConversations];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) loadConversations {
    // Find all conversations involving the current user
    PFQuery *myConversationsQuery = [PFQuery queryWithClassName:@"Conversation"];

    [myConversationsQuery whereKey:@"participants" equalTo:[PFUser currentUser]];
    [myConversationsQuery includeKey:@"participants"];
    [myConversationsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error){
            [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
            return;
        }
        self.conversations = [[NSMutableArray alloc] initWithCapacity:[objects count]];
        for (id c in objects){
            [self.conversations addObject:[Conversation parseModelWithParseObject:c]];
        }
        
        [self.tableView reloadData];
        
        [self.refreshControl endRefreshing];
        
    }];
}

#pragma mark button handlers
- (void) addConversationPressed{
    UIAlertView *newConvAlert = [[UIAlertView alloc] initWithTitle:@"Converse With:" message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    
    newConvAlert.alertViewStyle=UIAlertViewStylePlainTextInput;
    [newConvAlert bk_setDidDismissBlock:^(UIAlertView * a, NSInteger i) {
        if (i == 0){
            return;
        }
        NSString *userToAdd = [a textFieldAtIndex:0].text;
        
        [SVProgressHUD showWithStatus:@"Finding User..." maskType:SVProgressHUDMaskTypeGradient];
        
        // Now we need to find that person
        PFQuery *q = [PFUser query];
        [q whereKey:@"username" equalTo:userToAdd];
        [q getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            
            PFUser* withUser = (PFUser*)object;
            
            if (!object){
                [SVProgressHUD showErrorWithStatus:@"User not found"];
                return;
            }
            else if (error){
                [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
                return;
            }
            
            // If no errors, begin a new conversation
            Conversation* convo = [Conversation new];
            // TODO: update to support multiple users
            convo.participants = @[[PFUser currentUser], withUser];
            [convo.parseObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error){
                    [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
                    return;
                }
                
                // Subscribe to that conversation
                PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                [currentInstallation addUniqueObject:convo forKey:@"conversations"];
                [currentInstallation saveInBackground];
                
                // Create and push the messages view controller
                MessagesViewController *msgsViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Messages"];
                msgsViewController.conversation = convo;
                [self.navigationController pushViewController:msgsViewController animated:YES];
                [SVProgressHUD dismiss];
            }];
        }];
    }];
    
    [newConvAlert show];
}


#pragma mark table view delegate/datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ConversationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    Conversation *convo = self.conversations[indexPath.row];
    
    NSMutableString *participants = [NSMutableString new];
    for (PFUser* participant in convo.participants){
        // Don't add the current user to the conversation line
        if (![[PFUser currentUser].username isEqualToString:participant.username]){
            [participants appendString:participant.username];
            [participants appendString:@", "];
        }
    }
    
    // remove the trailing comma-space
    cell.particpantsLbl.text = participants.length>3?[participants substringToIndex:participants.length-2]:participants;
    
    
    // TODO: add support for types other than text
    
    // Fill in the last message reieved in the conversation. First element in array is first message, last is most recent.
    PFQuery *getLastMsg = [PFQuery queryWithClassName:@"Message"];
    [getLastMsg whereKey:@"conversation" equalTo:convo.parseObject];
    [getLastMsg orderByDescending:@"createdAt"];
    [getLastMsg whereKey:@"contentType" equalTo:@(MessageContentTypeText)];
    [getLastMsg getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        cell.lastContentLbl.text = object[@"content"];
    }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    MessagesViewController *msgsViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Messages"];
    msgsViewController.conversation = [self.conversations objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:msgsViewController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete){
        Conversation* c = self.conversations[indexPath.row];
        // Remove the current user from the conversation (we don't want to delete it because that would remove it for everyone)
        // Direct comparison of PFUser doesn't work, so need to loop through to pull out the user with our username
        NSMutableArray *participants = [c.participants mutableCopy];
        for (PFUser *u in [participants copy]){
            if ([u.username isEqualToString:[PFUser currentUser].username]){
                [participants removeObject:u];
            }
        }
        c.participants = participants;
        [c.parseObject saveEventually];
        
        // remove user's subscription to the conversation:
        PFInstallation *installation = [PFInstallation currentInstallation];
        [installation removeObject:c forKey:@"conversations"];
        [installation saveInBackground];
        
        // TODO: some cleanup here to delete orphaned conversations (w/o participants) and messages (w/o conversations)
        
        [self.conversations removeObjectAtIndex:indexPath.row];
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }
}

@end
