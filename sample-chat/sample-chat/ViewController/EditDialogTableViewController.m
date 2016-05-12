//
//  EditDialogTableViewController.m
//  sample-chat
//
//  Created by Anton Sokolchenko on 6/8/15.
//  Copyright (c) 2015 Igor Khomenko. All rights reserved.
//

#import "EditDialogTableViewController.h"
#import "UsersDataSource.h"
#import "ServicesManager.h"
#import "UserTableViewCell.h"
#import "ChatViewController.h"
#import "DialogsViewController.h"

@interface EditDialogTableViewController() <QMChatServiceDelegate, QMChatConnectionDelegate>
@property (nonatomic, strong) UsersDataSource *dataSource;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *btnSave;
@end

@implementation EditDialogTableViewController

#pragma mark - View Lyfecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView new];
    NSParameterAssert(self.channel);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadDataSource];
    [ServicesManager.instance.chatService addDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ServicesManager.instance.chatService removeDelegate:self];
}

#pragma mark - UITableView Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateSaveButtonState];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateSaveButtonState];
}

#pragma mark - IBActions
- (IBAction)saveButtonTapped:(id)sender {
    NSArray *indexPathArray = [self.tableView indexPathsForSelectedRows];
    assert(indexPathArray.count != 0);
    
    NSMutableArray *users = [NSMutableArray arrayWithCapacity:indexPathArray.count];
    NSMutableArray *usersIDs = [NSMutableArray arrayWithCapacity:indexPathArray.count];
    
    for (NSIndexPath *indexPath in indexPathArray) {
        UserTableViewCell *selectedCell = (UserTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
        [users addObject:selectedCell.user];
        [usersIDs addObject:@(selectedCell.user.ID)];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    __weak __typeof(self)weakSelf = self;
    
    if (self.channel.type == QBChatDialogTypePrivate) {
        // Retrieving users with identifiers.
        [[[ServicesManager instance].usersService getUsersWithIDs:self.channel.occupantIDs] continueWithBlock:^id(BFTask *task) {
            //
            __typeof(self) strongSelf = weakSelf;
            [users addObjectsFromArray:task.result];
            
            [strongSelf createGroupDialogWithUsers:users];
            
            return nil;
        }];
    } else {
        [self updateGroupDialogWithUsersIDs:usersIDs];
    }
}

#pragma mark QMChatServiceDelegate delegate

- (void)chatService:(QMChatService *)chatService didUpdateChatDialogInMemoryStorage:(QBChatDialog *)chatDialog {
    if ([chatDialog.ID isEqualToString:self.channel.ID]) {
        self.channel = chatDialog;
        [self reloadDataSource];
    }
}

#pragma mark - Helpers

- (void)reloadDataSource {
    self.dataSource = [[UsersDataSource alloc] init];
    [self.dataSource setExcludeUsersIDs:self.channel.occupantIDs];
    self.tableView.dataSource = self.dataSource;
    [self.tableView reloadData];
    [self updateSaveButtonState];
}
- (void)createGroupDialogWithUsers:(NSArray *)users {
    __weak __typeof(self)weakSelf = self;
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"SA_STR_LOADING", nil) maskType:SVProgressHUDMaskTypeClear];
    
    // Creating group chat dialog.
    [ServicesManager.instance.chatService createGroupChatDialogWithName:[self dialogNameFromUsers:users] photo:nil occupants:users completion:^(QBResponse *response, QBChatDialog *createdDialog) {
        
        if( response.success ) {
            [SVProgressHUD dismiss];
            [[ServicesManager instance].chatService sendSystemMessageAboutAddingToDialog:createdDialog toUsersIDs:createdDialog.occupantIDs completion:^(NSError *error) {
                //
            }];
            __typeof(self) strongSelf = weakSelf;
            [strongSelf navigateToChatViewControllerWithDialog:createdDialog];
        }
        else {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"SA_STR_CANNOT_CREATE_DIALOG", nil)];
            NSLog(@"can not create dialog: %@", response.error.error);
        }
    }];
}

- (void)updateGroupDialogWithUsersIDs:(NSArray *)usersIDs {
    __weak __typeof(self)weakSelf = self;
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"SA_STR_LOADING", nil) maskType:SVProgressHUDMaskTypeClear];
    
    // Retrieving users from cache.
    [[[ServicesManager instance].usersService getUsersWithIDs:usersIDs] continueWithBlock:^id(BFTask *task) {
        //
        // Updating dialog with occupants.
        [ServicesManager.instance.chatService joinOccupantsWithIDs:usersIDs toChatDialog:self.channel completion:^(QBResponse *response, QBChatDialog *updatedDialog) {
            if( response.success ) {
                
                // Notifying users about newly created dialog.
                [[ServicesManager instance].chatService sendSystemMessageAboutAddingToDialog:updatedDialog toUsersIDs:usersIDs completion:^(NSError *error) {
                    //
                    NSString *notificationText = [weakSelf updatedMessageWithUsers:task.result];
                    
                    // Notify occupants that dialog was updated.
                    [[ServicesManager instance].chatService sendNotificationMessageAboutAddingOccupants:usersIDs
                                                                                               toDialog:updatedDialog
                                                                                   withNotificationText:notificationText
                                                                                             completion:nil];
                    updatedDialog.lastMessageText = notificationText;
                    __typeof(self) strongSelf = weakSelf;
                    [strongSelf navigateToChatViewControllerWithDialog:updatedDialog];
                    [SVProgressHUD dismiss];
                }];
            }
            else {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"SA_STR_ERROR", nil)];
            }
        }];
        
        return nil;
    }];
}

- (NSString *)dialogNameFromUsers:(NSArray *)users {
    NSString *name = [NSString stringWithFormat:@"%@_", [QBSession currentSession].currentUser.login];
    for (QBUUser *user in users) {
        name = [NSString stringWithFormat:@"%@%@,", name, user.login];
    }
    name = [name substringToIndex:name.length - 1]; // remove last , (comma)
    return name;
}

- (NSString *)updatedMessageWithUsers:(NSArray *)users {
    NSString *message = [NSString stringWithFormat:@"%@ %@ ", [ServicesManager instance].currentUser.login, NSLocalizedString(@"SA_STR_ADDED", nil)];
    for (QBUUser *user in users) {
        message = [NSString stringWithFormat:@"%@%@,", message, user.login];
    }
    message = [message substringToIndex:message.length - 1]; // remove last , (comma)
    return message;
}

- (void)updateSaveButtonState {
    self.btnSave.enabled = [[self.tableView indexPathsForSelectedRows] count] != 0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kGoToChatSegueIdentifier]) {
        ChatViewController *vc = (ChatViewController *) segue.destinationViewController;
        vc.channel = sender;
    }
}

- (void)navigateToChatViewControllerWithDialog:(QBChatDialog *)dialog {
    
    NSMutableArray *newStack = [NSMutableArray array];

    //change stack by replacing view controllers after ChatVC with ChatVC
    for (UIViewController * vc in self.navigationController.viewControllers) {
        [newStack addObject:vc];
        
        if ([vc isKindOfClass:[DialogsViewController class]]) {
            
            ChatViewController * chatVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ChatViewController"];
            chatVC.channel = dialog;
            
            [newStack addObject:chatVC];
            [self.navigationController setViewControllers:newStack animated:true];
            
            return;
        }
    }
    
    [self performSegueWithIdentifier:kGoToChatSegueIdentifier sender:dialog];
}
@end
