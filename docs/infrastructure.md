# インフラストラクチャ

## 概要

このプロジェクトは、ローカル・Docker (devcontainer)・クラウド (Google Cloud Run) の3つの環境をサポートしています。

## 環境一覧

| 環境 | 用途 | 主な技術 |
|------|------|----------|
| ローカル (Docker Compose) | 開発・動作確認 | Docker, Docker Compose |
| devcontainer (VSCode) | 推奨開発環境 | VSCode Dev Containers, Docker |
| クラウド (Google Cloud) | 本番デプロイ | Cloud Run, Artifact Registry, Secret Manager, Terraform |

---

## ローカル環境 (Docker Compose)

### 構成

```yaml
services:
  frontend:  # ポート 3000
  backend:   # ポート 8081
```

### セットアップ

```bash
# 環境変数を設定
export GEMINI_API_KEY=your_api_key

# 起動
docker-compose up
```

### ポート

| サービス | ホスト側ポート | コンテナ側ポート |
|----------|---------------|-----------------|
| frontend | 3000 | 8080 |
| backend  | 8081 | 8080 |

### 環境変数

| 変数名 | 対象 | 説明 |
|--------|------|------|
| `GEMINI_API_KEY` | backend | Google Gemini APIキー |
| `ALLOWED_ORIGINS` | backend | CORS許可オリジン |
| `NEXT_PUBLIC_API_URL` | frontend | バックエンドURL |

---

## devcontainer 環境

devcontainerの詳細なセットアップ手順は [devcontainer-setup.md](devcontainer-setup.md) を参照してください。

### 概要

VSCode Dev Containers を使用した再現可能な開発環境です。`--dangerously-skip-permissions` を安全に使用するためのコンテナ分離環境を提供します。

### 構成

```
ホストマシン
├── VSCode (Dev Containers拡張機能)
├── Docker Desktop
└── Claude Code (ホストにインストール)
    │
    └──► devcontainer
         ├── Node.js 20
         ├── git, tmux, vim
         ├── GitHub CLI (gh)
         ├── gitleaks
         └── Claude Code CLI
```

### ボリュームマウント

| ホスト | コンテナ | 用途 |
|--------|----------|------|
| `~/.claude` | `~/.claude` | Claude Code認証情報の共有 |
| プロジェクトディレクトリ | プロジェクトディレクトリ | ソースコードの共有 |

### 転送ポート

| ポート | 用途 |
|--------|------|
| 3000 | フロントエンド開発サーバー |
| 8080 | バックエンド開発サーバー（代替） |
| 8081 | バックエンド API サーバー |

### 既知の問題と対策

devcontainer内でClaude Codeの強制終了が発生した場合は [devcontainer-claude-fix-proposal.md](devcontainer-claude-fix-proposal.md) を参照してください。主な原因：

- Claude Codeのインストール方法（npmパッケージを推奨）
- ファイアウォール設定の欠如（`NET_ADMIN`, `NET_RAW` capabilityが必要）
- `~/.claude` のバインドマウント設定

---

## クラウド環境 (Google Cloud)

### 使用サービス

| サービス | 用途 |
|----------|------|
| Cloud Run | フロントエンド・バックエンドのホスティング |
| Artifact Registry | Dockerイメージの保管 |
| Secret Manager | `GEMINI_API_KEY` などの機密情報管理 |
| Cloud Build | イメージのビルド |

### アーキテクチャ

```
[Cloud Run: frontend]
        │ HTTP POST
        ▼
[Cloud Run: backend]
        │
        ▼
  [Gemini API]
```

### デプロイ手順

詳細は `terraform/README.md` を参照してください。概要は以下の通りです：

```bash
# 1. 必要なAPIを有効化
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com

# 2. イメージをビルド&プッシュ（バックエンド）
cd chat-backend
gcloud builds submit --tag asia-northeast1-docker.pkg.dev/[PROJECT_ID]/chat-app/backend:latest

# 3. イメージをビルド&プッシュ（フロントエンド）
cd chat-frontend
gcloud builds submit ...

# 4. Terraformでデプロイ
cd terraform
terraform init && terraform plan && terraform apply
```

### クリーンアップ

```bash
cd terraform
terraform destroy
```

### 環境変数・シークレット

| 変数名 | 管理方法 | 対象サービス |
|--------|----------|-------------|
| `GEMINI_API_KEY` | Secret Manager | backend |
| `ALLOWED_ORIGINS` | 環境変数 | backend |
| `NEXT_PUBLIC_API_URL` | ビルド時引数 | frontend |

---

## マルチアーキテクチャ対応

devcontainerおよびDockerイメージは、Intel Mac (x86_64) と Appleシリコン Mac (ARM64) の両方に対応しています。

`Dockerfile` 内で `dpkg --print-architecture` を使用してアーキテクチャを自動検出し、適切なバイナリをダウンロードします。
