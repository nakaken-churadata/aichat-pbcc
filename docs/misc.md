# その他のドキュメント

上記3カテゴリ（アーキテクチャ・インフラストラクチャ・開発環境）に当てはまらない情報をまとめています。

## ドキュメント一覧

### エージェント通信・運用ガイドライン

- **[references/message-guidelines.md](references/message-guidelines.md)**: agent-send.sh を使った通信の最適化ガイドライン
  - メッセージの簡潔化ルール
  - カテゴリ別の良い例・悪い例
  - 役割別の口調ルール

### セキュリティ

- **[references/security-guidelines.md](references/security-guidelines.md)**: プロジェクトのセキュリティベストプラクティス
  - センシティブ情報の扱い方
  - APIキー・シークレットの管理方法
  - gitleaks によるコミット前チェック

### 調査・分析レポート

調査結果ドキュメントは `investigations/` ディレクトリに格納されています：

- **[investigations/cost-reduction-research.md](../investigations/cost-reduction-research.md)**: Claude Code トークン消費削減施策の調査結果
- **[investigations/kibidango-expression-fix-investigation.md](../investigations/kibidango-expression-fix-investigation.md)**: きびだんご儀式の表現修正に関連するissue調査結果
- **[investigations/phase1-measurement-report.md](../investigations/phase1-measurement-report.md)**: フェーズ1 効果測定レポート

### 技術的な問題分析・提案

- **[references/agent-role-fix-plan.md](references/agent-role-fix-plan.md)**: エージェント役割認識問題の分析と対応策
- **[references/devcontainer-claude-fix-proposal.md](references/devcontainer-claude-fix-proposal.md)**: devcontainer内でのClaude Code強制終了問題の対策案
- **[references/devcontainer-setup.md](references/devcontainer-setup.md)**: devcontainer詳細セットアップガイド
- **[references/frontend-backend-separation-plan.md](references/frontend-backend-separation-plan.md)**: フロントエンド・バックエンド分離の実装計画

## コントリビューション

このプロジェクトへの貢献方法は [CONTRIBUTING.md](../CONTRIBUTING.md) を参照してください。
