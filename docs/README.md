# docs/ ドキュメント構造

このディレクトリには、プロジェクトのドキュメントが格納されています。

## 0. 本ドキュメント（文書構造の説明）

このファイル（`README.md`）です。`docs/` ディレクトリ内のドキュメント一覧と概要を説明します。

---

## 1. アーキテクチャ

**[architecture.md](architecture.md)**

チャットアプリケーションおよびマルチエージェント開発システムのアーキテクチャを説明します。

- ブラウザ → フロントエンド → バックエンド → 生成AI の階層構造
- 各階層の役割・連携方法・使用技術
- エージェント構成（おじいさん・桃太郎・お供たち）

---

## 2. インフラストラクチャ

**[infrastructure.md](infrastructure.md)**

各環境のセットアップ方法・使用技術・運用方法を説明します。

- **ローカル環境**: Docker Compose によるローカル開発
- **devcontainer**: VSCode Dev Containers を使った推奨開発環境（詳細: [devcontainer-setup.md](devcontainer-setup.md)）
- **クラウド環境**: Google Cloud Run へのデプロイ（Terraform 使用）

---

## 3. 開発環境

**[development.md](development.md)**

開発環境の構築方法・ツール一覧・開発フローを説明します。

- Mac / Windows 別のセットアップ手順
- 使用ツール一覧（Node.js, git, tmux, GitHub CLI, gitleaks, Claude Code）
- マルチエージェント環境の起動方法
- トラブルシューティング

---

## 9. その他

**[misc.md](misc.md)**

上記3カテゴリに当てはまらないドキュメントの索引です。

- エージェント通信ガイドライン（[message-guidelines.md](message-guidelines.md)）
- セキュリティガイドライン（[security-guidelines.md](security-guidelines.md)）
- 技術的な問題分析・提案ドキュメント
- 調査レポート（`investigations/` ディレクトリ）
