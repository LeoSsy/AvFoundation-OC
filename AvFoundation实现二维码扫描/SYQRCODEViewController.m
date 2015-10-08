//
//  SYQRCODEViewController.m
//  AvFoundation实现二维码扫描
//
//  Created by 舒少勇 on 15/10/7.
//  Copyright © 2015年 shushaoyong. All rights reserved.
//

#import "SYQRCODEViewController.h"
#import "SYMYQRCODEViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface SYQRCODEViewController ()<UITabBarDelegate,AVCaptureMetadataOutputObjectsDelegate>

/**容器的高度约束**/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintHeightConstant;
/**冲击波顶部的约束**/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constanct;

/**底部的工具条**/
@property (weak, nonatomic) IBOutlet UITabBar *customTabBar;
/**边框的imageView**/
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
/**冲击波的imageview**/
@property (weak, nonatomic) IBOutlet UIImageView *popImageView;

/**session会话**/
@property(nonatomic,strong)AVCaptureSession *session;
/**session2**/
@property(nonatomic,strong)AVCaptureSession *session2;
/**输入设备**/
@property(nonatomic,strong)AVCaptureDeviceInput *input;
/**输出对象**/
@property(nonatomic,strong)AVCaptureMetadataOutput *output;
/**创建预览图层**/
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
/**提示边框**/
@property(nonatomic,strong)CALayer *drawLayer;

//扫描器灰色蒙板。
@property (nonatomic,strong)CALayer * maskLayer;

@end

@implementation SYQRCODEViewController

#pragma mark 懒加载
//提示图层
- (CALayer *)drawLayer
{
    if (!_drawLayer) {
        _drawLayer = [CALayer layer];
        _drawLayer.frame = self.view.frame;
    }
    return _drawLayer;
}
//会话
-(AVCaptureSession *)session
{
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

//输出对象
- (AVCaptureMetadataOutput *)output
{
    if (!_output) {
        _output = [[AVCaptureMetadataOutput alloc] init];
        
        //设置整个视图的尺寸填充控制器的view
        CGSize size =[UIScreen mainScreen].bounds.size;
        
        //屏幕的宽高
        CGFloat ScreenHight = [UIScreen mainScreen].bounds.size.height;
        CGFloat ScreenWidth = [UIScreen mainScreen].bounds.size.width;
        
        //扫描区域的宽高
        CGFloat width = 300;
        CGFloat height = 300;
        
        //计算扫描区域的xy值
        CGFloat x =(ScreenWidth -width)/2;
        CGFloat y = (ScreenHight - height)/2 ;
        
        //计算感兴趣的区域
        CGRect cropRect = CGRectMake(x , y, width, height);
        
        //计算当前屏幕的宽高比
        CGFloat currentScreenScale = size.height/size.width;
        
        //设定一个标准的比例（这里仅仅是做个参照 因为现在普遍的屏幕都是这个尺寸）
        CGFloat standardScreenScale = 1920./1080.;
        
        //如果当前的屏幕宽高比小于我们标准的宽高比 重新计算高度比例
        if (currentScreenScale < standardScreenScale) {
            //计算高度比例
            CGFloat fixHeight = ScreenWidth * 1920. / 1080.;
            CGFloat fixPadding = (fixHeight - size.height)/2;
            _output.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                cropRect.origin.x/size.width,
                                                cropRect.size.height/fixHeight,
                                                cropRect.size.width/size.width);
        } else {//重新计算宽度比例
            
            //计算宽度比例
            CGFloat fixWidth =ScreenHight * 1080. / 1920.;
            CGFloat fixPadding = (fixWidth - size.width)/2;
            _output.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                (cropRect.origin.x + fixPadding)/fixWidth,
                                                cropRect.size.height/size.height,
                                                cropRect.size.width/fixWidth);
        }
        
    }
    return _output;
}
//输入设备
- (AVCaptureDeviceInput *)input
{
    if (!_input) {
        
        //设置类型
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        //创建输入设备
        _input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
        
    }
    return _input;
    
}
//预览图层
- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (!_previewLayer) {
        //创建预览图层
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        //设置frame
        _previewLayer.frame = self.view.frame;
        //设置填充模式
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //开始动画
    [self startAnimation];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置控制器view的背景
    self.view.backgroundColor = [UIColor redColor];
    
    //设置item的字体颜色
    [self.customTabBar setTintColor:[UIColor orangeColor]];
    //设置底部视图默认选中第0个
    self.customTabBar.selectedItem = self.customTabBar.items[0];
    //设置代理
    self.customTabBar.delegate = self;
    
    //开始扫描
    [self startScan];
    
}


- (void)startScan
{
    //判断能否添加输入输出设备
    if (![self.session canAddInput:self.input]) {
        return;
    }
    if (![self.session canAddOutput:self.output]) {
        return;
    }
    
    //添加输入输入对象
    [self.session addInput:self.input];
    [self.session addOutput:self.output];
    
    //设置输出的数据类型
    self.output.metadataObjectTypes = self.output.availableMetadataObjectTypes;
    
    //设置代理监听扫描到的数据
    [ self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //添加预览图层
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    //添加提示框图层
    [self.previewLayer addSublayer:self.drawLayer];
    
    //创建蒙版图层
    self.maskLayer = [CALayer layer];
    self.maskLayer.frame = self.view.frame;
    //设置layer的代理
    self.maskLayer.delegate = self;
    //添加到我们预览图层的上面
    [self.view.layer insertSublayer:self.maskLayer above:self.previewLayer];
    //绘制layer
    [self.maskLayer setNeedsDisplay];
    
    //开始扫描
    [self.session startRunning];
    
}

#pragma mark  蒙版layer的代理方法
//layer需要绘图时，会调用代理的drawLayer:inContext:方法进行绘图
//注意这个方法 不会自动调用 需要通过setNeedDisplay方法调用
-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{
    
    if (layer == self.maskLayer) {
        //开启一个图形上下文
        UIGraphicsBeginImageContextWithOptions(self.maskLayer.frame.size, NO, 1.0);
        //设置填充颜色
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0 alpha:0.3].CGColor);
        //设置填充区域
        CGContextFillRect(ctx, self.maskLayer.frame);
        //设置需要清除的区域
        CGRect scanFrame = [self.view convertRect:self.popImageView.bounds fromView:self.popImageView.superview];
        //清楚区域
        CGContextClearRect(ctx, scanFrame);
    }
}

//开始动画
- (void)startAnimation
{
    //初始化冲击波的位置
    self.constanct.constant = - self.constraintHeightConstant.constant;
    [self.popImageView  layoutIfNeeded];
    
    [UIView animateWithDuration:1.25 animations:^{
        //修改约束
        self.constanct.constant = self.constraintHeightConstant.constant*0.05;
        //重复执行动画
        [UIView setAnimationRepeatCount:MAXFLOAT ];
        //强制更新
        [self.popImageView layoutIfNeeded];
    }];
    
}

#pragma mark UITabBarDelegate
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    //如果是二维码  这里事先已经绑定了tag值
    if (item.tag == 1) {
        
        //修改容器的高度约束
        self.constraintHeightConstant.constant = 300;
        
        //重新开始动画的方法
        [self reStartAnimation];
        
    }else{
        
        //修改容器的高度约束
        self.constraintHeightConstant.constant = 150;
        
        //重新开始动画的方法
        [self reStartAnimation];
    }
}

//重新开始动画的方法  注意每一次约束高度改变之后 都要调用一次这个方法
- (void)reStartAnimation
{
    //停止动画
    [self.popImageView.layer removeAllAnimations];
    
    //重新开始动画
    [self startAnimation];
    
    //重新绘制
    [self.maskLayer setNeedsDisplay];
}


- (void)dealloc
{
    //停止扫描
    [self.session stopRunning];
    [self.previewLayer removeFromSuperlayer];
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //移除之前的提示框layer
    [self clearLayer];
    
    NSString *url = nil;
    
    if ([[metadataObjects lastObject] respondsToSelector:@selector(stringValue)]) {
        url = [[metadataObjects lastObject] stringValue];
    }
    
    if ([url hasPrefix:@"http://"]) {
        NSString *message = [NSString stringWithFormat:@"可能存在风险,是否打开此链接?　　　%@",url];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"打开链接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
//            [self dismissViewControllerAnimated:YES completion:nil];
            [alert dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }else{
        NSLog(@"扫描到的信息为：%@",url);
    }
    
    if (metadataObjects.count>0) {
        //遍历数据 获取机器可以识别的数据对象
        for (id obj in metadataObjects) {
            
            if ([obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
                //转换元数据坐标 为我们看得懂的坐标点
                id codeObj = [self.previewLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject*)(AVMetadataObject*)obj];
                
                //画边框
                [self drawRect:codeObj];
            }
        }
    }else{
        NSLog(@"没有数据");
    }
}

//画边框
- (void)drawRect:(AVMetadataMachineReadableCodeObject*)codeObject
{
    if (codeObject==nil)  return;
    
    //创建不规则图层
    CAShapeLayer *shap = [CAShapeLayer layer];
    shap.lineWidth = 4;
    shap.strokeColor = [UIColor redColor].CGColor;
    shap.fillColor = [UIColor clearColor].CGColor;
    
    //绘制路径
    shap.path = [self drawPath:codeObject.corners];
    
    //添加图层
    [self.drawLayer addSublayer:shap];
    
}

//绘制路径
- (CGPathRef)drawPath:(NSArray*)pathPoint
{
    //创建贝塞尔路径
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    //初始化开始的位置
    CGPoint point = CGPointZero;
    
    //定义索引
    int  index = 0;
    
    //取出第1个点
    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)pathPoint[index], &point);
    //移动到第1个点
    [path moveToPoint:point];
    
    //取出其他点
    while (index < pathPoint.count) {
        //将字典中的获取一个坐标
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)pathPoint[index++], &point);
        //每获取到一个坐标就画一次
        [path addLineToPoint:point];
    }
    
    //关闭路径
    [path closePath];
    
    //返回路径
    return  path.CGPath;
}

//移除提示边框layer的所有子layer
- (void)clearLayer
{
    //判断当前图层上面是否有子图层
    if(self.drawLayer.sublayers.count==0 || self.drawLayer.sublayers==nil){
        return;
    }
    //如果有子图层 移除所有的子图层
    [self.drawLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
}
//我的二维码按钮被点击
- (IBAction)myQRcodeClick {
    //创建我的二维码控制器
    SYMYQRCODEViewController *myCode = [[SYMYQRCODEViewController alloc] init];
    //push出来
    [self presentViewController:myCode animated:YES completion:nil];
}
@end
