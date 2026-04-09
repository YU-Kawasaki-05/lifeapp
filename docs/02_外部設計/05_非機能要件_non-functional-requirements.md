# 非機能要件
## プロジェクト名: ARDORS（アーダース）

---

## 1. 概要

本ドキュメントは ARDORS の機能要件（FR）を除く品質・制約要件を定義する。
個人開発・趣味プロジェクトであることを踏まえ、**コスト最小・運用負荷最小** を基本方針とする。

---

## 2. パフォーマンス要件

### 2.1 レスポンスタイム目標

| 操作種別 | 目標 | 上限 | 備考 |
|---------|------|------|------|
| 画面初期表示（Server Components） | < 800ms | < 2000ms | TTFB (Time To First Byte) |
| CRUD操作（Server Actions） | < 500ms | < 1500ms | create/update/delete |
| AI応答（通常・Haiku） | < 3s | < 10s | 初回トークン受信まで |
| AI応答（レビュー・Sonnet） | < 5s | < 20s | 初回トークン受信まで |
| Google Calendar pull | < 5s | < 15s | 外部API依存 |
| Google Calendar push | < 5s | < 15s | 外部API依存 |
| ダッシュボード表示（全データ集約） | < 1.5s | < 3s | |

### 2.2 パフォーマンス実現策

- **Server Components**: データ取得をサーバーサイドで実行し、HTML を事前生成
- **Streaming**: AI 応答は `StreamingTextResponse` でトークン単位にストリーミング
- **インデックス**: DB クエリに使用する全カラムにインデックスを設定（詳細は DB設計参照）
- **React Cache**: Server Components 間でのデータ重複取得を `cache()` で防ぐ
- **TanStack Query**: クライアントサイドのデータキャッシュ・再フェッチ管理

---

## 3. 可用性・信頼性要件

### 3.1 稼働率目標

| 項目 | 目標 | 根拠 |
|------|------|------|
| サービス全体 | 99%（月間約 7.3h 停止許容） | Vercel Hobby プランの SLA 内 |
| DB（Supabase） | 99.5% | Supabase Free tier の実績値 |
| AI API | 99% | Anthropic の実績値（ベストエフォート） |

### 3.2 障害時のフォールバック

| 障害 | フォールバック動作 |
|------|----------------|
| AI API 障害 | AI機能を使わない手動CRUDは全て正常動作（AI非依存ベースライン） |
| GCal API 障害 | 「Google Calendarとの通信に失敗しました」を表示。ARDORS 単体での操作は継続可能 |
| Supabase 障害 | サービス停止。ユーザーにメンテナンスページを表示 |

### 3.3 データ保護

| 項目 | 対策 |
|------|------|
| DB バックアップ | Supabase が自動バックアップ（Free tier: 7日間） |
| ユーザーデータ損失防止 | 論理削除（deleted_at）による誤削除防止 |
| セッション | Supabase Auth がセッション管理・自動リフレッシュ |

---

## 4. セキュリティ要件

### 4.1 認証・認可

| 要件 | 実装 |
|------|------|
| 認証方式 | Supabase Auth（Google OAuth + Email/Password） |
| セッション管理 | JWT（Supabase 管理）。有効期限: 1時間（リフレッシュトークン: 30日） |
| パスワード | bcrypt ハッシュ（Supabase が管理） |
| パスワード強度 | 最低8文字 |
| データ分離 | Supabase RLS で全テーブルをユーザー単位に分離 |
| ルート保護 | Next.js Middleware で未認証ユーザーをリダイレクト |

### 4.2 通信セキュリティ

| 要件 | 実装 |
|------|------|
| 通信暗号化 | HTTPS 必須（Vercel が自動で TLS 終端） |
| API キー保護 | `ANTHROPIC_API_KEY` 等は Server Actions のみで使用。`NEXT_PUBLIC_` 接頭辞禁止 |
| CORS | Next.js デフォルト設定（同一オリジンのみ） |

### 4.3 入力バリデーション

| 要件 | 実装 |
|------|------|
| Server Actions 入力検証 | 全 Action で Zod スキーマによるバリデーション |
| XSS 対策 | Next.js の JSX 自動エスケープ + ユーザー入力の DOMPurify サニタイズ |
| SQLインジェクション | Supabase クライアントのパラメータバインディング。生 SQL は使用しない |

### 4.4 機密データ

| データ | 保護方針 |
|--------|---------|
| `gcal_tokens.access_token` | 本番環境で Supabase Vault に保存（またはサーバーサイド暗号化） |
| `ai_conversations.content` | ユーザーの個人情報を含む可能性があるため外部ログ送信禁止 |
| パスワード | Supabase が bcrypt で管理。平文保存禁止 |

---

## 5. スケーラビリティ要件

### 5.1 現フェーズの前提

- **MAU**: 1人（個人開発・個人利用）〜 数百人（SaaS 公開後）
- Vercel Hobby（無料）/ Supabase Free tier で運用
- スケールアウトは将来フェーズで検討

### 5.2 将来スケール対応設計

現時点から将来のスケールに対応できる設計にしておく。

| 懸念点 | 現在の設計 | スケール時の対応 |
|--------|----------|--------------|
| DB 接続数 | Supabase の接続プール（PgBouncer）を利用 | Supabase Pro へのアップグレード |
| AI コスト | Haiku（低コスト）をデフォルト使用 | キャッシュ追加 + 課金ユーザー制限 |
| Vercel 制限 | Hobby: 100GB 帯域 / 月 | Pro プランへのアップグレード |
| 同時接続 | Server Actions は Serverless Function（自動スケール） | 追加設定不要 |

---

## 6. 保守性・開発効率要件

### 6.1 コード品質

| 要件 | 基準 |
|------|------|
| 型安全性 | TypeScript strict mode。`any` 型使用禁止 |
| Lint | ESLint（Next.js 推奨設定）+ Prettier |
| テストカバレッジ | P0 機能の Server Actions: 70% 以上 |
| コードレビュー | 個人開発のため不要（Claude Code との協業で補完） |

### 6.2 テスト戦略

| 種類 | ツール | 対象 | 目標カバレッジ |
|------|--------|------|-------------|
| 単体テスト | Vitest | Server Actions / ユーティリティ関数 | 70% |
| コンポーネントテスト | Testing Library | 主要 UI コンポーネント | 50% |
| E2Eテスト | Playwright | 認証フロー・主要 CRUD 操作 | 主要フロー全カバー |

### 6.3 CI/CD

| ステップ | ツール | 条件 |
|---------|--------|------|
| Lint チェック | ESLint | PR / push |
| 型チェック | tsc --noEmit | PR / push |
| ユニットテスト | Vitest | PR / push |
| 自動デプロイ | Vercel + GitHub Actions | main ブランチ push 時 |

### 6.4 ローカル開発環境

```bash
# 必須コマンド
npm run dev          # 開発サーバー起動（Next.js）
npm run test         # Vitest 実行
npm run lint         # ESLint チェック
npm run type-check   # TypeScript 型チェック
supabase start       # ローカル Supabase 起動
supabase db push     # マイグレーション適用
```

---

## 7. ユーザビリティ要件

### 7.1 レスポンシブ対応

| ブレークポイント | 対象デバイス | 対応 |
|---------------|-----------|------|
| < 640px (sm) | スマートフォン | 必須（ボトムナビ） |
| 640px〜1024px (md) | タブレット | 対応 |
| ≥ 1024px (lg) | PC・ラップトップ | 必須（サイドバーナビ） |

### 7.2 アクセシビリティ

| 要件 | 基準 |
|------|------|
| WCAG 準拠レベル | AA（努力目標） |
| キーボード操作 | 全主要操作をキーボードで実行可能 |
| スクリーンリーダー | shadcn/ui の aria 属性を活用 |
| カラーコントラスト | WCAG AA（4.5:1 以上） |

### 7.3 ブラウザ対応

| ブラウザ | サポート状況 |
|---------|-----------|
| Chrome（最新2メジャーバージョン） | ✅ 完全対応 |
| Firefox（最新2メジャーバージョン） | ✅ 完全対応 |
| Safari（最新2メジャーバージョン） | ✅ 完全対応 |
| Edge（最新2メジャーバージョン） | ✅ 完全対応 |
| Chrome Android（最新） | ✅ 完全対応 |
| Safari iOS（最新） | ✅ 完全対応（Web Speech API は制限あり） |

**注意**: Web Speech API（音声入力）は Chrome / Edge で安定。Safari iOS は制限あり（ユーザーに案内）。

---

## 8. 環境・インフラ要件

### 8.1 環境構成

| 環境 | ホスティング | DB | 用途 |
|------|------------|-----|------|
| ローカル開発 | `localhost:3000` | Supabase CLI（Docker） | 開発・テスト |
| Staging | Vercel Preview Deploy | Supabase（別プロジェクト） | PR プレビュー |
| 本番 | Vercel Hobby | Supabase Free | 実運用 |

### 8.2 環境変数

| 変数名 | 必須 | 説明 |
|--------|------|------|
| `NEXT_PUBLIC_SUPABASE_URL` | ✅ | Supabase プロジェクト URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | ✅ | Supabase 匿名キー |
| `SUPABASE_SERVICE_ROLE_KEY` | ✅ | Supabase サービスキー（サーバーサイドのみ） |
| `ANTHROPIC_API_KEY` | ✅ | Anthropic API キー（サーバーサイドのみ） |
| `AI_MODEL_DEFAULT` | ✅ | 通常AIモデル名 |
| `AI_MODEL_COACHING` | ✅ | コーチングAIモデル名 |
| `GOOGLE_CLIENT_ID` | ✅ | Google OAuth クライアントID |
| `GOOGLE_CLIENT_SECRET` | ✅ | Google OAuth シークレット（サーバーサイドのみ） |
| `NEXT_PUBLIC_APP_URL` | ✅ | アプリのベースURL |

### 8.3 コスト上限

| サービス | 月額上限 | 超過時のアクション |
|---------|---------|----------------|
| Anthropic API | $10 | アカウントに予算アラートを設定 |
| Vercel | $0（Hobby） | Pro へのアップグレードを検討 |
| Supabase | $0（Free） | Pro へのアップグレードを検討 |
| Google Calendar API | $0（無料枠内） | — |

---

## 9. 法的・コンプライアンス要件

| 要件 | 対応 |
|------|------|
| プライバシーポリシー | SaaS公開時に作成（現フェーズは個人利用のため不要） |
| 利用規約 | SaaS公開時に作成 |
| GDPR | SaaS公開時・EU展開時に対応（現フェーズ不要） |
| データ保存場所 | Supabase: `ap-northeast-1`（東京）または `us-east-1`（デフォルト） |

---

## 10. ログ・モニタリング要件

| 項目 | ツール | 用途 |
|------|--------|------|
| エラーログ | Vercel Functions ログ（組み込み） | Server Actions エラーの確認 |
| パフォーマンス | Vercel Analytics（無料枠） | ページ表示速度モニタリング |
| DBクエリ | Supabase Dashboard | スロークエリの特定 |
| AIコスト | Anthropic Dashboard | トークン使用量・コスト追跡 |

**ユーザー行動のログ**: 個人利用フェーズではトラッキングサービス（Mixpanel等）は不要。SaaS公開時に検討。

---

文書バージョン: 1.0
作成日: 2026-04-09
最終更新日: 2026-04-09
