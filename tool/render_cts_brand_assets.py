#!/usr/bin/env python3
"""Render CTS logo and Android icon assets from a generated mark source.

Run with the bundled Codex Python runtime or any Python that has Pillow:

    python tool/render_cts_brand_assets.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
MARK_SOURCE = ROOT / "assets/logo/cts_mark_source.png"
LOGO_OUT = ROOT / "assets/logo/cts_logo.png"
ICON_OUT = ROOT / "assets/logo/cts_app_icon.png"

PUBLIC_SANS_BOLD = ROOT / "assets/fonts/PublicSans-Bold.ttf"

NAVY = (10, 32, 79, 255)
BLUE = (0, 113, 183, 255)
WHITE = (255, 255, 255, 255)
OFF_WHITE = (248, 250, 252, 255)
STROKE = (226, 232, 240, 255)

MIPMAP_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def main() -> None:
    mark = _load_mark()
    _render_horizontal_logo(mark)
    icon = _render_icon(mark, 1024)
    ICON_OUT.write_bytes(_encode_png(icon))

    for folder, size in MIPMAP_SIZES.items():
        out = ROOT / f"android/app/src/main/res/{folder}/ic_launcher.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        resized = icon.resize((size, size), Image.Resampling.LANCZOS)
        out.write_bytes(_encode_png(resized))


def _load_mark() -> Image.Image:
    source = Image.open(MARK_SOURCE).convert("RGBA")
    bbox = _colored_bbox(source)
    cropped = source.crop(_pad_bbox(bbox, source.size, 22))

    # The generated source is intentionally on white. Convert that white field
    # to alpha so it can sit cleanly on icon and banner backgrounds.
    data = []
    pixels = (
        cropped.get_flattened_data()
        if hasattr(cropped, "get_flattened_data")
        else cropped.getdata()
    )
    for r, g, b, a in pixels:
        distance_from_white = max(255 - r, 255 - g, 255 - b)
        if distance_from_white < 18:
            data.append((255, 255, 255, 0))
        else:
            alpha = min(255, max(0, int((distance_from_white - 18) * 3.6)))
            data.append((r, g, b, min(a, alpha)))
    cropped.putdata(data)
    return cropped


def _render_horizontal_logo(mark: Image.Image) -> None:
    canvas = Image.new("RGBA", (1400, 420), WHITE)
    draw = ImageDraw.Draw(canvas)

    mark_box = 310
    mark_img = _fit(mark, mark_box, mark_box)
    canvas.alpha_composite(mark_img, (78, (canvas.height - mark_img.height) // 2))

    x = 400
    combined_font = ImageFont.truetype(str(PUBLIC_SANS_BOLD), 142)
    services_font = ImageFont.truetype(str(PUBLIC_SANS_BOLD), 74)

    _draw_tracking_text(
        draw,
        (x, 94),
        "COMBINED",
        combined_font,
        NAVY,
        tracking=-5,
    )
    _draw_tracking_text(
        draw,
        (x + 5, 254),
        "TECHNICAL SERVICES",
        services_font,
        BLUE,
        tracking=3,
    )
    LOGO_OUT.write_bytes(_encode_png(canvas))


def _render_icon(mark: Image.Image, size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), WHITE)
    draw = ImageDraw.Draw(canvas)

    margin = 70
    draw.rounded_rectangle(
        (margin, margin, size - margin, size - margin),
        radius=190,
        fill=OFF_WHITE,
        outline=STROKE,
        width=6,
    )

    mark_img = _fit(mark, 720, 720)
    canvas.alpha_composite(
        mark_img,
        ((size - mark_img.width) // 2, (size - mark_img.height) // 2 - 2),
    )
    return canvas


def _colored_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    min_x, min_y = image.width, image.height
    max_x, max_y = 0, 0
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = image.getpixel((x, y))
            if a > 0 and not (r > 238 and g > 238 and b > 238):
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if min_x >= max_x or min_y >= max_y:
        raise RuntimeError(f"Unable to find colored mark pixels in {MARK_SOURCE}")
    return min_x, min_y, max_x + 1, max_y + 1


def _pad_bbox(
    bbox: tuple[int, int, int, int],
    image_size: tuple[int, int],
    pad: int,
) -> tuple[int, int, int, int]:
    left, top, right, bottom = bbox
    width, height = image_size
    return (
        max(0, left - pad),
        max(0, top - pad),
        min(width, right + pad),
        min(height, bottom + pad),
    )


def _fit(image: Image.Image, max_width: int, max_height: int) -> Image.Image:
    ratio = min(max_width / image.width, max_height / image.height)
    size = (round(image.width * ratio), round(image.height * ratio))
    return image.resize(size, Image.Resampling.LANCZOS)


def _draw_tracking_text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    text: str,
    font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int, int],
    tracking: int,
) -> None:
    x, y = xy
    for char in text:
        draw.text((x, y), char, font=font, fill=fill)
        x += round(draw.textlength(char, font=font)) + tracking


def _encode_png(image: Image.Image) -> bytes:
    from io import BytesIO

    output = BytesIO()
    image.save(output, format="PNG", optimize=True)
    return output.getvalue()


if __name__ == "__main__":
    main()
