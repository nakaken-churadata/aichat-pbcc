#!/bin/bash

# 🚀 Multi-Agent Communication Demo 環境構築
# 参考: setup_full_environment.sh

set -e  # エラー時に停止

# シェル検出
CURRENT_SHELL=$(basename "$SHELL")

# tmuxペインにカラープロンプトを設定する関数
# Usage: set_color_prompt PANE_ID TITLE COLOR_CODE
#   COLOR_CODE: 31=red, 34=blue, 35=magenta
set_color_prompt() {
    local PANE_ID="$1"
    local TITLE="$2"
    local COLOR_CODE="$3"

    if [ "$CURRENT_SHELL" = "zsh" ]; then
        local COLOR_NAME
        case "$COLOR_CODE" in
            31) COLOR_NAME="red" ;;
            34) COLOR_NAME="blue" ;;
            35) COLOR_NAME="magenta" ;;
            *)  COLOR_NAME="white" ;;
        esac
        tmux send-keys -t "$PANE_ID" "export PS1='(%B%F{${COLOR_NAME}}${TITLE}%f%b) %B%F{green}%~%f%b%# '" C-m
    else
        tmux send-keys -t "$PANE_ID" "export PS1='(\[\033[1;${COLOR_CODE}m\]${TITLE}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    fi
}

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

echo "🤖 Multi-Agent Communication Demo 環境構築"
echo "==========================================="
echo ""

# STEP 1: 既存セッションクリーンアップ
log_info "🧹 既存セッションクリーンアップ開始..."

tmux kill-session -t 仲間 2>/dev/null && log_info "仲間セッション削除完了" || log_info "仲間セッションは存在しませんでした"
tmux kill-session -t おじいさん 2>/dev/null && log_info "おじいさんセッション削除完了" || log_info "おじいさんセッションは存在しませんでした"

# 完了ファイルクリア
mkdir -p ./tmp
rm -f ./tmp/お供の*_done.txt 2>/dev/null && log_info "既存の完了ファイルをクリア" || log_info "完了ファイルは存在しませんでした"

log_success "✅ クリーンアップ完了"
echo ""

# STEP 2: 仲間セッション作成（4ペイン：桃太郎 + お供の犬,猿,雉）
log_info "📺 仲間セッション作成開始 (4ペイン)..."

# セッション作成
log_info "セッション作成中..."
tmux new-session -d -s 仲間 -n "agents"

# セッション作成の確認
if ! tmux has-session -t 仲間 2>/dev/null; then
    echo "❌ エラー: 仲間セッションの作成に失敗しました"
    exit 1
fi

log_info "セッション作成成功"

# 2x2グリッド作成（ウィンドウ名使用でbase-index非依存）
log_info "グリッド作成中..."

# 水平分割（ウィンドウ名で指定）
log_info "水平分割実行中..."
tmux split-window -h -t "仲間:agents"

# 左上ペインを選択して垂直分割
log_info "左側垂直分割実行中..."
tmux select-pane -t "仲間:agents" -L  # 左のペインを選択
tmux split-window -v

# 右上ペインを選択して垂直分割
log_info "右側垂直分割実行中..."
tmux select-pane -t "仲間:agents" -R  # 右のペインを選択
tmux split-window -v

# ペインの配置確認
log_info "ペイン配置確認中..."
PANE_COUNT=$(tmux list-panes -t "仲間:agents" | wc -l)
log_info "作成されたペイン数: $PANE_COUNT"

if [ "$PANE_COUNT" -ne 4 ]; then
    echo "❌ エラー: 期待されるペイン数(4)と異なります: $PANE_COUNT"
    exit 1
fi

# ペインの物理的な配置を取得（top-leftから順番に）
log_info "ペイン番号取得中..."
# tmuxのペイン番号を位置に基づいて取得
PANE_IDS=($(tmux list-panes -t "仲間:agents" -F "#{pane_id}" | sort))

log_info "検出されたペイン: ${PANE_IDS[*]}"

# ペインタイトル設定とセットアップ
log_info "ペインタイトル設定中..."
PANE_TITLES=("桃太郎" "お供の犬" "お供の猿" "お供の雉")

for i in {0..3}; do
    PANE_ID="${PANE_IDS[$i]}"
    TITLE="${PANE_TITLES[$i]}"

    log_info "設定中: ${TITLE} (${PANE_ID})"

    # ペインタイトル設定
    tmux select-pane -t "$PANE_ID" -T "$TITLE"

    # 作業ディレクトリ設定
    tmux send-keys -t "$PANE_ID" "cd $(pwd)" C-m

    # カラープロンプト設定
    if [ $i -eq 0 ]; then
        # 桃太郎: 赤色
        set_color_prompt "$PANE_ID" "$TITLE" "31"
    else
        # お供たち: 青色
        set_color_prompt "$PANE_ID" "$TITLE" "34"
    fi

    # ウェルカムメッセージ
    tmux send-keys -t "$PANE_ID" "echo '=== ${TITLE} エージェント ==='" C-m
done

log_success "✅ 仲間セッション作成完了"
echo ""

# STEP 3: おじいさんセッション作成（1ペイン）
log_info "👑 おじいさんセッション作成開始..."

tmux new-session -d -s おじいさん
tmux send-keys -t おじいさん "cd $(pwd)" C-m
set_color_prompt "おじいさん" "おじいさん" "35"
tmux send-keys -t おじいさん "echo '=== おじいさん セッション ==='" C-m
tmux send-keys -t おじいさん "echo 'プロジェクト統括責任者'" C-m
tmux send-keys -t おじいさん "echo '========================'" C-m

log_success "✅ おじいさんセッション作成完了"
echo ""

# STEP 4: 環境確認・表示
log_info "🔍 環境確認中..."

echo ""
echo "📊 セットアップ結果:"
echo "==================="

# tmuxセッション確認
echo "📺 Tmux Sessions:"
tmux list-sessions
echo ""

# ペイン構成表示
echo "📋 ペイン構成:"
echo "  仲間セッション（4ペイン）:"
tmux list-panes -t "仲間:agents" -F "    Pane #{pane_id}: #{pane_title}"
echo ""
echo "  おじいさんセッション（1ペイン）:"
echo "    Pane: おじいさん (プロジェクト統括)"

echo ""
log_success "🎉 Demo環境セットアップ完了！"
echo ""
echo "📋 次のステップ:"
echo "  1. 🔗 セッションアタッチ:"
echo "     tmux attach-session -t 仲間   # マルチエージェント確認"
echo "     tmux attach-session -t おじいさん    # おじいさん確認"
echo ""
echo "  2. 🤖 Claude Code起動:"
echo "     # 手順1: おじいさん認証"
echo "     tmux send-keys -t おじいさん 'claude' C-m"
echo "     # 手順2: 認証後、仲間一括起動"
echo "     # 各ペインのIDを使用してclaudeを起動"
echo "     tmux list-panes -t 仲間:agents -F '#{pane_id}' | while read pane; do"
echo "         tmux send-keys -t \"\$pane\" 'claude' C-m"
echo "     done"
echo ""
echo "  3. 📜 指示書確認:"
echo "     おじいさん: instructions/ojiisan.md"
echo "     桃太郎: instructions/momotarou.md"
echo "     お供の犬,猿,雉: instructions/otomo.md"
echo "     システム構造: CLAUDE.md"
echo ""
echo "  4. 🎯 デモ実行: おじいさんに「あなたはおじいさんです。指示書に従って」と入力"
