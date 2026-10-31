# hbg-hdr-glow

让普通视频在 iPhone 等 HDR 屏幕上"发光"的 Claude Code skill / 命令行脚本。

刷社交网络时，有些视频一出现就特别亮、周围界面却暗了下去。拆开这类视频会发现，它们的像素亮度并不比普通视频高，只是文件里带着 **HLG / BT.2020** 的 HDR 色彩标签。手机看到这个标签，就会把高光显示到比界面"白色"还亮的程度。

这个工具帮你一步完成这件事。

## 安装

需要 [ffmpeg](https://ffmpeg.org/)（macOS：`brew install ffmpeg`）。

作为 Claude Code skill 使用：

```bash
git clone https://github.com/Mr-funny/hbg-hdr-glow ~/.claude/skills/hbg-hdr-glow
```

之后在 Claude Code 里说"把这个视频做成 HDR 发光效果"即可。

## 直接用脚本

```bash
# 推荐：10-bit HEVC + HLG
./scripts/hdr_glow.sh input.mp4

# 极速：只改 H.264 标签，不重新编码
./scripts/hdr_glow.sh input.mp4 out.mp4 --mode h264-tag
```

| 模式 | 画质 | 优点 | 缺点 |
| --- | --- | --- | --- |
| `hevc10`（默认） | 重新编码，10-bit | 色带少，苹果设备识别稳 | 文件稍大，要等编码 |
| `h264-tag` | 无损，不重新编码 | 几秒完成 | 仅限 H.264；8-bit 易出色带 |

## 怎么验证

1. `ffprobe out.mp4` 能看到 `arib-std-b67` 和 `bt2020`。
2. 隔空投送到 iPhone，在相册播放，左上角出现 HDR 标识，画面明显比界面亮。

## 注意

- 颜色会变得更艳，色相略偏。
- 平台转码可能会去掉标签，效果以实测为准。
- 暗光环境下会刺眼，请适度使用。

## License

MIT
