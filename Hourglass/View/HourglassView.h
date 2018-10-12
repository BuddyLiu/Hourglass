//
//  HourglassView.h
//  CoreAnimationDemo
//
//  Created by Paul on 2018/10/9.
//  Copyright © 2018年 Qinghu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HourglassViewDelegate<NSObject>

-(void)timerDidStop;
-(void)ballsIsFinished;

@end

@interface HourglassView : UIView

@property (nonatomic, strong) id<HourglassViewDelegate> delegate;

/**
 刷新视图
 */
-(void)refreshHourglassView;

/**
 刷新视图
 指定总时长
 @param timeSecond 总时长
 @param totalBalls 总个数
 */
-(void)refreshHourglassViewWithWholeTime:(NSUInteger)timeSecond totalBalls:(NSUInteger)totalBalls;

/**
 开始计时
 */
-(void)startTimer;

/**
 结束计时
 */
-(void)stopTimer;

/**
 添加小球
 */
-(void)addBallManual;

/**
 移除小球
 
 @return 剩余小球个数
 */
-(NSInteger)removeBallManal;

/**
 设置是否允许播放音乐

 @param isAllowedMusic YES-允许 NO-不允许
 */
-(void)reSetIsAllowedMusic:(BOOL)isAllowedMusic;

@end
