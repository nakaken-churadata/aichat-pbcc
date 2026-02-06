# Agent Communication System

## エージェント構成
- **おじいさん** (別セッション): 統括責任者
- **桃太郎** (仲間:agents): チームリーダー
- **お供の犬,猿,雉** (仲間:agents): 実行担当

## あなたの役割
- **おじいさん**: @instructions/president.md
- **桃太郎**: @instructions/boss.md
- **お供の犬,猿,雉**: @instructions/otomo.md

## メッセージ送信
```bash
./agent-send.sh [相手] "[メッセージ]"
```

## 基本フロー
おじいさん → 桃太郎 → お供たち → 桃太郎 → おじいさん
