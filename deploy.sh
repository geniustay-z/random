#!/usr/bin/env bash
# 在服务器上执行：bash deploy.sh
set -euo pipefail

APP_DIR="/opt/cc-xia"
SERVICE="cc-xia"

echo "=== 1. 安装依赖 ==="
command -v node >/dev/null || (curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs)
command -v python3 >/dev/null || apt-get install -y python3

echo "=== 2. 创建目录并拉取代码 ==="
mkdir -p "$APP_DIR"
if [ -d "$APP_DIR/.git" ]; then
  git -C "$APP_DIR" pull origin claude/eloquent-heisenberg-mn7kkm
else
  git clone -b claude/eloquent-heisenberg-mn7kkm https://github.com/geniustay-z/random.git "$APP_DIR"
fi
chmod +x "$APP_DIR/bot.sh"

echo "=== 3. 复制 lark-cli 配置 (如果有) ==="
if [ -d "$HOME/.lark-cli" ]; then
  cp -r "$HOME/.lark-cli" /root/.lark-cli 2>/dev/null || true
fi

echo "=== 4. 安装 systemd 服务 ==="
cp "$APP_DIR/cc-xia.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable "$SERVICE"
systemctl restart "$SERVICE"

echo ""
echo "=== 部署完成 ==="
systemctl status "$SERVICE" --no-pager
