# devcontainer内でClaude Code実行時の強制終了問題 - 対策案

## 問題の概要

devcontainer内でClaude Codeを実行すると強制終了する問題が発生している。

## 原因分析

### 現在の実装と公式実装の比較

| 項目 | 現在の実装 | 公式実装 | 影響 |
|------|-----------|---------|------|
| **インストール方法** | インストールスクリプト<br>`curl -fsSL https://claude.ai/install.sh` | npmパッケージ<br>`npm install -g @anthropic-ai/claude-code` | ❌ スクリプトが失敗している可能性 |
| **ファイアウォール設定** | なし | `init-firewall.sh` を実行 | ❌ ネットワーク制御ができない |
| **コンテナ権限** | なし | `NET_ADMIN`, `NET_RAW` capability | ❌ ファイアウォール設定に必要 |
| **設定ディレクトリ** | ホストの `~/.claude` をバインドマウント | 名前付きボリューム + `CLAUDE_CONFIG_DIR` 環境変数 | ⚠️ 権限や互換性の問題がある可能性 |
| **ベースイメージ** | `mcr.microsoft.com/devcontainers/javascript-node:20-bookworm` | `node:20` | △ 大きな問題ではない |
| **ユーザー** | `node` | `node` | ✅ 一致 |

### 主な問題点

1. **Claude Codeのインストールが不完全**
   - インストールスクリプト（`install.sh`）は失敗時にスキップされるだけで、エラーが隠蔽されている
   - 公式のnpmパッケージを使用していない

2. **ファイアウォール設定の欠如**
   - 公式devcontainerでは `init-firewall.sh` によるネットワーク制御が必須
   - これがないとClaude Codeが適切に動作しない可能性がある

3. **必要な権限が付与されていない**
   - `NET_ADMIN` と `NET_RAW` のcapabilityがない
   - ファイアウォール設定に必要

## 対策案

### 方針

公式のdevcontainer実装を参考にして、以下の3つのアプローチが考えられる：

#### 【推奨】案1: 公式実装を完全に採用

Anthropicの公式devcontainer実装をそのまま採用する。

**メリット:**
- 公式でメンテナンスされている
- 動作保証がある
- セキュリティ機能（ファイアウォール）が含まれている

**デメリット:**
- 既存の設定を大幅に変更する必要がある
- 日本語対応などのカスタマイズが失われる

#### 案2: ハイブリッドアプローチ

公式実装の重要な部分（Claude Codeのインストール、ファイアウォール）を採用し、既存のカスタマイズ（日本語対応など）を維持する。

**メリット:**
- 既存のカスタマイズを維持できる
- Claude Codeの動作が保証される

**デメリット:**
- メンテナンスの手間が増える
- 公式実装との乖離が発生する可能性

#### 案3: 最小限の修正

インストール方法のみをnpmパッケージに変更し、ファイアウォール設定は導入しない。

**メリット:**
- 変更が少ない
- 既存の設定をほぼ維持できる

**デメリット:**
- セキュリティ機能がない
- 完全な動作保証がない

## 推奨される実装: 案2（ハイブリッドアプローチ）

既存のカスタマイズを維持しつつ、Claude Codeの確実な動作を実現する。

### 修正内容

#### 1. Dockerfile の修正

**変更前（48-52行目）:**
```dockerfile
# Claude Code CLI のインストール
RUN curl -fsSL https://claude.ai/install.sh -o /tmp/install-claude.sh \
    && chmod +x /tmp/install-claude.sh \
    && bash /tmp/install-claude.sh || echo "⚠️  Claude CLI のインストールをスキップ" \
    && rm -f /tmp/install-claude.sh
```

**変更後:**
```dockerfile
# Claude Code CLI のインストール（npmパッケージを使用）
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
```

**PATH設定の修正（54-55行目）:**
```dockerfile
# PATH に追加（npmグローバルパッケージのパス）
ENV PATH="/home/node/.local/bin:/usr/local/share/npm-global/bin:${PATH}"
```

#### 2. init-firewall.sh の追加

公式リポジトリから `init-firewall.sh` を取得して `.devcontainer/` に配置する。

```bash
# 取得コマンド（参考）
curl -fsSL https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/init-firewall.sh \
    -o .devcontainer/init-firewall.sh
chmod +x .devcontainer/init-firewall.sh
```

#### 3. devcontainer.json の修正

**追加する設定:**

```json
{
  "capAdd": [
    "NET_ADMIN",
    "NET_RAW"
  ],
  "postStartCommand": "sudo ./.devcontainer/init-firewall.sh",
  "containerEnv": {
    "IN_DEVCONTAINER": "true",
    "CLAUDE_CONFIG_DIR": "/home/node/.claude",
    "NODE_OPTIONS": "--max-old-space-size=4096"
  }
}
```

**マウント設定の見直し（オプション）:**

現在のホストバインドマウントを維持するか、名前付きボリュームに変更するか検討：

```json
{
  "mounts": [
    // 現行（ホストバインド）
    "source=${localEnv:HOME}/.claude,target=/home/node/.claude,type=bind,consistency=cached"

    // または 公式（名前付きボリューム）
    // "source=claude-code-config-${devcontainerId},target=/home/node/.claude,type=volume"
  ]
}
```

### 実装手順

#### ステップ1: バックアップ
```bash
# 現在の設定をバックアップ
cp .devcontainer/Dockerfile .devcontainer/Dockerfile.backup
cp .devcontainer/devcontainer.json .devcontainer/devcontainer.json.backup
```

#### ステップ2: Dockerfile を修正
- Claude Codeのインストール方法をnpmパッケージに変更
- PATH設定を更新

#### ステップ3: init-firewall.sh を追加
- 公式リポジトリから取得
- 実行権限を付与

#### ステップ4: devcontainer.json を修正
- `capAdd` でNET_ADMIN, NET_RAWを追加
- `postStartCommand` でinit-firewall.shを実行
- `containerEnv` でCLAUDE_CONFIG_DIR, NODE_OPTIONSを設定

#### ステップ5: devcontainerを再ビルド
```bash
# VSCodeのコマンドパレットから
# "Dev Containers: Rebuild Container" を実行
```

#### ステップ6: 動作確認
```bash
# コンテナ内で確認
claude --version
echo $CLAUDE_CONFIG_DIR
which claude
```

#### ステップ7: Claude Code の起動テスト
```bash
# setup.shを実行してtmuxセッションを作成
./setup.sh

# 各ペインでClaude Codeを起動
source ./agent-init.sh && claude --dangerously-skip-permissions
```

## 追加の考慮事項

### ドキュメントの更新

`docs/devcontainer-setup.md` の以下の箇所を修正：

1. **28-30行目**: 「ホストのClaude Codeを使用する」という記述を削除
2. **98-102行目**: Claude Codeのインストール方法をnpmパッケージに更新
3. **189-209行目**: トラブルシューティングセクションを更新

### テスト計画

1. **基本動作テスト**
   - devcontainerのビルドが成功すること
   - Claude Codeがインストールされていること
   - Claude Codeが起動すること

2. **マルチエージェント環境テスト**
   - setup.shが正常に動作すること
   - 各tmuxペインでClaude Codeが起動すること
   - agent-send.shでメッセージ送信ができること

3. **セキュリティテスト**
   - ファイアウォールルールが適用されていること
   - 許可されたドメインにのみアクセスできること

## 参考資料

### 公式ドキュメント
- [Claude Code devcontainer ドキュメント](https://code.claude.com/docs/en/devcontainer)
- [公式devcontainer実装](https://github.com/anthropics/claude-code/tree/main/.devcontainer)
- [Anthropic Dev Container Features](https://github.com/anthropics/devcontainer-features)

### コミュニティリソース
- [Trail of Bits: claude-code-devcontainer](https://github.com/trailofbits/claude-code-devcontainer) - セキュリティ監査用のサンドボックス実装
- [Using Claude Code Safely with Dev Containers](https://nakamasato.medium.com/using-claude-code-safely-with-dev-containers-b46b8fedbca9)
- [How to Safely Run AI Agents Inside a DevContainer](https://codewithandrea.com/articles/run-ai-agents-inside-devcontainer/)

## 次のステップ

1. 桃太郎/おじいさんに方針を確認
2. 承認後、GitHub issueを作成
3. 修正作業を実施
4. テストとドキュメント更新
5. プルリクエスト作成

---

**調査実施**: お供の犬
**作成日**: 2026-02-15
