# Chat with Gemini

Next.jsとGoogle Gemini AIを使用したシンプルなチャットアプリケーションです。

## 機能

- リアルタイムストリーミング応答
- ChatGPTスタイルのUI
- ダークモード対応
- セッション内での会話履歴保持

## セットアップ

### 1. APIキーの設定

`app/page.tsx` ファイルを開き、`GEMINI_API_KEY` を自分のAPIキーに置き換えてください。

```typescript
const GEMINI_API_KEY = 'YOUR_API_KEY_HERE';
```

Google AI Studioで無料のAPIキーを取得できます: https://makersuite.google.com/app/apikey

### 2. 依存関係のインストール

```bash
npm install
```

### 3. 開発サーバーの起動

```bash
npm run dev
```

ブラウザで http://localhost:3000 を開いてください。

## ビルド

```bash
npm run build
npm start
```

## Google Cloud Runへのデプロイ

### 前提条件

- Google Cloud CLIがインストールされていること
- Google Cloudプロジェクトが作成されていること
- Cloud Run APIが有効化されていること

### デプロイ手順

1. Google Cloudにログイン

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

2. Container Registryの有効化

```bash
gcloud services enable containerregistry.googleapis.com
gcloud services enable run.googleapis.com
```

3. Dockerイメージのビルドとプッシュ

```bash
# プロジェクトIDを設定
export PROJECT_ID=YOUR_PROJECT_ID

# イメージをビルド
docker build -t gcr.io/$PROJECT_ID/chat-app:latest .

# Container Registryにプッシュ
docker push gcr.io/$PROJECT_ID/chat-app:latest
```

4. Cloud Runにデプロイ

```bash
gcloud run deploy chat-app \
  --image gcr.io/$PROJECT_ID/chat-app:latest \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --port 3000
```

デプロイが完了すると、アクセス可能なURLが表示されます。

## Cloud Build を使った自動デプロイ（オプション）

`cloudbuild.yaml` ファイルを使用して、Cloud Build経由でデプロイすることもできます。

```bash
gcloud builds submit --config cloudbuild.yaml
```

## 環境変数

本番環境でAPIキーを環境変数として管理する場合：

1. `app/page.tsx` を編集して環境変数から読み込むように変更

```typescript
const GEMINI_API_KEY = process.env.NEXT_PUBLIC_GEMINI_API_KEY || 'YOUR_API_KEY_HERE';
```

2. Cloud Runデプロイ時に環境変数を設定

```bash
gcloud run deploy chat-app \
  --image gcr.io/$PROJECT_ID/chat-app:latest \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --port 3000 \
  --set-env-vars NEXT_PUBLIC_GEMINI_API_KEY=your_actual_api_key
```

## 技術スタック

- **フレームワーク**: Next.js 15 (App Router)
- **言語**: TypeScript
- **スタイリング**: Tailwind CSS
- **AI**: Google Gemini API
- **デプロイ**: Google Cloud Run

## ライセンス

MIT
