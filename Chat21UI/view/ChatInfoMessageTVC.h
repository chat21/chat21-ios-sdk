//
//  ChatInfoMessageTVC.h
//  chat21
//
//  Created by Andrea Sponziello on 05/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChatMessage;

@interface ChatInfoMessageTVC : UITableViewController

@property (strong, nonatomic) ChatMessage *message;

@property (weak, nonatomic) IBOutlet UILabel *mtype;
@property (weak, nonatomic) IBOutlet UILabel *subtype;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UILabel *senderFullname;
@property (weak, nonatomic) IBOutlet UILabel *senderId;
@property (weak, nonatomic) IBOutlet UILabel *recipientFullname;
@property (weak, nonatomic) IBOutlet UILabel *recipientId;
@property (weak, nonatomic) IBOutlet UILabel *language;
@property (weak, nonatomic) IBOutlet UILabel *channel;
@property (weak, nonatomic) IBOutlet UILabel *messageId;
@property (weak, nonatomic) IBOutlet UILabel *attributes;


@end
