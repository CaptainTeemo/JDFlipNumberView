//
//  JDCountdownFlipView.m
//
//  Created by Markus Emrich on 12.03.11.
//  Copyright 2011 Markus Emrich. All rights reserved.
//

#import "JDFlipNumberView.h"

#import "JDDateCountdownFlipView.h"

static CGFloat kFlipAnimationUpdateInterval = 0.5; // = 2 times per second

@interface JDDateCountdownFlipView ()
@property (nonatomic) NSInteger dayDigitCount;
@property (nonatomic, copy) NSString *imageBundleName;

@property (nonatomic, strong) JDFlipNumberView* dayFlipNumberView;
@property (nonatomic, strong) JDFlipNumberView* hourFlipNumberView;
@property (nonatomic, strong) JDFlipNumberView* minuteFlipNumberView;
@property (nonatomic, strong) JDFlipNumberView* secondFlipNumberView;

@property (nonatomic, strong) UIImageView *daySeparator;
@property (nonatomic, strong) UIImageView *hourSeparator;
@property (nonatomic, strong) UIImageView *minuteSeparator;

@property (nonatomic, strong) UILabel *dayDescLabel;
@property (nonatomic, strong) UILabel *hourDescLabel;
@property (nonatomic, strong) UILabel *minuteDescLabel;
@property (nonatomic, strong) UILabel *secondDescLabel;

@property (nonatomic, strong) NSTimer *animationTimer;
@end

@implementation JDDateCountdownFlipView

- (id)init
{
    return [self initWithDayDigitCount:3];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [self initWithDayDigitCount:3];
    if (self) {
        self.frame = frame;
    }
    return self;
}

- (id)initWithDayDigitCount:(NSInteger)dayDigits;
{
    return [self initWithDayDigitCount:dayDigits imageBundleName:nil];
}

- (id)initWithDayDigitCount:(NSInteger)dayDigits
            imageBundleName:(NSString*)imageBundleName;
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _dayDigitCount = dayDigits;
        // view setup
        self.backgroundColor = [UIColor clearColor];
        self.autoresizesSubviews = NO;
		
        // setup flipviews
        _imageBundleName = imageBundleName;
        self.dayFlipNumberView = [[JDFlipNumberView alloc] initWithDigitCount:_dayDigitCount imageBundleName:imageBundleName];
        self.hourFlipNumberView = [[JDFlipNumberView alloc] initWithDigitCount:2 imageBundleName:imageBundleName];
        self.minuteFlipNumberView = [[JDFlipNumberView alloc] initWithDigitCount:2 imageBundleName:imageBundleName];
        self.secondFlipNumberView = [[JDFlipNumberView alloc] initWithDigitCount:2 imageBundleName:imageBundleName];
		
		self.daySeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"JDFlipNumberView.bundle/flip_separator.png"]];
		self.hourSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"JDFlipNumberView.bundle/flip_separator.png"]];
		self.minuteSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"JDFlipNumberView.bundle/flip_separator.png"]];
        
        // set maximum values
        self.hourFlipNumberView.maximumValue = 23;
        self.minuteFlipNumberView.maximumValue = 59;
        self.secondFlipNumberView.maximumValue = 59;
        
        // disable reverse flipping
        self.dayFlipNumberView.reverseFlippingDisabled = YES;
        self.hourFlipNumberView.reverseFlippingDisabled = YES;
        self.minuteFlipNumberView.reverseFlippingDisabled = YES;
        self.secondFlipNumberView.reverseFlippingDisabled = YES;

        [self setZDistance: 60];
        
        // set initial frame
        CGRect frame = self.hourFlipNumberView.frame;
        self.frame = CGRectMake(0, 0, frame.size.width*(dayDigits+7), frame.size.height);
        
        // add subviews
        for (UIView* view in @[self.dayFlipNumberView, self.daySeparator, self.hourFlipNumberView, self.hourSeparator, self.minuteFlipNumberView, self.minuteSeparator, self.secondFlipNumberView]) {
			if ([view isKindOfClass:[UIImageView class]]) {
				view.contentMode = UIViewContentModeScaleAspectFit;
			}
            [self addSubview:view];
        }
		
		self.dayDescLabel = [UILabel new];
		self.dayDescLabel.textAlignment = NSTextAlignmentCenter;
		
		self.hourDescLabel = [UILabel new];
		self.hourDescLabel.textAlignment = NSTextAlignmentCenter;

		self.minuteDescLabel = [UILabel new];
		self.minuteDescLabel.textAlignment = NSTextAlignmentCenter;

		self.secondDescLabel = [UILabel new];
		self.secondDescLabel.textAlignment = NSTextAlignmentCenter;
		
		for (UILabel *label in @[self.dayDescLabel, self.hourDescLabel, self.minuteDescLabel, self.secondDescLabel]) {
			[self addSubview:label];
		}
        
        // set initial dates
        self.targetDate = [NSDate date];
        [self setupUpdateTimer];
    }
    return self;
}

#pragma mark setter

- (NSUInteger)zDistance;
{
    return self.dayFlipNumberView.zDistance;
}

- (void)setZDistance:(NSUInteger)zDistance;
{
    for (JDFlipNumberView* view in @[self.dayFlipNumberView, self.hourFlipNumberView, self.minuteFlipNumberView, self.secondFlipNumberView]) {
        [view setZDistance:zDistance];
    }
}

//- (void)setStartDate:(NSDate *)startDate {
//    _startDate = startDate;
//    [self updateValuesAnimated:NO];
//}
//
//- (void)setTargetDate:(NSDate *)targetDate;
//{
//    _targetDate = targetDate;
//    [self updateValuesAnimated:NO];
//}

- (void)setDayDesc:(NSAttributedString *)dayDesc {
	self.dayDescLabel.attributedText = dayDesc;
}

- (void)setHourDesc:(NSAttributedString *)hourDesc {
	self.hourDescLabel.attributedText = hourDesc;
}

- (void)setMinuteDesc:(NSAttributedString *)minuteDesc {
	self.minuteDescLabel.attributedText = minuteDesc;
}

- (void)setSecondDesc:(NSAttributedString *)secondDesc {
	self.secondDescLabel.attributedText = secondDesc;
}

#pragma mark layout

- (CGSize)sizeThatFits:(CGSize)size;
{
    if (self.dayFlipNumberView == nil) {
        return [super sizeThatFits:size];
    }
    
    CGFloat digitWidth = size.width/(self.dayFlipNumberView.digitCount+7);
//    CGFloat margin     = digitWidth/4.0;
	CGFloat margin     = 0;
    CGFloat currentX   = 0;
    
    // check first number size
    CGSize firstSize = CGSizeMake(digitWidth * self.dayDigitCount, size.height);
    firstSize = [self.dayFlipNumberView sizeThatFits:firstSize];
//    currentX += firstSize.width;
	currentX += digitWidth * self.dayDigitCount;
	
    // check other numbers
    CGSize nextSize;
    for (UIView* view in @[self.dayFlipNumberView, self.daySeparator, self.hourFlipNumberView, self.hourSeparator, self.minuteFlipNumberView, self.minuteSeparator, self.secondFlipNumberView]) {
		CGFloat width = digitWidth * 2;
		if ([view isKindOfClass:[UIImageView class]]) {
			width = 4;
		}
        currentX += margin;
        nextSize = CGSizeMake(width, size.height);
        nextSize = [view sizeThatFits:nextSize];
        currentX += nextSize.width;
    }
    
    // use bottom right of last number
    size.width  = ceil(currentX);
    size.height = ceil(nextSize.height + 30);
    
    return size;
}

- (void)layoutSubviews;
{
    [super layoutSubviews];
    
    if (self.dayFlipNumberView == nil) {
        return;
    }
    
//    CGSize size = [self sizeThatFits:self.bounds.size];
	CGSize size = self.bounds.size;


//    CGFloat margin     = digitWidth/4.0;
	CGFloat margin     = 5;
	
		//    CGFloat digitWidth = size.width/(self.dayFlipNumberView.digitCount+7);
	CGFloat digitWidth = (size.width - margin * 7 - 12) / 8;
	
    CGFloat currentX = round((self.bounds.size.width - size.width)/2.0);
//	CGFloat currentX = 0;
	
    // resize first flipview
    self.dayFlipNumberView.frame = CGRectMake(currentX, 0, digitWidth * self.dayDigitCount, size.height);
//    currentX += self.dayFlipNumberView.frame.size.width;
	
    // update flipview frames
    for (UIView* view in @[self.dayFlipNumberView, self.daySeparator, self.hourFlipNumberView, self.hourSeparator, self.minuteFlipNumberView, self.minuteSeparator, self.secondFlipNumberView]) {
		CGFloat width = digitWidth * 2;
		if ([view isKindOfClass:[UIImageView class]]) {
			width = 4;
		}
        currentX   += margin;
        view.frame = CGRectMake(currentX, 10, width, size.height);
        currentX   += view.frame.size.width;
    }
	
	self.dayDescLabel.frame = CGRectMake(0, 0, digitWidth * 2, 20);
	self.dayDescLabel.center = CGPointMake(self.dayFlipNumberView.center.x, self.dayDescLabel.center.y);
	
	self.hourDescLabel.frame = CGRectMake(0, 0, digitWidth * 2, 20);
	self.hourDescLabel.center = CGPointMake(self.hourFlipNumberView.center.x, self.hourDescLabel.center.y);
	
	self.minuteDescLabel.frame = CGRectMake(0, 0, digitWidth * 2, 20);
	self.minuteDescLabel.center = CGPointMake(self.minuteFlipNumberView.center.x, self.minuteDescLabel.center.y);
	
	self.secondDescLabel.frame = CGRectMake(0, 0, digitWidth * 2, 20);
	self.secondDescLabel.center = CGPointMake(self.secondFlipNumberView.center.x, self.secondDescLabel.center.y);
}

#pragma mark update timer

- (void)start {
	if (self.animationTimer == nil) {
		[self setupUpdateTimer];
		self.timerRunning = YES;
	}
}

- (void)stop {
    [self.animationTimer invalidate];
    self.animationTimer = nil;
	self.timerRunning = NO;
}

- (void)setupUpdateTimer {
    self.animationTimer = [NSTimer timerWithTimeInterval:kFlipAnimationUpdateInterval
                                                  target:self
                                                selector:@selector(handleTimer:)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.animationTimer forMode:NSRunLoopCommonModes];
}

- (void)handleTimer:(NSTimer*)timer {
    [self updateValuesAnimated:YES];
}

- (void)updateValuesAnimated:(BOOL)animated {
	NSDate *startDate = self.startDate ?: [NSDate date];
	[self updateValuesWithDate:startDate animated:animated];
}

- (void)updateValuesWithDate:(NSDate *)date animated:(BOOL)animated {
	if (self.targetDate == nil) {
		return;
	}
	if ([self.targetDate timeIntervalSinceDate:date] > 0) {
		NSUInteger flags = NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
		NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:flags fromDate:date toDate:self.targetDate options:0];
		
		[self.dayFlipNumberView setValue:[dateComponents day] animated:animated];
		[self.hourFlipNumberView setValue:[dateComponents hour] animated:animated];
		[self.minuteFlipNumberView setValue:[dateComponents minute] animated:animated];
		[self.secondFlipNumberView setValue:[dateComponents second] animated:animated];
		
		_startDate = [NSDate dateWithTimeIntervalSince1970:[date timeIntervalSince1970] + 0.5];
	} else {
		[self.dayFlipNumberView setValue:0 animated:animated];
		[self.hourFlipNumberView setValue:0 animated:animated];
		[self.minuteFlipNumberView setValue:0 animated:animated];
		[self.secondFlipNumberView setValue:0 animated:animated];
		[self stop];
		
		if (self.delegate && [self.delegate respondsToSelector:@selector(timerDidStop)]) {
			[self.delegate timerDidStop];
		}
	}
}

@end
