#!/usr/bin/env bash
# cc虾 消息回复 bot
# 用法: ./bot.sh
# 收到消息 → 以 thread reply 回复 "已收到"（可替换为 Claude API 调用）
set -euo pipefail

LARK="npx --yes @larksuite/cli@latest"

echo "[bot] cc虾 启动，监听消息中..."

$LARK event consume im.message.receive_v1 --as bot --quiet < <(tail -f /dev/null) 2>/dev/null | while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  MSG_ID=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message_id',''))" 2>/dev/null)
  CONTENT=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('content',''))" 2>/dev/null)
  SENDER=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sender_id',''))" 2>/dev/null)
  CHAT_TYPE=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('chat_type',''))" 2>/dev/null)

  [[ -z "$MSG_ID" ]] && continue

  echo "[bot] 收到消息 msg_id=$MSG_ID sender=$SENDER chat_type=$CHAT_TYPE content=$CONTENT"

  # 回复（thread reply 到原消息）
  REPLY="已收到：$CONTENT"
  $LARK im +messages-reply --message-id "$MSG_ID" --text "$REPLY" --as bot 2>&1 | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    if d.get('ok'): print('[bot] 回复成功 message_id=' + d.get('data',{}).get('message_id',''))
    else: print('[bot] 回复失败: ' + str(d))
except: print('[bot] 回复解析失败')
"
done

echo "[bot] 事件流结束，退出"
