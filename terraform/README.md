# Chat Application - Terraform Deployment

このディレクトリには、チャットアプリケーション（フロントエンド・バックエンド）を Google Cloud Run にデプロイするための Terraform 設定が含まれています。

## 前提条件

1. Google Cloud SDK (`gcloud`) がインストールされていること
2. Terraform (>= 1.0) がインストールされていること
3. Google Cloud プロジェクトが作成されていること
4. 必要な API が有効化されていること:
   - Cloud Run API
   - Cloud Build API
   - Artifact Registry API
   - Secret Manager API

## セットアップ

### 1. API の有効化

```bash
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

### 2. イメージのビルドとプッシュ

#### バックエンド

```bash
cd ../chat-backend

gcloud builds submit \
  --tag asia-northeast1-docker.pkg.dev/[PROJECT_ID]/chat-app/backend:latest
```

#### フロントエンド

まず、バックエンドの URL を取得します（デプロイ後）:

```bash
BACKEND_URL=$(terraform output -raw backend_url)
```

次に、フロントエンドをビルドします:

```bash
cd ../chat-frontend

gcloud builds submit \
  --substitutions _NEXT_PUBLIC_API_URL=$BACKEND_URL \
  --config - <<EOF
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'asia-northeast1-docker.pkg.dev/\$PROJECT_ID/chat-app/frontend:latest'
      - '--build-arg'
      - 'NEXT_PUBLIC_API_URL=\${_NEXT_PUBLIC_API_URL}'
      - '.'
images:
  - 'asia-northeast1-docker.pkg.dev/\$PROJECT_ID/chat-app/frontend:latest'
EOF
```

### 3. Terraform の設定

#### terraform.tfvars の作成

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集して、以下の値を設定してください:

- `project_id`: GCP プロジェクト ID
- `region`: デプロイするリージョン（デフォルト: asia-northeast1）
- `gemini_api_key`: Gemini API キー

### 4. Terraform の実行

#### 初期化

```bash
terraform init
```

#### プランの確認

```bash
terraform plan
```

#### デプロイ

```bash
terraform apply
```

### 5. URL の確認

デプロイが完了したら、以下のコマンドで URL を確認できます:

```bash
terraform output backend_url
terraform output frontend_url
```

## アーキテクチャ

```
┌─────────────────────┐
│  Cloud Run          │
│  (Frontend)         │
│  Port: 8080         │
│  Memory: 256Mi      │
│  CPU: 1             │
└──────────┬──────────┘
           │ HTTPS
           │
           ▼
┌─────────────────────┐       ┌──────────────────┐
│  Cloud Run          │◄──────┤ Secret Manager   │
│  (Backend)          │       │ (GEMINI_API_KEY) │
│  Port: 8080         │       └──────────────────┘
│  Memory: 512Mi      │
│  CPU: 1             │
└──────────┬──────────┘
           │
           ▼
    ┌────────────┐
    │ Gemini API │
    └────────────┘
```

## リソース

Terraform で管理されるリソース:

- **Artifact Registry Repository**: Docker イメージの保存
- **Cloud Run Service (Backend)**: バックエンド API
- **Cloud Run Service (Frontend)**: フロントエンド UI
- **Secret Manager Secret**: Gemini API キーの安全な保存
- **IAM Bindings**: パブリックアクセスとシークレットアクセスの権限

## 環境変数

### バックエンド

- `NODE_ENV`: 本番環境（production）
- `ALLOWED_ORIGINS`: フロントエンドの URL（CORS 設定）
- `GEMINI_API_KEY`: Secret Manager から取得

### フロントエンド

- `NODE_ENV`: 本番環境（production）
- `NEXT_PUBLIC_API_URL`: バックエンドの URL（ビルド時に埋め込み）

## クリーンアップ

すべてのリソースを削除する場合:

```bash
terraform destroy
```

## トラブルシューティング

### イメージが見つからない

Artifact Registry にイメージがプッシュされていることを確認してください:

```bash
gcloud artifacts docker images list \
  asia-northeast1-docker.pkg.dev/[PROJECT_ID]/chat-app
```

### Secret Manager のエラー

Secret Manager API が有効化されていることを確認してください:

```bash
gcloud services enable secretmanager.googleapis.com
```

### CORS エラー

フロントエンドの URL がバックエンドの `ALLOWED_ORIGINS` に正しく設定されていることを確認してください。フロントエンドのデプロイ後、バックエンドの環境変数を更新する必要がある場合があります:

```bash
terraform apply -var="frontend_url=https://your-frontend-url.run.app"
```
