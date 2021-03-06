//
//  JDCountdownFlipView.h
//
//  Created by Markus Emrich on 12.03.11.
//  Copyright 2011 Markus Emrich. All rights reserved.
//


@protocol JSDateCountdownFlipViewDelegate <NSObject>
@optional
- (void)timerDidStop;
@end

@interface JDDateCountdownFlipView : UIView

@property (nonatomic, weak) id<JSDateCountdownFlipViewDelegate> delegate;

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *targetDate;
@property (nonatomic, assign) NSUInteger zDistance;

@property (nonatomic, strong) NSAttributedString *dayDesc;
@property (nonatomic, strong) NSAttributedString *hourDesc;
@property (nonatomic, strong) NSAttributedString *minuteDesc;
@property (nonatomic, strong) NSAttributedString *secondDesc;

@property (nonatomic, assign) BOOL timerRunning;

- (id)initWithDayDigitCount:(NSInteger)dayDigits;
- (id)initWithDayDigitCount:(NSInteger)dayDigits
            imageBundleName:(NSString*)imageBundleName;

- (void)start;
- (void)stop;

- (void)updateValuesAnimated:(BOOL)animated;
- (void)updateValuesWithDate:(NSDate *)date animated:(BOOL)animated;

@end
