# インフラストラクチャ（aichat）

## 概要

aichat は、ローカル (Docker Compose) とクラウド (Google Cloud Run) の2つの環境をサポートしています。

> **注**: devcontainer はエージェント型コーディングの開発環境です。[development.md](development.md) を参照してください。

## 環境一覧

| 環境 | 用途 | 主な技術 |
|------|------|----------|
| ローカル (Docker Compose) | 動作確認・開発 | Docker, Docker Compose |
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

