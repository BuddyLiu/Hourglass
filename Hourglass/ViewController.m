//
//  ViewController.m
//  Hourglass
//
//  Created by Paul on 2018/10/11.
//  Copyright © 2018年 LiuBo. All rights reserved.
//

#import "ViewController.h"
#import "HourglassView.h"

@interface ViewController ()<HourglassViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UIView *operateView;
@property (strong, nonatomic) IBOutlet UIButton *minusBtn;
@property (strong, nonatomic) IBOutlet UIButton *addBtn;
@property (strong, nonatomic) IBOutlet UIButton *startBtn;

@property (nonatomic, strong) HourglassView *animationView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.startBtn setImage:[UIImage imageNamed:@"icon_start_bule"] forState:(UIControlStateNormal)];
    self.startBtn.tag = 205;
    [self.view addSubview:[self createHourglassView]];
}

-(UIView *)createHourglassView
{
    self.animationView = [[HourglassView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 240)/2.0,
                                                                                   self.nameLabel.frame.size.height + self.nameLabel.frame.origin.y + 40,
                                                                                   240,
                                                                                   320)];
    self.animationView.delegate = self;
    self.animationView.backgroundColor = [UIColor clearColor];
    
    return self.animationView;
}

- (IBAction)startBtnAction:(UIButton *)sender
{
    if(sender.tag == 205)
    {
        [self setStartTimerViewState];
        [self.animationView startTimer];
    }
    else
    {
        [self setStopTimerViewState];
        [self.animationView stopTimer];
    }
}

- (IBAction)minusBtnAction:(UIButton *)sender
{
    [self setStopTimerViewState];
    [self.animationView stopTimer];
    NSInteger count = [self.animationView removeBallManal];
    if(count == 0)
    {
        __weak typeof(self) weakSelf = self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨小提示" message:@"没有小球了，是否要重新开始?" preferredStyle:(UIAlertControllerStyleAlert)];
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf.animationView refreshHourglassView];
            __weak typeof(weakSelf) strongSelf = weakSelf;
            [UIView animateWithDuration:0.5 animations:^{
                [strongSelf.mainView addSubview:strongSelf.animationView];
            }];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (IBAction)addBtnAction:(UIButton *)sender
{
    [self setStopTimerViewState];
    [self.animationView stopTimer];
    [self.animationView addBallManual];
}

-(void)setStartTimerViewState
{
    self.addBtn.userInteractionEnabled = NO;
    self.minusBtn.userInteractionEnabled = NO;
    
    self.addBtn.alpha = 0.5;
    self.minusBtn.alpha = 0.5;
    
    self.startBtn.tag = 206;
    [self.startBtn setImage:[UIImage imageNamed:@"icon_stop_bule"] forState:(UIControlStateNormal)];
}

-(void)setStopTimerViewState
{
    self.addBtn.userInteractionEnabled = YES;
    self.minusBtn.userInteractionEnabled = YES;
    
    self.addBtn.alpha = 1;
    self.minusBtn.alpha = 1;
    
    self.startBtn.tag = 205;
    [self.startBtn setImage:[UIImage imageNamed:@"icon_start_bule"] forState:(UIControlStateNormal)];
}

-(void)timerDidStop
{
    [self setStopTimerViewState];
}

-(void)ballsIsFinished
{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨小提示" message:@"要重新开始计时吗？" preferredStyle:(UIAlertControllerStyleAlert)];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf.animationView refreshHourglassView];
        __weak typeof(weakSelf) strongSelf = weakSelf;
        [UIView animateWithDuration:0.5 animations:^{
            [strongSelf.mainView addSubview:strongSelf.animationView];
        }];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
