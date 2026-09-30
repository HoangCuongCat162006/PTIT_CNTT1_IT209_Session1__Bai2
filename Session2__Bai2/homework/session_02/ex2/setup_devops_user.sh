#!/bin/bash
# ==============================================================================
# Script Name: setup_devops_user.sh
# Purpose: Khởi tạo user 'devops', cấp quyền sudo và cấu hình SSH Key tự động
# Requirement: Chạy script với quyền root trên Ubuntu Server
# ==============================================================================

set -euo pipefail

TARGET_USER="devops"

echo "=== [1/5] Kiểm tra quyền thực thi ==="
if [ "$EUID" -ne 0 ]; then
  echo "[LỖI] Vui lòng chạy script này với quyền root (hoặc dùng sudo)." >&2
  exit 1
fi

echo "=== [2/5] Tạo người dùng $TARGET_USER ==="
if id "$TARGET_USER" &>/dev/null; then
    echo "Người dùng '$TARGET_USER' đã tồn tại. Bỏ qua bước tạo."
else
    adduser --disabled-password --gecos "DevOps Engineer" "$TARGET_USER"
    echo "Vui lòng nhập mật khẩu cho user $TARGET_USER:"
    passwd "$TARGET_USER"
    echo "Tạo người dùng '$TARGET_USER' thành công."
fi

echo "=== [3/5] Gán $TARGET_USER vào nhóm sudo ==="
usermod -aG sudo "$TARGET_USER"
echo "Đã thêm '$TARGET_USER' vào nhóm sudo."

echo "=== [4/5] Sao chép cấu hình SSH Key từ root ==="
if [ -d "$HOME/.ssh" ]; then
    rsync --archive --chown="${TARGET_USER}:${TARGET_USER}" "$HOME/.ssh" "/home/${TARGET_USER}/"
    chmod 700 "/home/${TARGET_USER}/.ssh"
    if [ -f "/home/${TARGET_USER}/.ssh/authorized_keys" ]; then
        chmod 600 "/home/${TARGET_USER}/.ssh/authorized_keys"
    fi
    chown -R "${TARGET_USER}:${TARGET_USER}" "/home/${TARGET_USER}/.ssh"
    echo "Đã đồng bộ và phân quyền SSH Key thành công."
else
    echo "[CẢNH BÁO] Không tìm thấy thư mục ~/.ssh của root!"
fi

echo "=== [5/5] Kiểm tra trạng thái phân quyền ==="
ls -ld "/home/${TARGET_USER}/.ssh"
ls -la "/home/${TARGET_USER}/.ssh"

echo "=============================================================================="
echo "HOÀN TẤT THIẾT LẬP!"
echo "Hãy mở một Terminal khác trên máy Client và kiểm tra đăng nhập bằng lệnh:"
echo "  ssh -i <path_to_private_key> ${TARGET_USER}@<IP_ADDRESS>"
echo "Sau đó chạy lệnh kiểm tra sudo:"
echo "  sudo whoami"
echo "=============================================================================="
