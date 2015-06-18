//
//  XCZWorkDetailViewController.m
//  xcz
//
//  Created by 刘志鹏 on 14-6-30.
//  Copyright (c) 2014年 Zhipeng Liu. All rights reserved.
//

#import "XCZWorkDetailViewController.h"
#import "XCZUtils.h"
#import "XCZQuote.h"
#import "IonIcons.h"
#import "XCZLike.h"
#import "XCZAuthorDetailsViewController.h"
#include<AssetsLibrary/AssetsLibrary.h>

typedef void (^SaveImageCompletion)(NSError *error);

@interface XCZWorkDetailViewController ()<UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *authorTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *contentNoIntroView;
@property (weak, nonatomic) IBOutlet UILabel *titleField;
@property (weak, nonatomic) IBOutlet UILabel *authorField;
@property (weak, nonatomic) IBOutlet UILabel *contentField;
@property (weak, nonatomic) IBOutlet UILabel *introField;

@end

@implementation XCZWorkDetailViewController

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.showAuthorButton = YES;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 初始化navbar按钮
    bool showLike = ![XCZLike checkExist:self.work.id];
    [self initNavbarShowAuthor:self.showAuthorButton showLike:showLike];
    
    self.title = self.work.title;

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleBars:)];
    [self.view addGestureRecognizer:singleTap];
}

// 设置navbar的按钮显示
- (void) initNavbarShowAuthor:(bool)showAuthor showLike:(bool)showLike
{
    NSMutableArray *btnArrays = [[NSMutableArray alloc] initWithObjects:nil];
    
    // 是否显示作者按钮
    if (showAuthor) {
        UIBarButtonItem * authorButton = [self createAuthorButton];
        [btnArrays addObject:authorButton];
    }
    
    // 显示收藏/取消收藏按钮
    if (showLike) {
        UIBarButtonItem * likeButton = [self createLikeButton];
        [btnArrays addObject:likeButton];
    } else {
        UIBarButtonItem * unlikeButton = [self createUnlikeButton];
        [btnArrays addObject:unlikeButton];
    }
    
    UIBarButtonItem *shareBtn = [self createShareButton];
    [btnArrays addObject:shareBtn];
    
    self.navigationItem.rightBarButtonItems = btnArrays;
}

//设置背景
-(void)setBackGroundImage
{
    UIImage *img = [UIImage imageNamed:@"bg"];
    self.view.layer.contents = (id)img.CGImage;
    
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height)];
    [iv setImage:[img stretchableImageWithLeftCapWidth:img.size.width/2 topCapHeight:img.size.height/2]];
    [self.contentView insertSubview:iv atIndex:0];
}

// 创建AuthorButton
- (UIBarButtonItem *)createAuthorButton
{
    UIImage *authorIcon = [IonIcons imageWithIcon:ion_person
                                        iconColor:self.view.tintColor
                                         iconSize:31.0f
                                        imageSize:CGSizeMake(31.0f, 31.0f)];
    return [[UIBarButtonItem alloc] initWithImage:authorIcon style:UIBarButtonItemStylePlain target:self action:@selector(redirectToAuthor:)];
}

// 创建LikeButton
- (UIBarButtonItem *)createLikeButton
{
    UIImage *likeIcon = [IonIcons imageWithIcon:ion_ios_star_outline
                                      iconColor:self.view.tintColor
                                       iconSize:27.0f
                                      imageSize:CGSizeMake(27.0f, 27.0f)];
    return [[UIBarButtonItem alloc] initWithImage:likeIcon style:UIBarButtonItemStylePlain target:self action:@selector(likeWork:)];
}

// 创建UnlikeButton
- (UIBarButtonItem *)createUnlikeButton
{
    UIImage *unlikeIcon = [IonIcons imageWithIcon:ion_ios_star
                                        iconColor:[UIColor colorWithRed:137.0/255.0 green:24.0/255.0 blue:27.0/255.0 alpha:1.0]
                                         iconSize:27.0f
                                        imageSize:CGSizeMake(27.0f, 27.0f)];
    return [[UIBarButtonItem alloc] initWithImage:unlikeIcon style:UIBarButtonItemStylePlain target:self action:@selector(unlikeWork:)];
}

// 创建ShareButton
- (UIBarButtonItem *)createShareButton
{
    UIImage *shareIcon = [IonIcons imageWithIcon:ion_image
                                        iconColor:self.view.tintColor
                                         iconSize:27.0f
                                        imageSize:CGSizeMake(27.0f, 27.0f)];
    return [[UIBarButtonItem alloc] initWithImage:shareIcon style:UIBarButtonItemStylePlain target:self action:@selector(shareImage:)];
}

// 进入/退出全屏模式
- (void)toggleBars:(UITapGestureRecognizer *)gesture
{
    // Toggle statusbar
    [[UIApplication sharedApplication] setStatusBarHidden:![[UIApplication sharedApplication] isStatusBarHidden] withAnimation:UIStatusBarAnimationSlide];
    
    // Toggle navigationbar
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBar.hidden animated:YES];
    
    // Toggle tabbar
    [self.view layoutIfNeeded];
    
    BOOL tabBarHidden = self.tabBarController.tabBar.hidden;

    // 全屏模式下，扩大title的顶部间距
    if (tabBarHidden) {
        self.titleTopConstraint.constant = 10;
    } else {
        self.titleTopConstraint.constant = 30;
    }
    
    [UIView animateWithDuration:0.4
                     animations:^{
                         [self.view layoutIfNeeded]; // Called on parent view
                     }];
    
    [self.tabBarController.tabBar setHidden:!tabBarHidden];
}

// 移除NSNotification Observer
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 发起本地通知
    /*
    NSCalendar *calendar = [NSCalendar currentCalendar]; // gets default calendar
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]]; // gets the year, month, day,hour and minutesfor today's date
    [components setHour:12];
    [components setMinute:48];

    XCZQuote *quote = [XCZQuote getRandomQuote];
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    
    //localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:10];
    localNotification.fireDate = [calendar dateFromComponents:components];
    
    [localNotification setRepeatInterval: NSMinuteCalendarUnit];
    
    localNotification.alertBody = [[NSString alloc] initWithFormat:@"每日一句：%@—《%@》", quote.quote, quote.work];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:quote.workId] forKey:@"workId"];
    localNotification.userInfo = infoDict;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    */
     
//    [AVAnalytics beginLogPageView:[[NSString alloc] initWithFormat:@"work-%@/%@", self.work.author, self.work.title]];
    
    XCZWork *work = self.work;
    
    // 标题
    NSMutableParagraphStyle *titleParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    titleParagraphStyle.lineHeightMultiple = 1.2;
    titleParagraphStyle.alignment = NSTextAlignmentCenter;
    self.titleField.attributedText = [[NSAttributedString alloc] initWithString:work.title attributes:@{NSParagraphStyleAttributeName: titleParagraphStyle}];
    
    // 作者
    self.authorField.text = [[NSString alloc] initWithFormat:@"[%@] %@", work.dynasty, work.author];
    
    // 内容
    NSMutableParagraphStyle *contentParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    // 缩进排版
    if ([self.work.layout isEqual: @"indent"]) {
        contentParagraphStyle.firstLineHeadIndent = 25;
        contentParagraphStyle.paragraphSpacing = 20;
        contentParagraphStyle.lineHeightMultiple = 1.35;
        self.contentField.preferredMaxLayoutWidth = [XCZUtils currentWindowWidth] - 30;
    // 居中排版
    } else {
        contentParagraphStyle.alignment = NSTextAlignmentCenter;
        contentParagraphStyle.paragraphSpacing = 0;
        contentParagraphStyle.lineHeightMultiple = 1;
        self.authorTopConstraint.constant = 16;
        self.contentField.preferredMaxLayoutWidth = [XCZUtils currentWindowWidth] - 20;
    }
    contentParagraphStyle.paragraphSpacing = 10;
    self.contentField.attributedText = [[NSAttributedString alloc] initWithString:work.content attributes:@{NSParagraphStyleAttributeName: contentParagraphStyle}];
    
    // 评析
    NSMutableParagraphStyle *introParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    introParagraphStyle.lineHeightMultiple = 1.3;
    introParagraphStyle.paragraphSpacing = 8;
    self.introField.attributedText = [[NSAttributedString alloc] initWithString:work.intro attributes:@{NSParagraphStyleAttributeName: introParagraphStyle}];
    
    // 设置UILabel的preferredMaxLayoutWidth，以保证正确的换行长度
    self.titleField.preferredMaxLayoutWidth = [XCZUtils currentWindowWidth] - 50;
    self.introField.preferredMaxLayoutWidth = [XCZUtils currentWindowWidth] - 30;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
//    [AVAnalytics endLogPageView:[[NSString alloc] initWithFormat:@"work-%@/%@", self.work.author, self.work.title]];
}

- (IBAction)redirectToAuthor:(id)sender
{
//    [self.navigationItem setTitle:@"返回"];
    
    XCZAuthorDetailsViewController *authorDetailController = [[XCZAuthorDetailsViewController alloc] initWithAuthorId:self.work.authorId];
    [self.navigationController pushViewController:authorDetailController animated:YES];
}

- (IBAction)likeWork:(id)sender
{
    bool result = [XCZLike like:self.work.id];
    
    if (result) {
        [self initNavbarShowAuthor:self.showAuthorButton showLike:false];
    }
    
    // 发送数据重载通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadLikesData" object:nil userInfo:nil];
}

- (IBAction)unlikeWork:(id)sender
{
    bool result = [XCZLike unlike:self.work.id];
    
    if (result) {
        [self initNavbarShowAuthor:self.showAuthorButton showLike:true];
    }
    
    // 发送数据重载通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadLikesData" object:nil userInfo:nil];
}

-(IBAction)shareImage:(id)sender
{
    [self likeWork:nil];
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"选择截图内容"
                                                 message:nil
                                                delegate:self
                                       cancelButtonTitle:@"全部"
                                       otherButtonTitles:@"No评析", nil];
    av.tag = 1;
    [av show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//share
#pragma mark - Private method
- (UIImage *)snapshot:(UIView *)view
{
    CGRect rt = [[UIScreen mainScreen] bounds];
    rt.size.height = view.frame.size.height;
    rt.origin = view.frame.origin;
    UIGraphicsBeginImageContextWithOptions(rt.size, NO, 0.0);
    [view drawViewHierarchyInRect:rt afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo
{
    NSString *msg = nil ;
    if(error != NULL){
        msg = @"保存图片失败" ;
    }else{
        msg = @"保存图片成功" ;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"保存图片结果提示"
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil];
    alert.tag = 0;
    [alert show];
}

-(void)addAssetURL:(NSURL*)assetURL toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock
{
    //相册存在标示
    __block BOOL albumWasFound = NO;
    
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    //search all photo albums in the library
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop)
     {
         
         //判断相册是否存在
         if ([albumName compare: [group valueForProperty:ALAssetsGroupPropertyName]]==NSOrderedSame) {
             
             //存在
             albumWasFound = YES;
             
             //get a hold of the photo's asset instance
             [assetsLibrary assetForURL: assetURL
                            resultBlock:^(ALAsset *asset) {
                                
                                //add photo to the target album
                                [group addAsset: asset];
                                
                                //run the completion block
                                completionBlock(nil);
                                
                            } failureBlock: completionBlock];
             return;
         }
         
         //如果不存在该相册创建
         if (group==nil && albumWasFound==NO)
         {
             __weak ALAssetsLibrary* weakSelf = assetsLibrary;
             
             //创建相册
             [assetsLibrary addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group)
              {
                  
                  //get the photo's instance
                  [weakSelf assetForURL: assetURL
                            resultBlock:^(ALAsset *asset)
                   {
                       
                       //add photo to the newly created album
                       [group addAsset: asset];
                       
                       //call the completion block
                       completionBlock(nil);
                       
                   } failureBlock: completionBlock];
                  
              } failureBlock: completionBlock];
             return;
         }
         
     }failureBlock:completionBlock];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag != 1)
    {
        return;
    }
    UIImage *image = nil;
    if (buttonIndex == 0)
    {
        image = [self snapshot:self.contentView];
    }
    else
    {
        image = [self snapshot:self.contentNoIntroView];
    }
    
    
    
    __weak XCZWorkDetailViewController *weak_self = self;
    ALAssetsLibrary *lib = [ALAssetsLibrary new];
    [lib writeImageToSavedPhotosAlbum:image.CGImage
                          orientation:(ALAssetOrientation)image.imageOrientation
                      completionBlock:^(NSURL *assetURL, NSError *error)
     {
         [weak_self addAssetURL:assetURL toAlbum:@"诗词赋" withCompletionBlock:^(NSError *error)
          {
              NSString *msg = nil ;
              if(error != NULL){
                  msg = @"保存图片失败" ;
              }else{
                  msg = @"保存图片成功" ;
              }
              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"保存图片结果提示"
                                                              message:msg
                                                             delegate:self
                                                    cancelButtonTitle:@"确定"
                                                    otherButtonTitles:nil];
              [alert show];
          }];
     }];
}

@end
