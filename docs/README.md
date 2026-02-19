# docs/ ドキュメント構造

このディレクトリには、プロジェクトのドキュメントが格納されています。

## 0. 本ドキュメント（文書構造の説明）

このファイル（`README.md`）です。`docs/` ディレクトリ内のドキュメント一覧と概要を説明します。

---

## 1. アーキテクチャ

**[architecture.md](architecture.md)**

**aichat** のアーキテクチャを説明します。

- ブラウザ → フロントエンド → バックエンド → 生成AI の階層構造
- 各階層の役割・連携方法・使用技術（Next.js, Gemini API）

---

## 2. インフラストラクチャ

**[infrastructure.md](infrastructure.md)**

**aichat** のインフラ環境を説明します。

- **ローカル環境**: Docker Compose によるローカル動作確認
- **クラウド環境**: Google Cloud Run へのデプロイ（Terraform 使用）

---

## 3. 開発環境

**[development.md](development.md)**

**エージェント型コーディング**（Claude Code を使った開発）のローカルマシンセットアップを説明します。

- devcontainer（推奨）・ローカル環境 別のセットアップ手順
- 使用ツール一覧（tmux, GitHub CLI, gitleaks, Claude Code）
- マルチエージェント環境の起動方法・開発フロー

---

## 9. その他

**[misc.md](misc.md)**

上記3カテゴリに当てはまらないドキュメントの索引です。

- エージェント通信ガイドライン（[references/message-guidelines.md](references/message-guidelines.md)）
- セキュリティガイドライン（[references/security-guidelines.md](references/security-guidelines.md)）
- 技術的な問題分析・提案ドキュメント（`references/`）
- 調査レポート（`investigations/`）
