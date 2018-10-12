//
//  ESTimer.h
//  DaddyLoan
//
//  Created by Paul on 2018/6/7.
//  Copyright © 2018 QingHu. All rights reserved.
//

/**
 * 用于创建计时器，通过回调执行方法，
 * 默认计时间隔1s，可设置，设置后返回的数字以设置后的为准，例如设为timeInterval=3s，则返回一次timeInterval=1表示3s。
 * 提供三种创建计时器的方式
 * 默认的NSTimer创建计时器
 * CADisplayLink创建计时器
 * GCD创建计时器
 **/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^StartTimerBlock)(CGFloat seconds);
typedef void(^StopTimerBlock)(void);

typedef enum : NSUInteger {
    ESTimerTypeDefault, //默认的NSTimer创建计时器
    ESTimerTypeCAD,     //CADisplayLink创建计时器
    ESTimerTypeGCD,     //GCD创建计时器
} ESTimerType;

@interface ESTimer : NSObject

-(void)startTimerWithTimerType:(ESTimerType)timerType startTimerBlock:(StartTimerBlock)startTimerBlock;
-(void)startTimerWithTimerType:(ESTimerType)timerType timeInterval:(CGFloat)timeInterval startTimerBlock:(StartTimerBlock)startTimerBlock;

-(void)stopTimerWithTimerType:(ESTimerType)timerType stopTimerBlock:(StopTimerBlock)stopTimerBlock;

@end
