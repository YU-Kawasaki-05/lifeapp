# Sprint計画 & AI開発ワークフロー
## プロジェクト名: ARDORS（アーダース）

---

## 1. P0機能のSprint計画

**前提:**
- 個人開発（1人）
- 趣味・副業スタイル（平日1〜2h + 休日集中）
- 1 Sprint = 約2週間
- 全P0機能完成目標: 約18〜20週（4〜5ヶ月）

| Sprint | 期間（目安） | 機能 | FR | 完了条件 |
|--------|------------|------|-----|---------|
| **Sprint 1** | Week 1-2 | 認証基盤 + LP + Supabaseセットアップ | FR-01, FR-02, FR-03, FR-05 | ログイン・登録・パスワードリセットが動く。RLS設定済み |
| **Sprint 2** | Week 3-4 | オンボーディング + ダッシュボード基盤 | FR-04, FR-60 | 初回ユーザーがオンボーディングを完了してダッシュボードに到達できる |
| **Sprint 3** | Week 5-6 | PJ・タスク管理 | FR-20, FR-22, FR-23 | PJとタスクのCRUDが動く。Active/Warm/Cold切り替え可能 |
| **Sprint 4** | Week 7-8 | 目標階層 + AI対話基盤 | FR-21, FR-10, FR-11 | 目標ツリーが作れる。AIテキスト対話・音声入力が動く |
| **Sprint 5** | Week 9-10 | ブレインダンプ + 新規PJ作成 + モーニングブリーフィング | FR-12, FR-24, FR-13 | ブレインダンプで構造化→承認→PJ/タスク作成が動く |
| **Sprint 6** | Week 11-12 | タイムボクシング + タイムライン | FR-30, FR-31 | AIがスケジュールを生成し、タイムラインで表示できる |
| **Sprint 7** | Week 13-14 | Google Calendar連携 | FR-32, FR-33 | GCal pull/pushが動く。タイムラインにGCal予定が表示される |
| **Sprint 8** | Week 15-16 | 習慣管理 + デイリークローズ | FR-40, FR-41, FR-50 | 習慣の定義・1タップチェック・デイリークローズが動く |
| **Sprint 9** | Week 17-18 | ウィークリー/月次レビュー + AIコーチ | FR-51, FR-52, FR-53 | 週次レビューの完全フロー（入力→AI分析→PJ見直し→タイムボクシング→push）が動く |
| **Sprint 10** | Week 19-20 | ゴール可視化 + 通知 + 仕上げ | FR-61, FR-62, FR-70, FR-71 | ゴールジャーニーマップ・時間分析・ブロック/レビュー通知が動く |

---

## 2. Sprint 1 詳細タスクブレークダウン（例）

Sprint 1 の具体的なタスクリスト（初回Sprintの参考に）:

```
Week 1:
  [ ] Next.js 15 プロジェクト初期化（TypeScript + Tailwind + shadcn/ui）
  [ ] Supabase プロジェクト作成・ローカル環境構築
  [ ] supabase/migrations/001_create_profiles.sql 作成・適用
  [ ] RLSポリシー設定（profiles テーブル）
  [ ] Google OAuth を Supabase Auth に設定
  [ ] src/shared/lib/supabase/ セットアップ（client.ts / server.ts / middleware.ts）
  [ ] Next.js Middleware で認証チェック実装

Week 2:
  [ ] SCR-01 LP ページ実装（静的コンテンツ）
  [ ] SCR-02 登録フォーム実装（Google OAuth + Email/Password）
  [ ] SCR-03 ログインフォーム実装
  [ ] SCR-04/05 パスワードリセットフロー実装
  [ ] /api/auth/callback/route.ts 実装
  [ ] E2Eテスト: 登録→確認メール→ログインフロー
```

---

## 3. AI開発ワークフロー（Claude Codeとの協働）

### 3.1 Claude Codeの活用方針

ARDORSはClaude Codeと協働して開発する。役割分担は以下の通り:

| 作業 | 人間 | Claude Code |
|------|------|-------------|
| 要件・仕様の決定 | ✅ 最終判断 | 提案・整理 |
| アーキテクチャ設計 | ✅ 承認 | 設計・ドキュメント化 |
| コンポーネント実装 | ✅ レビュー | コード生成 |
| Server Actions実装 | ✅ レビュー | コード生成 |
| Supabase migration作成 | ✅ レビュー | SQL生成 |
| テスト作成 | ✅ レビュー | テストコード生成 |
| バグ調査・修正 | ✅ 確認 | 原因特定・修正 |
| プロンプト設計（AIのAI） | ✅ 調整 | 初稿作成 |

### 3.2 Sprint内の標準的な作業フロー

```
1. Sprint開始時
   - CLAUDE.md を更新（現在のSprint目標・注意点）
   - 対象機能のFR仕様・受入基準を Claude Code に読み込ませる

2. 機能実装サイクル（1機能あたり）
   a. DB設計: Supabase migration SQLを生成 → レビュー → 適用
   b. 型生成: supabase gen types を実行
   c. バックエンド: Server Actions + Zodスキーマを実装
   d. フロントエンド: Server Component + Client Componentを実装
   e. テスト: Server Actionsのユニットテストを追加
   f. 手動確認: ブラウザで受入基準を確認

3. Sprint終了時
   - 完成した機能を自分でユーザーとして使ってみる
   - 気になった点・改善案をメモ（次Sprintのバックログへ）
```

### 3.3 CLAUDE.md テンプレート

```markdown
# ARDORS 開発ノート

## 現在のSprint
Sprint 3 (Week 5-6): PJ・タスク管理

## 今Sprintの目標
- FR-20 PJ CRUD を実装する
- FR-22 PJ状態管理 (Active/Warm/Cold) を実装する
- FR-23 タスクCRUD を実装する

## 技術スタック
- Next.js 15 App Router
- TypeScript + Zod + React Hook Form
- Supabase (PostgreSQL + Auth)
- Tailwind CSS + shadcn/ui

## 重要な設計原則（必ず守る）
1. Server ActionsはResult型を返す
2. 全Server ActionにZodバリデーションを入れる
3. any型は使わない
4. APIキーはサーバーのみ（NEXT_PUBLIC_以外は客に露出させない）
5. featuresを跨いだ直接importは禁止（index.tsを経由）

## 現在の既知の問題
- なし

## 参照ドキュメント
- docs/01_要件定義/03_機能一覧_feature-list.md
- docs/03_技術設計/01_アーキテクチャ_architecture.md
- docs/03_技術設計/02_ディレクトリ構成_directory-structure.md
```

### 3.4 DB設計の進め方（Supabase migration）

機能実装前に必ずDBスキーマを設計・適用する:

```bash
# 新しいmigrationを作成
npx supabase migration new create_projects

# supabase/migrations/XXX_create_projects.sql を実装後:
npx supabase db reset   # ローカルに適用（シードも再実行）

# 型を再生成
npx supabase gen types typescript --local > src/shared/types/database.types.ts
```

---

## 4. P1・P2機能のバックログ（P0完成後）

### P1（SHOULD）優先順位案

| 優先 | 機能 | FR | 理由 |
|------|------|-----|------|
| 1 | ユーザー設定 | FR-06 | 通知・AIレベル設定が使いやすさに直結 |
| 2 | エネルギーチェックイン | FR-90 | AIの精度向上に貢献 |
| 3 | コンテキスト復元 | FR-25 | 長期利用でのUX改善 |
| 4 | ヘルススコア | FR-26 | PJ状態の可視化強化 |
| 5 | ブロック間トランジション | FR-54 | 集中管理の質向上 |
| 6 | 達成の可視化 | FR-65 | モチベーション維持 |
| 7 | ナッジ + 先読みアラート | FR-72, FR-73 | 通知の質向上 |
| 8 | 管理者画面 | FR-07 | SaaS公開前に必要 |

### P2（COULD）実装検討条件

P2機能は「P0+P1が完成し、実際に3ヶ月使って価値を感じたもの」を実装する:

| 機能 | FR | 実装条件 |
|------|-----|---------|
| セレンディピティエンジン | FR-81 | ナレッジキャプチャ（FR-80）が500件以上溜まったら |
| Future Self Letter | FR-82 | 月次レビューを3回以上完了したら |
| ゴールシミュレーション | FR-83 | 3ヶ月分のタイムボクシングデータが溜まったら |
| ライフバランスレーダー | FR-63 | エネルギーチェックイン（FR-90）が安定して使えたら |

---

## 5. リリース計画

| マイルストーン | 内容 | 目安時期 |
|--------------|------|---------|
| **α版（自分用）** | P0機能完成。個人で毎日使い始める | Sprint 10完了後 |
| **β版（SaaS公開）** | LP公開・ユーザー登録受付開始。P1機能を追加 | α版から2ヶ月後 |
| **v1.0** | P1完成・管理者画面・有料プランを検討 | β版から3ヶ月後 |

---

文書バージョン: 1.0
作成日: 2026-04-08
