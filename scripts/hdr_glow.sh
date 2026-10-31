#!/usr/bin/env bash
# hdr_glow.sh — 给普通（SDR）视频打上 HLG / BT.2020 标签，让它在支持 HDR 的屏幕上"发光"。
# 用法: hdr_glow.sh <输入视频> [输出视频] [--mode hevc10|h264-tag] [--crf N]
set -euo pipefail

usage() { sed -n '2,3p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

IN="" OUT="" MODE="hevc10" CRF="16"
while [ $# -gt 0 ]; do
  case "$1" in
    --mode) MODE="${2:?}"; shift 2 ;;
    --crf)  CRF="${2:?}"; shift 2 ;;
    -h|--help) usage ;;
    *) if [ -z "$IN" ]; then IN="$1"; elif [ -z "$OUT" ]; then OUT="$1"; else usage; fi; shift ;;
  esac
done
[ -n "$IN" ] || usage
[ -f "$IN" ] || { echo "找不到输入文件: $IN" >&2; exit 1; }
command -v ffmpeg >/dev/null && command -v ffprobe >/dev/null || { echo "需要先安装 ffmpeg（含 ffprobe）" >&2; exit 1; }
[ -n "$OUT" ] || OUT="${IN%.*}_HLG.mp4"

case "$MODE" in
  hevc10)
    # 重新编码为 10-bit HEVC，带 HLG 标签；hvc1 让苹果设备正确识别
    ffmpeg -hide_banner -loglevel error -y -i "$IN" -map 0:v:0 -map 0:a? \
      -c:v libx265 -pix_fmt yuv420p10le -crf "$CRF" -preset slow -tag:v hvc1 \
      -x265-params "log-level=error:colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited" \
      -color_primaries bt2020 -color_trc arib-std-b67 -colorspace bt2020nc -color_range tv \
      -c:a copy -movflags +faststart "$OUT" ;;
  h264-tag)
    # 不重新编码，只改 H.264 码流里的色彩标签（输入必须是 H.264）
    codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$IN")
    [ "$codec" = "h264" ] || { echo "h264-tag 模式只支持 H.264 输入，当前是 $codec，请改用 --mode hevc10" >&2; exit 1; }
    ffmpeg -hide_banner -loglevel error -y -i "$IN" -map 0 -c copy \
      -bsf:v "h264_metadata=video_full_range_flag=0:colour_primaries=9:transfer_characteristics=18:matrix_coefficients=9" \
      -movflags +faststart "$OUT" ;;
  *) echo "未知模式: $MODE（可选 hevc10 / h264-tag）" >&2; exit 1 ;;
esac

info=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,pix_fmt,color_transfer,color_primaries -of compact=p=0:nk=0 "$OUT")
echo "$info"
case "$info" in
  *arib-std-b67*bt2020*|*bt2020*arib-std-b67*) echo "完成: $OUT" ;;
  *) echo "警告: 输出文件没有检测到 HLG/BT.2020 标签" >&2; exit 1 ;;
esac
