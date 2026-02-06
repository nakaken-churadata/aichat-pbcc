# 🤖 Tmux Multi-Agent Communication Demo

Agent同士がやり取りするtmux環境のデモシステム

**📖 Read this in other languages:** [English](README-en.md)

## 🎯 デモ概要

おじいさん → 桃太郎 → お供たち の階層型指示システムを体感できます

### 👥 エージェント構成

```
📊 おじいさん セッション (1ペイン)
└── おじいさん: プロジェクト統括責任者

📊 仲間 セッション (4ペイン)
├── 桃太郎: チームリーダー
├── お供の犬: 実行担当者A
├── お供の猿: 実行担当者B
└── お供の雉: 実行担当者C
```

## 🚀 クイックスタート

### 0. リポジトリのクローン

```bash
git clone https://github.com/nishimoto265/Claude-Code-Communication.git
cd Claude-Code-Communication
```

### 1. tmux環境構築

⚠️ **注意**: 既存の `仲間` と `おじいさん` セッションがある場合は自動的に削除されます。

```bash
./setup.sh
```

### 2. セッションアタッチ

```bash
# マルチエージェント確認
tmux attach-session -t 仲間

# おじいさん確認（別ターミナルで）
tmux attach-session -t おじいさん
```

### 3. Claude Code起動

**手順1: おじいさん認証**
```bash
# まずおじいさんで認証を実施
tmux send-keys -t おじいさん 'claude' C-m
```
認証プロンプトに従って許可を与えてください。

**手順2: 仲間一括起動**
```bash
# 認証完了後、仲間セッションを一括起動
for i in {0..3}; do tmux send-keys -t 仲間:0.$i 'claude' C-m; done
```

### 4. デモ実行

おじいさんセッションで直接入力：
```
あなたはおじいさんです。指示書に従って
```

## 📜 指示書について

各エージェントの役割別指示書：
- **おじいさん**: `instructions/president.md`
- **桃太郎**: `instructions/boss.md`
- **お供の犬,猿,雉**: `instructions/otomo.md`

**Claude Code参照**: `CLAUDE.md` でシステム構造を確認

**要点:**
- **おじいさん**: 「あなたはおじいさんです。指示書に従って」→ 桃太郎に指示送信
- **桃太郎**: おじいさん指示受信 → お供全員に指示 → 完了報告
- **お供たち**: Hello World実行 → 完了ファイル作成 → 最後の人が報告

## 🎬 期待される動作フロー

```
1. おじいさん → 桃太郎: "あなたは桃太郎です。Hello World プロジェクト開始指示"
2. 桃太郎 → お供たち: "あなたはお供の[犬/猿/雉]です。Hello World 作業開始"
3. お供たち → ./tmp/ファイル作成 → 最後のお供 → 桃太郎: "全員作業完了しました"
4. 桃太郎 → おじいさん: "全員完了しました"
```

## 🔧 手動操作

### agent-send.shを使った送信

```bash
# 基本送信
./agent-send.sh [エージェント名] [メッセージ]

# 例
./agent-send.sh 桃太郎 "緊急タスクです"
./agent-send.sh お供の犬 "作業完了しました"
./agent-send.sh おじいさん "最終報告です"

# エージェント一覧確認
./agent-send.sh --list
```

## 🧪 確認・デバッグ

### ログ確認

```bash
# 送信ログ確認
cat logs/send_log.txt

# 特定エージェントのログ
grep "桃太郎" logs/send_log.txt

# 完了ファイル確認
ls -la ./tmp/お供の*_done.txt
```

### セッション状態確認

```bash
# セッション一覧
tmux list-sessions

# ペイン一覧
tmux list-panes -t 仲間
tmux list-panes -t おじいさん
```

## 🔄 環境リセット

```bash
# セッション削除
tmux kill-session -t 仲間
tmux kill-session -t おじいさん

# 完了ファイル削除
rm -f ./tmp/お供の*_done.txt

# 再構築（自動クリア付き）
./setup.sh
```

---

## 📄 ライセンス

このプロジェクトは[MIT License](LICENSE)の下で公開されています。

## 🤝 コントリビューション

プルリクエストやIssueでのコントリビューションを歓迎いたします！

---

🚀 **Agent Communication を体感してください！** 🤖✨
