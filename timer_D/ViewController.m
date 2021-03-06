//
//  ViewController.m
//  timer_D
//
//  Created by idea on 2018/6/20.
//  Copyright © 2018年 idea. All rights reserved.
//

#import "ViewController.h"
//下拉刷新库
#import <MJRefresh/MJRefresh.h>
#define  ScreenW   [UIScreen mainScreen].bounds.size.width
// UIScreen height.
#define  ScreenH  [UIScreen mainScreen].bounds.size.height
#define WeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    dispatch_source_t _timer;
}
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *lab;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    @WeakObj(self);
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [selfWeak activeCountDownAction];
    }];
    self.lab = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, ScreenW-100, 50)];
    self.lab.backgroundColor = UIColor.purpleColor;
    self.lab.textAlignment = NSTextAlignmentCenter;
    self.lab.font = [UIFont systemFontOfSize:12];
    self.lab.textColor = UIColor.whiteColor;
    self.lab.text = @"下拉加载倒计时";
    [self.view addSubview:self.lab];
    
    // Do any additional setup after loading the view, typically from a nib.
}
-(UITableView *)tableView
{
    if(_tableView == nil){
        _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, ScreenW, ScreenH) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        //        _tableView.tableFooterView = [UIView new];
        //        [_tableView registerClass:[ThirdCell class] forCellReuseIdentifier:@"cell"];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"第%ld行",(long)indexPath.row];
    return cell;
}

- (void)activeCountDownAction {
     [self.tableView.mj_header endRefreshing];
    // 1.计算截止时间与当前时间差值
    // 倒计时的时间 测试数据
    NSString *deadlineStr = @"2018-08-20 15:50:00";
    // 当前时间的时间戳
    NSString *nowStr = [self getCurrentTimeyyyymmdd];
    // 计算时间差值
    NSInteger secondsCountDown = [self getDateDifferenceWithNowDateStr:nowStr deadlineStr:deadlineStr];
    
    // 2.使用GCD来实现倒计时 用GCD这个写有一个好处，跳页不会清零 跳页清零会出现倒计时错误的
    @WeakObj(self);
    
    if (_timer == nil) {
        __block NSInteger timeout = secondsCountDown; // 倒计时时间
        
        if (timeout!=0) {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
            dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0*NSEC_PER_SEC,  0); //每秒执行
            dispatch_source_set_event_handler(_timer, ^{
                if(timeout <= 0){ //  当倒计时结束时做需要的操作: 关闭 活动到期不能提交
                    dispatch_source_cancel(self->_timer);
                    self->_timer = nil;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        selfWeak.lab.text = @"当前活动已结束";
                    });
                } else { // 倒计时重新计算 时/分/秒
                    NSInteger days = (int)(timeout/(3600*24));
                    NSInteger hours = (int)((timeout-days*24*3600)/3600);
                    NSInteger minute = (int)(timeout-days*24*3600-hours*3600)/60;
                    NSInteger second = timeout - days*24*3600 - hours*3600 - minute*60;
                    NSString *strTime = [NSString stringWithFormat:@"活动倒计时 %02ld : %02ld : %02ld", hours, minute, second];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (days == 0) {
                            selfWeak.lab.text = strTime;
                        } else {
                            selfWeak.lab.text = [NSString stringWithFormat:@"活动倒计时            %ld天 %02ld : %02ld : %02ld", days, hours, minute, second];
                        }
                        
                    });
                    timeout--; // 递减 倒计时-1(总时间以秒来计算)
                }
            });
            dispatch_resume(_timer);
        }
    }
}



/**
 *  获取当天的字符串
 *
 *  @return 格式为年-月-日 时分秒
 */
- (NSString *)getCurrentTimeyyyymmdd {
    
    NSDate *now = [NSDate date];
    NSDateFormatter *formatDay = [[NSDateFormatter alloc] init];
    formatDay.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *dayStr = [formatDay stringFromDate:now];
    
    return dayStr;
}

/**
 *  获取时间差值  截止时间-当前时间
 *  nowDateStr : 当前时间
 *  deadlineStr : 截止时间
 *  @return 时间戳差值
 */
- (NSInteger)getDateDifferenceWithNowDateStr:(NSString*)nowDateStr deadlineStr:(NSString*)deadlineStr {
    
    NSInteger timeDifference = 0;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yy-MM-dd HH:mm:ss"];
    NSDate *nowDate = [formatter dateFromString:nowDateStr];
    NSDate *deadline = [formatter dateFromString:deadlineStr];
    NSTimeInterval oldTime = [nowDate timeIntervalSince1970];
    NSTimeInterval newTime = [deadline timeIntervalSince1970];
    timeDifference = newTime - oldTime;
    
    return timeDifference;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
