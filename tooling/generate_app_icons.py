#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SOURCE = ROOT / "image.png"
APPLE_BG = (12, 12, 11, 255)
MASKABLE_BG = (12, 12, 11, 255)


def render_square(
    source: Image.Image,
    size: int,
    *,
    padding: float = 0.0,
    background: tuple[int, int, int, int] | None = None,
) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), background or (0, 0, 0, 0))
    max_content = int(size * (1 - (padding * 2)))
    resized = source.copy()
    resized.thumbnail((max_content, max_content), Image.Resampling.LANCZOS)
    left = (size - resized.width) // 2
    top = (size - resized.height) // 2
    canvas.alpha_composite(resized, (left, top))
    return canvas


def flatten(image: Image.Image, background: tuple[int, int, int, int]) -> Image.Image:
    base = Image.new("RGBA", image.size, background)
    base.alpha_composite(image)
    return base.convert("RGB")


def write_png(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG")


def generate_android(source: Image.Image) -> None:
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for directory, size in android_sizes.items():
        output = ROOT / "android" / "app" / "src" / "main" / "res" / directory / "ic_launcher.png"
        write_png(output, render_square(source, size))


def generate_ios(source: Image.Image) -> None:
    contents_path = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / "Contents.json"
    contents = json.loads(contents_path.read_text())
    for item in contents["images"]:
        filename = item.get("filename")
        if not filename:
            continue
        size = float(item["size"].split("x")[0])
        scale = int(item["scale"].rstrip("x"))
        pixel_size = int(round(size * scale))
        rendered = render_square(source, pixel_size, padding=0.08, background=APPLE_BG)
        write_png(contents_path.parent / filename, flatten(rendered, APPLE_BG))


def generate_macos(source: Image.Image) -> None:
    contents_path = ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / "Contents.json"
    contents = json.loads(contents_path.read_text())
    for item in contents["images"]:
        filename = item.get("filename")
        if not filename:
            continue
        size = float(item["size"].split("x")[0])
        scale = int(item["scale"].rstrip("x"))
        pixel_size = int(round(size * scale))
        rendered = render_square(source, pixel_size, padding=0.08, background=APPLE_BG)
        write_png(contents_path.parent / filename, flatten(rendered, APPLE_BG))


def generate_web(source: Image.Image) -> None:
    write_png(ROOT / "web" / "favicon.png", render_square(source, 32))
    write_png(ROOT / "web" / "icons" / "Icon-192.png", render_square(source, 192))
    write_png(ROOT / "web" / "icons" / "Icon-512.png", render_square(source, 512))
    write_png(
        ROOT / "web" / "icons" / "Icon-maskable-192.png",
        render_square(source, 192, padding=0.12, background=MASKABLE_BG),
    )
    write_png(
        ROOT / "web" / "icons" / "Icon-maskable-512.png",
        render_square(source, 512, padding=0.12, background=MASKABLE_BG),
    )


def generate_windows(source: Image.Image) -> None:
    output = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    output.parent.mkdir(parents=True, exist_ok=True)
    sizes = [16, 24, 32, 48, 64, 128, 256]
    master = render_square(source, 256)
    master.save(output, format="ICO", sizes=[(size, size) for size in sizes])


def generate_linux(source: Image.Image) -> None:
    output = ROOT / "linux" / "runner" / "resources" / "app_icon.png"
    write_png(output, render_square(source, 256))


def main() -> None:
    source_path = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else DEFAULT_SOURCE
    if not source_path.exists():
        raise SystemExit(f"Missing icon source: {source_path}")
    source = Image.open(source_path).convert("RGBA")
    generate_android(source)
    generate_ios(source)
    generate_macos(source)
    generate_web(source)
    generate_windows(source)
    generate_linux(source)
    print(f"Generated app icons from {source_path}")


if __name__ == "__main__":
    main()
