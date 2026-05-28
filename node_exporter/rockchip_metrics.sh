#!/bin/bash

# Sử dụng file tạm để tránh Node Exporter đọc file đang viết dở
TMP_FILE="/opt/custom_metrics/rockchip.prom.tmp"
PROM_FILE="/opt/custom_metrics/rockchip.prom"

# Xóa file tạm cũ
> "$TMP_FILE"

# ========================================
# 1. Thu thập GPU Load
# ========================================
GPU_LOAD=$(cat /sys/class/devfreq/*.gpu/load 2>/dev/null | awk -F'@' '{print $1}')
if [ -z "$GPU_LOAD" ]; then
    GPU_LOAD=$(cat /sys/class/devfreq/*.mali/load 2>/dev/null | awk -F'@' '{print $1}')
fi
GPU_LOAD=${GPU_LOAD:-0}

echo "# HELP rockchip_gpu_load_percent Mali GPU Load Percentage" >> "$TMP_FILE"
echo "# TYPE rockchip_gpu_load_percent gauge" >> "$TMP_FILE"
echo "rockchip_gpu_load_percent $GPU_LOAD" >> "$TMP_FILE"

# ========================================
# 2. Thu thập NPU Load
# ========================================
echo "# HELP rockchip_npu_load_percent NPU Load Percentage per Core" >> "$TMP_FILE"
echo "# TYPE rockchip_npu_load_percent gauge" >> "$TMP_FILE"

NPU_RAW=$(cat /sys/kernel/debug/rknpu/load 2>/dev/null)
if [ -n "$NPU_RAW" ]; then
    # Lấy thông số từng core
    C0=$(echo "$NPU_RAW" | grep -o 'Core0: *[0-9]*' | awk '{print $2}')
    C1=$(echo "$NPU_RAW" | grep -o 'Core1: *[0-9]*' | awk '{print $2}')
    C2=$(echo "$NPU_RAW" | grep -o 'Core2: *[0-9]*' | awk '{print $2}')
    
    [ -n "$C0" ] && echo "rockchip_npu_load_percent{core=\"0\"} $C0" >> "$TMP_FILE"
    [ -n "$C1" ] && echo "rockchip_npu_load_percent{core=\"1\"} $C1" >> "$TMP_FILE"
    [ -n "$C2" ] && echo "rockchip_npu_load_percent{core=\"2\"} $C2" >> "$TMP_FILE"
fi

# ========================================
# 3. Thu thập VPU (MPP Sessions)
# ========================================
echo "# HELP rockchip_vpu_sessions Active Hardware Video Processing Sessions" >> "$TMP_FILE"
echo "# TYPE rockchip_vpu_sessions gauge" >> "$TMP_FILE"

VPU_ENC=$(cat /proc/mpp_service/sessions-summary 2>/dev/null | grep -c "RKVENC")
VPU_DEC=$(cat /proc/mpp_service/sessions-summary 2>/dev/null | grep -c "RKVDEC")

echo "rockchip_vpu_sessions{type=\"encoder\"} $VPU_ENC" >> "$TMP_FILE"
echo "rockchip_vpu_sessions{type=\"decoder\"} $VPU_DEC" >> "$TMP_FILE"

# Đổi tên file tạm thành file chính thức (Atomic operation)
mv "$TMP_FILE" "$PROM_FILE"