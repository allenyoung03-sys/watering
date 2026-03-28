#!/usr/bin/env python3
"""
生成三个App图标优化方案的预览图
"""

import sys
import os
from PIL import Image, ImageDraw, ImageFilter
import math

def draw_plant(draw, center, size, leaf_color):
    """绘制植物轮廓（更精致的版本）"""
    # 绘制主茎
    stem_width = int(size * 0.08)
    stem_height = int(size * 0.4)
    stem_top = center[1] - stem_height // 2
    stem_bottom = center[1] + stem_height // 2
    
    draw.rectangle([center[0] - stem_width // 2, stem_top,
                    center[0] + stem_width // 2, stem_bottom],
                   fill=leaf_color, outline=leaf_color)
    
    # 绘制更精致的叶子
    leaf_size = int(size * 0.25)
    
    # 左侧叶子（更自然的形状）
    left_leaf = [
        (center[0] - stem_width // 2, stem_top + leaf_size // 3),
        (center[0] - stem_width // 2 - leaf_size, stem_top - leaf_size // 6),
        (center[0] - stem_width // 2 - leaf_size // 2, stem_top - leaf_size // 3),
        (center[0] - stem_width // 2, stem_top - leaf_size // 6)
    ]
    draw.polygon(left_leaf, fill=leaf_color, outline=leaf_color)
    
    # 右侧叶子
    right_leaf = [
        (center[0] + stem_width // 2, stem_top + leaf_size // 3),
        (center[0] + stem_width // 2 + leaf_size, stem_top - leaf_size // 6),
        (center[0] + stem_width // 2 + leaf_size // 2, stem_top - leaf_size // 3),
        (center[0] + stem_width // 2, stem_top - leaf_size // 6)
    ]
    draw.polygon(right_leaf, fill=leaf_color, outline=leaf_color)
    
    # 顶部叶子（更优雅的形状）
    top_leaf = [
        (center[0], stem_top - leaf_size // 1.2),
        (center[0] - leaf_size // 1.8, stem_top - leaf_size // 4),
        (center[0] - leaf_size // 3.6, stem_top - leaf_size // 3),
        (center[0] + leaf_size // 3.6, stem_top - leaf_size // 3),
        (center[0] + leaf_size // 1.8, stem_top - leaf_size // 4)
    ]
    draw.polygon(top_leaf, fill=leaf_color, outline=leaf_color)

def create_scheme1_gradient_background(size=512):
    """方案一：渐变背景优化"""
    img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    radius = size // 2 - 30
    
    # 创建渐变背景（从浅绿到更浅的绿）
    for y in range(size):
        for x in range(size):
            dist = math.sqrt((x - center) ** 2 + (y - center) ** 2)
            if dist <= radius:
                # 渐变：中心较深，边缘较浅
                ratio = dist / radius
                r = int(232 - 20 * ratio)  # #E8F5E9 -> 更浅
                g = int(245 - 25 * ratio)
                b = int(233 - 20 * ratio)
                draw.point((x, y), fill=(r, g, b, 255))
    
    # 绘制水滴（带高光效果）
    drop_radius = radius * 0.5
    drop_top = center - int(drop_radius * 0.7)
    drop_bottom = center + int(drop_radius * 0.8)
    
    # 水滴主体
    draw.ellipse([center - drop_radius, drop_top,
                  center + drop_radius, drop_bottom],
                 fill=(33, 150, 243, 255))  # 蓝色 #2196F3
    
    # 水滴尖端
    tip_radius = drop_radius * 0.3
    tip_top = drop_top - tip_radius // 2
    draw.ellipse([center - tip_radius, tip_top,
                  center + tip_radius, tip_top + tip_radius * 2],
                 fill=(33, 150, 243, 255))
    
    # 水滴高光
    highlight_radius = drop_radius * 0.2
    highlight_x = center - drop_radius * 0.3
    highlight_y = drop_top + drop_radius * 0.3
    draw.ellipse([highlight_x - highlight_radius, highlight_y - highlight_radius,
                  highlight_x + highlight_radius, highlight_y + highlight_radius],
                 fill=(100, 180, 255, 180))
    
    # 绘制精致的植物轮廓
    draw_plant(draw, (center, center), drop_radius * 1.8, (255, 255, 255, 255))
    
    # 柔和的阴影边框
    border_width = 3
    draw.ellipse([center - radius - border_width, center - radius - border_width,
                  center + radius + border_width, center + radius + border_width],
                 outline=(200, 230, 200, 150), width=border_width)
    
    return img

def create_scheme2_3d_effect(size=512):
    """方案二：立体感增强"""
    img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    radius = size // 2 - 30
    
    # 绘制立体圆形背景（带内阴影）
    # 主圆形
    draw.ellipse([center - radius, center - radius,
                  center + radius, center + radius],
                 fill=(232, 245, 233, 255))
    
    # 内阴影（顶部）
    for i in range(10):
        shadow_radius = radius - i
        alpha = 30 - i * 3
        if alpha > 0:
            draw.ellipse([center - shadow_radius, center - shadow_radius - 2,
                          center + shadow_radius, center + shadow_radius - 2],
                         outline=(200, 220, 200, alpha), width=1)
    
    # 绘制立体水滴
    drop_radius = radius * 0.5
    drop_top = center - int(drop_radius * 0.7)
    drop_bottom = center + int(drop_radius * 0.8)
    
    # 水滴主体（带渐变）
    for y in range(drop_top, drop_bottom):
        for x in range(center - int(drop_radius), center + int(drop_radius)):
            dist_x = abs(x - center) / drop_radius
            dist_y = (y - drop_top) / (drop_bottom - drop_top)
            
            if dist_x**2 + (dist_y*0.8)**2 <= 1:  # 椭圆方程
                # 创建立体效果：顶部较亮，底部较暗
                brightness = 1.0 - dist_y * 0.3
                r = int(33 * brightness)
                g = int(150 * brightness)
                b = int(243 * brightness)
                draw.point((x, y), fill=(r, g, b, 255))
    
    # 水滴尖端
    tip_radius = drop_radius * 0.3
    tip_top = drop_top - tip_radius // 2
    draw.ellipse([center - tip_radius, tip_top,
                  center + tip_radius, tip_top + tip_radius * 2],
                 fill=(33, 150, 243, 255))
    
    # 水滴高光（更明显）
    highlight_radius = drop_radius * 0.25
    highlight_x = center - drop_radius * 0.25
    highlight_y = drop_top + drop_radius * 0.4
    draw.ellipse([highlight_x - highlight_radius, highlight_y - highlight_radius,
                  highlight_x + highlight_radius, highlight_y + highlight_radius],
                 fill=(150, 210, 255, 200))
    
    # 绘制精致的植物轮廓
    draw_plant(draw, (center, center), drop_radius * 1.8, (255, 255, 255, 240))
    
    # 外阴影效果
    for i in range(5):
        shadow_radius = radius + 5 + i
        alpha = 40 - i * 8
        draw.ellipse([center - shadow_radius, center - shadow_radius + 2,
                      center + shadow_radius, center + shadow_radius + 2],
                     outline=(180, 200, 180, alpha), width=1)
    
    return img

def create_scheme3_minimalist(size=512):
    """方案三：简化现代风格"""
    img = Image.new('RGBA', (size, size), (245, 250, 245, 255))  # 非常浅的绿背景
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    radius = size // 2 - 40
    
    # 极简圆形背景（无边框）
    draw.ellipse([center - radius, center - radius,
                  center + radius, center + radius],
                 fill=(240, 248, 240, 255))  # 比背景稍深的绿
    
    # 简化水滴（纯色，无高光）
    drop_radius = radius * 0.45
    drop_top = center - int(drop_radius * 0.6)
    drop_bottom = center + int(drop_radius * 0.7)
    
    # 水滴主体（更现代的蓝色）
    draw.ellipse([center - drop_radius, drop_top,
                  center + drop_radius, drop_bottom],
                 fill=(41, 128, 185, 255))  # 更现代的蓝色
    
    # 水滴尖端
    tip_radius = drop_radius * 0.25
    tip_top = drop_top - tip_radius // 3
    draw.ellipse([center - tip_radius, tip_top,
                  center + tip_radius, tip_top + tip_radius * 1.5],
                 fill=(41, 128, 185, 255))
    
    # 极简植物轮廓（线条风格）
    plant_size = drop_radius * 1.5
    stem_width = int(plant_size * 0.06)
    stem_height = int(plant_size * 0.35)
    
    # 主茎
    draw.rectangle([center - stem_width // 2, center - stem_height // 2,
                    center + stem_width // 2, center + stem_height // 2],
                   fill=(255, 255, 255, 255))
    
    # 简化叶子（三角形）
    leaf_size = int(plant_size * 0.2)
    
    # 左侧叶子
    left_leaf = [
        (center - stem_width // 2, center - stem_height // 4),
        (center - stem_width // 2 - leaf_size, center - stem_height // 3),
        (center - stem_width // 2, center)
    ]
    draw.polygon(left_leaf, fill=(255, 255, 255, 255))
    
    # 右侧叶子
    right_leaf = [
        (center + stem_width // 2, center - stem_height // 4),
        (center + stem_width // 2 + leaf_size, center - stem_height // 3),
        (center + stem_width // 2, center)
    ]
    draw.polygon(right_leaf, fill=(255, 255, 255, 255))
    
    # 顶部叶子
    top_leaf = [
        (center, center - stem_height // 2 - leaf_size // 2),
        (center - leaf_size // 2, center - stem_height // 2),
        (center + leaf_size // 2, center - stem_height // 2)
    ]
    draw.polygon(top_leaf, fill=(255, 255, 255, 255))
    
    # 极细边框
    border_width = 1
    draw.ellipse([center - radius - border_width, center - radius - border_width,
                  center + radius + border_width, center + radius + border_width],
                 outline=(220, 235, 220, 255), width=border_width)
    
    return img

def generate_previews():
    """生成所有预览图"""
    print("开始生成三个方案的预览图...")
    
    # 创建输出目录
    output_dir = "icon_previews"
    os.makedirs(output_dir, exist_ok=True)
    
    # 生成方案一：渐变背景优化
    scheme1 = create_scheme1_gradient_background(512)
    scheme1.save(os.path.join(output_dir, "scheme1_gradient.png"), "PNG")
    print("生成: scheme1_gradient.png")
    
    # 生成方案二：立体感增强
    scheme2 = create_scheme2_3d_effect(512)
    scheme2.save(os.path.join(output_dir, "scheme2_3d.png"), "PNG")
    print("生成: scheme2_3d.png")
    
    # 生成方案三：简化现代风格
    scheme3 = create_scheme3_minimalist(512)
    scheme3.save(os.path.join(output_dir, "scheme3_minimalist.png"), "PNG")
    print("生成: scheme3_minimalist.png")
    
    # 生成当前图标作为对比
    from generate_icon import create_app_icon
    current = create_app_icon(512)
    current.save(os.path.join(output_dir, "current_design.png"), "PNG")
    print("生成: current_design.png（当前设计作为对比）")
    
    print(f"\n所有预览图已保存到 '{output_dir}' 目录")
    print("方案一：渐变背景优化 (scheme1_gradient.png)")
    print("方案二：立体感增强 (scheme2_3d.png)")
    print("方案三：简化现代风格 (scheme3_minimalist.png)")
    print("当前设计：作为对比 (current_design.png)")

if __name__ == "__main__":
    # 检查PIL是否安装
    try:
        from PIL import Image, ImageDraw, ImageFilter
    except ImportError:
        print("错误: 需要安装Pillow库")
        print("请运行: pip3 install Pillow")
        sys.exit(1)
    
    generate_previews()
