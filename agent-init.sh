#!/bin/bash
# agent-init.sh - エージェント環境変数初期化スクリプト

if [ -n "$TMUX" ]; then
    # TMUX_PANE 環境変数を使用（tmuxが各ペインに自動設定）
    PANE_ID="$TMUX_PANE"
    echo "🔍 デバッグ: 現在のペインID = $PANE_ID"

    AGENT_ROLE_FROM_TMUX=$(tmux show-option -pv -t "$PANE_ID" @agent_role 2>/dev/null)
    echo "🔍 デバッグ: @agent_role = $AGENT_ROLE_FROM_TMUX"

    if [ -n "$AGENT_ROLE_FROM_TMUX" ]; then
        export AGENT_ROLE="$AGENT_ROLE_FROM_TMUX"
        echo "✅ AGENT_ROLE を設定しました: $AGENT_ROLE"
    else
        echo "⚠️  @agent_role が見つかりません"
    fi
else
    echo "⚠️  tmux 環境外で実行されています"
fi
