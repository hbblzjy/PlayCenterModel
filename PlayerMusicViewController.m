//
//  PlayerMusicViewController.m
//  ycBook
//
//  Created by LaiWang on 2017/2/21.
//  Copyright © 2017年 Alexander. All rights reserved.
//播放页界面

#import "PlayerMusicViewController.h"

@interface PlayerMusicViewController ()

@end

@implementation PlayerMusicViewController

static PlayerMusicViewController *playerVC = nil;
+(PlayerMusicViewController *)sharePlayerVC
{
    if (!playerVC) {
        playerVC = [PlayerMusicViewController new];
    }
    return playerVC;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.tabBarController.tabBar.hidden = YES;
    
}
-(void)viewDidAppear:(BOOL)animated
{
    //当在详情页面选择时重新请求数据开始播放
    if ([self.detailStr isEqualToString:@"1"]) {
        //从详情界面过来
        //数据请求方法
        //NSLog(@"执行了音乐播放。。。。。");
        [self pushRequstData];
    }
}
- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.tabBarController.tabBar.hidden = NO;
}
-(void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"后台" object:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = BACK_COLOR;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    currentInt = 0;
    currentIndexPR = 0;
    aFloatValue = -1;
    bFloatValue = -1;
    currentIdStr = @"";
    
    _duanDianArray = [NSMutableArray new];
    //_duanDianArray = [[NSMutableArray alloc]initWithObjects:@{@"name":@"1",@"isPlay":@"0"},@{@"name":@"2",@"isPlay":@"0"},@{@"name":@"3",@"isPlay":@"0"},@{@"name":@"4",@"isPlay":@"0"}, nil];
    
    _textArray = [NSMutableArray new];
    //_textArray = [[NSArray alloc] initWithObjects:@"这是测试文字1",@"这是测试文字2",@"这是测试文字3",@"这是测试文字4", nil];
    
    [self.view addSubview:self.tableViewW];
    
    [self.view addSubview:self.playerView];
    
    
    
}
#pragma mark ----- 数据请求相关代码
#pragma mark --------- 数据请求方法
- (void)pushRequstData {
    //__weak typeof (self) selfVc = self;
    dispatch_group_t group = dispatch_group_create();
    
    //下载图书的列表数据请求
    dispatch_group_enter(group);
    NSDictionary *paramDic = @{@"uid":self.uidStr,@"code":self.codeStr};
    //NSLog(@"输出此时的字典。。。。。。%@",paramDic);
    [HttpRequestUtil requestForSuccessLoadingSimpleView:BOOK_LIST_DATA param:paramDic start:0 complete:^(NSDictionary *resultDic) {
        //NSLog(@"下载图书的列表数据.....%@",resultDic);
        if (resultDic) {
            NSNumber *codeNum = resultDic[@"code"];
            NSNumber *num = [[NSNumber alloc] initWithInt:200];
            if ([codeNum isEqualToNumber:num]) {
                NSDictionary *dataDic = resultDic[@"data"];
                _musicArray = [[NSArray alloc] initWithArray:dataDic[@"list"]];
            }else{
                
            }
        }else{
            
        }
        
        dispatch_group_leave(group);
    }];
    
    //断点列表数据请求
    dispatch_group_enter(group);
    NSDictionary *paramDic1 = @{@"record_id":self.recordIdStr};
    //NSLog(@"输出此时的字典。。。。。。%@",paramDic1);
    [HttpRequestUtil requestForSuccessLoadingSimpleView:DUANDIAN_LIST_DATA param:paramDic1 start:0 complete:^(NSDictionary *resultDic) {
        //NSLog(@"断点列表的数据.....%@",resultDic);
        if (resultDic) {
            NSNumber *codeNum = resultDic[@"code"];
            NSNumber *num = [[NSNumber alloc] initWithInt:200];
            if ([codeNum isEqualToNumber:num]) {
                
                //返回数据
                NSDictionary *dataDic = resultDic[@"data"];
                //音频信息
                _musicDetailDic = dataDic[@"info"];
                //数组信息
                NSArray *listArray = dataDic[@"list"];
                _duanDianArray = [NSMutableArray new];
                if (listArray.count>0) {
                    for (NSMutableDictionary *dic in listArray) {
                        [dic setObject:@"0" forKey:@"isPlay"];
                        [_duanDianArray addObject:dic];
                    }
                }
                self.title = _musicDetailDic[@"fn"];
            }else{
                _duanDianArray = [NSMutableArray new];
                
            }
        }else{
            
        }
        
        dispatch_group_leave(group);
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 汇总结果
        if ([[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH] isEqualToString:@"1"]) {
            ONEBUTTONALERT(@"请重新下载音频文件!");
            //self.detailStr = @"0";
            _playerView.userInteractionEnabled = NO;
        }else{
            NSString *path1 = [NSString stringWithFormat:@"%@/%@",[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH],_musicDetailDic[@"filename"]];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:path1]) {
                //刷新表格
                [self.tableViewW reloadData];
                
                //开启音频
                [self createPlayer:_musicArray clickMusicPath:_musicDetailDic];
                
                if ([self.detailStr isEqualToString:@"1"] && ![[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH] isEqualToString:@"1"]) {
                    [longUnderBtn addTarget:self action:@selector(longUnderBtnClick:event:) forControlEvents:UIControlEventTouchUpInside];
                }
                //开启交互
                _playerView.userInteractionEnabled = YES;
                
                //取消复读
                aImgV.hidden = YES;
                bImgV.hidden = YES;
                
                //同时修改A、B的值
                aFloatValue = -1;
                bFloatValue = -1;
                
                fuDuInt = 0;
                
                //添加一个通知，当锁屏时，改变相应的状态
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backEvent:) name:@"后台" object:nil];
                
            }else{
                ONEBUTTONALERT(@"请重新下载音频文件!");
                //self.detailStr = @"0";
                _playerView.userInteractionEnabled = NO;
            }
            
        }
    });
}
#pragma mark ------- 锁屏后台操作，对应的通知
-(void)backEvent:(NSNotification *)notiFi
{
    //NSLog(@"哈哈哈哈后台执行了方法...........");
    
    //暂停
    [[PlayCenter shareCenter] pause];
    
    UIButton *underBtn = (UIButton *)[_playerView viewWithTag:3];
    [underBtn setBackgroundImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
}
#pragma mark ------- 断点列表数据请求
-(void)duanDianHttpRequest:(NSString *)str
{
    NSDictionary *paramDic = @{@"record_id":str};
    [HttpRequestUtil requestForSuccessLoadingSimpleView:DUANDIAN_LIST_DATA param:paramDic start:0 complete:^(NSDictionary *resultDic) {
        //NSLog(@"断点列表的数据.....%@",resultDic);
        if (resultDic) {
            NSNumber *codeNum = resultDic[@"code"];
            NSNumber *num = [[NSNumber alloc] initWithInt:200];
            if ([codeNum isEqualToNumber:num]) {
                
                //返回数据
                NSDictionary *dataDic = resultDic[@"data"];
                //音频信息
                _musicDetailDic = dataDic[@"info"];
                //数组信息
                NSArray *listArray = dataDic[@"list"];
                _duanDianArray = [NSMutableArray new];
                if (listArray.count>0) {
                    for (NSMutableDictionary *dic in listArray) {
                        [dic setObject:@"0" forKey:@"isPlay"];
                        [_duanDianArray addObject:dic];
                    }
                }
                
                [self.tableViewW reloadData];
            }else{
                _duanDianArray = [NSMutableArray new];
                [self.tableViewW reloadData];
            }
        }else{
            
        }
    }];
}
#pragma mark ------- 保存断点数据请求
-(void)saveDuanDianHttpRequest:(NSString *)startTime endStr:(NSString *)endTimeStr nameStr:(NSString *)nameS idStr:(NSString *)aIdStr//这个地方修改传id，新增不用传id
{
    NSDictionary *paramDic = [NSDictionary new];
    if (aIdStr.length>0) {
        //修改
        paramDic = @{@"startime":startTime,@"endtime":endTimeStr,@"name":nameS,@"record_id":self.recordIdStr,@"id":aIdStr};
    }else{
        //新增
        paramDic = @{@"startime":startTime,@"endtime":endTimeStr,@"name":nameS,@"record_id":self.recordIdStr};
    }
    //NSLog(@".........%@",paramDic);
    [HttpRequestUtil requestForSuccessLoadingSimpleView:SAVE_DUANDIAN_DATA param:paramDic start:0 complete:^(NSDictionary *resultDic) {
        //NSLog(@"保存断点的数据.....%@",resultDic);
        if (resultDic) {
            NSNumber *codeNum = resultDic[@"code"];
            NSNumber *num = [[NSNumber alloc] initWithInt:200];
            if ([codeNum isEqualToNumber:num]){
                [_bhAlertV hide];
                
                aFloatValue = -1;
                bFloatValue = -1;
                currentIndexPR = 0;
                
                //刷新数据
                [self duanDianHttpRequest:self.recordIdStr];
            }else{
                ONEBUTTONALERT(@"数据保存失败！");
            }
        }else{
            ONEBUTTONALERT(@"数据保存失败！");
        }
    }];
}
#pragma mark ------- 删除断点数据请求
-(void)deleteDuanDianHttpRequest:(NSString *)duanId nameStr:(NSString *)nameS currentTag:(NSInteger)currentI
{
    NSDictionary *paramDic = @{@"id":duanId,@"name":nameS};
    //NSLog(@".........%@",paramDic);
    [HttpRequestUtil requestForSuccessLoadingSimpleView:DELETE_DUANDIAN_DATA param:paramDic start:0 complete:^(NSDictionary *resultDic) {
        //NSLog(@"删除断点的数据.....%@",resultDic);
        if (resultDic) {
            NSNumber *codeNum = resultDic[@"code"];
            NSNumber *num = [[NSNumber alloc] initWithInt:200];
            if ([codeNum isEqualToNumber:num]) {
                
                aFloatValue = -1;
                bFloatValue = -1;
                currentIndexPR = 0;
                
                //刷新数据
                [self duanDianHttpRequest:self.recordIdStr];
            }else{
                
            }
        }else{
            
        }
    }];
}
#pragma mark ----- 音频播放相关,传递音频数组，和点击的音频信息Dic
-(void)createPlayer:(NSArray *)musicArr clickMusicPath:(NSDictionary *)urlPathDic;
{
    PlayCenter *playCen = [PlayCenter shareCenter];
    NSDictionary *musicDic = [playCen play:musicArr clickMusicPath:urlPathDic];
    
    [self nameAndTimeWithMusicDic:musicDic];
    
    //添加一个观察者，观察PlayCenter的属性musicInfo值的变化，方便替换音乐信息
    [playCen addObserver:self forKeyPath:@"musicInfo" options:NSKeyValueObservingOptionNew context:nil];
    
    if (_musicTimer == nil) {
        _musicTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(musicTimeShow:) userInfo:nil repeats:YES];
        [_musicTimer fire];
    }
    
    UIButton *underBtn = (UIButton *)[_playerView viewWithTag:3];
    [underBtn setBackgroundImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
}
//定时器的方法
-(void)musicTimeShow:(NSTimer *)timerr
{
    CGFloat currentTimeFloat = (CGFloat)[PlayCenter shareCenter].player.currentTime;
    if (currentTimeFloat-bFloatValue>=0.1 && bFloatValue > 0) {
        [PlayCenter shareCenter].player.currentTime = aFloatValue;
        currentTimeFloat = aFloatValue;
    }
    
    NSInteger secondInt = (NSInteger)(currentTimeFloat) % 60;
    if (secondInt>9) {
        headTimeLabel.text = [NSString stringWithFormat:@"%ld:%ld",(NSInteger)(currentTimeFloat)/60,(NSInteger)(currentTimeFloat) % 60];
    }else{
        headTimeLabel.text = [NSString stringWithFormat:@"%ld:0%ld",(NSInteger)(currentTimeFloat)/60,(NSInteger)(currentTimeFloat) % 60];
    }
    
    //底部长条
    CGFloat widthFloat = currentTimeFloat/allTimeFloat*(f_Device_w-40);
    longView2.frame = CGRectMake(0, 0, widthFloat, 12);
    
    if (allTimeFloat-currentTimeFloat <=2) {
        //播放完成以后，播放下一首
        [[PlayCenter shareCenter] nextItem];
    }
}
//观察者执行的方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSDictionary *musicDic = [PlayCenter shareCenter].musicInfo;
    [self nameAndTimeWithMusicDic:musicDic];
    //NSLog(@"输出音乐的相关信息。。。。%@",musicDic);
    
    //播放到下一首时，重新获取对应音频的断点列表和相关信息
    self.title = musicDic[@"fn"];
    self.recordIdStr = musicDic[@"id"];
    [self duanDianHttpRequest:self.recordIdStr];
}
//设置名称和时间
-(void)nameAndTimeWithMusicDic:(NSDictionary *)musicDic
{
    self.title = musicDic[@"fn"];
    
    musicTitleLabel.text = [NSString stringWithFormat:@"%@",musicDic[@"filesourcename"]];
    
    //CGFloat timeFloat = (CGFloat)[[PlayCenter shareCenter].player duration];
    //allTimeFloat = timeFloat;
    
    NSString *path1 = [NSString stringWithFormat:@"%@/%@",[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH],musicDic[@"filename"]];
    //NSLog(@"。。。。。。/.....地址%@",path1);
    NSURL *url = [NSURL fileURLWithPath:path1];
    CGFloat timeFloat = [self durationWithMusic:url];
    allTimeFloat = timeFloat;
    //NSLog(@"输出总的时间长度。。。。。%f",allTimeFloat);
    NSInteger secondInt = (NSInteger)(timeFloat) % 60;
    if (secondInt>9) {
        endLabel1.text = [NSString stringWithFormat:@"%ld:%ld",(NSInteger)(timeFloat)/60,(NSInteger)(timeFloat) % 60];
    }else{
        endLabel1.text = [NSString stringWithFormat:@"%ld:0%ld",(NSInteger)(timeFloat)/60,(NSInteger)(timeFloat) % 60];
    }
}
///  获取音频文件的时长
-(CGFloat)durationWithMusic:(NSURL *)urlPath
{
    AVURLAsset *audioAsset=[AVURLAsset assetWithURL:urlPath];
    
    CMTime durationTime = audioAsset.duration;
    
    CGFloat reultTime=0;
    
    reultTime = CMTimeGetSeconds(durationTime);
    
    return reultTime;
    
}
#pragma mark ----- 底部播放视图样式
-(UIView *)playerView
{
    if (_playerView == nil) {
        _playerView = [[UIView alloc] initWithFrame:CGRectMake(0, f_Device_h-200, f_Device_w, 200)];
        _playerView.backgroundColor = [UIColor whiteColor];
        
        //线
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, f_Device_w, 1)];
        lineView.backgroundColor = [UIColor blackColor];
        [_playerView addSubview:lineView];
        //打标签
        UIButton *labelBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 10, 80, 40)];
        [labelBtn setTitle:@"打标签" forState:UIControlStateNormal];
        labelBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [labelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        if ([self.detailStr isEqualToString:@"1"] && ![[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH] isEqualToString:@"1"]) {
            [labelBtn addTarget:self action:@selector(labelBtnClick) forControlEvents:UIControlEventTouchUpInside];
        }
        [_playerView addSubview:labelBtn];
        //文字板
        UIButton *textBtn = [[UIButton alloc] initWithFrame:CGRectMake(f_Device_w-100, 10, 80, 40)];
        [textBtn setTitle:@"文字板" forState:UIControlStateNormal];
        [textBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        textBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        if ([self.detailStr isEqualToString:@"1"] && ![[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH] isEqualToString:@"1"]) {
            [textBtn addTarget:self action:@selector(textBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        }
        [_playerView addSubview:textBtn];
        
        //长条
        longUnderView1 = [[UIView alloc] initWithFrame:CGRectMake(20, 60, f_Device_w-40, 12)];
        longUnderView1.backgroundColor = [UIColor lightGrayColor];
        [_playerView addSubview:longUnderView1];
        
        //底部有颜色的长条
        longView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 12)];
        longView2.backgroundColor = [UIColor orangeColor];
        [longUnderView1 addSubview:longView2];
        
        //上面覆盖可点击的btn
        longUnderBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 51, f_Device_w-40, 30)];
        [longUnderBtn setBackgroundColor:[UIColor clearColor]];
        [_playerView addSubview:longUnderBtn];
        
        //添加两个断点视图A B
        fuDuInt = 0;
        aImgV = [[UIImageView alloc] initWithFrame:CGRectMake(0, -5, 20, 20)];
        aImgV.image = [UIImage imageNamed:@"A"];
        aImgV.hidden = YES;
        aImgV.backgroundColor = [UIColor clearColor];
        [longUnderView1 addSubview:aImgV];
        bImgV = [[UIImageView alloc] initWithFrame:CGRectMake(longUnderView1.width-10, -6, 22, 22)];
        bImgV.image = [UIImage imageNamed:@"b"];
        bImgV.hidden = YES;
        bImgV.backgroundColor = [UIColor clearColor];
        [longUnderView1 addSubview:bImgV];
        
        //头时间
        headTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 75, 60, 20)];
        headTimeLabel.text = @"00:00";
        headTimeLabel.textAlignment = NSTextAlignmentCenter;
        headTimeLabel.font = [UIFont systemFontOfSize:13];
        headTimeLabel.backgroundColor = [UIColor clearColor];
        [_playerView addSubview:headTimeLabel];
        //尾时间
        endLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(f_Device_w-60, 75, 60, 20)];
        endLabel1.text = @"00:00";
        endLabel1.textAlignment = NSTextAlignmentCenter;
        endLabel1.font = [UIFont systemFontOfSize:13];
        endLabel1.backgroundColor = [UIColor clearColor];
        [_playerView addSubview:endLabel1];
        
        musicTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 100, f_Device_w-20, 40)];
        musicTitleLabel.font = [UIFont systemFontOfSize:15];
        musicTitleLabel.textColor = [UIColor redColor];
        //[_playerView addSubview:musicTitleLabel];
        //操作按钮
        NSArray *imgArray = @[@"before",@"left",@"stop",@"fudu",@"right",@"after"];
        //间隔
        CGFloat spaceWeight = (f_Device_w-40*6)/7.0;
        for (int i = 0; i < 6; i++) {
            UIButton *itemBtn = [[UIButton alloc]initWithFrame:CGRectMake(spaceWeight+i*(spaceWeight+40), 150, 40, 40)];
            [itemBtn setBackgroundImage:[UIImage imageNamed:imgArray[i] ] forState:UIControlStateNormal];
            itemBtn.tag = i+1;
            [itemBtn addTarget:self action:@selector(itemBtnClick:) forControlEvents:UIControlEventTouchUpInside];
            [_playerView addSubview:itemBtn];
        }
        
    }
    return _playerView;
}
//音乐条操作按钮
-(void)longUnderBtnClick:(id)sender event:(id)event
{
    NSSet *toucheSet = [event allTouches];
    UITouch *touchUI = [toucheSet anyObject];
    CGPoint currentTouchPosition = [touchUI locationInView:longUnderView1];
    
    //有颜色的底部长条
    CGFloat currentTime = currentTouchPosition.x/(f_Device_w-40)*allTimeFloat;
    //NSLog(@"........shuchchus %f",currentTime);
    
    
    //移动B点位置，需要判断是否在A点值之后
    if (bImgV.hidden==NO) {
        CGFloat widthFloat = aFloatValue/allTimeFloat*(f_Device_w-40);
        if (currentTouchPosition.x > widthFloat) {
            bImgV.frame = CGRectMake(currentTouchPosition.x-11, -6, 22, 22);
            bFloatValue = currentTime;
            
            //先判断是否这个点是否大于A点如果大于不显示
            longView2.frame = CGRectMake(0, 0, currentTouchPosition.x, 12);
            
            [PlayCenter shareCenter].player.currentTime = currentTime;
        }
    }else{
        //如果只有A点出来，A点根据长条的改变而改变
        if (aImgV.hidden == NO) {
            aImgV.frame = CGRectMake(currentTouchPosition.x-10, -5, 20, 20);
            aFloatValue = currentTime;
            
            longView2.frame = CGRectMake(0, 0, currentTouchPosition.x, 12);
            
            [PlayCenter shareCenter].player.currentTime = currentTime;
        }else{
            if (aFloatValue != -1 && bFloatValue != -1) {
                CGFloat widthFloatA = aFloatValue/allTimeFloat*(f_Device_w-40);
                CGFloat widthFloatB = bFloatValue/allTimeFloat*(f_Device_w-40);
                if (currentTouchPosition.x >= widthFloatA && currentTouchPosition.x <= widthFloatB) {
                    
                    longView2.frame = CGRectMake(0, 0, currentTouchPosition.x, 12);
                    
                    [PlayCenter shareCenter].player.currentTime = currentTime;
                }
            }else{
                longView2.frame = CGRectMake(0, 0, currentTouchPosition.x, 12);
                
                [PlayCenter shareCenter].player.currentTime = currentTime;
            }
            
        }
        
    }
    
}
//音乐操作按钮
-(void)itemBtnClick:(UIButton *)btn
{
    switch (btn.tag) {
        case 1:
        {
            //NSLog(@"回退十秒。。。。。");
            if ([self.detailStr isEqualToString:@"1"] && ![[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH] isEqualToString:@"1"]) {
                [PlayCenter shareCenter].player.currentTime -= 10;
            }
        }
            break;
        case 2:
        {
            if ([self.detailStr isEqualToString:@"1"] && ![[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH] isEqualToString:@"1"]) {
                ////NSLog(@"上一首.....");
                [[PlayCenter shareCenter] forwardItem];
                
                UIButton *underBtn = (UIButton *)[_playerView viewWithTag:3];
                [underBtn setBackgroundImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
                
                //点击下一首把复读去掉
                aImgV.hidden = YES;
                bImgV.hidden = YES;
                
                //同时修改A、B的值
                aFloatValue = -1;
                bFloatValue = -1;
                
                fuDuInt = 0;
                
            }
        }
            break;
        case 3:
        {
            if ([self.detailStr isEqualToString:@"1"] && ![[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH] isEqualToString:@"1"]) {
                //NSLog(@"开始、暂停.....");
                if ([PlayCenter shareCenter].player.playing) {
                    //暂停
                    [[PlayCenter shareCenter] pause];
                    
                    UIButton *underBtn = (UIButton *)[_playerView viewWithTag:3];
                    [underBtn setBackgroundImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
                }else{
                    //播放
                    [[PlayCenter shareCenter] play];
                    
                    UIButton *underBtn = (UIButton *)[_playerView viewWithTag:3];
                    [underBtn setBackgroundImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
                }
            }
            
        }
            break;
        case 4:
        {
            if ([self.detailStr isEqualToString:@"1"] && ![[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH] isEqualToString:@"1"]) {
                //NSLog(@"重复。。。。。。");
                CGFloat currentTimeFloat = (CGFloat)[PlayCenter shareCenter].player.currentTime;
                //底部长条
                CGFloat widthFloat = currentTimeFloat/allTimeFloat*(f_Device_w-40);
                if (fuDuInt == 0) {
                    aImgV.frame = CGRectMake(widthFloat-10, -5, 20, 20);
                    aImgV.hidden = NO;
                    
                    //记录此时A点的值
                    aFloatValue = currentTimeFloat;
                    
                    fuDuInt = 1;
                }else if(fuDuInt == 1){
                    bImgV.frame = CGRectMake(widthFloat-11, -6, 22, 22);
                    if (bImgV.frame.origin.x-aImgV.frame.origin.x < 20) {
                        bImgV.frame = CGRectMake(widthFloat-11+20, -6, 22, 22);
                    }
                    bImgV.hidden = NO;
                    
                    //记录此时B点的值，//此时因为要进行重复播放，而定时器一直在执行，所以在定时器方法中进行判断
                    bFloatValue = currentTimeFloat;
                    
                    fuDuInt = 2;
                }else{
                    aImgV.hidden = YES;
                    bImgV.hidden = YES;
                    
                    //同时修改A、B的值
                    aFloatValue = -1;
                    bFloatValue = -1;
                    
                    fuDuInt = 0;
                }
            }
            
        }
            break;
        case 5:
        {
            if ([self.detailStr isEqualToString:@"1"] && ![[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH] isEqualToString:@"1"]) {
                //NSLog(@"下一首........");
                [[PlayCenter shareCenter] nextItem];
                
                UIButton *underBtn = (UIButton *)[_playerView viewWithTag:3];
                [underBtn setBackgroundImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
                
                //点击下一首把复读去掉
                aImgV.hidden = YES;
                bImgV.hidden = YES;
                
                //同时修改A、B的值
                aFloatValue = -1;
                bFloatValue = -1;
                
                fuDuInt = 0;
            }
            
        }
            break;
        case 6:
        {
            if ([self.detailStr isEqualToString:@"1"] && ![[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH] isEqualToString:@"1"]) {
                //NSLog(@"前进十秒。。。。。");
                [PlayCenter shareCenter].player.currentTime += 10;
            }
        }
            break;
            
        default:
            break;
    }
}
-(void)labelBtnClick//:(UIButton *)btn
{
    //NSLog(@"点击了打标签按钮......");
    
    _bhAlertV = [[BHAlertView alloc] init];
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, f_Device_w-20, 220)];
    bgView.backgroundColor = [UIColor whiteColor];
    bgView.layer.borderWidth = 1;
    bgView.layer.cornerRadius = 5;
    
    //关闭按钮
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(f_Device_w-30-20, 5, 25, 25)];
    [closeBtn setBackgroundImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:closeBtn];
    
    //输入框
    nameTextF = [[UITextField alloc] initWithFrame:CGRectMake(30, 30, 200, 34)];
    nameTextF.placeholder = @"请输入标签名";
    nameTextF.layer.borderWidth = 1;
    nameTextF.layer.borderColor = BACK_COLOR.CGColor;
    nameTextF.layer.cornerRadius = 5;
    nameTextF.delegate = self;
    [bgView addSubview:nameTextF];
    //确定按钮
    UIButton *okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    okBtn.frame = CGRectMake(265, 30, 70, 34);
    [okBtn setTitle:@"确定" forState:UIControlStateNormal];
    [okBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    okBtn.layer.borderWidth = 1.0;
    okBtn.layer.cornerRadius = 5;
    okBtn.layer.borderColor = BACK_COLOR.CGColor;
    [bgView addSubview:okBtn];
    [okBtn addTarget:self action:@selector(okBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    //提示信息
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 70, f_Device_w-40, 30)];
    infoLabel.text = @"可拖动圆圈位置设置区间；若拖动圆圈位置，则记录设定值";
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.adjustsFontSizeToFitWidth = YES;
    infoLabel.font = [UIFont systemFontOfSize:13];
    [bgView addSubview:infoLabel];
    
    //添加滑杆视图
    _slider = [[JLDoubleSlider alloc]initWithFrame:CGRectMake(10, 115, f_Device_w-40, 40)];
    _slider.minNum = 0.0;
    _slider.maxNum = allTimeFloat;
    _slider.minTintColor = [UIColor lightGrayColor];
    _slider.maxTintColor = [UIColor lightGrayColor];
    _slider.mainTintColor = [UIColor orangeColor];
    [bgView addSubview:_slider];
    
    _bhAlertV.contentView = bgView;
    [_bhAlertV show];
}
//确定按钮
-(void)okBtnClick:(UIButton *)btn
{
    //NSLog(@"点击了确定按钮");
    if ([StringUtil isEmpty:nameTextF.text] ) {
        ONEBUTTONALERT(@"输入框不能为空!");
    }else{
        
        [nameTextF resignFirstResponder];
        
        //断点保存
        [self saveDuanDianHttpRequest:_slider.minLabel.text endStr:_slider.maxLabel.text nameStr:nameTextF.text idStr:currentIdStr];
    }
}
//关闭按钮
-(void)closeBtnClick:(UIButton *)btn
{
    [nameTextF resignFirstResponder];
    [_bhAlertV hide];
}
#pragma mark --------- UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
#pragma mark --------- BHAlertViewDelegate
- (void)alertView:(BHAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"输出此时点击的按钮索引值......%ld", (long)buttonIndex);
}
//文字板按钮
-(void)textBtnClick:(UIButton *)btn
{
    //NSLog(@"点击了文字板按钮......");
    
    if (currentInt == 0) {
        currentInt = 1;
    }else{
        currentInt = 0;
    }
    
    [self.tableViewW reloadData];
}
//表格
-(UITableView *)tableViewW
{
    if (_tableViewW==nil) {
        _tableViewW = [[UITableView alloc]initWithFrame:CGRectMake(0, 64, f_Device_w, f_Device_h-64-200) style:UITableViewStylePlain];
        _tableViewW.delegate = self;
        _tableViewW.dataSource = self;
        _tableViewW.rowHeight = 50;
        _tableViewW.tableFooterView = [UIView new];
        if ([_tableViewW respondsToSelector:@selector(setLayoutMargins:)]) {
            [_tableViewW setLayoutMargins:UIEdgeInsetsZero];
        }
        if ([_tableViewW respondsToSelector:@selector(setSeparatorInset:)]) {
            [_tableViewW setSeparatorInset:UIEdgeInsetsZero];
        }
    }
    
    return _tableViewW;
}
#pragma mark ------ UITableViewDelegate,UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (currentInt == 0) {
        if (_duanDianArray.count<=0) {
            return 1;
        }
        return _duanDianArray.count;
    }else{
        if (_textArray.count <= 0) {
            return 1;
        }
        return _textArray.count;
    }
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (currentInt == 0) {
        if (_duanDianArray.count<=0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell0"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell0"];
            }
            if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
                [cell setLayoutMargins:UIEdgeInsetsZero];
            }
            if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
                [cell setSeparatorInset:UIEdgeInsetsZero];
            }
            cell.selectionStyle = NO;
            cell.textLabel.text = @"暂无标签";
            return cell;
        }else{
            PlayerTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (cell ==nil) {
                cell = [[PlayerTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"playerCell"];
            }
            if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
                [cell setLayoutMargins:UIEdgeInsetsZero];
            }
            if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
                [cell setSeparatorInset:UIEdgeInsetsZero];
            }
            cell.selectionStyle = NO;
            
            [cell setDataDic:_duanDianArray[indexPath.row] indexPath:indexPath];
            
            //播放暂停按钮
            UIButton *playerBtn = (UIButton *)[cell viewWithTag:indexPath.row+1];
            [playerBtn addTarget:self action:@selector(playerBtnClick:) forControlEvents:UIControlEventTouchUpInside];
            
            //删除按钮
            UIButton *deleteBtn = (UIButton *)[cell viewWithTag:indexPath.row+2];
            [deleteBtn addTarget:self action:@selector(deleteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
            
            return cell;
        }
    }else{
        if (_textArray.count<=0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell1"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell1"];
            }
            if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
                [cell setLayoutMargins:UIEdgeInsetsZero];
            }
            if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
                [cell setSeparatorInset:UIEdgeInsetsZero];
            }
            tableView.separatorStyle = NO;
            cell.selectionStyle = NO;
            cell.textLabel.text = @"功能敬请期待";
            return cell;
        }else{
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"textCell"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"textCell"];
            }
            if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
                [cell setLayoutMargins:UIEdgeInsetsZero];
            }
            if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
                [cell setSeparatorInset:UIEdgeInsetsZero];
            }
            cell.selectionStyle = NO;
            cell.textLabel.text = _textArray[indexPath.row];
            
            return cell;
        }
    }
}
//播放暂停按钮
-(void)playerBtnClick:(UIButton *)btn
{
    //NSLog(@"点击了第。。。%ld.....",btn.tag);
    
    NSMutableDictionary *newDic = [NSMutableDictionary dictionaryWithDictionary:_duanDianArray[btn.tag-1]];
    
    if (currentIndexPR == btn.tag-1) {
        if ([newDic[@"isPlay"] isEqualToString:@"0"]) {
            [newDic setObject:@"1" forKey:@"isPlay"];
            
            //断点播放
            [[PlayCenter shareCenter] play];
            
            UIButton *underBtn = (UIButton *)[_playerView viewWithTag:3];
            [underBtn setBackgroundImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
        }else{
            [newDic setObject:@"0" forKey:@"isPlay"];
            
            //断点暂停
            [[PlayCenter shareCenter] pause];
            
            UIButton *underBtn = (UIButton *)[_playerView viewWithTag:3];
            [underBtn setBackgroundImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        }
        [_duanDianArray replaceObjectAtIndex:btn.tag-1 withObject:newDic];
    }else{
        NSMutableDictionary *oldDic = [NSMutableDictionary dictionaryWithDictionary:_duanDianArray[currentIndexPR]];
        [oldDic setObject:@"0" forKey:@"isPlay"];
        [_duanDianArray replaceObjectAtIndex:currentIndexPR withObject:oldDic];
        
        
        [newDic setObject:@"1" forKey:@"isPlay"];
        [_duanDianArray replaceObjectAtIndex:btn.tag-1 withObject:newDic];
        
        UIButton *underBtn = (UIButton *)[_playerView viewWithTag:3];
        [underBtn setBackgroundImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
        
        //断点播放
        [[PlayCenter shareCenter] play];
    }
    
    //取消复读A/B点
    aImgV.hidden = YES;
    bImgV.hidden = YES;
    //同时修改A、B的值
    NSArray *aArray = [newDic[@"startime"] componentsSeparatedByString:@":"];
    CGFloat aNewFloat = [aArray[0] floatValue]*60.0+[aArray[1] floatValue];
    aFloatValue = aNewFloat;
    [PlayCenter shareCenter].player.currentTime = aFloatValue;
    NSArray *bArray = [newDic[@"endtime"] componentsSeparatedByString:@":"];
    CGFloat bNewFloat = [bArray[0] floatValue]*60.0+[bArray[1] floatValue];
    bFloatValue = bNewFloat;
    fuDuInt = 0;
    
    //记录当前Cell的row
    currentIndexPR = btn.tag-1;
    [self.tableViewW reloadData];
}
//删除按钮
-(void)deleteBtnClick:(UIButton *)btn
{
    //NSLog(@"点击了第。。。%d.....",btn.tag);
    
    NSDictionary *dic = _duanDianArray[btn.tag-2];
    [self deleteDuanDianHttpRequest:dic[@"id"] nameStr:dic[@"name"] currentTag:btn.tag-2];
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (currentInt == 0) {
        if (_duanDianArray.count > 0) {
            //NSLog(@"点击是修改内容.....");
            [self showActionSheetView:_duanDianArray[indexPath.row]];
        }
    }
}
#pragma mark --- 弹出提示框
-(void)showActionSheetView:(NSDictionary *)dataDic
{
    UIAlertController *actionSheetC = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"修改" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        currentIdStr = dataDic[@"id"];
        [self labelBtnClick];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [actionSheetC addAction:cameraAction];
    [actionSheetC addAction:cancelAction];
    
    [self presentViewController:actionSheetC animated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//释放
-(void)dealloc
{
    [[PlayCenter shareCenter] removeObserver:self forKeyPath:@"musicInfo"];
}

@end
