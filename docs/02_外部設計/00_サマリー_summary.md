# 外部設計サマリー
## プロジェクト名: ARDORS（アーダース）

---

## 1. 外部設計の目的

外部設計は「要件定義（Phase 1）で定義した What（何を作るか）」を受け、**How（どのように作るか）** を具体化する工程。
開発者がコードを書き始める前に、全ての技術的設計判断を文書化する。

---

## 2. 成果物一覧

| ドキュメント | パス | 内容 |
|------------|------|------|
| **外部設計サマリー** | `00_サマリー_summary.md` | 本書。全体概要 |
| **DB設計** | `01_DB設計_database-design.md` | 全16テーブルの CREATE TABLE / RLS / インデックス / トリガー |
| **API仕様（Server Actions）** | `02_API仕様_api-specification.md` | 全 Server Actions の関数名・Zodスキーマ・戻り値・副作用 |
| **権限設計** | `03_権限設計_authorization.md` | RLS ポリシー / Middleware / 所有者確認パターン |
| **画面設計** | `04_画面設計_screen-design.md` | デザインシステム / 全画面レイアウト / コンポーネントマッピング |
| **非機能要件** | `05_非機能要件_non-functional-requirements.md` | パフォーマンス / セキュリティ / 可用性 / ブラウザ対応 |

---

## 3. データモデル概要

### 3.1 テーブル一覧

| テーブル名 | 概要 | 関連 FR |
|-----------|------|--------|
| `profiles` | ユーザープロフィール（auth.users の拡張） | FR-01〜04 |
| `user_settings` | 通知時刻・AIトーン・GCal設定 | FR-06 |
| `projects` | プロジェクト（Active/Warm/Cold） | FR-20, FR-22 |
| `goals` | 目標階層（長期/中期/週次） | FR-21 |
| `tasks` | タスク（PJ・目標に紐付け） | FR-23 |
| `habits` | 習慣定義（cue + 最小行動） | FR-40 |
| `habit_logs` | 習慣実行ログ | FR-41 |
| `time_blocks` | タイムボクシングブロック + GCalイベント | FR-30〜33 |
| `ai_conversations` | AI対話の全履歴 | FR-10〜13, FR-50〜53 |
| `daily_reviews` | デイリークローズ | FR-50 |
| `weekly_reviews` | ウィークリーレビュー | FR-51 |
| `monthly_reviews` | 月次・四半期レビュー | FR-52 |
| `notes` | ナレッジキャプチャ | FR-80 |
| `gcal_tokens` | Google Calendar OAuth トークン | FR-32〜33 |
| `energy_checkins` | エネルギーチェックイン | FR-90 |
| `notifications` | 通知レコード | FR-70〜71 |

### 3.2 テーブル共通設計

```
全テーブル共通:
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid()
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()

ユーザーデータテーブル共通（profiles 除く）:
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
  ※ RLS: auth.uid() = user_id

論理削除対応テーブル:
  deleted_at  TIMESTAMPTZ  ← NULL = 有効、非NULL = 削除済み
  対象: projects, goals, tasks, habits, time_blocks, notes
```

---

## 4. Server Actions 全体マップ

| 機能カテゴリ | ファイルパス | Actions 数 |
|------------|-----------|-----------|
| 認証 | `src/features/auth/actions.ts` | 5 |
| オンボーディング | `src/features/onboarding/actions.ts` | 1 |
| プロジェクト | `src/features/projects/actions.ts` | 6 |
| タスク | `src/features/tasks/actions.ts` | 5 |
| 目標 | `src/features/goals/actions.ts` | 5 |
| 習慣 | `src/features/habits/actions.ts` | 6 |
| スケジュール | `src/features/schedule/actions.ts` | 7 |
| Google Calendar | `src/features/schedule/gcal-actions.ts` | 4 |
| AI対話 | `src/features/ai-chat/actions.ts` | 4 |
| 振り返り | `src/features/review/actions.ts` | 5 |
| 通知 | `src/features/notifications/actions.ts` | 3 |
| ユーザー設定 | `src/features/settings/actions.ts` | 3 |
| エネルギー | `src/features/energy/actions.ts` | 2 |
| ノート | `src/features/notes/actions.ts` | 4 |
| 管理者 | `src/features/admin/actions.ts` | 2 |
| **合計** | | **62** |

---

## 5. 権限制御サマリー

| レイヤー | 実装場所 | 内容 |
|---------|---------|------|
| ルート保護 | `src/middleware.ts` | 未認証 → /login、管理者専用ルート → /dashboard |
| オンボーディング強制 | `src/middleware.ts` | onboarding_completed = false → /onboarding |
| Server Actions 認証 | 全 actions.ts | `getAuthenticatedUser()` を最初に呼ぶ |
| 所有者確認 | `src/shared/lib/auth/verify-ownership.ts` | `verifyProjectOwnership()` 等 |
| DBレベル分離 | Supabase RLS | `auth.uid() = user_id` 全テーブルに適用 |

---

## 6. 画面構成サマリー

| 画面ID | URL | 認証 | 主要 FR |
|--------|-----|------|--------|
| SCR-01 | / | 不要 | FR-05 |
| SCR-02 | /signup | 不要 | FR-01 |
| SCR-03 | /login | 不要 | FR-02 |
| SCR-04 | /reset-password | 不要 | FR-03 |
| SCR-05 | /reset-password/:token | 不要 | FR-03 |
| SCR-10 | /onboarding | 必要 | FR-04 |
| SCR-20 | /dashboard | 必要 | FR-60, FR-13, FR-41 |
| SCR-21 | /chat | 必要 | FR-10, FR-11, FR-12 |
| SCR-30 | /projects | 必要 | FR-20, FR-22 |
| SCR-31 | /projects/:id | 必要 | FR-20, FR-23 |
| SCR-32 | /projects/:id/tasks/:taskId | 必要 | FR-23 |
| SCR-40 | /schedule | 必要 | FR-30〜33 |
| SCR-50 | /habits | 必要 | FR-40, FR-41 |
| SCR-60 | /review | 必要 | FR-50〜53 |
| SCR-70 | /goals | 必要 | FR-61, FR-62 |
| SCR-80 | /notes | 必要 | FR-80 |
| SCR-90 | /settings | 必要 | FR-06 |
| SCR-A1 | /admin | 管理者 | FR-07 |
| SCR-A2 | /admin/users | 管理者 | FR-07 |

**グローバルナビ（5項目）**: ホーム / スケジュール / プロジェクト / ゴール / レビュー  
**AIフローティングボタン**: 全認証済みページに常駐

---

## 7. AI モデル使い分け

| 機能 | モデル | 環境変数 | 理由 |
|------|--------|---------|------|
| 通常チャット | Haiku | `AI_MODEL_DEFAULT` | 高速・低コスト |
| ブレインダンプ | Haiku | `AI_MODEL_DEFAULT` | 構造化処理・高頻度 |
| モーニングブリーフィング | Haiku | `AI_MODEL_DEFAULT` | 毎日実行・コスト重視 |
| デイリークローズ | Haiku | `AI_MODEL_DEFAULT` | 毎日実行 |
| タイムボクシング生成 | Haiku | `AI_MODEL_DEFAULT` | 週次実行・十分な性能 |
| ウィークリーレビュー | **Sonnet** | `AI_MODEL_COACHING` | 深い分析・週1回 |
| 月次レビュー | **Sonnet** | `AI_MODEL_COACHING` | 深い分析・月1回 |
| AIコーチモード | **Sonnet** | `AI_MODEL_COACHING` | 建設的で率直なフィードバック |

---

## 8. 非機能要件サマリー

| 項目 | 目標値 |
|------|--------|
| 画面表示速度 | < 800ms (TTFB) |
| CRUD操作速度 | < 500ms |
| AI応答（初回トークン） | < 3s (Haiku), < 5s (Sonnet) |
| 稼働率 | 99%（月間） |
| ブラウザ対応 | Chrome/Firefox/Safari/Edge 最新2世代 |
| レスポンシブ | スマートフォン〜PC 全対応 |
| 月額コスト | ~$1〜5（AI API コストのみ） |
| テストカバレッジ | Server Actions 70%以上 |

---

## 9. 前後フェーズとの関係

```
Phase 1: 要件定義
  ↓ 「What（何を作るか）」
Phase 2: 外部設計（本フェーズ）← 今ここ
  ↓ 「How（どのように作るか）」
Phase 3: 技術設計
  ↓ 「With（何の技術で）」
Phase 4: 実装（Sprint 1〜10）
```

### 参照関係

| Phase 2 ドキュメント | 参照先（Phase 1） | 参照先（Phase 3） |
|-------------------|----------------|----------------|
| DB設計 | 機能一覧（FR一覧） | アーキテクチャ・認証フロー |
| API仕様 | 機能一覧・受入基準 | 開発ガイドライン |
| 権限設計 | ユーザー像・画面遷移図 | 認証フロー |
| 画面設計 | ワイヤーフレーム・画面遷移図 | ディレクトリ構成 |
| 非機能要件 | 業務理解 | 外部サービス・Sprint計画 |

---

文書バージョン: 1.0
作成日: 2026-04-09
最終更新日: 2026-04-09
