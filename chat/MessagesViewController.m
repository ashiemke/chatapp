//
//  MessagesViewController.m
//  chat
//
//  Created by Adam Shiemke on 11/5/14.
//  Copyright (c) 2014 Adam Shiemke. All rights reserved.
//

#import "MessagesViewController.h"
#import <Parse/Parse.h>
#import <SVProgressHUD.h>
#import <JSQMessagesBubbleImageFactory.h>

#import "Conversation.h"
#import "Message.h"
#import "PFUser+AvatarImage.h"
#import "AppDelegate.h"

@interface MessagesViewController ()

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation MessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.senderId = [PFUser currentUser].username;
    self.senderDisplayName = [PFUser currentUser].username;
    
    // pull to refresh thing
    // Add a pull-to-refresh thingy
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.collectionView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(fetchMessages) forControlEvents:UIControlEventValueChanged];
    
    // Bubbles:
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubble = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    self.incomingBubble = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor blueColor]];
    
    // Register for notifications when conversations I'm in are updated:
    __weak typeof(self) wself = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kNewDataForConversationNotificationName object:self queue:nil usingBlock:^(NSNotification *note) {
        if (note.userInfo[@"conversationId"] && [note.userInfo[@"conversationId"] isEqualToString:wself.conversation.parseObject.objectId]){
            // refresh messages
            [wself fetchMessages];
        }
    }];
    
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    // remove notification subscription
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) fetchMessages{
    // Pull all messages for the passed in conversation
    [SVProgressHUD showWithStatus:@"Loading..." maskType:SVProgressHUDMaskTypeGradient];
    
    PFQuery* getMessages = [PFQuery queryWithClassName:@"Message"];
    [getMessages whereKey:@"conversation" equalTo:self.conversation.parseObject];
    [getMessages includeKey:@"fromUser"];
    [getMessages findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (error){
            [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
        }
        NSMutableArray *msgs = [NSMutableArray new];
        for (PFObject *obj in objects){
            [msgs addObject:[Message parseModelWithParseObject:obj]];
        }
        self.conversation.messages = msgs;
        [SVProgressHUD dismiss];
        [self finishReceivingMessage];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark JSQMesage collection view data source
- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.conversation.messages[indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    Message *message = [self.conversation.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        
        return self.outgoingBubble;
    }
    
    return self.incomingBubble;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath{
    Message *message = self.conversation.messages[indexPath.item];
    return (id<JSQMessageAvatarImageDataSource>)message.fromUser; // implmented protocol in category
}

-(void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date{
    
    Message *msg = [Message new];
    msg.content = text;
    msg.contentType = MessageContentTypeText;
    msg.conversation = self.conversation;
    msg.fromUser = [PFUser currentUser];
    
    // update conversation to reflect message
    [self.conversation.messages addObject:msg];
    
    [msg.parseObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded){
            [self finishSendingMessage];
            
            // Send out push to alert other users:
            PFQuery *pushQuery = [PFInstallation query];
            [pushQuery whereKey:@"conversations" equalTo:self.conversation];
            PFPush *push = [PFPush new];
            [push setQuery:pushQuery];
            // TODO: it'd be cooler here to send the message, but it's not trivial to sealize the parse object, so this'll do for now
            [push setData:@{@"alert":@"New message", @"badge":@"Increment", @"conversation":self.conversation.parseObject.objectId}];
            [push sendPushInBackground];
            
        }
        else {
            [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
        }
    }];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    switch (buttonIndex) {
        case 0:
            //TODO: show image picker w/ photos
            break;
            
        case 1:
        {
            // TODO: capture location
        }
            break;
            
        case 2:
            // show video
            break;
    }
    
    [self finishSendingMessage];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    // TODO: implement other (non-text) types of message
//    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages"
//                                                       delegate:self
//                                              cancelButtonTitle:@"Cancel"
//                                         destructiveButtonTitle:nil
//                                              otherButtonTitles:@"Send photo", @"Send location", @"Send video", nil];
//    
//    [sheet showFromToolbar:self.inputToolbar];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.conversation.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    Message *msg = [self.conversation.messages objectAtIndex:indexPath.item];
    
    if (msg.contentType == MessageContentTypeText) {
        
        if ([msg.fromUser.username isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
        cell.textView.text = msg.content;
    }
    // TODO: Handle display of other media types
    
    return cell;
}



#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath{
    // show timestamp
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.conversation.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        Message *previousMessage = [self.conversation.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    Message *currentMessage = [self.conversation.messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        Message *previousMessage = [self.conversation.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}



@end
