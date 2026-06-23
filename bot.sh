#!/usr/bin/env bash
# cc虾 — 飞书消息监听 + 智谱 GLM 智能回复
set -euo pipefail

LARK="npx --yes @larksuite/cli@latest"
ZHIPU_KEY="${ZHIPU_API_KEY:?请设置环境变量 ZHIPU_API_KEY（见 .env.example）}"
ZHIPU_URL="https://open.bigmodel.cn/api/paas/v4/chat/completions"
ZHIPU_MODEL="${ZHIPU_MODEL:-glm-4-flash}"

# 调用智谱 API，输入用户消息，返回回复文本
ask_zhipu() {
  local user_msg="$1"
  local body
  body=$(python3 -c "
import json, sys
msg = sys.argv[1]
payload = {
    'model': '${ZHIPU_MODEL}',
    'messages': [
        {'role': 'system', 'content': '你是 cc虾，一个飞书智能助手，简洁友好地回答用户问题。'},
        {'role': 'user',   'content': msg}
    ]
}
print(json.dumps(payload))
" "$user_msg")

  local resp
  resp=$(curl -sf --connect-timeout 15 -X POST "$ZHIPU_URL" \
    -H "Authorization: Bearer $ZHIPU_KEY" \
    -H "Content-Type: application/json" \
    -d "$body")

  echo "$resp" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d['choices'][0]['message']['content'].strip())
except Exception as e:
    print('（回复生成失败: ' + str(e) + '）')
"
}

echo "[bot] cc虾 启动 — 模型: $ZHIPU_MODEL"
echo "[bot] 监听 im.message.receive_v1 ..."

$LARK event consume im.message.receive_v1 --as bot --quiet < <(tail -f /dev/null) 2>/dev/null \
| while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  MSG_ID=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message_id',''))" 2>/dev/null || true)
  CONTENT=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('content',''))" 2>/dev/null || true)
  SENDER=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sender_id',''))" 2>/dev/null || true)

  [[ -z "$MSG_ID" || -z "$CONTENT" ]] && continue

  echo "[bot] 收到 msg=$MSG_ID sender=$SENDER: $CONTENT"

  REPLY=$(ask_zhipu "$CONTENT")
  echo "[bot] 智谱回复: $REPLY"

  $LARK im +messages-reply --message-id "$MSG_ID" --text "$REPLY" --as bot 2>&1 \
  | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    if d.get('ok'): print('[bot] 发送成功')
    else: print('[bot] 发送失败: ' + str(d))
except: print('[bot] 解析失败')
"
done

echo "[bot] 事件流结束，退出"
