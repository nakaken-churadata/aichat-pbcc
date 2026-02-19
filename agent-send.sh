#!/bin/bash

# 🚀 Agent間メッセージ送信スクリプト

# スクリプトディレクトリ（絶対パス）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
QUEUE_DIR="$SCRIPT_DIR/queue"

# エージェント→tmuxターゲット マッピング（ユーザーオプションベース）
get_agent_target() {
    local agent_name="$1"

    # 全てのペインからユーザーオプション @agent_role を取得
    local pane_info
    pane_info=$(tmux list-panes -a -F "#{pane_id} #{@agent_role}" 2>/dev/null)

    if [[ -z "$pane_info" ]]; then
        echo ""
        return 1
    fi

    # 該当する役割名を持つ pane_id を検索
    local target_pane_id
    target_pane_id=$(echo "$pane_info" | grep -F "$agent_name" | awk '{print $1}')

    if [[ -z "$target_pane_id" ]]; then
        echo ""
        return 1
    fi

    # pane_id をそのまま返す（例: %1, %2, etc.）
    echo "$target_pane_id"
}

show_usage() {
    cat << EOF
🤖 Agent間メッセージ送信

使用方法:
  $0 [エージェント名] [メッセージ]
  $0 --list
  $0 --show-queue [エージェント名]
  $0 --retry-queue [エージェント名]

利用可能エージェント:
  おじいさん - プロジェクト統括責任者
  桃太郎     - チームリーダー
  お供の犬   - 実行担当者A
  お供の猿   - 実行担当者B
  お供の雉   - 実行担当者C

使用例:
  $0 おじいさん "指示書に従って"
  $0 桃太郎 "Hello World プロジェクト開始指示"
  $0 お供の犬 "作業完了しました"
  $0 --show-queue お供の犬
  $0 --retry-queue お供の犬
EOF
}

# エージェント一覧表示
show_agents() {
    echo "📋 利用可能なエージェント:"
    echo "=========================="

    # 各エージェントの状態を確認
    local agents=("おじいさん:プロジェクト統括責任者" "桃太郎:チームリーダー" "お供の犬:実行担当者A" "お供の猿:実行担当者B" "お供の雉:実行担当者C")

    for agent_info in "${agents[@]}"; do
        local agent_name="${agent_info%%:*}"
        local agent_desc="${agent_info#*:}"
        local target=$(get_agent_target "$agent_name")

        if [[ -n "$target" ]]; then
            echo "  $agent_name → $target  ($agent_desc)"
        else
            echo "  $agent_name → [未起動]  ($agent_desc)"
        fi
    done
}

# ログ記録
log_send() {
    local agent="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p "$SCRIPT_DIR/logs"
    echo "[$timestamp] $agent: SENT - \"$message\"" >> "$SCRIPT_DIR/logs/send_log.txt"
}

# キュー: メッセージIDを生成
generate_msg_id() {
    echo "$(date '+%Y%m%d%H%M%S')_$$_$RANDOM"
}

# キュー: メッセージを追加（ペンディング状態）
enqueue_message() {
    local agent="$1"
    local sender="$2"
    local message="$3"

    local agent_queue_dir="$QUEUE_DIR/$agent"
    mkdir -p "$agent_queue_dir"

    local msg_id
    msg_id=$(generate_msg_id)
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # メッセージファイルに記録（--- 以降がメッセージ本文）
    printf "SENDER: %s\nTIMESTAMP: %s\n---\n%s" "$sender" "$timestamp" "$message" \
        > "$agent_queue_dir/${msg_id}.pending"

    echo "$msg_id"
}

# キュー: 配信完了としてマーク（.pending → .delivered にリネーム）
dequeue_message() {
    local agent="$1"
    local msg_id="$2"

    local pending_file="$QUEUE_DIR/$agent/${msg_id}.pending"
    if [[ -f "$pending_file" ]]; then
        mv "$pending_file" "$QUEUE_DIR/$agent/${msg_id}.delivered"
    fi
}

# キュー: ペンディングメッセージを表示
show_queue() {
    local agent="$1"
    local agent_queue_dir="$QUEUE_DIR/$agent"

    if [[ ! -d "$agent_queue_dir" ]]; then
        echo "📭 キュー: ${agent} のペンディングメッセージなし"
        return 0
    fi

    local has_pending=false
    for msg_file in "$agent_queue_dir"/*.pending; do
        [[ -e "$msg_file" ]] || continue
        has_pending=true
        break
    done

    if [[ "$has_pending" == "false" ]]; then
        echo "📭 キュー: ${agent} のペンディングメッセージなし"
        return 0
    fi

    echo "📬 キュー: ${agent} のペンディングメッセージ:"
    for msg_file in "$agent_queue_dir"/*.pending; do
        [[ -e "$msg_file" ]] || continue
        local msg_id
        msg_id=$(basename "$msg_file" .pending)
        local sender
        sender=$(grep '^SENDER: ' "$msg_file" | sed 's/^SENDER: //')
        local timestamp
        timestamp=$(grep '^TIMESTAMP: ' "$msg_file" | sed 's/^TIMESTAMP: //')
        local message
        message=$(awk '/^---$/{found=1; next} found{print}' "$msg_file")
        echo "  [${msg_id}] ${timestamp} from ${sender}: ${message}"
    done
}

# キュー: ペンディングメッセージを再送
retry_queue() {
    local agent="$1"
    local agent_queue_dir="$QUEUE_DIR/$agent"

    if [[ ! -d "$agent_queue_dir" ]]; then
        echo "📭 リトライ不要: ${agent} のペンディングメッセージなし"
        return 0
    fi

    local has_pending=false
    for msg_file in "$agent_queue_dir"/*.pending; do
        [[ -e "$msg_file" ]] || continue
        has_pending=true
        break
    done

    if [[ "$has_pending" == "false" ]]; then
        echo "📭 リトライ不要: ${agent} のペンディングメッセージなし"
        return 0
    fi

    local target
    target=$(get_agent_target "$agent")
    if [[ -z "$target" ]]; then
        echo "❌ エラー: ${agent} のペインが見つかりません。再送をスキップします"
        return 1
    fi

    if ! check_target "$target"; then
        return 1
    fi

    echo "🔄 キュー再送: ${agent}"

    for msg_file in "$agent_queue_dir"/*.pending; do
        [[ -e "$msg_file" ]] || continue
        local msg_id
        msg_id=$(basename "$msg_file" .pending)
        local sender
        sender=$(grep '^SENDER: ' "$msg_file" | sed 's/^SENDER: //')
        local message
        message=$(awk '/^---$/{found=1; next} found{print}' "$msg_file")

        echo "  📤 再送: [${msg_id}] ${message}"

        tmux send-keys -t "$target" "【${sender}より】${message}"
        sleep 0.1
        tmux send-keys -t "$target" C-m
        sleep 0.5

        # 配信完了としてマーク
        mv "$msg_file" "$agent_queue_dir/${msg_id}.delivered"
        echo "  ✅ 再送完了: [${msg_id}]"
    done

    echo "✅ キュー再送完了"
}

# メッセージ送信
send_message() {
    local target="$1"
    local message="$2"
    local sender="$3"
    local agent_name="$4"

    echo "📤 送信中: $sender → $target"
    echo "   メッセージ: '$message'"

    # キューに追加（未配信として記録）
    local msg_id
    msg_id=$(enqueue_message "$agent_name" "$sender" "$message")

    # メッセージ送信（送信元を明示）
    tmux send-keys -t "$target" "【${sender}より】${message}"
    sleep 0.1

    # エンター押下
    tmux send-keys -t "$target" C-m
    sleep 0.5

    # 配信完了としてキューから移動
    dequeue_message "$agent_name" "$msg_id"
}

# ターゲット存在確認
check_target() {
    local target="$1"

    # pane_id が有効かどうかを確認
    if ! tmux display-message -p -t "$target" "#{pane_id}" 2>/dev/null >/dev/null; then
        echo "❌ ペイン '$target' が見つかりません"
        return 1
    fi

    return 0
}

# メイン処理
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    # --listオプション
    if [[ "$1" == "--list" ]]; then
        show_agents
        exit 0
    fi

    # --show-queue オプション
    if [[ "$1" == "--show-queue" ]]; then
        if [[ $# -lt 2 ]]; then
            echo "使用方法: $0 --show-queue [エージェント名]"
            exit 1
        fi
        show_queue "$2"
        exit 0
    fi

    # --retry-queue オプション
    if [[ "$1" == "--retry-queue" ]]; then
        if [[ $# -lt 2 ]]; then
            echo "使用方法: $0 --retry-queue [エージェント名]"
            exit 1
        fi
        retry_queue "$2"
        exit 0
    fi

    if [[ $# -lt 2 ]]; then
        show_usage
        exit 1
    fi

    local agent_name="$1"
    local message="$2"

    # 現在のペインのエージェント名を取得
    local current_pane_id
    current_pane_id=$(tmux display-message -p "#{pane_id}" 2>/dev/null)
    local sender

    # 環境変数を優先、なければtmuxオプションを使用
    if [[ -n "$AGENT_ROLE" ]]; then
        sender="$AGENT_ROLE"
    else
        sender=$(tmux display-message -p "#{@agent_role}" 2>/dev/null)
    fi

    # 送信元が不明な場合のフォールバック
    if [[ -z "$sender" ]]; then
        sender="不明"
    fi

    # エージェントターゲット取得
    local target
    target=$(get_agent_target "$agent_name")

    if [[ -z "$target" ]]; then
        echo "❌ エラー: 不明なエージェント '$agent_name'"
        echo "利用可能エージェント: $0 --list"
        exit 1
    fi

    # ターゲット確認
    if ! check_target "$target"; then
        exit 1
    fi

    # メッセージ送信
    send_message "$target" "$message" "$sender" "$agent_name"

    # ログ記録
    log_send "$agent_name" "$message"

    echo "✅ 送信完了: $sender → $agent_name"

    return 0
}

# ロックディレクトリを使って排他制御（macOS互換）
LOCK_DIR="/tmp/agent-send.lock"

# クリーンアップ関数
cleanup() {
    rmdir "$LOCK_DIR" 2>/dev/null
}
trap cleanup EXIT

# ロックを取得（最大10秒待機、100ms間隔で100回試行）
for i in {1..100}; do
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        # ロック取得成功
        break
    fi
    if [ $i -eq 100 ]; then
        echo "❌ エラー: 他の agent-send.sh が実行中です。しばらく待ってから再試行してください"
        exit 1
    fi
    sleep 0.1
done

# メイン処理を実行（ロックは EXIT 時に自動解放）
main "$@"
