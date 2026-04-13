# ARDORS（アーダース）

> AIとともに、毎日を前へ進める — 個人向け生産性・タスク・習慣・内省の統合管理パートナー

![Next.js](https://img.shields.io/badge/Next.js-15-black?logo=next.js)
![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![Vercel](https://img.shields.io/badge/Deployed%20on-Vercel-black?logo=vercel)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## 概要

ARDORS は「ARDORSだけ開けば1日が回る」をコンセプトにした、AIパートナー搭載の個人向け SaaS アプリです。

- **タスク・プロジェクト管理** — Active / Warm / Cold の3状態で多数のPJを俯瞰
- **AIタイムボクシング** — AIが週間スケジュールを自動生成、Google Calendar と同期
- **ブレインダンプ** — 音声/テキストで話すだけ → AIが構造化してタスク化
- **習慣エンジン** — cue付き習慣定義・1タップ実行ログ・ストリーク管理
- **AIレビュー** — デイリー/ウィークリー/月次の振り返りをAIコーチがサポート

---

## 技術スタック

| カテゴリ | 技術 |
|----------|------|
| フレームワーク | Next.js 15 App Router |
| 言語 | TypeScript 5.x |
| スタイリング | Tailwind CSS 4.x + shadcn/ui |
| 状態管理 | Zustand + TanStack Query |
| フォーム | React Hook Form + Zod |
| DB / Auth | Supabase（PostgreSQL + Auth + RLS） |
| AI（通常） | Anthropic Claude Haiku 4.5 |
| AI（コーチ） | Anthropic Claude Sonnet 4.6 |
| 音声入力 | Web Speech API（ブラウザ標準） |
| カレンダー連携 | Google Calendar API v3 |
| ホスティング | Vercel Hobby |
| テスト | Vitest + Testing Library + Playwright |

---

## 前提条件

- Node.js 20.x 以上
- [Supabase](https://supabase.com/) プロジェクト（無料 tier で動作）
- [Anthropic API キー](https://console.anthropic.com/)
- Google Cloud Console プロジェクト（Google Calendar 連携を使う場合）

---

## セットアップ

### 1. リポジトリをクローン

```bash
git clone https://github.com/<your-username>/lifeapp.git
cd lifeapp
```

### 2. 依存関係をインストール

```bash
npm install
```

### 3. 環境変数を設定

```bash
cp .env.local.example .env.local
```

`.env.local` を編集し、各値を設定してください（[環境変数の詳細](#環境変数) を参照）。

### 4. Supabase DB マイグレーションを適用

```bash
npx supabase db push
```

### 5. 開発サーバーを起動

```bash
npm run dev
```

[http://localhost:3000](http://localhost:3000) で起動します。

---

## 環境変数

| 変数名 | 説明 | 取得場所 |
|--------|------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase プロジェクト URL | Supabase Dashboard > Settings > API |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase 匿名キー | Supabase Dashboard > Settings > API |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase サービスロールキー（管理者機能用） | Supabase Dashboard > Settings > API |
| `ANTHROPIC_API_KEY` | Anthropic API キー | [console.anthropic.com](https://console.anthropic.com/) |
| `AI_MODEL_DEFAULT` | 通常会話用モデル | デフォルト: `claude-haiku-4-5-20251001` |
| `AI_MODEL_COACHING` | コーチモード用モデル | デフォルト: `claude-sonnet-4-6` |
| `GOOGLE_CLIENT_ID` | Google OAuth クライアント ID | Google Cloud Console |
| `GOOGLE_CLIENT_SECRET` | Google OAuth クライアントシークレット | Google Cloud Console |
| `NEXT_PUBLIC_APP_URL` | アプリの公開 URL | 開発: `http://localhost:3000` |

> **注意**: `ANTHROPIC_API_KEY` / `SUPABASE_SERVICE_ROLE_KEY` / `GOOGLE_CLIENT_SECRET` は絶対に公開リポジトリにコミットしないこと。

---

## 開発コマンド

```bash
npm run dev          # 開発サーバー起動（Turbopack）
npm run build        # 本番ビルド
npm run start        # 本番サーバー起動
npm run lint         # ESLint チェック
npm run type-check   # TypeScript 型チェック
npm run test         # Vitest ユニットテスト
npm run test:e2e     # Playwright E2E テスト
```

---

## ディレクトリ構成（概要）

```
src/
├── app/              # ルーティングのみ（ページファイル）
│   ├── (public)/     # 認証不要（LP・ログイン・登録）
│   └── (protected)/  # 認証必須（ダッシュボード〜設定）
├── features/         # 機能単位の高凝集モジュール
│   ├── auth/         # 認証（登録・ログイン・PW リセット）
│   ├── ai-chat/      # AI 対話・ブレインダンプ
│   ├── projects/     # プロジェクト・タスク管理
│   ├── goals/        # 目標階層
│   ├── schedule/     # タイムボクシング・GCal 連携
│   ├── habits/       # 習慣管理
│   ├── review/       # デイリー/ウィークリー/月次レビュー
│   ├── dashboard/    # ダッシュボード
│   └── notes/        # ナレッジ・気づきメモ
└── shared/           # 機能横断リソース（UI・lib・型）
```

詳細なディレクトリ構成は [docs/03_技術設計/02_ディレクトリ構成_directory-structure.md](docs/03_技術設計/02_ディレクトリ構成_directory-structure.md) を参照してください。

---

## ドキュメント

### Phase 1: 要件定義

| ドキュメント | 説明 |
|-------------|------|
| [機能一覧（P0/P1/P2）](docs/01_要件定義/03_機能一覧_feature-list.md) | 全機能と優先度 |
| [画面遷移図](docs/01_要件定義/04_画面遷移図_screen-transition.md) | 画面 ID・URL・遷移フロー |
| [受入基準（Gherkin）](docs/01_要件定義/05_受入基準_acceptance-criteria.md) | 機能ごとのテスト基準 |
| [ワイヤーフレーム](docs/01_要件定義/wireframes/) | 画面別ワイヤーフレーム |

### Phase 2: 外部設計

| ドキュメント | 説明 |
|-------------|------|
| [DB 設計](docs/02_外部設計/01_DB設計_database-design.md) | テーブル定義・ER 図・RLS |
| [API 仕様（Server Actions）](docs/02_外部設計/02_API仕様_api-specification.md) | 全 Server Actions の仕様 |
| [権限設計](docs/02_外部設計/03_権限設計_authorization.md) | RBAC・RLS ポリシー・Middleware |
| [画面設計](docs/02_外部設計/04_画面設計_screen-design.md) | デザインシステム・コンポーネント構成 |
| [非機能要件](docs/02_外部設計/05_非機能要件_non-functional-requirements.md) | パフォーマンス・セキュリティ・可用性 |

### Phase 3: 技術設計

| ドキュメント | 説明 |
|-------------|------|
| [アーキテクチャ](docs/03_技術設計/01_アーキテクチャ_architecture.md) | システム構成図・データフロー |
| [開発ガイドライン](docs/03_技術設計/05_開発ガイドライン_development-guidelines.md) | コーディング規約・命名・テスト方針 |
| [Sprint 計画](docs/03_技術設計/06_Sprint計画_sprint-and-ai-workflow.md) | 10 Sprint × 2週間の開発計画 |

### Phase 4: タスク（AI プロンプト集）

Sprint ごとの AI 実装プロンプトは [docs/04_タスク/](docs/04_タスク/) を参照してください。

---

## コーディング規約（抜粋）

- **Server Actions は `Result<T>` 型を返す**（`{ success: true; data: T } | { success: false; error: string }`）
- **`any` 型を使わない**（`unknown` + type guard を使う）
- **全 Server Action に Zod バリデーションを入れる**
- **APIキーはサーバーのみ**（`NEXT_PUBLIC_` を付けない）
- **features 間の直接 import は禁止**（必ず `index.ts` の公開 API 経由）

詳細は [docs/03_技術設計/05_開発ガイドライン_development-guidelines.md](docs/03_技術設計/05_開発ガイドライン_development-guidelines.md) を参照。

---

## ライセンス

MIT License — 詳細は [LICENSE](LICENSE) を参照してください。
