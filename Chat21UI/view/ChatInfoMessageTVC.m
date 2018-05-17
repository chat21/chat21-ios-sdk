//
//  ChatInfoMessageTVC.m
//  chat21
//
//  Created by Andrea Sponziello on 05/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatInfoMessageTVC.h"
#import "ChatMessage.h"
#import "ChatInfoMessageAttributesTVC.h"

@interface ChatInfoMessageTVC ()

@end

@implementation ChatInfoMessageTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Message info";
    
    self.mtype.text = self.message.mtype;
    
    if (self.message.subtype) {
        self.subtype.text = self.message.subtype;
    } else {
        self.subtype.text = @"-";
    }
    
    // date
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"dd MMM yyyy HH:mm"];
    NSString *date = [timeFormat stringFromDate:self.message.date];
    self.date.text = date;
    
    self.status.text = [@(self.message.status) stringValue];
    
    if (self.message.status == MSG_STATUS_FAILED) {
        self.status.text = [[NSString alloc] initWithFormat:@"(%d) %@", self.message.status, NSLocalizedString(@"Failed", nil) ];
    }
    else if (self.message.status == MSG_STATUS_SENDING) {
        self.status.text = [[NSString alloc] initWithFormat:@"(%d) %@", self.message.status, NSLocalizedString(@"Sending", nil) ];
    }
    else if (self.message.status == MSG_STATUS_QUEUED) {
        self.status.text = [[NSString alloc] initWithFormat:@"(%d) %@", self.message.status, NSLocalizedString(@"Queued", nil) ];
    }
    else if (self.message.status == MSG_STATUS_SENT) {
        self.status.text = [[NSString alloc] initWithFormat:@"(%d) %@", self.message.status, NSLocalizedString(@"Sent", nil) ];
    }
    else if (self.message.status == MSG_STATUS_RECEIVED) {
        self.status.text = [[NSString alloc] initWithFormat:@"(%d) %@", self.message.status, NSLocalizedString(@"Server received", nil) ];
    }
    else if (self.message.status == MSG_STATUS_RETURN_RECEIPT) {
        self.status.text = [[NSString alloc] initWithFormat:@"(%d) %@", self.message.status, NSLocalizedString(@"Recipient received", nil) ];
    }
    else if (self.message.status == MSG_STATUS_SEEN) {
        self.status.text = [[NSString alloc] initWithFormat:@"(%d) %@", self.message.status, NSLocalizedString(@"Recipient seen", nil) ];
    }
    
    self.senderFullname.text = self.message.senderFullname;
    self.senderId.text = self.message.sender;
    
    self.recipientFullname.text = self.message.recipientFullName;
    self.recipientId.text = self.message.recipient;
    
    self.language.text = self.message.lang;
    self.channel.text = self.message.channel_type;
    
    self.messageId.text = self.message.messageId;
    
    if (self.message.attributes && self.message.attributes.allKeys.count > 0) {
        self.attributes.text = [[NSString alloc] initWithFormat:@"%lu attributes", (unsigned long)self.message.attributes.allKeys.count];
    } else {
        self.attributes.text = @"-";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return 2;
//}

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    if (section == 0) {
//        return [self.message.snapshot.allKeys count];
//    } else {
//        return [self.message.attributes.allKeys count];
//    }
//}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"attributes"]) {
        ChatInfoMessageAttributesTVC *vc = (ChatInfoMessageAttributesTVC *)[segue destinationViewController];
        vc.attributes = self.message.attributes;
    }
}

@end
