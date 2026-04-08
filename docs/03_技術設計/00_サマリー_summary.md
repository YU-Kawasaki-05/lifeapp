# 技術設計サマリー
## プロジェクト名: ARDORS（アーダース）

---

## 1. 技術スタック一覧（確定版）

| カテゴリ | 選定技術 | バージョン目安 | 選定理由 |
|----------|---------|--------------|---------|
| フレームワーク | Next.js (App Router) | 15.x | React経験活用・Vercel親和性・Server Actionsでバックエンドレス |
| 言語 | TypeScript | 5.x | 型安全・IDEサポート・バグ早期検知 |
| スタイリング | Tailwind CSS | 4.x | ユーティリティファーストで高速UI構築 |
| UIコンポーネント | shadcn/ui | latest | コピペ型・デザインシステム不要・アクセシビリティ対応 |
| 状態管理 | Zustand | 5.x | 軽量・ボイラープレート最小・この規模に適切 |
| フォーム | React Hook Form + Zod | latest | TS型とバリデーションが一体。デファクトスタンダード |
| DB / BaaS | Supabase (PostgreSQL) | latest | 既経験あり・Auth込み・無料tier十分 |
| 認証 | Supabase Auth | - | Google OAuth + Email/Password + パスワードリセット対応 |
| サーバー処理 | Next.js Server Actions | - | AI APIプロキシ・DB書き込みをサーバーサイドで安全に処理 |
| AIモデル（標準） | Claude Haiku 4.5 | - | 高速・低コスト・通常の対話・ブレインダンプ |
| AIモデル（詳細分析） | Claude Sonnet 4.6 | - | 週次/月次レビュー・コーチモードの深い分析 |
| 音声入力（STT） | Web Speech API（ブラウザ標準） | - | 完全無料・Chrome/Edge対応 |
| Google Calendar | Google Calendar API v3 | - | 手動pull + 一括push。無料枠内で収まる |
| ホスティング | Vercel Hobby | - | 無料・Next.js最適化済み |
| テスト | Vitest + Testing Library | latest | Jest互換・高速・Server Actions対応 |
| CI/CD | GitHub Actions | - | 無料tier内でlint/test/deploy自動化 |

---

## 2. アーキテクチャ概要

```
[ ブラウザ ]
    │  HTTPS
    ▼
[ Vercel Hobby（無料）]
  Next.js 15 App Router
  ├─ Server Components ──────→ Supabase PostgreSQL（データ取得）
  ├─ Server Actions ─────────→ Supabase（書き込み）
  │                 ─────────→ Anthropic API（AI対話）
  │                 ─────────→ Google Calendar API（pull/push）
  └─ Client Components
       ├─ Web Speech API（音声→テキスト変換 ※ブラウザ内）
       └─ Zustand（クライアント状態）

[ Supabase（無料tier）]
  ├─ PostgreSQL（DB本体）
  ├─ Auth（Google OAuth + Email/Password）
  └─ Row Level Security（RLS）でユーザー間データ分離
```

---

## 3. AIモデル切り替え戦略

モデルは環境変数で管理し、機能ごとに使い分ける。

```bash
# .env.local
AI_MODEL_DEFAULT=claude-haiku-4-5-20251001        # 通常の対話・ブレインダンプ・タイムボクシング生成
AI_MODEL_COACHING=claude-sonnet-4-6               # 週次/月次レビュー・コーチモード
```

```typescript
// src/shared/lib/ai/models.ts
export const AI_MODELS = {
  default:  process.env.AI_MODEL_DEFAULT  ?? 'claude-haiku-4-5-20251001',
  coaching: process.env.AI_MODEL_COACHING ?? 'claude-sonnet-4-6',
} as const;
```

---

## 4. コスト試算

| サービス | プラン | 月額費用 | 備考 |
|---------|--------|---------|------|
| Vercel | Hobby | **$0** | 個人・趣味プロジェクト対象 |
| Supabase | Free | **$0** | 500MB DB・2GB storage・50k MAU |
| Anthropic API (Haiku) | Pay-per-use | **~$1〜3** | 日常会話・ブレインダンプ想定 |
| Anthropic API (Sonnet) | Pay-per-use | **~$0〜1** | 週1回のレビューのみ |
| Google Calendar API | Free tier | **$0** | 1M req/day まで無料 |
| Web Speech API | 無料（ブラウザ） | **$0** | - |
| GitHub | Free | **$0** | Private repoも無料 |
| **合計** | | **~$1〜5/月** | |

---

## 5. フォルダ構成概要

```
src/
├─ app/              # ルーティングのみ（ページファイル）
│   ├─ (public)/     # 認証不要（LP・ログイン・登録）
│   └─ (protected)/  # 認証必須（ダッシュボード〜設定）
├─ features/         # 機能単位の高凝集モジュール
│   ├─ auth/
│   ├─ ai-chat/
│   ├─ projects/
│   ├─ schedule/
│   ├─ habits/
│   ├─ reviews/
│   ├─ goals/
│   └─ ...
└─ shared/           # 機能横断の共有リソース
    ├─ components/ui/ # shadcn/uiプリミティブ
    ├─ lib/          # supabase client, ai client, utils
    └─ types/        # 共通型定義
```

---

## 6. 成果物一覧

| ファイル | 内容 |
|---------|------|
| [01_アーキテクチャ](./01_アーキテクチャ_architecture.md) | アーキテクチャ詳細・システム構成図・レイヤー設計 |
| [02_ディレクトリ構成](./02_ディレクトリ構成_directory-structure.md) | フォルダ構造・命名規則・インポートルール |
| [03_外部サービス](./03_外部サービス_external-services.md) | 外部サービス詳細・環境変数一覧・コスト詳細 |
| [04_認証フロー](./04_認証フロー_auth-flow.md) | Google OAuth・Email認証・パスワードリセット・セッション管理 |
| [05_開発ガイドライン](./05_開発ガイドライン_development-guidelines.md) | コーディング規則・コンポーネント設計・テスト方針 |
| [06_Sprint計画](./06_Sprint計画_sprint-and-ai-workflow.md) | P0機能のスプリント計画・AIワークフロー |

---

文書バージョン: 1.0
作成日: 2026-04-08
