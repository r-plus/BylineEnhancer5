#import <AASpringRefresh.h>
#import <ColorLog.h>

#define PREF_PATH @"/var/mobile/Library/Preferences/jp.r-plus.bylineenhancer.plist"

static BOOL markAllAsReading = NO;
static void (^block)(UIAlertAction *action) = nil;

// interfaces {{{
@interface BLItemViewController : UIViewController
@property(retain, nonatomic) UIWebView *webView;
- (void)forwardAction:(id)arg1;
@end
@interface BLListViewController : UIViewController
@property(retain, nonatomic) UITableView *searchTableView;
@property(retain, nonatomic) BLItemViewController *itemViewController;
- (void)markAllAsReadAction:(id)arg1;
- (UITableView *)tableView;
@end
@interface BLHomeViewController : UITableViewController <UIApplicationDelegate>
@property(retain, nonatomic) BLListViewController *listViewController;
@end
@interface BLAppDelegate
@property(retain, nonatomic) BLHomeViewController *homeViewController;
@end
// }}}
// PullAction {{{
static void DoPullToAction(int actionNumber)
{
    BLAppDelegate *delegate = (BLAppDelegate *)[[UIApplication sharedApplication] delegate];
    switch (actionNumber) {
        case 0:
            // markAllAsRead then pop.
            {
                // TODO: silently mark all as read.
/*                for (BLNewsItem *item in UIApplication.sharedApplication.delegate.homeViewController.listViewController.newsList.items) {*/
/*                }*/
                markAllAsReading = YES;
                [delegate.homeViewController.listViewController markAllAsReadAction:nil]; 
            }
            break;
        case 1:
            // pop
            [delegate.homeViewController.listViewController.navigationController popViewControllerAnimated:YES];
            break;
        case 2:
            // pop to root
            [delegate.homeViewController.listViewController.navigationController popToRootViewControllerAnimated:YES];
            break;
        case 3:
            // forward
            [delegate.homeViewController.listViewController.itemViewController forwardAction:nil]; 
            break;
        default:
            break;
    }
}
// }}}
// {{{ hook for dont show UIAlertController for MarkAllasRead.
%hook UIAlertAction
+ (id)actionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction *action))handler
{
    CMLog(@"actionWithTitle = '%@'", title);
     if ([title isEqualToString:@"すべて既読にする"]) {
        block = handler;
    }
    return %orig;
}
%end
%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    CMLog(@"presentViewController");
    if (block && markAllAsReading && [viewControllerToPresent isKindOfClass:[UIAlertController class]]) {
        markAllAsReading = NO;
        block(nil);
        block = nil;
        // skip present UIAlertController.
        return;
    }
    %orig;
}
%end
// }}}
// folder hook {{{
%hook BLListViewController
- (void)viewDidLoad
{
    %orig;
    UITableView *tableView = [self tableView];
    AASpringRefresh *springRefresh = [tableView addSpringRefreshPosition:AASpringRefreshPositionBottom actionHandler:^(AASpringRefresh *v) {
        DoPullToAction(0);// markallasread
    }];
/*    springRefresh.affordanceMargin = 20.0;*/
    springRefresh.threshold = 60.0;
    springRefresh.text = @"MarkAllasRead";
}
%end
// }}}
// item hook {{{
%hook BLItemViewController
- (void)viewDidLayoutSubviews
{
    %orig;

    AASpringRefresh *top = [self.webView.scrollView addSpringRefreshPosition:AASpringRefreshPositionTop actionHandler:^(AASpringRefresh *) {
        DoPullToAction(1); // pop
    }];
    top.text = @"Back";

    AASpringRefresh *bottom = [self.webView.scrollView addSpringRefreshPosition:AASpringRefreshPositionBottom actionHandler:^(AASpringRefresh *v) {
        DoPullToAction(3); // forward
    }];
    bottom.text = @"Go to Web";
}
%end
// }}}
// {{{ LoadSettings
static void LoadSettings()
{   
/*    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];*/
/*    id existListPullViewBottomIsEnabled = [dict objectForKey:@"ListPullViewBottomIsEnabled"];*/
/*    listPullViewBottomIsEnabled = existListPullViewBottomIsEnabled ? [existListPullViewBottomIsEnabled boolValue] : YES;*/
/*    id existListPullViewBottomThreshold = [dict objectForKey:@"ListPullViewBottomThreshold"];*/
/*    listPullViewBottomThreshold = existListPullViewBottomThreshold ? [existListPullViewBottomThreshold floatValue] : 100.0f;*/
/*    id existListPullViewBottomAction = [dict objectForKey:@"ListPullViewBottomAction"];*/
/*    listPullViewBottomAction = existListPullViewBottomAction ? [existListPullViewBottomAction intValue] : 1; // markAllAsRead*/

/*    hidePullView();*/
/*    updateThreadhold();*/
}

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    LoadSettings();
}
// }}}
// {{{ Constructor
%ctor {
    @autoreleasepool {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, CFSTR("jp.r-plus.BylineEnhancer5.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        LoadSettings();
    }
}
// }}}
