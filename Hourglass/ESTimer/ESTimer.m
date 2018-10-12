//
//  ESTimer.m
//  DaddyLoan
//
//  Created by Paul on 2018/6/7.
//  Copyright © 2018 QingHu. All rights reserved.
//

#import "ESTimer.h"

@interface ESTimer()

@property (nonatomic, assign) ESTimerType timerType;
@property (nonatomic, assign) CGFloat timeInterval;

@property (nonatomic, strong) NSTimer *defaultTimer;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) dispatch_source_t gcdTimer;

@property (nonatomic, strong) StartTimerBlock defaultTimerStartTimerBlock;
@property (nonatomic, strong) StartTimerBlock displayLinkStartTimerBlock;
@property (nonatomic, strong) StartTimerBlock gcdTimerStartTimerBlock;

@property (nonatomic, strong) StopTimerBlock defaultTimerStopTimerBlock;
@property (nonatomic, strong) StopTimerBlock displayLinkStopTimerBlock;
@property (nonatomic, strong) StopTimerBlock gcdTimerStopTimerBlock;

@end

static CGFloat defaultTimeInterval = 1.0;

static NSUInteger defaultTimerSecond = 0;
static NSUInteger displayLinkSecond = 0;
static NSUInteger gcdTimerSecond = 0;

@implementation ESTimer

-(void)startTimerWithTimerType:(ESTimerType)timerType startTimerBlock:(StartTimerBlock)startTimerBlock
{
    [self startTimerWithTimerType:timerType timeInterval:1.0 startTimerBlock:startTimerBlock];
}

-(void)startTimerWithTimerType:(ESTimerType)timerType timeInterval:(CGFloat)timeInterval startTimerBlock:(StartTimerBlock)startTimerBlock
{
    self.timerType = timerType;
    self.timeInterval = timeInterval;
    if(self.timerType == ESTimerTypeDefault)
    {
        defaultTimerSecond = 0;
        self.defaultTimerStartTimerBlock = startTimerBlock;
        self.defaultTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeInterval
                                                                target:self
                                                              selector:@selector(defaultTimerAction)
                                                              userInfo:nil
                                                               repeats:YES];
    }
    else if(self.timerType == ESTimerTypeCAD)
    {
        displayLinkSecond = 0;
        self.displayLinkStartTimerBlock = startTimerBlock;
        self.displayLink = [CADisplayLink displayLinkWithTarget:self
                                                       selector:@selector(handleDisplayLink)];
        // 每隔1帧调用一次
        self.displayLink.frameInterval = self.timeInterval*60;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    else if(self.timerType == ESTimerTypeGCD)
    {
        gcdTimerSecond = 0;
        self.gcdTimerStartTimerBlock = startTimerBlock;
        self.gcdTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
        dispatch_source_set_timer(self.gcdTimer, DISPATCH_TIME_NOW, self.timeInterval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.gcdTimer, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                gcdTimerSecond += 1;
                self.gcdTimerStartTimerBlock(gcdTimerSecond);
            });
        });
        dispatch_resume(self.gcdTimer);
    }
    else
    {
        
    }
}

-(void)stopTimerWithTimerType:(ESTimerType)timerType stopTimerBlock:(StopTimerBlock)stopTimerBlock
{
    self.timerType = timerType;
    if(self.timerType == ESTimerTypeDefault)
    {
        defaultTimerSecond = 0.0;
        self.defaultTimerStopTimerBlock = stopTimerBlock;
        if(self.defaultTimerStopTimerBlock)
        {
            self.defaultTimerStopTimerBlock();
        }
        [self.defaultTimer invalidate];
        self.defaultTimer = nil;
    }
    else if(self.timerType == ESTimerTypeCAD)
    {
        displayLinkSecond = 0.0;
        self.displayLinkStopTimerBlock = stopTimerBlock;
        if(self.displayLinkStopTimerBlock)
        {
            self.displayLinkStopTimerBlock();
        }
        if(self.displayLink)
        {
            [self.displayLink invalidate];
        }
        self.displayLink = nil;
    }
    else if(self.timerType == ESTimerTypeGCD)
    {
        gcdTimerSecond = 0.0;
        self.gcdTimerStopTimerBlock = stopTimerBlock;
        if(self.gcdTimerStopTimerBlock)
        {
            self.gcdTimerStopTimerBlock();
        }
        // 挂起定时器（dispatch_suspend 之后的 Timer，是不能被释放的！会引起崩溃）
//        dispatch_suspend(self.gcdTimer);
        // 关闭定时器
        if(self.gcdTimer)
        {
            dispatch_source_cancel(self.gcdTimer);
        }
    }
    else
    {
        
    }
}

-(void)defaultTimerAction
{
    defaultTimerSecond += 1;
    self.defaultTimerStartTimerBlock(defaultTimerSecond);
}

-(void)handleDisplayLink
{
    displayLinkSecond += 1;
    self.displayLinkStartTimerBlock(displayLinkSecond);
}

@end
