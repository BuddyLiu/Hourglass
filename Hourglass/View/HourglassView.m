//
//  HourglassView.m
//  CoreAnimationDemo
//
//  Created by Paul on 2018/10/9.
//  Copyright © 2018年 Qinghu. All rights reserved.
//

#import "HourglassView.h"
#import "ESTimer.h"
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface HourglassView()<UICollisionBehaviorDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) CAShapeLayer *borderLayer;

//物理仿真 动画
@property (nonatomic, strong) UIDynamicAnimator * dynamicAnimator;
//物理仿真 行为
@property (nonatomic, strong) UIDynamicItemBehavior * dynamicItemBehavior;
//碰撞 行为
@property (nonatomic, strong) UICollisionBehavior * collisionBehavior;
//重力 行为
@property (nonatomic, strong) UIGravityBehavior * gravityBehavior;

// 传感器
@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) ESTimer *timer;
@property (nonatomic, strong) NSMutableArray *balls;
@property (nonatomic, strong) UIBezierPath *borderPath;
@property (nonatomic, assign) NSUInteger timeSecond;
@property (nonatomic, strong) UILabel *ballsCountLabel;
@property (nonatomic, strong) UILabel *ballsCountLabelUp;
@property (nonatomic, strong) UILabel *ballsCountLabelDown;
@property (nonatomic, assign) BOOL isAllowedMusic;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@end

static CGFloat LineWidth = 10;
static CGFloat LineWidthHalf = 5;
static CGFloat CurveOffset = 30;
static NSUInteger maxBalls = 180;
static NSUInteger totalBalls = 60;
static BOOL isShowMessage = NO;
static CGFloat ballSize = 10;
static SystemSoundID soundID = 0;

#define random(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)/255.0]
#define randomColor random(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256), 255.0)
#define BorderColor random(57, 131, 233, 255)

@implementation HourglassView

//绘图
- (void)drawRect:(CGRect)rect
{
    self.timeSecond = 60;
    
    self.isAllowedMusic = NO;
    
    [self createBoder];
    
    [self createOperatViews];
    
    [self createDynamic];
    
    [self useGyroPush];
    
    __weak typeof(self) weakSelf = self;
    for (int i = 0; i < totalBalls; i++)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1*i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf createItemIsDown:NO];
        });
    }
}

//默认刷新
-(void)refreshHourglassView
{
    self.timeSecond = 60;
    totalBalls = 60;
    [self refreshHourglassViewWithWholeTime:self.timeSecond totalBalls:totalBalls];
}

//指定时长刷新
-(void)refreshHourglassViewWithWholeTime:(NSUInteger)timeSecond totalBalls:(NSUInteger)totalBalls
{
    totalBalls = totalBalls;
    self.timeSecond = timeSecond;
    [self.timer stopTimerWithTimerType:(ESTimerTypeGCD) stopTimerBlock:nil];
    
    [self removeOperateViews];
    
    UIImageView *imageView;
    do
    {
        imageView = [self viewWithTag:100];
        if(!imageView)
        {
            imageView = [self viewWithTag:200];
        }
        if(imageView)
        {
            [self removeItem:imageView];
        }
    } while (imageView);
    
    [self removeFromSuperview];
    [self setNeedsDisplay];
}

//创建边框
-(void)createBoder
{
    CGFloat viewWidth = self.frame.size.width;
    CGFloat viewHeight = self.frame.size.height;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    //up
    [path moveToPoint:CGPointMake(0, LineWidthHalf)];
    [path addLineToPoint:CGPointMake(viewWidth, LineWidthHalf)];
    [path addLineToPoint:CGPointMake(viewWidth - LineWidth - LineWidthHalf, LineWidthHalf)];
    //right
    [path addQuadCurveToPoint:CGPointMake(viewWidth/2.0 + LineWidth, viewHeight/2.0)
                 controlPoint:CGPointMake(viewWidth, viewHeight/4.0 + CurveOffset)];
    [path addQuadCurveToPoint:CGPointMake(viewWidth - LineWidth - LineWidthHalf, viewHeight - LineWidthHalf)
                 controlPoint:CGPointMake(viewWidth, viewHeight/4.0 + viewHeight/2.0 - CurveOffset)];
    [path addLineToPoint:CGPointMake(viewWidth, viewHeight - LineWidthHalf)];
    //down
    [path addLineToPoint:CGPointMake(0, viewHeight - LineWidthHalf)];
    [path addLineToPoint:CGPointMake(LineWidth + LineWidthHalf, viewHeight - LineWidthHalf)];
    //left
    [path addQuadCurveToPoint:CGPointMake(viewWidth/2.0 - LineWidth, viewHeight/2.0)
                 controlPoint:CGPointMake(0, viewHeight/4.0 + viewHeight/2.0 - CurveOffset)];
    [path addQuadCurveToPoint:CGPointMake(LineWidth + LineWidthHalf, LineWidthHalf)
                 controlPoint:CGPointMake(0, viewHeight/4.0 + CurveOffset)];
    [path addLineToPoint:CGPointMake(0, LineWidthHalf)];
    
    self.borderLayer = [CAShapeLayer layer];
    self.borderLayer.path = path.CGPath;
    self.borderLayer.lineCap = kCALineCapRound;
    self.borderLayer.lineJoin = kCALineJoinRound;
    self.borderLayer.strokeColor = BorderColor.CGColor;
    self.borderLayer.fillColor = [UIColor whiteColor].CGColor;
    self.borderLayer.fillMode = kCAFillModeRemoved;
    self.borderLayer.lineWidth = 10;
    [self.layer addSublayer:self.borderLayer];
    
    self.borderPath = path;
}

//创建操作视图
-(void)createOperatViews
{
    self.ballsCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(LineWidth*2, self.frame.size.height/2.0 - 10, self.frame.size.width/6.0, 20)];
    self.ballsCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.timeSecond];
    self.ballsCountLabel.textColor = [UIColor redColor];
    self.ballsCountLabel.font = [UIFont systemFontOfSize:13];
    self.ballsCountLabel.textAlignment = NSTextAlignmentCenter;
    self.ballsCountLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.ballsCountLabel];
    
    self.ballsCountLabelUp = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, LineWidth)];
    self.ballsCountLabelUp.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.timeSecond];
    self.ballsCountLabelUp.textColor = [UIColor whiteColor];
    self.ballsCountLabelUp.font = [UIFont systemFontOfSize:10];
    self.ballsCountLabelUp.textAlignment = NSTextAlignmentCenter;
    self.ballsCountLabelUp.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.ballsCountLabelUp];
    
    self.ballsCountLabelDown = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height - LineWidth, self.frame.size.width, LineWidth)];
    self.ballsCountLabelDown.text = @"0";
    self.ballsCountLabelDown.textColor = [UIColor whiteColor];
    self.ballsCountLabelDown.font = [UIFont systemFontOfSize:10];
    self.ballsCountLabelDown.textAlignment = NSTextAlignmentCenter;
    self.ballsCountLabelDown.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.ballsCountLabelDown];
}

-(void)removeOperateViews
{
    [self.ballsCountLabel removeFromSuperview];
    [self.ballsCountLabelUp removeFromSuperview];
    [self.ballsCountLabelDown removeFromSuperview];
}

//添加小球按钮事件
-(void)addBallsBtnAction:(UIButton *)sender
{
    [self isShowBtn:sender];
    
    [self addBallManual];
}

//开始计时
-(void)startTimer
{
    __weak typeof(self) weakSelf = self;
    CGFloat timeSecond = self.timeSecond/totalBalls;
    [self.timer startTimerWithTimerType:(ESTimerTypeGCD) timeInterval:timeSecond startTimerBlock:^(CGFloat seconds) {
        NSMutableArray *mArr = [NSMutableArray arrayWithArray:[[weakSelf refreshLabels] copy]];
        if(mArr.count == 0)
        {
            if(self.delegate && [self.delegate respondsToSelector:@selector(ballsIsFinished)])
            {
                [self.delegate ballsIsFinished];
            }
        }
        UIView *view = [self getBottomViewWithViews:[mArr copy]];
        if(view && view.tag == 100)
        {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [UIView animateWithDuration:0.1 animations:^{
                
                [strongSelf removeItem:view];
                
            } completion:^(BOOL finished) {
                
                [strongSelf createItemIsDown:YES];
                
            }];
            if(weakSelf.isAllowedMusic)
            {
                [weakSelf playMusicAfter:0.5];
            }
        }
        else
        {
            [self stopTimer];
        }
    }];
}

-(void)playMusicAfter:(CGFloat)delay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSString *str = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"drop%u", arc4random_uniform(2)+1] ofType:@"wav"];
//        NSURL *url = [NSURL fileURLWithPath:str];
//        AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &soundID);
//        AudioServicesPlayAlertSoundWithCompletion(soundID, ^{
//        });
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        
        // 1.获取要播放音频文件的URL
        NSURL *fileURL = [[NSBundle mainBundle]URLForResource:[NSString stringWithFormat:@"drop%u", arc4random_uniform(2)+1] withExtension:@"wav"];
        // 2.创建 AVAudioPlayer 对象
        self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:fileURL error:nil];
        // 3.打印歌曲信息
//        NSString *msg = [NSString stringWithFormat:@"音频文件声道数:%ld\n 音频文件持续时间:%g",self.audioPlayer.numberOfChannels,self.audioPlayer.duration];
//        NSLog(@"%@",msg);
        // 4.设置循环播放
        self.audioPlayer.numberOfLoops = 1;
        self.audioPlayer.delegate = self;
        // 5.开始播放
        [self.audioPlayer play];
    });
}

//停止计时
-(void)stopTimer
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(timerDidStop)])
    {
        [self.delegate timerDidStop];
    }
    [self.timer stopTimerWithTimerType:(ESTimerTypeGCD) stopTimerBlock:nil];
}

//获取最下面的小球
-(UIView *)getBottomViewWithViews:(NSArray *)views
{
    UIView *retView = (UIView *)[views firstObject];
    for (int i = 0; i < views.count; i++)
    {
        UIView *viewNext = views[i];
        if(retView.center.y < viewNext.center.y)
        {
            retView = viewNext;
        }
    }
    return retView;
}

//手动添加按钮统一处理事件
-(void)addBallManual
{
    [self playMusicAfter:0.3];
    [self refreshLabels];
    if(totalBalls < maxBalls)
    {
        totalBalls++;
        self.timeSecond++;
        [self createItemIsDown:NO];
    }
    else
    {
        
        if(!isShowMessage)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"不能再加了"
                                                                message:@"会撑坏的哦！"
                                                               delegate:self
                                                      cancelButtonTitle:@"确定"
                                                      otherButtonTitles:nil];
            [alertView show];
            isShowMessage = YES;
        }
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    isShowMessage = NO;
}

//改变按钮透明度统一处理事件
-(void)isShowBtn:(UIButton *)sender
{
    static BOOL isShowBtn = NO;
    if(!isShowBtn)
    {
        isShowBtn = YES;
        [UIView animateWithDuration:0.3 animations:^{
            sender.alpha = 1.0;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                isShowBtn = NO;
                [UIView animateWithDuration:0.3 animations:^{
                    sender.alpha = 0.3;
                }];
            });
        }];
    }
}

//初始化传感器
- (void)useGyroPush
{
    //初始化全局管理对象
    CMMotionManager *manager = [[CMMotionManager alloc] init];
    self.motionManager = manager;
    //判断传感器是否可用
    if ([self.motionManager isDeviceMotionAvailable])
    {
        ///设备 运动 更新 间隔
        manager.deviceMotionUpdateInterval = 1;
        ///启动设备运动更新队列
        __weak typeof(self) weakSelf = self;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                                withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
                                                    double gravityX = motion.gravity.x;
                                                    double gravityY = motion.gravity.y;
                                                    // double gravityZ = motion.gravity.z;
                                                    // 获取手机的倾斜角度(z是手机与水平面的夹角， xy是手机绕自身旋转的角度)：
                                                    //double z = atan2(gravityZ,sqrtf(gravityX * gravityX + gravityY * gravityY))  ;
                                                    double xy = atan2(gravityX, gravityY);
                                                    // 计算相对于y轴的重力方向
                                                    weakSelf.gravityBehavior.angle = xy-M_PI_2;
                                                    
                                                }];
        
    }
}

//创建物理仿真体系
- (void)createDynamic
{
    CGFloat viewWidth = self.frame.size.width;
    CGFloat viewHeight = self.frame.size.height;
    
    //创建现实动画 设定动画模拟区间。self.view : 地球
    self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
    //创建物理仿真行为
    self.dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[]];
    //设置弹性系数,数值越大,弹力值越大
    self.dynamicItemBehavior.elasticity = 0.5;
    self.dynamicItemBehavior.friction = 0.01;
    //重力行为
    self.gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[]];
    //碰撞行为
    self.collisionBehavior = [[UICollisionBehavior alloc]initWithItems:@[]];
    
    UIBezierPath *borderPath = [UIBezierPath bezierPathWithRect:CGRectMake(LineWidth*2, LineWidth, viewWidth - LineWidth*4.0, viewHeight - LineWidth*2.0)];
    [self.collisionBehavior addBoundaryWithIdentifier:@"border" forPath:borderPath];
    
    UIBezierPath *circlePathUp = [UIBezierPath bezierPath];
    [circlePathUp moveToPoint:CGPointMake(LineWidth + LineWidthHalf, LineWidth)];
    [circlePathUp addQuadCurveToPoint:CGPointMake(viewWidth/2.0, viewHeight/2.0) controlPoint:CGPointMake(0, viewHeight/4.0 + CurveOffset)];
    [circlePathUp addQuadCurveToPoint:CGPointMake(viewWidth - (LineWidth + LineWidthHalf), LineWidth) controlPoint:CGPointMake(viewWidth, viewHeight/4.0 + CurveOffset)];
    [self.collisionBehavior addBoundaryWithIdentifier:@"up" forPath:circlePathUp];
    
    UIBezierPath *circlePathDown = [UIBezierPath bezierPath];
    [circlePathDown moveToPoint:CGPointMake(LineWidth + LineWidthHalf, viewHeight - LineWidth)];
    [circlePathDown addQuadCurveToPoint:CGPointMake(viewWidth/2.0, viewHeight/2.0) controlPoint:CGPointMake(0, viewHeight*3.0/4.0 - CurveOffset)];
    [circlePathDown addQuadCurveToPoint:CGPointMake(viewWidth - (LineWidth + LineWidthHalf), viewHeight - LineWidth) controlPoint:CGPointMake(viewWidth, viewHeight*3.0/4.0 - CurveOffset)];
    [self.collisionBehavior addBoundaryWithIdentifier:@"Down" forPath:circlePathDown];

    //开启刚体碰撞
    self.collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    //将行为添加到物理仿动画中
    [self.dynamicAnimator addBehavior:self.dynamicItemBehavior];
    [self.dynamicAnimator addBehavior:self.gravityBehavior];
    [self.dynamicAnimator addBehavior:self.collisionBehavior];
    
}

//创建小球，是否在下面
- (void)createItemIsDown:(BOOL)isDown
{
    int x = self.frame.size.width/2.0;
    int size = ballSize;
    CGFloat positionY = LineWidth + LineWidthHalf;
    if(isDown)
    {
        positionY = self.frame.size.height/2.0+LineWidthHalf;
    }
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, positionY, size, size)];
    imageView.clipsToBounds = YES;
    imageView.tag = isDown?200:100;
    imageView.layer.cornerRadius = imageView.frame.size.width/2.0;
    imageView.userInteractionEnabled = YES;
    imageView.backgroundColor = randomColor;
    [self addSubview:imageView];
    
    //让imageView遵循行为
    [_dynamicItemBehavior addItem:imageView];
    [_gravityBehavior addItem:imageView];
    [_collisionBehavior addItem:imageView];
}

-(NSInteger)removeBallManal
{
    NSInteger count = 0;
    for (int i = 0; i < self.gravityBehavior.items.count; i++)
    {
        id<UIDynamicItem> view = self.gravityBehavior.items[i];
        if(((UIView *)view).tag == 100)
        {
            count ++;
            if(count == 1)
            {
                [self removeItem:((UIView *)view)];
            }
        }
    }
    [self refreshLabels];
    return count;
}

//移除小球及相关的物理仿真
-(void)removeItem:(UIView *)view
{
    [_dynamicItemBehavior removeItem:view];
    [_gravityBehavior removeItem:view];
    [_collisionBehavior removeItem:view];
    [view removeFromSuperview];
}

-(NSMutableArray *)refreshLabels
{
    NSMutableArray *mArr = [NSMutableArray new];
    NSInteger countUp = 0;
    NSInteger countDown = 0;
    for (int i = 0; i < self.gravityBehavior.items.count; i++)
    {
        id<UIDynamicItem> view = self.gravityBehavior.items[i];
        if(((UIView *)view).tag == 100)
        {
            countUp ++;
            [mArr addObject:((UIView *)view)];
        }
        if(((UIView *)view).tag == 200)
        {
            countDown++;
        }
    }
    self.ballsCountLabel.text = [NSString stringWithFormat:@"%ld", countUp + countDown];
    self.ballsCountLabelUp.text = [NSString stringWithFormat:@"%ld", countUp];
    self.ballsCountLabelDown.text = [NSString stringWithFormat:@"%ld", countDown];
    return mArr;
}

-(ESTimer *)timer
{
    if(!_timer)
    {
        _timer = [[ESTimer alloc] init];
    }
    return _timer;
}

-(NSMutableArray *)balls
{
    if(!_balls)
    {
        _balls = [NSMutableArray new];
    }
    return _balls;
}

-(void)reSetIsAllowedMusic:(BOOL)isAllowedMusic
{
    _isAllowedMusic = isAllowedMusic;
}

@end
