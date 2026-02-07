# GEMINI チャットアプリ

Next.js を使用した GEMINI API チャットアプリケーションです。

## 機能

- GEMINI API (Gemini 3 Flash) を使用したチャット機能
- セキュアな API キー管理（Secret Manager）
- レスポンシブデザイン

## 技術スタック

- Next.js 15 (App Router)
- TypeScript
- Tailwind CSS
- Google Generative AI SDK

## ローカル開発

### 必要なもの

- Node.js 20 以上
- GEMINI API キー

### セットアップ

1. 依存関係のインストール:
```bash
npm install
```

2. 環境変数の設定:
```bash
cp .env.example .env.local
```

`.env.local` ファイルに GEMINI API キーを設定してください。

3. 開発サーバーの起動:
```bash
npm run dev
```

http://localhost:3000 でアプリケーションが起動します。

## Cloud Run へのデプロイ

### 前提条件

- Google Cloud プロジェクトの作成
- Secret Manager で GEMINI_API_KEY の設定
- Container Registry または Artifact Registry の有効化

### デプロイ手順

1. Docker イメージのビルド:
```bash
docker build -t gcr.io/[PROJECT_ID]/chat-app .
```

2. イメージのプッシュ:
```bash
docker push gcr.io/[PROJECT_ID]/chat-app
```

3. Cloud Run へのデプロイ:
```bash
gcloud run deploy chat-app \
  --image gcr.io/[PROJECT_ID]/chat-app \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --set-secrets GEMINI_API_KEY=GEMINI_API_KEY:latest
```

## 環境変数

- `GEMINI_API_KEY`: GEMINI API キー（必須）

本番環境では Secret Manager から取得します。

## ライセンス

MIT
