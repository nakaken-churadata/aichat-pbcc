#!/bin/bash

# 🤖 全エージェントに役割を自動通知するスクリプト

set -e

echo "🎯 全エージェントに役割を通知中..."
echo "=================================="
echo ""

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

# おじいさんセッション確認
if ! tmux has-session -t main 2>/dev/null; then
    echo "❌ エラー: mainセッションが起動していません"
    echo "   まず ./setup.sh を実行してください"
    exit 1
fi

# agentsセッション確認
if ! tmux has-session -t agents 2>/dev/null; then
    echo "❌ エラー: agentsセッションが起動していません"
    echo "   まず ./setup.sh を実行してください"
    exit 1
fi

# 各エージェントに役割を通知
log_info "おじいさんに役割を通知中..."
./agent-send.sh おじいさん "あなたは「おじいさん」です。環境変数 AGENT_ROLE を確認し、instructions/ojiisan.md の指示に従ってください。"
sleep 1

log_info "桃太郎に役割を通知中..."
./agent-send.sh 桃太郎 "あなたは「桃太郎」です。環境変数 AGENT_ROLE を確認し、instructions/momotarou.md の指示に従ってください。"
sleep 1

log_info "お供の犬に役割を通知中..."
./agent-send.sh お供の犬 "あなたは「お供の犬」です。環境変数 AGENT_ROLE を確認し、instructions/otomo.md の指示に従ってください。語尾は「ワン」です。"
sleep 1

log_info "お供の猿に役割を通知中..."
./agent-send.sh お供の猿 "あなたは「お供の猿」です。環境変数 AGENT_ROLE を確認し、instructions/otomo.md の指示に従ってください。語尾は「ウキー」です。"
sleep 1

log_info "お供の雉に役割を通知中..."
./agent-send.sh お供の雉 "あなたは「お供の雉」です。環境変数 AGENT_ROLE を確認し、instructions/otomo.md の指示に従ってください。語尾は「ケーン」です。"
sleep 1

echo ""
log_success "✅ 全エージェントへの役割通知が完了しました！"
echo ""
echo "📋 次のステップ:"
echo "  各セッションをアタッチして、エージェントが正しく役割を認識しているか確認してください。"
echo ""
echo "  tmux attach-session -t agents      # 桃太郎とお供たち"
echo "  tmux attach-session -t main # おじいさん"
echo ""
