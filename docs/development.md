# 開発環境

## 概要

このプロジェクトの開発環境セットアップ方法を説明します。2つの開発方法があります：

| 方法 | 推奨度 | 特徴 |
|------|--------|------|
| **devcontainer** | ★★★ 推奨 | `--dangerously-skip-permissions` を安全に使用、再現性が高い |
| **ローカル環境** | ★★ | Docker不要、より慎重な操作 |

---

## 前提条件

### 共通
- [Claude Code](https://claude.ai/download) がインストール・認証済み
- [GitHub CLI (gh)](https://cli.github.com/) がインストール・認証済み
- git が設定済み

### devcontainer の場合（追加）
- [VSCode](https://code.visualstudio.com/) がインストール済み
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) が起動中
- VSCode の [Dev Containers 拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) がインストール済み

---

## セットアップ手順

### オプションA: devcontainer（推奨）

devcontainerの詳細なセットアップ手順は [devcontainer-setup.md](devcontainer-setup.md) を参照してください。

概要：
1. Docker Desktop を起動
2. VSCode でプロジェクトを開く
3. コマンドパレットから "Dev Containers: Reopen in Container" を実行
4. コンテナのビルドを待つ（初回は数分かかります）
5. コンテナ内のターミナルで以下の手順を続行

### オプションB: ローカル環境

#### Mac

```bash
# リポジトリをクローン
git clone https://github.com/nakaken-churadata/aichat-pbcc.git
cd aichat-pbcc

# tmux環境を構築（既存セッションは自動削除）
./setup.sh
```

#### Windows

Windows では WSL2 (Windows Subsystem for Linux) を使用することを推奨します。WSL2 上で Mac と同様の手順を実行してください。

---

## マルチエージェント環境の起動

### 1. セッションにアタッチ

```bash
# 仲間セッション（桃太郎・お供3名）
tmux attach-session -t 仲間

# おじいさんセッション（別ターミナルで）
tmux attach-session -t おじいさん
```

### 2. Claude Code を起動

```bash
# おじいさんの認証を先に実施
tmux send-keys -t おじいさん 'claude' C-m
```

認証完了後、おじいさんに役割を伝える：

```bash
./agent-send.sh おじいさん "あなたは「おじいさん」です。環境変数 AGENT_ROLE を確認し、instructions/ojiisan.md の指示に従ってください。"
```

仲間セッションを一括起動：

```bash
for i in {0..3}; do tmux send-keys -t 仲間:0.$i 'claude' C-m; done
```

---

## 開発ツール一覧

| ツール | バージョン | 用途 |
|--------|-----------|------|
| Node.js | 20.x | フロントエンド・バックエンド実行環境 |
| git | 最新 | バージョン管理 |
| tmux | 最新 | マルチエージェント環境 |
| GitHub CLI (gh) | 最新 | PR・issue管理 |
| gitleaks | 最新 | シークレット漏洩検知（コミット時フック） |
| Claude Code | 最新 | AIエージェント実行 |

---

## エージェント役割と環境変数

各エージェントは `AGENT_ROLE` 環境変数で役割が指定されます：

| 値 | 役割 | 指示書 |
|----|------|--------|
| `おじいさん` | 統括責任者 | `instructions/ojiisan.md` |
| `桃太郎` | チームリーダー | `instructions/momotarou.md` |
| `お供の犬` | 実行担当A | `instructions/otomo.md` |
| `お供の猿` | 実行担当B | `instructions/otomo.md` |
| `お供の雉` | 実行担当C | `instructions/otomo.md` |

---

## 開発フロー

詳細なフローは `instructions/flow.md` を参照してください。基本的な流れ：

1. おじいさんが桃太郎に作業を依頼
2. 桃太郎がGitHub issueを作成し、お供に指示（きびだんご儀式）
3. お供がブランチ・worktree作成 → 実装 → PR作成 → 桃太郎に報告
4. 別のお供がレビュー → 桃太郎が承認判断
5. お供がクローズ処理（マージ → worktree/ブランチ削除 → main最新化）

### worktree の作成場所

```bash
# 必ずプロジェクトルート直下の worktrees/ に作成
git worktree add worktrees/feature-issue-XX -b feature/issue-XX-description
```

---

## トラブルシューティング

### エージェントが役割を正しく認識しない

`AGENT_ROLE` 環境変数が正しく設定されているか確認してください：

```bash
echo $AGENT_ROLE
```

詳細な分析と対策は `docs/agent-role-fix-plan.md` を参照してください。

### devcontainer で Claude Code が強制終了する

`docs/devcontainer-claude-fix-proposal.md` を参照してください。主な対策：
- npmパッケージでのインストール: `npm install -g @anthropic-ai/claude-code`
- `NET_ADMIN`, `NET_RAW` capabilityの付与

### CORSエラーが発生する

バックエンドの `ALLOWED_ORIGINS` 環境変数が正しく設定されているか確認：

```bash
# docker-compose の場合
# docker-compose.yml の backend.environment.ALLOWED_ORIGINS を確認
```

### Gemini API エラー

`GEMINI_API_KEY` が正しく設定されているか確認：

```bash
echo $GEMINI_API_KEY
```
