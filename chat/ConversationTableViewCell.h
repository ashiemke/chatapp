//
//  ConversationTableViewCell.h
//  chat
//
//  Created by Adam Shiemke on 11/5/14.
//  Copyright (c) 2014 Adam Shiemke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConversationTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *particpantsLbl;
@property (weak, nonatomic) IBOutlet UILabel *lastContentLbl;


@end
