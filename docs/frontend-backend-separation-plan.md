# フロントエンド・バックエンド分離プラン

## Context

現在、チャットアプリケーション（`chat-app/`）は、Next.js 16で構築された単一のモノリシックアプリケーションです。フロントエンド（React UI）とバックエンド（API Routes）が同じDockerコンテナで動作しており、以下の課題があります：

- **スケーリングの柔軟性不足**: フロントエンドとバックエンドを独立してスケールできない
- **デプロイの複雑さ**: 片方の変更でも両方を再デプロイする必要がある
- **セキュリティ**: API Keyなどの機密情報がフロントエンドと同じコンテナに存在
- **パフォーマンス**: 静的コンテンツ配信とAPI処理が同一リソースを共有

この変更により、以下を実現します：

- フロントエンドとバックエンドを**別々のCloud Runインスタンス**で動作
- 独立したスケーリング、デプロイ、モニタリング
- セキュリティの向上（API Keyはバックエンドのみ）
- 既存機能（Gemini API、Google Search grounding、citations）の完全な維持

---

## Architecture Overview

### 現在のアーキテクチャ

```
[Next.js Container (Port 8080)]
├── Frontend (React UI) - SSR/SSG
└── Backend (API Routes - /api/chat)
    └── Gemini API Integration
```

### 新しいアーキテクチャ

```
[Frontend Instance - Cloud Run]          [Backend Instance - Cloud Run]
├── Next.js 16 (SSR)                     ├── Next.js 16 (API Routes only)
├── React 19 UI                          ├── /api/chat endpoint
└── Tailwind CSS                         ├── /api/health endpoint
    │                                    ├── CORS middleware
    │ HTTP POST                          └── Gemini API Integration
    └────────────────────────────────────►
         NEXT_PUBLIC_API_URL
```

**技術選択の理由:**

- **フロントエンド**: Next.js SSR を保持
  - SEO対応が可能
  - フォント最適化などNext.js機能を活用
  - 将来的な認証・セッション管理の拡張が容易

- **バックエンド**: Next.js API Routes を保持
  - 既存コードの最小限の変更で移行可能
  - TypeScript型安全性を維持
  - Google Generative AI SDKとの統合をそのまま活用

---

## Implementation Plan

### Phase 1: プロジェクト構造の準備

**1.1 既存コードのバックアップ**
```bash
cd /Users/kenji.nakagaki/git/aichat-pbcc
mv chat-app chat-app-legacy
```

**1.2 新ディレクトリの作成**
```bash
mkdir -p chat-frontend/app chat-frontend/lib chat-frontend/public
mkdir -p chat-backend/app/api
```

---

### Phase 2: バックエンドの実装

**2.1 基本ファイルのコピー**
```bash
# 既存のAPIロジックをコピー
cp -r chat-app-legacy/app/api/chat chat-backend/app/api/
cp chat-app-legacy/package.json chat-backend/
cp chat-app-legacy/tsconfig.json chat-backend/
cp chat-app-legacy/next.config.ts chat-backend/
cp chat-app-legacy/.env.example chat-backend/
```

**2.2 CORS ミドルウェアの作成**

ファイル: `chat-backend/middleware.ts`
```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const origin = request.headers.get('origin');
  const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [];

  if (process.env.NODE_ENV === 'development') {
    allowedOrigins.push('http://localhost:3000', 'http://localhost:8080');
  }

  const response = NextResponse.next();

  if (origin && (allowedOrigins.includes(origin) || allowedOrigins.includes('*'))) {
    response.headers.set('Access-Control-Allow-Origin', origin);
    response.headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
    response.headers.set('Access-Control-Max-Age', '86400');
  }

  if (request.method === 'OPTIONS') {
    return new NextResponse(null, { status: 204, headers: response.headers });
  }

  return response;
}

export const config = {
  matcher: '/api/:path*',
};
```

**2.3 ヘルスチェックエンドポイントの追加**

ファイル: `chat-backend/app/api/health/route.ts`
```typescript
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'chat-backend',
  });
}
```

**2.4 chat/route.ts の修正**

`chat-backend/app/api/chat/route.ts` に OPTIONS メソッドを追加:
```typescript
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
```

**2.5 package.json の修正**

`chat-backend/package.json` から不要な依存を削除（React関連は不要）

**2.6 環境変数設定**

`chat-backend/.env.example`:
```
GEMINI_API_KEY=your_api_key_here
ALLOWED_ORIGINS=http://localhost:3000
```

`chat-backend/.env.local`:
```
GEMINI_API_KEY=AIzaSyCrIltaWWJZNwS0djqhdIn5xNRW-_ZeZbg
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

**2.7 Dockerfile の作成**

`chat-backend/Dockerfile` は既存の `chat-app-legacy/Dockerfile` とほぼ同じ:
```dockerfile
FROM node:20-alpine AS base

FROM base AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 8080
ENV PORT=8080
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
```

---

### Phase 3: フロントエンドの実装

**3.1 基本ファイルのコピー**
```bash
cp -r chat-app-legacy/app chat-frontend/
cp -r chat-app-legacy/public chat-frontend/
cp chat-app-legacy/package.json chat-frontend/
cp chat-app-legacy/tsconfig.json chat-frontend/
cp chat-app-legacy/next.config.ts chat-frontend/
cp chat-app-legacy/postcss.config.mjs chat-frontend/
cp chat-app-legacy/eslint.config.mjs chat-frontend/
cp chat-app-legacy/.env.example chat-frontend/
```

**3.2 app/api ディレクトリの削除**
```bash
rm -rf chat-frontend/app/api
```

**3.3 API クライアントライブラリの作成**

ファイル: `chat-frontend/lib/api-client.ts`
```typescript
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8081';

export interface ChatRequest {
  message: string;
}

export interface ChatResponse {
  response: string;
  citations?: string[];
  searchEntryPoint?: string;
}

export async function sendChatMessage(message: string): Promise<ChatResponse> {
  const response = await fetch(`${API_BASE_URL}/api/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ message }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'API request failed' }));
    throw new Error(error.error || 'チャット処理中にエラーが発生しました');
  }

  return response.json();
}
```

**3.4 page.tsx の修正**

`chat-frontend/app/page.tsx` の fetch 呼び出しを `api-client.ts` 経由に変更:

変更前:
```typescript
const response = await fetch('/api/chat', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ message: input }),
});
const data = await response.json();
```

変更後:
```typescript
import { sendChatMessage } from '@/lib/api-client';

// ...

try {
  const data = await sendChatMessage(input);
  // ... 既存の処理
} catch (error) {
  setMessages(prev => [...prev, {
    role: 'assistant',
    content: error instanceof Error ? error.message : 'エラーが発生しました',
  }]);
}
```

**3.5 package.json の修正**

`chat-frontend/package.json` から `@google/generative-ai` を削除

**3.6 環境変数設定**

`chat-frontend/.env.example`:
```
NEXT_PUBLIC_API_URL=http://localhost:8081
```

`chat-frontend/.env.local`:
```
NEXT_PUBLIC_API_URL=http://localhost:8081
```

**3.7 Dockerfile の作成**

`chat-frontend/Dockerfile`:
```dockerfile
FROM node:20-alpine AS base

FROM base AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 8080

ENV PORT=8080
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
```

---

### Phase 4: ローカル開発環境の構築

**4.1 docker-compose.yml の作成**

ファイル: `/Users/kenji.nakagaki/git/aichat-pbcc/docker-compose.yml`
```yaml
version: '3.8'

services:
  frontend:
    build:
      context: ./chat-frontend
      dockerfile: Dockerfile
      args:
        NEXT_PUBLIC_API_URL: http://localhost:8081
    ports:
      - "3000:8080"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8080
    depends_on:
      - backend
    networks:
      - chat-network

  backend:
    build:
      context: ./chat-backend
      dockerfile: Dockerfile
    ports:
      - "8081:8080"
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}
      - ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
      - NODE_ENV=development
    networks:
      - chat-network

networks:
  chat-network:
    driver: bridge
```

---

### Phase 5: テストと検証

**5.1 バックエンド単体テスト**
```bash
cd /Users/kenji.nakagaki/git/aichat-pbcc/chat-backend
npm install
cp .env.example .env.local
# .env.local に GEMINI_API_KEY を設定
PORT=8081 npm run dev
```

ヘルスチェック:
```bash
curl http://localhost:8081/api/health
```

API テスト:
```bash
curl -X POST http://localhost:8081/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "こんにちは"}'
```

**5.2 フロントエンド単体テスト**
```bash
cd /Users/kenji.nakagaki/git/aichat-pbcc/chat-frontend
npm install
cp .env.example .env.local
# .env.local に NEXT_PUBLIC_API_URL=http://localhost:8081 を設定
npm run dev
```

ブラウザで `http://localhost:3000` を開いてチャット機能を確認

**5.3 統合テスト（docker-compose）**
```bash
cd /Users/kenji.nakagaki/git/aichat-pbcc
export GEMINI_API_KEY=your_api_key_here
docker-compose up --build
```

ブラウザで `http://localhost:3000` を開いて:
- チャットメッセージの送信
- AI応答の受信
- 引用元URLの表示
- エラーハンドリング

全て動作することを確認

---

### Phase 6: Cloud Run デプロイ

**6.1 バックエンドのデプロイ**
```bash
cd /Users/kenji.nakagaki/git/aichat-pbcc/chat-backend

# イメージビルド
gcloud builds submit --tag asia-northeast1-docker.pkg.dev/[PROJECT_ID]/chat-app/backend:latest

# Cloud Run デプロイ
gcloud run deploy chat-backend \
  --image asia-northeast1-docker.pkg.dev/[PROJECT_ID]/chat-app/backend:latest \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --set-secrets GEMINI_API_KEY=GEMINI_API_KEY:latest \
  --set-env-vars ALLOWED_ORIGINS=https://chat-frontend-[HASH].run.app \
  --port 8080 \
  --memory 512Mi \
  --cpu 1

# バックエンドURLを取得
BACKEND_URL=$(gcloud run services describe chat-backend --region asia-northeast1 --format 'value(status.url)')
echo "Backend URL: $BACKEND_URL"
```

**6.2 フロントエンドのデプロイ**
```bash
cd /Users/kenji.nakagaki/git/aichat-pbcc/chat-frontend

# イメージビルド（バックエンドURLを埋め込む）
gcloud builds submit \
  --config - <<EOF
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'asia-northeast1-docker.pkg.dev/$PROJECT_ID/chat-app/frontend:latest'
      - '--build-arg'
      - 'NEXT_PUBLIC_API_URL=$BACKEND_URL'
      - '.'
images:
  - 'asia-northeast1-docker.pkg.dev/$PROJECT_ID/chat-app/frontend:latest'
EOF

# Cloud Run デプロイ
gcloud run deploy chat-frontend \
  --image asia-northeast1-docker.pkg.dev/[PROJECT_ID]/chat-app/frontend:latest \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 256Mi \
  --cpu 1

# フロントエンドURLを取得
FRONTEND_URL=$(gcloud run services describe chat-frontend --region asia-northeast1 --format 'value(status.url)')
echo "Frontend URL: $FRONTEND_URL"
```

**6.3 バックエンドのCORS設定を更新**
```bash
gcloud run services update chat-backend \
  --region asia-northeast1 \
  --set-env-vars ALLOWED_ORIGINS=$FRONTEND_URL
```

**6.4 本番環境での動作確認**

ブラウザで `$FRONTEND_URL` を開いて、全機能をテスト

---

### Phase 7: クリーンアップ

**7.1 レガシーコードの削除**

動作確認が完了したら:
```bash
cd /Users/kenji.nakagaki/git/aichat-pbcc
rm -rf chat-app-legacy
```

**7.2 ドキュメントの更新**

`README.md` を更新して新しいアーキテクチャを反映

---

## Critical Files

### 新規作成が必要なファイル

1. **`chat-backend/middleware.ts`**
   - CORS設定の中核
   - すべてのAPIリクエストに適用される

2. **`chat-backend/app/api/health/route.ts`**
   - ヘルスチェックエンドポイント
   - モニタリング用

3. **`chat-frontend/lib/api-client.ts`**
   - API通信を抽象化
   - エラーハンドリングを一元管理

4. **`docker-compose.yml`**
   - ローカル開発環境の統合
   - フロントエンドとバックエンドのネットワーク構成

### 修正が必要なファイル

5. **`chat-frontend/app/page.tsx`**
   - 既存: `/api/chat` への直接fetch
   - 修正: `sendChatMessage()` 関数を使用

6. **`chat-backend/app/api/chat/route.ts`**
   - 既存: POST メソッドのみ
   - 追加: OPTIONS メソッド（CORS プリフライト対応）

7. **`chat-frontend/package.json`**
   - 削除: `@google/generative-ai` 依存

8. **`chat-backend/package.json`**
   - 削除: React関連の依存（react, react-dom）

### 環境変数ファイル

9. **`chat-frontend/.env.local`**
   ```
   NEXT_PUBLIC_API_URL=http://localhost:8081
   ```

10. **`chat-backend/.env.local`**
    ```
    GEMINI_API_KEY=AIzaSyCrIltaWWJZNwS0djqhdIn5xNRW-_ZeZbg
    ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
    ```

---

## Verification（検証手順）

### ローカル開発環境でのテスト

**1. バックエンドの起動と確認**
```bash
cd chat-backend
PORT=8081 npm run dev

# 別ターミナルで
curl http://localhost:8081/api/health
# 期待: {"status":"ok","timestamp":"...","service":"chat-backend"}

curl -X POST http://localhost:8081/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "2024年の日本の首相は誰ですか？"}'
# 期待: Gemini APIからの応答 + citations
```

**2. フロントエンドの起動と確認**
```bash
cd chat-frontend
npm run dev

# ブラウザで http://localhost:3000 を開く
```

**3. エンドツーエンドテスト**

ブラウザで以下を確認:
- [ ] チャット入力フィールドが表示される
- [ ] メッセージを送信できる
- [ ] AIからの応答が表示される
- [ ] 引用元URLがクリック可能なリンクとして表示される
- [ ] エラー時に適切なメッセージが表示される
- [ ] ブラウザのDevToolsでCORSエラーがないことを確認
- [ ] ネットワークタブで `http://localhost:8081/api/chat` へのリクエストが成功

**4. Docker Composeでのテスト**
```bash
cd /Users/kenji.nakagaki/git/aichat-pbcc
export GEMINI_API_KEY=your_api_key_here
docker-compose up --build

# ブラウザで http://localhost:3000 を開いて上記テストを繰り返す
```

### 本番環境（Cloud Run）でのテスト

**1. デプロイ後の確認**
```bash
# バックエンド
curl https://chat-backend-xxxxx.run.app/api/health

# フロントエンド
# ブラウザで https://chat-frontend-xxxxx.run.app を開く
```

**2. 機能テスト**
- [ ] チャット機能が正常に動作
- [ ] Google Search grounding が機能（引用元が表示される）
- [ ] レスポンスタイムが許容範囲内（< 3秒）
- [ ] CORSエラーがない
- [ ] モバイルブラウザでも動作

**3. セキュリティ確認**
- [ ] フロントエンドのソースコードにGEMINI_API_KEYが含まれていない
- [ ] バックエンドのCORS設定が特定のオリジンのみを許可
- [ ] HTTPSで通信されている

**4. パフォーマンステスト**
```bash
# 複数リクエストを送信してレスポンスタイムを測定
for i in {1..10}; do
  time curl -X POST https://chat-backend-xxxxx.run.app/api/chat \
    -H "Content-Type: application/json" \
    -d '{"message": "Hello"}' > /dev/null 2>&1
done
```

---

## Rollback Plan（ロールバック計画）

問題が発生した場合の復旧手順:

**1. Cloud Runで以前のバージョンに戻す**
```bash
gcloud run services update-traffic chat-backend --to-revisions PREVIOUS_REVISION=100
gcloud run services update-traffic chat-frontend --to-revisions PREVIOUS_REVISION=100
```

**2. ローカルで既存コードに戻す**
```bash
cd /Users/kenji.nakagaki/git/aichat-pbcc
# chat-app-legacy が残っている場合
mv chat-app-legacy chat-app
```

**3. Docker Composeの停止**
```bash
docker-compose down
docker system prune -f
```

---

## Estimated Timeline

- **Phase 1-3** (コード実装): 2-3時間
- **Phase 4-5** (ローカルテスト): 1時間
- **Phase 6** (Cloud Runデプロイ): 1-2時間
- **Phase 7** (クリーンアップ): 30分

**合計**: 約5-7時間の作業時間を見込む

---

## Notes

- GEMINI_API_KEY は `.env.local` に既に設定済み（`AIzaSyCrIltaWWJZNwS0djqhdIn5xNRW-_ZeZbg`）
- Google Cloud Project ID は実際の値に置き換える必要あり
- 既存の `chat-app/` は `chat-app-legacy/` として保持し、動作確認後に削除
- フロントエンドはSSRを保持するため、完全な静的エクスポートではない
- 両方のサービスを同じリージョン（asia-northeast1）にデプロイして低レイテンシを確保
