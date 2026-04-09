# タスク管理サマリー
## プロジェクト名: ARDORS（アーダース）

---

## 概要

このフォルダは **Claude Code（AI）へのプロンプト集** である。
各 Sprint ファイルのタスクをそのまま Claude Code に貼り付けて実行する。

### フォルダ構成

| ファイル | 内容 |
|---------|------|
| `00_サマリー_summary.md` | 本書。並列/直列ガイド・Sprint対応表 |
| `01_共通ブロック_common-blocks.md` | 全プロンプト末尾に追記する共通ブロック |
| `02_Sprint1_auth.md` | Sprint 1: 認証基盤（LP・登録・ログイン・PW リセット・Middleware） |
| `03_Sprint2_onboarding-dashboard.md` | Sprint 2: オンボーディング + ダッシュボード基盤 |
| `04_Sprint3_projects-tasks.md` | Sprint 3: PJ・タスク管理 |
| `05_Sprint4_goals-ai-chat.md` | Sprint 4: 目標階層 + AI 対話基盤 |
| `06_Sprint5_braindump-briefing.md` | Sprint 5: ブレインダンプ + 新規PJ作成AI + モーニングブリーフィング |
| `07_Sprint6_schedule-timebox.md` | Sprint 6: タイムボクシング + タイムライン |
| `08_Sprint7_gcal.md` | Sprint 7: Google Calendar 連携（pull/push） |
| `09_Sprint8_habits-daily-review.md` | Sprint 8: 習慣管理 + デイリークローズ |
| `10_Sprint9_weekly-monthly-review.md` | Sprint 9: ウィークリー/月次レビュー + AIコーチモード |
| `11_Sprint10_goals-viz-notifications.md` | Sprint 10: ゴール可視化 + 通知 + 仕上げ |

---

## 並列実行ガイド

### 基本方針

- **依存のないタスクのみ並列実行する（最大 2〜3 本推奨）。**
- 同じファイル（特に `src/middleware.ts`、`src/app/layout.tsx`、`src/shared/` 配下）を触るタスク同士は並列しない。
- 各タスクは `feature/*` ブランチで作業し PR を作成してからマージする（CLAUDE.md のGit運用方針に従う）。

---

### Sprint 1: 認証基盤

| タスクID | タスク名 | 並列可否 | 備考 |
|---------|---------|---------|------|
| SPR1-01 | プロジェクト初期セットアップ | ✅ 先行必須 | 他の全タスクの前提。最初に実施 |
| SPR1-02 | DB マイグレーション（初期スキーマ） | ✅ SPR1-01 後に単独実行 | SPR1-01 完了後すぐ実施 |
| SPR1-03 | Supabase クライアント・Middleware | ✅ SPR1-02 後 | SPR1-02 後。SPR1-04〜06 の前提 |
| SPR1-04 | LP（SCR-01） | ✅ 並列可 | SPR1-03 後、SPR1-05〜06 と並列可 |
| SPR1-05 | 認証画面（SCR-02〜05） | ✅ 並列可 | SPR1-03 後、SPR1-04・06 と並列可 |
| SPR1-06 | 認証 Server Actions | ✅ 並列可 | SPR1-03 後、SPR1-04・05 と並列可 |

**推奨実行順**: SPR1-01 → SPR1-02 → SPR1-03 → [SPR1-04 / SPR1-05 / SPR1-06 を並列]

### Sprint 2: オンボーディング + ダッシュボード基盤

| タスクID | タスク名 | 並列可否 | 備考 |
|---------|---------|---------|------|
| SPR2-01 | グローバルレイアウト・ナビ | ✅ 先行必須 | 全画面の骨格。最初に実施 |
| SPR2-02 | オンボーディング画面（SCR-10）+ Action | ✅ 並列可 | SPR2-01 後、SPR2-03 と並列可 |
| SPR2-03 | ダッシュボード基盤（SCR-20） | ✅ 並列可 | SPR2-01 後、SPR2-02 と並列可 |
| SPR2-04 | AI フローティングパネル | ⚠️ SPR2-03 後 | ダッシュボードレイアウトに依存 |

### Sprint 3: PJ・タスク管理

| タスクID | タスク名 | 並列可否 | 備考 |
|---------|---------|---------|------|
| SPR3-01 | プロジェクト Server Actions | ✅ 並列可 | SPR3-02 と並列可 |
| SPR3-02 | プロジェクト一覧・詳細画面（SCR-30〜31） | ✅ 並列可 | SPR3-01 とほぼ並列可（actions.ts は先に欲しい） |
| SPR3-03 | タスク Server Actions + タスク詳細（SCR-32） | ⚠️ SPR3-01 後 | projects テーブルが必要 |
| SPR3-04 | PJ 状態管理 UI（Active/Warm/Cold） | ✅ 並列可 | SPR3-01〜02 と並列可 |

### Sprint 4: 目標階層 + AI 対話基盤

| タスクID | タスク名 | 並列可否 | 備考 |
|---------|---------|---------|------|
| SPR4-01 | 目標 Server Actions + 目標 UI | ✅ 並列可 | SPR4-02 と並列可 |
| SPR4-02 | AI クライアント設定 + sendMessage Action | ✅ 先行推奨 | SPR4-03〜04 の前提 |
| SPR4-03 | AI 対話画面（SCR-21）+ 音声入力 | ⚠️ SPR4-02 後 | AI クライアント必要 |
| SPR4-04 | レート制限ミドルウェア | ✅ 並列可 | SPR4-02〜03 と並列可 |

### Sprint 5: ブレインダンプ + モーニングブリーフィング

| タスクID | タスク名 | 並列可否 | 備考 |
|---------|---------|---------|------|
| SPR5-01 | ブレインダンプ Action + 承認フロー | ✅ 並列可 | SPR5-02 と並列可 |
| SPR5-02 | ブレインダンプ UI（SCR-21 内モード） | ⚠️ SPR5-01 後 | Action の型に依存 |
| SPR5-03 | 新規PJ作成 AI 対話 | ✅ 並列可 | SPR5-01 と並列可 |
| SPR5-04 | モーニングブリーフィング Action + ダッシュボード統合 | ✅ 並列可 | SPR5-01〜03 と並列可 |

### Sprint 6: タイムボクシング + タイムライン

| タスクID | タスク名 | 並列可否 | 備考 |
|---------|---------|---------|------|
| SPR6-01 | time_blocks Server Actions | ✅ 先行推奨 | SPR6-02〜04 の前提 |
| SPR6-02 | 週間スケジュール画面（SCR-40）+ タイムライン表示 | ⚠️ SPR6-01 後 | time_blocks 型に依存 |
| SPR6-03 | AI タイムボクシング生成 Action | ⚠️ SPR6-01 後 | time_blocks テーブル必要 |
| SPR6-04 | タイムブロック承認・評価 UI | ⚠️ SPR6-02 後 | 画面コンポーネントに依存 |

### Sprint 7: Google Calendar 連携

| タスクID | タスク名 | 並列可否 | 備考 |
|---------|---------|---------|------|
| SPR7-01 | Google OAuth（Calendar scope）+ gcal_tokens | ✅ 先行必須 | SPR7-02〜03 の前提 |
| SPR7-02 | GCal pull Action | ⚠️ SPR7-01 後 | トークン必要 |
| SPR7-03 | GCal push Action | ⚠️ SPR7-01 後 | SPR7-02 と並列可 |
| SPR7-04 | GCal 連携設定 UI（SCR-90） | ⚠️ SPR7-01 後 | SPR7-02〜03 と並列可 |

### Sprint 8: 習慣管理 + デイリークローズ

| タスクID | タスク名 | 並列可否 | 備考 |
|---------|---------|---------|------|
| SPR8-01 | habits / habit_logs Server Actions | ✅ 先行推奨 | SPR8-02〜03 の前提 |
| SPR8-02 | 習慣管理画面（SCR-50） | ⚠️ SPR8-01 後 | |
| SPR8-03 | デイリークローズ Action + レビュー日次タブ | ⚠️ SPR8-01 後 | SPR8-02 と並列可 |
| SPR8-04 | ダッシュボードへの習慣チェック統合 | ⚠️ SPR8-01〜02 後 | |

### Sprint 9: ウィークリー/月次レビュー + AIコーチ

| タスクID | タスク名 | 並列可否 | 備考 |
|---------|---------|---------|------|
| SPR9-01 | ウィークリーレビュー Action（Sonnet） | ✅ 並列可 | SPR9-03 と並列可 |
| SPR9-02 | レビュー画面 週次タブ（SCR-60） | ⚠️ SPR9-01 後 | |
| SPR9-03 | 月次レビュー Action（Sonnet） | ✅ 並列可 | SPR9-01 と並列可 |
| SPR9-04 | レビュー画面 月次タブ + AIコーチモード UI | ⚠️ SPR9-01・03 後 | |

### Sprint 10: ゴール可視化 + 通知 + 仕上げ

| タスクID | タスク名 | 並列可否 | 備考 |
|---------|---------|---------|------|
| SPR10-01 | ゴール・分析画面（SCR-70）| ✅ 並列可 | SPR10-02〜03 と並列可 |
| SPR10-02 | 通知 Server Actions + 通知 UI | ✅ 並列可 | SPR10-01 と並列可 |
| SPR10-03 | ユーザー設定画面（SCR-90） | ✅ 並列可 | 他と並列可 |
| SPR10-04 | ナレッジ一覧（SCR-80）+ notes Actions | ✅ 並列可 | 他と並列可 |
| SPR10-05 | 管理者画面（SCR-A1〜A2） | ✅ 並列可 | 他と並列可 |
| SPR10-06 | E2E テスト + 全体仕上げ | ⚠️ 全スプリント完了後 | 最後に実施 |

---

## 人間作業ゲート

### ゲート A（Sprint 1 完了後）
- [ ] Supabase プロジェクト作成・DB マイグレーション適用済みを確認
- [ ] Google OAuth クライアント設定（Supabase Dashboard）
- [ ] 登録 → メール確認 → ログイン → ダッシュボード の一連フローを手動確認
- [ ] 未認証で `/dashboard` にアクセスすると `/login` にリダイレクトされることを確認
- [ ] パスワードリセットメールが届くことを確認

### ゲート B（Sprint 2 完了後）
- [ ] オンボーディング完了後にダッシュボードへ遷移することを確認
- [ ] PC / モバイル両方でナビゲーションが正しく表示されることを確認
- [ ] onboarding_completed = false のユーザーが /onboarding に強制遷移することを確認

### ゲート C（Sprint 4 完了後）
- [ ] AI チャットが実際に Anthropic API と通信して返答されることを確認
- [ ] 音声入力が Chrome で動作することを確認
- [ ] ANTHROPIC_API_KEY の設定を本番環境に投入

### ゲート D（Sprint 7 完了後）
- [ ] Google Calendar API の OAuth 設定（Google Cloud Console）
- [ ] GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET を環境変数に設定
- [ ] GCal pull / push の動作を手動確認

### ゲート E（Sprint 10 完了後）
- [ ] `npm run lint && npm run type-check && npm run test` が全て通ることを確認
- [ ] Playwright E2E テストが主要フローを通ることを確認
- [ ] Vercel 本番環境へのデプロイ動作確認

---

## SPR → FR 対応表

| SPR ID | 対応 FR | 概要 | Sprint |
|--------|--------|------|--------|
| SPR1-01〜06 | FR-01〜05 | 認証基盤・LP | Sprint 1 |
| SPR2-01〜04 | FR-04, FR-60（基盤） | オンボーディング・ダッシュボード | Sprint 2 |
| SPR3-01〜04 | FR-20〜23 | PJ・タスク管理 | Sprint 3 |
| SPR4-01〜04 | FR-21, FR-10〜11 | 目標・AI対話 | Sprint 4 |
| SPR5-01〜04 | FR-12〜13, FR-24 | ブレインダンプ・ブリーフィング | Sprint 5 |
| SPR6-01〜04 | FR-30〜31 | タイムボクシング | Sprint 6 |
| SPR7-01〜04 | FR-32〜33 | GCal 連携 | Sprint 7 |
| SPR8-01〜04 | FR-40〜41, FR-50 | 習慣・デイリークローズ | Sprint 8 |
| SPR9-01〜04 | FR-51〜53 | ウィークリー/月次・コーチ | Sprint 9 |
| SPR10-01〜06 | FR-60〜62, FR-70〜71, FR-06〜07, FR-80 | 可視化・通知・仕上げ | Sprint 10 |

---

文書バージョン: 1.0
作成日: 2026-04-09
