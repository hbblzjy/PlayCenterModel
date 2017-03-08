//
//  PlayerMusicViewController.h
//  ycBook
//
//  Created by LaiWang on 2017/2/21.
//  Copyright © 2017年 Alexander. All rights reserved.
//播放页界面

#import <UIKit/UIKit.h>
#import "PlayerTableViewCell.h"
#import "define.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "PlayCenter.h"
#import "JLDoubleSlider.h"

@interface PlayerMusicViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,BHAlertViewDelegate,UITextFieldDelegate>
{
    //-----底部播放操作
    UIView *longUnderView1;//灰色长条
    UIView *longView2;//颜色视图
    UIButton *longUnderBtn;//长条视图上的按钮
    UILabel *headTimeLabel;//时间
    UILabel *endLabel1;//总时间Label
    UILabel *musicTitleLabel;//音频名称
    NSInteger fuDuInt;//三种状态，0：A点开始，1：B点开始，2：取消
    UIImageView *aImgV;//A点
    UIImageView *bImgV;//B点
    CGFloat aFloatValue;//A点值
    CGFloat bFloatValue;//B点值
    
    //-----弹出框
    UITextField *nameTextF;//弹出框的编辑框
    
    JLDoubleSlider *_slider;//滑杆视图
    
    BHAlertView *_bhAlertV;//弹出框
    
    //-----表格相关
    NSInteger currentInt;//记录当前状态
    NSInteger currentIndexPR;//记录当前点击的cell
    NSString *currentIdStr;//记录当前修改的id值
    
    //-----音乐播放控制
    NSTimer *_musicTimer;//定时器
    CGFloat allTimeFloat;//总时间
    
}
@property(nonatomic,strong)NSDictionary *musicDetailDic;//音频信息

@property(nonatomic,strong)UITableView *tableViewW;
@property(nonatomic,strong)NSMutableArray *duanDianArray;//断点数据
@property(nonatomic,strong)NSArray *textArray;//歌词数据
@property(nonatomic,strong)NSArray *musicArray;//音频数组
@property(nonatomic,strong)UIView *playerView;//底部播放视图

@property(nonatomic,copy)NSString *uidStr;//用户id
@property(nonatomic,copy)NSString *codeStr;//书id
@property(nonatomic,copy)NSString *recordIdStr;//音频id

@property(nonatomic,copy)NSString *detailStr;//从详情界面跳转

//定义唯一的播放页
+(PlayerMusicViewController *)sharePlayerVC;

@end
