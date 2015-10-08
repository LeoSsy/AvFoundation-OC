//
//  SYMYQRCODEViewController.m
//  AvFoundation实现二维码扫描
//
//  Created by 舒少勇 on 15/10/7.
//  Copyright © 2015年 shushaoyong. All rights reserved.
//

#import "SYMYQRCODEViewController.h"

@interface SYMYQRCODEViewController ()
/**iconView**/
@property(nonatomic,weak)UIImageView *bgView;
@end

@implementation SYMYQRCODEViewController

#pragma mark  返回按钮的点击
- (void)backPreviousVC
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置白色背景
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(10, 20, 40, 40);
    button.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    [button setTitle:@"返回" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(backPreviousVC) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    //创建父视图
    CGFloat bgW = 300;
    CGFloat bgH = 300;
    CGFloat bgX = (self.view.bounds.size.width - bgW)*0.5;
    CGFloat bgY = (self.view.bounds.size.height - bgH)*0.5;
    UIImageView *bgView = [[UIImageView alloc] initWithFrame:CGRectMake(bgX, bgY, bgW, bgH)];
    //作为属性引用
    self.bgView = bgView;
    
    //设置图片
    bgView.image = [self createQRCodeImage] ;
    
    
    //添加
    [self.view addSubview:bgView];
    
}

- (UIImage*)createQRCodeImage
{
    //创建过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    //恢复默认设置
    [filter setDefaults];
    
    //给过滤器添加数据
    NSString *str = @"http://www.baidu.com";
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];
    
    //获取输出的二维码
    CIImage *outputImage = [filter outputImage];
    
    //获取高清的背景图
    UIImage  *bgImage = [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:self.bgView.frame.size.width];
    
    //创建头像
    UIImage *icon = [UIImage imageNamed:@"zapya_connect_radar"];
    
    //合并两种图片为一张图片
    return [self createNewImageWithBgImage:bgImage icon:icon];
}

/**
 生成二维码名片
 
 @param: bgImage   背景图片
 @param: iconImage 头像
 
  returns: 生成好的图片
 */
- (UIImage*)createNewImageWithBgImage:(UIImage *)bgImage icon:(UIImage*)icon
{
    //开启图形上下文
    UIGraphicsBeginImageContext(bgImage.size);
    
    //绘制背景图
    [bgImage drawInRect:CGRectMake(0, 0, bgImage.size.width, bgImage.size.height)];

    //预定义中间头像的尺寸
    CGFloat iconW = 50;
    CGFloat iconH = 50;
    CGFloat iconX = (bgImage.size.width - iconW)*0.5;
    CGFloat iconY = (bgImage.size.height - iconH)*0.5;
    //绘制头像
    [icon drawInRect:CGRectMake(iconX, iconY, iconW, iconH)];
    
    //获取会知道的图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    //关闭图形上下文
    UIGraphicsEndImageContext();
    
    //返回生成好的图片
    return newImage;
    
}


/**
 *  根据CIImage生成指定大小的UIImage
 *
 *  @param image CIImage
 *  @param size  图片宽度
 */
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    UIImage *newImage = [UIImage imageWithCGImage:scaledImage];
    //释放所有对象
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    CGImageRelease(scaledImage);
    CGColorSpaceRelease(cs);
    return  newImage;
}




@end
