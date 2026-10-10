#!/usr/bin/env python3
import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ASSETS_DIR = os.path.join(os.path.dirname(__file__), "..", "docs", "assets")
os.makedirs(ASSETS_DIR, exist_ok=True)

LOGO_PATH = os.path.join(ASSETS_DIR, "logo.png")
logo_img = Image.open(LOGO_PATH).convert("RGBA") if os.path.exists(LOGO_PATH) else None

def get_font(size, bold=False):
    # Try system Apple SF fonts or fall back to DejaVu / default
    candidates = [
        "/System/Library/Fonts/SFPro-Bold.otf" if bold else "/System/Library/Fonts/SFPro-Regular.otf",
        "/System/Library/Fonts/SFCompact-Bold.otf" if bold else "/System/Library/Fonts/SFCompact-Regular.otf",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf"
    ]
    for c in candidates:
        if os.path.exists(c):
            try:
                return ImageFont.truetype(c, size)
            except Exception:
                continue
    return ImageFont.load_default()

def draw_window_frame(draw, width, height, title="NovaPlayer"):
    # Mac borderless cinema window mockup with subtle border & traffic lights
    # Traffic lights
    draw.ellipse([24, 20, 36, 32], fill=(255, 95, 87, 240))
    draw.ellipse([44, 20, 56, 32], fill=(254, 188, 46, 240))
    draw.ellipse([64, 20, 76, 32], fill=(40, 200, 64, 240))
    
    font = get_font(14, bold=True)
    draw.text((88, 18), title, fill=(255, 255, 255, 210), font=font)

# 1. BANNER: 1200 x 480
def generate_banner():
    width, height = 1200, 480
    im = Image.new("RGBA", (width, height), (13, 15, 26, 255))
    draw = ImageDraw.Draw(im)

    # Cosmic glowing gradients
    for r in range(250, 0, -5):
        alpha = int(45 * (1 - r / 250))
        draw.ellipse([200 - r, 240 - r, 200 + r, 240 + r], fill=(60, 100, 240, alpha))
        draw.ellipse([900 - r, 180 - r, 900 + r, 180 + r], fill=(160, 60, 240, alpha))

    # Add logo
    if logo_img:
        logo_resized = logo_img.resize((190, 190), Image.Resampling.LANCZOS)
        im.paste(logo_resized, (120, 145), logo_resized)

    # Text
    title_font = get_font(56, bold=True)
    sub_font = get_font(24, bold=False)
    tag_font = get_font(16, bold=True)

    draw.text((360, 150), "NovaPlayer", fill=(255, 255, 255, 255), font=title_font)
    draw.text((360, 225), "The Modern, High-Performance Mac Video Player", fill=(200, 210, 245, 240), font=sub_font)
    draw.text((360, 265), "with YouTube-Style Ergonomics & Native AI Translation", fill=(140, 160, 210, 220), font=sub_font)

    # Pill tags
    tags = ["⚡ 0.05× Granular Speed", "⏩ 5s Seeking", "🎞️ Hover Frame Scrubber", "💬 Subtitles & Voice-Over"]
    x = 360
    for tag in tags:
        tw = len(tag) * 9 + 20
        draw.rounded_rectangle([x, 320, x + tw, 355], radius=18, fill=(255, 255, 255, 25), outline=(255, 255, 255, 45), width=1)
        draw.text((x + 12, 328), tag, fill=(230, 235, 255, 240), font=tag_font)
        x += tw + 14

    im.convert("RGB").save(os.path.join(ASSETS_DIR, "banner.png"), quality=95)
    print("Generated banner.png")

# 2. FEATURE: WELCOME SCREEN (1000 x 600)
def generate_feature_welcome():
    w, h = 1000, 600
    im = Image.new("RGBA", (w, h), (14, 16, 24, 255))
    draw = ImageDraw.Draw(im)

    draw_window_frame(draw, w, h, "NovaPlayer — Welcome")

    # Center Logo
    if logo_img:
        l = logo_img.resize((110, 110), Image.Resampling.LANCZOS)
        im.paste(l, (w//2 - 55, 110), l)

    f_title = get_font(32, bold=True)
    f_sub = get_font(16, bold=False)
    f_btn = get_font(15, bold=True)

    draw.text((w//2 - 85, 240), "NovaPlayer", fill=(255, 255, 255), font=f_title)
    draw.text((w//2 - 190, 285), "High-performance video player with YouTube-like ergonomics", fill=(160, 170, 195), font=f_sub)

    # Dashed drop zone box
    box = [w//2 - 250, 330, w//2 + 250, 480]
    draw.rounded_rectangle(box, radius=16, fill=(255, 255, 255, 12), outline=(90, 130, 240, 200), width=2)
    
    draw.text((w//2 - 130, 360), "Drag and drop any MP4, MOV, or M4V video here", fill=(220, 225, 245), font=f_sub)
    draw.text((w//2 - 8, 395), "or", fill=(140, 150, 180), font=f_sub)

    btn_box = [w//2 - 95, 425, w//2 + 95, 465]
    draw.rounded_rectangle(btn_box, radius=8, fill=(40, 110, 240, 230), outline=(255, 255, 255, 60), width=1)
    draw.text((w//2 - 75, 435), "Choose Video File…", fill=(255, 255, 255), font=f_btn)

    im.convert("RGB").save(os.path.join(ASSETS_DIR, "feature_welcome.png"), quality=95)
    print("Generated feature_welcome.png")

# 3. FEATURE: 0.05x SPEED DIAL & PRESETS
def generate_feature_speed():
    w, h = 1000, 600
    im = Image.new("RGBA", (w, h), (10, 11, 18, 255))
    draw = ImageDraw.Draw(im)

    # Background video simulation
    draw.rectangle([0, 0, w, h], fill=(22, 25, 38))
    for i in range(0, w, 40):
        draw.line([(i, 0), (i, h)], fill=(30, 34, 52), width=1)

    draw_window_frame(draw, w, h, "NovaPlayer — Interstellar_Trailer.mp4")

    # Center Popover for Speed
    pop_box = [w//2 - 160, 140, w//2 + 160, 460]
    draw.rounded_rectangle(pop_box, radius=16, fill=(28, 30, 42, 245), outline=(255, 255, 255, 40), width=1)

    f_head = get_font(18, bold=True)
    f_num = get_font(28, bold=True)
    f_body = get_font(14, bold=False)
    f_btn = get_font(13, bold=True)

    draw.text((pop_box[0] + 20, pop_box[1] + 20), "Playback Speed", fill=(255, 255, 255), font=f_head)
    draw.text((pop_box[1] + 195, pop_box[1] + 15), "1.15×", fill=(60, 150, 255), font=f_num)

    # Steppers
    st_y = pop_box[1] + 65
    draw.rounded_rectangle([pop_box[0] + 20, st_y, pop_box[0] + 105, st_y + 36], radius=6, fill=(45, 48, 65))
    draw.text((pop_box[0] + 32, st_y + 9), "− 0.05×", fill=(255, 255, 255), font=f_btn)

    draw.rounded_rectangle([pop_box[0] + 115, st_y, pop_box[0] + 205, st_y + 36], radius=6, fill=(45, 48, 65))
    draw.text((pop_box[0] + 128, st_y + 9), "Reset (1.0×)", fill=(200, 210, 235), font=f_btn)

    draw.rounded_rectangle([pop_box[0] + 215, st_y, pop_box[0] + 300, st_y + 36], radius=6, fill=(45, 48, 65))
    draw.text((pop_box[0] + 228, st_y + 9), "+ 0.05×", fill=(255, 255, 255), font=f_btn)

    # Slider bar
    sl_y = st_y + 55
    draw.line([(pop_box[0] + 20, sl_y + 10), (pop_box[0] + 300, sl_y + 10)], fill=(70, 75, 95), width=4)
    draw.line([(pop_box[0] + 20, sl_y + 10), (pop_box[0] + 150, sl_y + 10)], fill=(60, 150, 255), width=4)
    draw.ellipse([pop_box[0] + 144, sl_y + 4, pop_box[0] + 156, sl_y + 16], fill=(255, 255, 255))

    draw.text((pop_box[0] + 20, sl_y + 24), "0.25×", fill=(140, 150, 175), font=f_body)
    draw.text((pop_box[0] + 145, sl_y + 24), "1.0×", fill=(140, 150, 175), font=f_body)
    draw.text((pop_box[0] + 270, sl_y + 24), "3.0×", fill=(140, 150, 175), font=f_body)

    # Presets
    draw.line([(pop_box[0] + 20, sl_y + 55), (pop_box[0] + 300, sl_y + 55)], fill=(50, 55, 75), width=1)
    draw.text((pop_box[0] + 20, sl_y + 65), "Presets", fill=(150, 160, 185), font=f_body)

    presets = ["0.75×", "1.0×", "1.15×", "1.25×", "1.5×", "2.0×"]
    px = pop_box[0] + 20
    py = sl_y + 95
    for p in presets:
        is_active = p == "1.15×"
        bg = (60, 150, 255) if is_active else (45, 48, 65)
        fg = (255, 255, 255) if is_active else (190, 200, 225)
        draw.rounded_rectangle([px, py, px + 42, py + 28], radius=6, fill=bg)
        draw.text((px + 6, py + 6), p, fill=fg, font=f_btn)
        px += 48

    # Tip
    draw.text((pop_box[0] + 20, pop_box[3] - 40), "💡 Shortcut: Press [ and ] keys to adjust by 0.05×", fill=(150, 170, 210), font=get_font(11))

    # Bottom Player Bar
    draw.rectangle([0, h - 60, w, h], fill=(0, 0, 0, 200))
    draw.rectangle([20, h - 50, w - 20, h - 45], fill=(255, 255, 255, 60))
    draw.rectangle([20, h - 50, w * 0.38, h - 45], fill=(240, 40, 50, 255))
    draw.ellipse([w * 0.38 - 5, h - 53, w * 0.38 + 5, h - 42], fill=(255, 255, 255))

    im.convert("RGB").save(os.path.join(ASSETS_DIR, "feature_speed.png"), quality=95)
    print("Generated feature_speed.png")

# 4. FEATURE: HOVER FRAME PREVIEW & SCRUBBER
def generate_feature_hover():
    w, h = 1000, 600
    im = Image.new("RGBA", (w, h), (18, 20, 32, 255))
    draw = ImageDraw.Draw(im)

    draw_window_frame(draw, w, h, "NovaPlayer — Big_Buck_Bunny_4K.mp4")

    # Simulating movie scene
    draw.rectangle([0, 40, w, h - 70], fill=(25, 30, 48))
    draw.ellipse([w//2 - 180, 150, w//2 + 180, 450], fill=(45, 90, 160, 120))

    # Floating Thumbnail Preview Card above scrubber
    card_x = 420
    card_y = 350
    card_w, card_h = 210, 145

    draw.rounded_rectangle([card_x, card_y, card_x + card_w, card_y + card_h], radius=12, fill=(15, 17, 25, 245), outline=(255, 255, 255, 50), width=1)
    # Thumbnail frame inside
    draw.rounded_rectangle([card_x + 8, card_y + 8, card_x + card_w - 8, card_y + card_h - 35], radius=8, fill=(40, 70, 120))
    # Simulated thumbnail details
    draw.ellipse([card_x + 75, card_y + 35, card_x + 135, card_y + 85], fill=(80, 140, 220))
    
    # Timestamp badge inside card
    draw.rounded_rectangle([card_x + card_w//2 - 35, card_y + card_h - 28, card_x + card_w//2 + 35, card_y + card_h - 8], radius=10, fill=(0, 0, 0, 200))
    draw.text((card_x + card_w//2 - 22, card_y + card_h - 26), "04:12", fill=(255, 255, 255), font=get_font(13, bold=True))

    # Bottom Player Bar
    bar_y = h - 55
    draw.rectangle([0, h - 70, w, h], fill=(0, 0, 0, 220))
    draw.rectangle([30, bar_y, w - 30, bar_y + 6], fill=(255, 255, 255, 60))
    draw.rectangle([30, bar_y, 525, bar_y + 6], fill=(255, 255, 255, 110)) # hover trail
    draw.rectangle([30, bar_y, 350, bar_y + 6], fill=(240, 40, 50)) # played

    # Cursor line down from preview card
    draw.line([(525, card_y + card_h), (525, bar_y)], fill=(255, 255, 255, 160), width=1)
    draw.ellipse([521, bar_y - 1, 529, bar_y + 7], fill=(255, 255, 255))

    # Controls text
    draw.text((30, bar_y + 16), "▶  ⏪ 5s   ⏩ 5s   🔊   02:45 / 10:30", fill=(255, 255, 255), font=get_font(13))
    draw.text((w - 180, bar_y + 16), "💬   1.00×   ⛶", fill=(255, 255, 255), font=get_font(13))

    im.convert("RGB").save(os.path.join(ASSETS_DIR, "feature_hover.png"), quality=95)
    print("Generated feature_hover.png")

# 5. FEATURE: 5-SECOND SEEK & TRANSIENT HUD
def generate_feature_skip():
    w, h = 1000, 600
    im = Image.new("RGBA", (w, h), (16, 18, 28, 255))
    draw = ImageDraw.Draw(im)

    draw_window_frame(draw, w, h, "NovaPlayer — Movie_Scene.mp4")

    # Center transient HUD badge
    hud_w, hud_h = 170, 75
    hx, hy = w//2 - hud_w//2, h//2 - hud_h//2
    draw.rounded_rectangle([hx, hy, hx + hud_w, hy + hud_h], radius=18, fill=(0, 0, 0, 210), outline=(255, 255, 255, 40), width=1)

    draw.text((hx + 28, hy + 22), "⏩  +5s", fill=(255, 255, 255), font=get_font(26, bold=True))

    # Scrubber Bar
    draw.rectangle([0, h - 60, w, h], fill=(0, 0, 0, 200))
    draw.rectangle([30, h - 50, w - 30, h - 45], fill=(255, 255, 255, 60))
    draw.rectangle([30, h - 50, 480, h - 45], fill=(240, 40, 50))
    draw.ellipse([475, h - 53, 485, h - 42], fill=(255, 255, 255))

    draw.text((w//2 - 130, h - 120), "Press Left (← / J) or Right (→ / L) arrow keys", fill=(200, 210, 235), font=get_font(14))

    im.convert("RGB").save(os.path.join(ASSETS_DIR, "feature_skip.png"), quality=95)
    print("Generated feature_skip.png")

# 6. FEATURE: SUBTITLES & REAL-TIME VOICE-OVER DUBBING
def generate_feature_subtitles():
    w, h = 1000, 600
    im = Image.new("RGBA", (w, h), (18, 20, 30, 255))
    draw = ImageDraw.Draw(im)

    draw_window_frame(draw, w, h, "NovaPlayer — Presentation.mp4")

    # Movie canvas with translated subtitle pill
    sub_text = "Benvenuti in NovaPlayer: riproduzione video fluida e precisa."
    sub_font = get_font(18, bold=True)
    tw = len(sub_text) * 9 + 40
    sx = w//2 - tw//2
    sy = h - 140
    draw.rounded_rectangle([sx, sy, sx + tw, sy + 44], radius=10, fill=(0, 0, 0, 215), outline=(255, 255, 255, 45), width=1)
    draw.text((sx + 20, sy + 12), sub_text, fill=(255, 255, 255), font=sub_font)

    # Popover for Subtitles & Audio
    px, py = w - 340, 160
    pw, ph = 300, 340
    draw.rounded_rectangle([px, py, px + pw, py + ph], radius=14, fill=(26, 28, 40, 245), outline=(255, 255, 255, 45), width=1)

    f_title = get_font(16, bold=True)
    f_sub = get_font(13, bold=True)
    f_opt = get_font(13)

    draw.text((px + 18, py + 16), "Audio & Subtitles", fill=(255, 255, 255), font=f_title)
    draw.line([(px + 18, py + 42), (px + pw - 18, py + 42)], fill=(50, 55, 75))

    draw.text((px + 18, py + 55), "Subtitles Track", fill=(200, 210, 235), font=f_sub)
    draw.rounded_rectangle([px + 18, py + 78, px + pw - 18, py + 106], radius=6, fill=(40, 44, 60))
    draw.text((px + 28, py + 84), "sample.srt (External)", fill=(255, 255, 255), font=f_opt)

    draw.text((px + 18, py + 122), "Translate Subtitles To", fill=(200, 210, 235), font=f_sub)
    draw.rounded_rectangle([px + 18, py + 145, px + pw - 18, py + 173], radius=6, fill=(40, 44, 60))
    draw.text((px + 28, py + 151), "Italian (Italiano)  ✓", fill=(60, 160, 255), font=f_opt)

    draw.text((px + 18, py + 188), "Audio Language Track", fill=(200, 210, 235), font=f_sub)
    draw.rounded_rectangle([px + 18, py + 211, px + pw - 18, py + 239], radius=6, fill=(40, 44, 60))
    draw.text((px + 28, py + 217), "Audio Track 1 (Stereo)", fill=(255, 255, 255), font=f_opt)

    draw.line([(px + 18, py + 252), (px + pw - 18, py + 252)], fill=(50, 55, 75))
    draw.text((px + 18, py + 264), "Spoken Voice-Over Dub", fill=(255, 255, 255), font=f_sub)
    draw.text((px + 18, py + 286), "Speaks Italian lines via macOS speech", fill=(150, 160, 185), font=get_font(11))
    # Toggle on
    draw.rounded_rectangle([px + pw - 55, py + 268, px + pw - 18, py + 290], radius=11, fill=(40, 180, 75))
    draw.ellipse([px + pw - 38, py + 270, px + pw - 20, py + 288], fill=(255, 255, 255))

    im.convert("RGB").save(os.path.join(ASSETS_DIR, "feature_subtitles.png"), quality=95)
    print("Generated feature_subtitles.png")

# 7. FEATURE: SETTINGS & CUSTOMIZATION
def generate_feature_settings():
    w, h = 1000, 600
    im = Image.new("RGBA", (w, h), (14, 16, 26, 255))
    draw = ImageDraw.Draw(im)

    draw_window_frame(draw, w, h, "NovaPlayer — Preferences")

    # Center Settings Popover Card
    sx, sy = w//2 - 150, 110
    sw, sh = 300, 380
    draw.rounded_rectangle([sx, sy, sx + sw, sy + sh], radius=14, fill=(26, 28, 40, 245), outline=(255, 255, 255, 45), width=1)

    f_title = get_font(16, bold=True)
    f_sub = get_font(13, bold=True)
    f_opt = get_font(12)

    draw.text((sx + 18, sy + 18), "NovaPlayer Settings", fill=(255, 255, 255), font=f_title)
    draw.line([(sx + 18, sy + 44), (sx + sw - 18, sy + 44)], fill=(50, 55, 75))

    # Skip Interval Picker (3s | 5s | 10s | 15s | 30s)
    draw.text((sx + 18, sy + 58), "Skip Forward / Backward", fill=(200, 210, 235), font=f_sub)
    seg_x = sx + 18
    intervals = ["3s", "5s", "10s", "15s", "30s"]
    for i, s in enumerate(intervals):
        is_sel = s == "5s"
        bg = (60, 140, 240) if is_sel else (40, 44, 60)
        draw.rectangle([seg_x, sy + 82, seg_x + 52, sy + 108], fill=bg)
        draw.text((seg_x + 16, sy + 88), s, fill=(255, 255, 255), font=f_opt)
        seg_x += 53

    # Speed Granularity (0.01x | 0.02x | 0.05x | 0.10x)
    draw.text((sx + 18, sy + 130), "Speed Step Increment", fill=(200, 210, 235), font=f_sub)
    seg_x = sx + 18
    steps = ["0.01×", "0.02×", "0.05×", "0.10×"]
    for i, st in enumerate(steps):
        is_sel = st == "0.05×"
        bg = (60, 140, 240) if is_sel else (40, 44, 60)
        draw.rectangle([seg_x, sy + 154, seg_x + 65, sy + 180], fill=bg)
        draw.text((seg_x + 14, sy + 160), st, fill=(255, 255, 255), font=f_opt)
        seg_x += 66

    draw.line([(sx + 18, sy + 210), (sx + sw - 18, sy + 210)], fill=(50, 55, 75))

    # Hover previews toggle
    draw.text((sx + 18, sy + 225), "Timeline Frame Previews", fill=(255, 255, 255), font=f_sub)
    draw.text((sx + 18, sy + 245), "Show preview thumbnails when hovering", fill=(140, 150, 175), font=get_font(11))
    draw.rounded_rectangle([sx + sw - 55, sy + 228, sx + sw - 18, sy + 250], radius=11, fill=(40, 180, 75))
    draw.ellipse([sx + sw - 38, sy + 230, sx + sw - 20, sy + 248], fill=(255, 255, 255))

    # Auto-hide slider
    draw.text((sx + 18, sy + 280), "Auto-Hide Controls Delay", fill=(255, 255, 255), font=f_sub)
    draw.text((sx + sw - 50, sy + 280), "2.5s", fill=(160, 170, 200), font=f_opt)
    draw.line([(sx + 18, sy + 310), (sx + sw - 18, sy + 310)], fill=(60, 65, 85), width=3)
    draw.line([(sx + 18, sy + 310), (sx + 140, sy + 310)], fill=(60, 140, 240), width=3)
    draw.ellipse([sx + 134, sy + 304, sx + 146, sy + 316], fill=(255, 255, 255))

    im.convert("RGB").save(os.path.join(ASSETS_DIR, "feature_settings.png"), quality=95)
    print("Generated feature_settings.png")

if __name__ == "__main__":
    generate_banner()
    generate_feature_welcome()
    generate_feature_speed()
    generate_feature_hover()
    generate_feature_skip()
    generate_feature_subtitles()
    generate_feature_settings()
    print("All doc visual assets successfully created in docs/assets/")
