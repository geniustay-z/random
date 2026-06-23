#!/usr/bin/env bash
# 在服务器上执行：bash deploy.sh
# 前置：已在 /opt/cc-xia/.env 填好 ZHIPU_API_KEY，并已完成 lark-cli config/auth
set -euo pipefail

APP_DIR="/opt/cc-xia"
SERVICE="cc-xia"
BRANCH="claude/eloquent-heisenberg-mn7kkm"

echo "=== 1. 安装依赖 ==="
command -v node >/dev/null || (curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs)
command -v python3 >/dev/null || apt-get install -y python3
command -v git >/dev/null || apt-get install -y git

echo "=== 2. 拉取代码到 $APP_DIR ==="
if [ -d "$APP_DIR/.git" ]; then
  git -C "$APP_DIR" fetch origin "$BRANCH" && git -C "$APP_DIR" reset --hard "origin/$BRANCH"
else
  git clone -b "$BRANCH" https://github.com/geniustay-z/random.git "$APP_DIR"
fi
chmod +x "$APP_DIR/bot.sh"

echo "=== 3. 检查 .env ==="
if [ ! -f "$APP_DIR/.env" ]; then
  echo "!! 缺少 $APP_DIR/.env —— 请先创建并填入 ZHIPU_API_KEY（参考 .env.example）"
  exit 1
fi

echo "=== 4. 检查 lark-cli 配置 ==="
if [ ! -f "$HOME/.lark-cli/config.json" ]; then
  echo "!! 未检测到 lark-cli 配置 —— 请先执行："
  echo "   echo '<APP_SECRET>' | npx @larksuite/cli@latest config init --app-id cli_aa835a390fb85ccd --app-secret-stdin"
  echo "   npx @larksuite/cli@latest auth login --recommend   # 扫码授权"
  exit 1
fi

echo "=== 5. 安装并启动 systemd 服务 ==="
cp "$APP_DIR/cc-xia.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable "$SERVICE"
systemctl restart "$SERVICE"

echo ""
echo "=== 部署完成 ==="
sleep 2
systemctl status "$SERVICE" --no-pager || true
echo ""
echo "查看实时日志： journalctl -u $SERVICE -f"
