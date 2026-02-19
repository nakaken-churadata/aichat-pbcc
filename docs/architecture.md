# アーキテクチャ（aichat）

## 概要

aichat は Gemini API を利用したチャットシステムです。フロントエンドとバックエンドを分離した構成で、クラウド・ローカルどちらの環境でも動作します。

## 階層構造

```
[ブラウザ]
    │ HTTP/HTTPS
    ▼
[フロントエンド (chat-frontend)]
    │ HTTP POST (NEXT_PUBLIC_API_URL)
    ▼
[バックエンド (chat-backend)]
    ├──► [生成AI (Gemini API)]
    └──► [データベース] ※将来的な拡張
```

## 各階層の説明

### フロントエンド (`chat-frontend/`)
- **役割**: ユーザーインターフェースの提供
- **技術**: Next.js (SSR), React, Tailwind CSS
- **連携**: バックエンドの `/api/chat` エンドポイントにHTTP POSTでリクエスト
- **環境変数**: `NEXT_PUBLIC_API_URL`（バックエンドURL）

### バックエンド (`chat-backend/`)
- **役割**: APIリクエストの処理・生成AIとの連携
- **技術**: Next.js API Routes, TypeScript
- **エンドポイント**:
  - `POST /api/chat` - チャットメッセージの処理
  - `GET /api/health` - ヘルスチェック
- **連携**: Gemini API (Google Generative AI SDK)
- **セキュリティ**: CORS middleware（`ALLOWED_ORIGINS` 環境変数で制御）

### 生成AI (Gemini API)
- **役割**: チャットメッセージへの応答生成
- **技術**: Google Gemini API
- **認証**: `GEMINI_API_KEY`（バックエンドのみが保持）

## ディレクトリ構成

```
aichat-pbcc/
├── chat-frontend/          # フロントエンド（Next.js SSR）
│   ├── app/               # Next.js App Router
│   ├── lib/               # API クライアント
│   ├── Dockerfile
│   └── package.json
│
├── chat-backend/          # バックエンド（Next.js API Routes）
│   ├── app/api/          # API エンドポイント
│   │   ├── chat/        # チャットAPI
│   │   └── health/      # ヘルスチェック
│   ├── middleware.ts     # CORS設定
│   ├── Dockerfile
│   └── package.json
│
├── terraform/             # Cloud Run デプロイ用
└── docker-compose.yml     # ローカル開発環境
```

## 設計上の特徴

- **フロントエンド・バックエンド分離**: 独立したスケーリング・デプロイが可能
- **セキュリティ**: API キーはバックエンドのみが保持し、フロントエンドには露出しない
- **型安全性**: TypeScript による一貫した型チェック
