//
//  TestViewController.m
//  渐变色
//
//  Created by 陈双林 on 17/4/9.
//  Copyright © 2017年 Ugiant. All rights reserved.
//

#import "TestViewController.h"

#define H_sgc_image 4  //渐变彩色滑竿的高度

@interface TestViewController ()
@property (weak, nonatomic) IBOutlet UISlider *colorSlider;
@property (strong, nonatomic) UIImage * sliderGradientColorImage;
@property (strong, nonatomic) UIImageView * bulbImageView;
@end

@implementation TestViewController

/* 实现思路
 * 1、创建slider，添加到self.view
 * 2、将slider的进度条颜色设置为透明
 * 3、绘制一张和slider进度条同样大小的图片，并且绘制七彩渐变色，插入到slider视图下面，充当slider进度条假象
 * 4、当slider滑动时，将进度转换为上面绘制的图片上的坐标，然后计算出图片上这一点的颜色
 * 5、绘制灯泡轮廓，从第4步拿到滑到的颜色，填充灯泡内部的渐变色，并且处理渐变色不超出灯泡底部的螺纹
 * 6、最后设置灯泡外围的阴影色，外围的阴影色是包含了灯泡底部螺纹的
 */

/*
 * 问题一、由于滑动时，只要slider的value有变化，就进行了灯泡的重绘，可不可以只改变渐变颜色？
 * 问题二、可能是由于问题一，如果是一直滑着玩，内存会涨
 */

- (UIImageView *)bulbImageView{
    if (!_bulbImageView) {
        _bulbImageView = [UIImageView new];
        [self.view addSubview:_bulbImageView];
    }
    return _bulbImageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self drawGradientColorImage];
    [self drawBulbWithColor:[UIColor yellowColor]];
}

#pragma mark -----绘制滑竿渐变彩色图片----
- (void)drawGradientColorImage{
    CGSize imageSize = CGSizeMake(CGRectGetWidth(self.colorSlider.bounds), H_sgc_image);
    //开始绘制图片
    UIGraphicsBeginImageContext(imageSize);
    //创建CGContextRef上下文
    CGContextRef gcr = UIGraphicsGetCurrentContext();
    //创建CGMutablePathRef可变路径
    CGMutablePathRef path = CGPathCreateMutable();
    //绘制Path路径
    CGRect rect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGPathAddLineToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(rect), CGRectGetMinY(rect));
    //关闭绘制路径
    CGPathCloseSubpath(path);
    
    //↓↓↓↓↓↓↓↓↓↓↓↓↓绘制渐变色↓↓↓↓↓↓↓↓↓↓↓↓↓
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //渐变颜色值
    NSArray *colors = @[(__bridge id)[UIColor redColor].CGColor,
                        (__bridge id)[UIColor orangeColor].CGColor,
                        (__bridge id)[UIColor yellowColor].CGColor,
                        (__bridge id)[UIColor greenColor].CGColor,
                        (__bridge id)[UIColor cyanColor].CGColor,
                        (__bridge id)[UIColor blueColor].CGColor,
                        (__bridge id)[UIColor purpleColor].CGColor];
    //颜色渐变范围
    CGFloat locations[] = { 0.0,1/6.0,2/6.0,3/6.0,4/6.0,5/6.0,1.0 };
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    CGRect pathRect = CGPathGetBoundingBox(path);
    //渐变方向
    CGPoint startPoint = CGPointMake(CGRectGetMinX(pathRect), CGRectGetMidY(pathRect));
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(pathRect), CGRectGetMidY(pathRect));
    //添加绘制
    CGContextSaveGState(gcr);
    CGContextAddPath(gcr, path);
    CGContextClip(gcr);
    CGContextDrawLinearGradient(gcr, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(gcr);
    //释放
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    //↑↑↑↑↑↑↑↑↑↑↑↑↑↑绘制渐变色↑↑↑↑↑↑↑↑↑↑↑↑↑
    
    //注意释放CGMutablePathRef
    CGPathRelease(path);
    //从Context中获取图像，并显示在界面上
    self.sliderGradientColorImage = UIGraphicsGetImageFromCurrentImageContext();
    //图片绘制结束
    UIGraphicsEndImageContext();
    
    //创建imageview，插入到slider下面，，显示绘制的渐变颜色图片
    UIImageView * imageView = [[UIImageView alloc] initWithImage:self.sliderGradientColorImage];
    imageView.frame = CGRectMake(CGRectGetMinX(self.colorSlider.frame), self.colorSlider.center.y-H_sgc_image/2.0, self.sliderGradientColorImage.size.width, self.sliderGradientColorImage.size.height);
    [self.view insertSubview:imageView belowSubview:self.colorSlider];
    
}

#pragma mark ------绘制灯泡并初始化灯泡渐变色
- (void)drawBulbWithColor:(UIColor *)color {
    //创建CGContextRef
    UIGraphicsBeginImageContext(self.view.bounds.size);
    CGContextRef gcr = UIGraphicsGetCurrentContext();
    //创建CGMutablePathRef
    UIBezierPath *bagPath = [UIBezierPath bezierPath];
    
    CGPoint basePoint = CGPointMake(self.view.bounds.size.width/2, 100);
    CGFloat radius = 80;
    
    [bagPath addArcWithCenter:CGPointMake(basePoint.x, basePoint.y+radius) radius:radius startAngle:M_PI endAngle:0 clockwise:YES];
    
    [bagPath moveToPoint:CGPointMake(basePoint.x-radius, basePoint.y+radius)];
    
    [bagPath addQuadCurveToPoint:CGPointMake(basePoint.x-0.6*radius, basePoint.y+2*radius) controlPoint:CGPointMake(basePoint.x-radius, basePoint.y+1.4*radius)];
    
    [bagPath addCurveToPoint:CGPointMake(basePoint.x-0.35*radius, basePoint.y+2.8*radius) controlPoint1:CGPointMake(basePoint.x-0.4*radius,basePoint.y+ 2.3*radius) controlPoint2:CGPointMake(basePoint.x-0.6*radius, basePoint.y+2.7*radius)];
    [bagPath addLineToPoint:CGPointMake(basePoint.x-0.35*radius, basePoint.y+3.2*radius)];
    [bagPath addLineToPoint:CGPointMake(basePoint.x, basePoint.y+3.4*radius)];
    [bagPath addLineToPoint:CGPointMake(basePoint.x+0.35*radius, basePoint.y+3.2*radius)];
    [bagPath addLineToPoint:CGPointMake(basePoint.x+0.35*radius, basePoint.y+2.8*radius)];
    
    [bagPath addCurveToPoint:CGPointMake(basePoint.x+0.6*radius, basePoint.y+2*radius) controlPoint1:CGPointMake(basePoint.x+0.6*radius, basePoint.y+2.7*radius) controlPoint2:CGPointMake(basePoint.x+0.4*radius,basePoint.y+ 2.3*radius)];
    [bagPath addQuadCurveToPoint:CGPointMake(basePoint.x+radius, basePoint.y+radius) controlPoint:CGPointMake(basePoint.x+radius, basePoint.y+1.4*radius)];

    //将CGMutablePathRef添加到当前Context内
    CGContextAddPath(gcr, bagPath.CGPath);
    //设置绘图属性
    [[UIColor redColor] setStroke];
    //执行绘画
    CGContextStrokePath(gcr);
    
    //绘制渐变
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = @[(__bridge id) [UIColor whiteColor].CGColor, (__bridge id) color.CGColor];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    CGPoint center = CGPointMake(basePoint.x, basePoint.y+2.8*radius/2);
    
    CGContextSaveGState(gcr);
    CGContextAddPath(gcr, bagPath.CGPath);
    CGContextEOClip(gcr);
    CGContextDrawRadialGradient(gcr, gradient, center, 0, center, 1.4*radius, 0);
    
    CGContextRestoreGState(gcr);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    //从Context中获取图像，并显示在界面上
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.bulbImageView.image = img;
    self.bulbImageView.frame = CGRectMake(0, 0, img.size.width, img.size.height);
    self.bulbImageView.layer.shadowColor = color.CGColor;
    self.bulbImageView.layer.shadowRadius = 10;
    self.bulbImageView.layer.shadowOpacity = 0.9;
    self.bulbImageView.layer.shadowOffset = CGSizeMake(0, 0);

}


- (IBAction)changeColor:(UISlider *)sender {
    CGFloat location = CGRectGetWidth(sender.bounds)*sender.value;
    //当滑到1时，会达到一个临界值，此时计算的颜色会变成错误的纯红色，做下处理，让滑竿达不到临界值
    location == CGRectGetWidth(sender.bounds)?(location = CGRectGetWidth(sender.bounds)-1):location;
        CGPoint sliderPoint = CGPointMake(location, 1);
    UIColor * color = [self getPixelColorAtLocation:sliderPoint withImage:self.sliderGradientColorImage];
    [self drawBulbWithColor:color];
    
}

//获取图片上某一点的颜色
- (UIColor *)getPixelColorAtLocation:(CGPoint)point withImage:(UIImage*)image{
    UIColor * color = nil;
    CGImageRef inImage = image.CGImage;
    CGContextRef cgctx = [self createARGBBitmapContextFromImage:inImage];
    if (cgctx == NULL) { return nil;  }
    
    size_t w = CGImageGetWidth(inImage);
    size_t h = CGImageGetHeight(inImage);
    CGRect rect = {{0,0},{w,h}};
    
    CGContextDrawImage(cgctx, rect, inImage);
    
    unsigned char * data = CGBitmapContextGetData(cgctx);
    if (data != NULL) {
        @try {
            int offset = 4*((w*round(point.y))+round(point.x));
            int alpha =  data[offset];
            int red = data[offset+1];
            int green = data[offset+2];
            int blue = data[offset+3];
            NSLog(@"offset: %i colors: RGB A %i %i %i  %i",offset,red,green,blue,alpha);
            color = [UIColor colorWithRed:(red/255.0f) green:(green/255.0f) blue:(blue/255.0f) alpha:(alpha/255.0f)];
        }
        @catch (NSException * e) {
            NSLog(@"%@",[e reason]);
        }
        @finally {
            
        }
    }
    return color;
}

- (CGContextRef)createARGBBitmapContextFromImage:(CGImageRef)inImage {
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    void * bitmapData;
    unsigned long bitmapByteCount;
    unsigned long bitmapBytesPerRow;
    
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    
    bitmapBytesPerRow = (pixelsWide * 4);
    bitmapByteCount = (bitmapBytesPerRow * pixelsHigh);
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (colorSpace == NULL){
        fprintf(stderr, "Error allocating color spacen");
        return NULL;
    }
    
    bitmapData = malloc(bitmapByteCount);
    if (bitmapData == NULL){
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedFirst);
    if (context == NULL){
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
    CGColorSpaceRelease(colorSpace);
    return context;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
