# Kishax Terraria Server

TShock を使用した Terraria サーバの Docker 環境です。

## 特徴

- **TShock 5.2.4** for Terraria 1.4.4.9
- **TerrariaChatRelay** プラグインによる Discord 連携
- **S3 自動同期**: ワールドデータとユーザーデータベースの自動ダウンロード・アップロード
- **再現性の高い環境**: Docker による環境の統一

## ディレクトリ構成

```
apps/terraria/
├── Dockerfile
├── compose.yml
├── Makefile
├── .env.example
├── README.md
└── docker/
    ├── config/
    │   ├── config.json.template              # TShock サーバ設定テンプレート
    │   └── TerrariaChatRelay-Discord.json.template  # Discord Bot 設定テンプレート
    ├── scripts/
    │   ├── start.sh                          # 起動スクリプト
    │   ├── download-from-s3.sh               # S3 からのダウンロード
    │   └── upload-to-s3.sh                   # S3 へのアップロード
    └── docs/
```

## セットアップ

### 1. 環境変数の設定

```bash
cp .env.example .env
```

`.env` を編集して以下の値を設定:

```bash
# Discord Bot Configuration
DISCORD_BOT_TOKEN=your-discord-bot-token
DISCORD_CHANNEL_ID=your-discord-channel-id

# Server Configuration
SERVER_PASSWORD=your-server-password
SERVER_NAME=Kishax Terraria Server

# REST API Configuration
REST_API_TOKEN=$(openssl rand -base64 32)
```

### 2. サーバの起動

```bash
docker compose up -d
```

### 3. サーバコンソールへのアクセス

```bash
make console
```

終了するには `Ctrl+A` → `D` を押してください。

## 使い方

### よく使うコマンド

| コマンド | 説明 |
|---------|------|
| `make console` | サーバコンソールに接続 |
| `make upload-s3` | ワールドデータを S3 にアップロード |
| `make download-s3` | S3 からワールドデータをダウンロード |
| `make backup-world` | ワールドを新バージョンとしてバックアップ |

詳細は `make help` を参照してください。

## S3 バケット構造

```
s3://kishax-production-terraria-backups/
  └── deployment/
      └── YYYYMM/
          └── VERSION/
              └── terraria/
                  ├── Worlds/
                  │   └── world.wld
                  └── tshock/
                      └── tshock.sqlite
```

### S3 連携の仕組み

1. **起動時**: S3 から最新のワールドデータと `tshock.sqlite` をダウンロード
2. **手動アップロード**: `make upload-s3` で既存バージョンに上書き
3. **バックアップ**: `make backup-world` で新しいバージョン番号を作成してアップロード

## Discord Bot セットアップ

1. [Discord Developer Portal](https://discord.com/developers/applications) でボットを作成
2. Bot Settings で **Message Content Intent** を有効化
3. Bot Token をコピーして `.env` の `DISCORD_BOT_TOKEN` に設定
4. サーバに Bot を招待
5. チャンネル ID を取得して `.env` の `DISCORD_CHANNEL_ID` に設定

## TShock コマンド

サーバコンソールまたはゲーム内で使用できるコマンド:

```bash
/help                          # ヘルプ表示
/setup <token>                 # 初回セットアップ
/user add <name> <pass> owner  # 管理者アカウント作成
/login <name> <pass>           # ログイン
/item <id> <count>             # アイテム付与
/godmode                       # 無敵モード切替
```

詳細は [`data/terraria/COMMANDS.md`](../../data/terraria/COMMANDS.md) を参照してください。

## トラブルシューティング

### サーバが起動しない

```bash
make logs
```

でログを確認してください。

### Discord Bot が動作しない

1. Bot Token が正しいか確認
2. Message Content Intent が有効になっているか確認
3. Bot がサーバに招待されているか確認

### ワールドデータが見つからない

初回起動時はワールドが自動生成されます。既存のワールドを使用する場合は:

```bash
make download-s3
docker compose restart
```

## 参考リンク

- [TShock 公式ドキュメント](https://tshock.readme.io/)
- [Terraria Wiki](https://terraria.fandom.com/wiki/Terraria_Wiki)
- [TerrariaChatRelay GitHub](https://github.com/xNarnia/TCR-TerrariaChatRelay)
