#!/bin/bash

# 🚀 Agent間メッセージ送信スクリプト

# tmuxのbase-indexとpane-base-indexを動的に取得
get_tmux_indices() {
    local session="$1"
    local window_index=$(tmux show-options -t "$session" -g base-index 2>/dev/null | awk '{print $2}')
    local pane_index=$(tmux show-options -t "$session" -g pane-base-index 2>/dev/null | awk '{print $2}')

    # デフォルト値
    window_index=${window_index:-0}
    pane_index=${pane_index:-0}

    echo "$window_index $pane_index"
}

# エージェント→tmuxターゲット マッピング
get_agent_target() {
    case "$1" in
        "おじいさん") echo "おじいさん" ;;
        "桃太郎"|"お供の犬"|"お供の猿"|"お供の雉")
            # 仲間セッションのindexを動的に取得
            if tmux has-session -t 仲間 2>/dev/null; then
                local indices=($(get_tmux_indices 仲間))
                local window_index=${indices[0]}
                local pane_index=${indices[1]}

                # window名で取得（base-indexに依存しない）
                local window_name="agents"

                # pane番号を計算
                case "$1" in
                    "桃太郎") echo "仲間:$window_name.$((pane_index))" ;;
                    "お供の犬") echo "仲間:$window_name.$((pane_index + 1))" ;;
                    "お供の猿") echo "仲間:$window_name.$((pane_index + 2))" ;;
                    "お供の雉") echo "仲間:$window_name.$((pane_index + 3))" ;;
                esac
            else
                echo ""
            fi
            ;;
        *) echo "" ;;
    esac
}

show_usage() {
    cat << EOF
🤖 Agent間メッセージ送信

使用方法:
  $0 [エージェント名] [メッセージ]
  $0 --list

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
EOF
}

# エージェント一覧表示
show_agents() {
    echo "📋 利用可能なエージェント:"
    echo "=========================="

    # おじいさんセッション確認
    if tmux has-session -t おじいさん 2>/dev/null; then
        echo "  おじいさん → おじいさん       (プロジェクト統括責任者)"
    else
        echo "  おじいさん → [未起動]        (プロジェクト統括責任者)"
    fi

    # 仲間セッション確認
    if tmux has-session -t 仲間 2>/dev/null; then
        local momotaro_target=$(get_agent_target "桃太郎")
        local inu_target=$(get_agent_target "お供の犬")
        local saru_target=$(get_agent_target "お供の猿")
        local kiji_target=$(get_agent_target "お供の雉")

        echo "  桃太郎     → ${momotaro_target:-[エラー]}  (チームリーダー)"
        echo "  お供の犬   → ${inu_target:-[エラー]}  (実行担当者A)"
        echo "  お供の猿   → ${saru_target:-[エラー]}  (実行担当者B)"
        echo "  お供の雉   → ${kiji_target:-[エラー]}  (実行担当者C)"
    else
        echo "  桃太郎     → [未起動]        (チームリーダー)"
        echo "  お供の犬   → [未起動]        (実行担当者A)"
        echo "  お供の猿   → [未起動]        (実行担当者B)"
        echo "  お供の雉   → [未起動]        (実行担当者C)"
    fi
}

# ログ記録
log_send() {
    local agent="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p logs
    echo "[$timestamp] $agent: SENT - \"$message\"" >> logs/send_log.txt
}

# メッセージ送信
send_message() {
    local target="$1"
    local message="$2"

    echo "📤 送信中: $target ← '$message'"

    # Claude Codeのプロンプトを一度クリア
    tmux send-keys -t "$target" C-c
    sleep 0.3

    # メッセージ送信
    tmux send-keys -t "$target" "$message"
    sleep 0.1

    # エンター押下
    tmux send-keys -t "$target" C-m
    sleep 0.5
}

# ターゲット存在確認
check_target() {
    local target="$1"
    local session_name="${target%%:*}"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "❌ セッション '$session_name' が見つかりません"
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

    if [[ $# -lt 2 ]]; then
        show_usage
        exit 1
    fi

    local agent_name="$1"
    local message="$2"

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
    send_message "$target" "$message"

    # ログ記録
    log_send "$agent_name" "$message"

    echo "✅ 送信完了: $agent_name に '$message'"

    return 0
}

main "$@"
