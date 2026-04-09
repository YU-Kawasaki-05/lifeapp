# Sprint 6: タイムボクシング + タイムライン
## ARDORS — FR-30, FR-31

---

## 並列実行ガイド

```
SPR6-01（time_blocks Actions）← 先行推奨
  ├─→ SPR6-02（週間スケジュール画面 + タイムライン）
  └─→ SPR6-03（AI タイムボクシング生成）← SPR6-01 後
        └─→ SPR6-04（承認・評価 UI）← SPR6-02 後
```

---

## SPR6-01: time_blocks Server Actions

```text
[Task]
SPR6-01: タイムブロック Server Actions の実装

Goal
- `src/features/schedule/actions.ts` に time_blocks CRUD の全 Server Actions を実装する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.7 タイムボクシング・スケジュール）
- 参照: docs/02_外部設計/01_DB設計_database-design.md（3.8 time_blocks テーブル）
- 対応機能: FR-30

Scope
- 変更OK:
  - `src/features/schedule/actions.ts`（新規作成）
  - `src/features/schedule/schemas.ts`
  - `src/features/schedule/types.ts`（TimeBlock 型）
  - `src/features/schedule/index.ts`
  - `supabase/migrations/20260409000004_add_time_blocks.sql`
- 変更NG:
  - UI コンポーネント

DB マイグレーション
- `time_blocks` テーブル（docs/02_外部設計/01_DB設計_database-design.md 3.8 参照）

Actions to implement
1. createTimeBlock(input) → Result<{ blockId: string }>
   - end_at > start_at のバリデーション
2. updateTimeBlock(input) → Result<void>
3. deleteTimeBlock(input) → Result<void>  ← deleted_at = now()
4. approveTimeBlocks(input) → Result<void>  ← is_approved = true に一括更新
5. rateTimeBlock(input) → Result<void>  ← focus_rating + transition_note 更新
6. getTimeBlocksForWeek(input) → Result<TimeBlock[]>
   - weekStart 〜 weekStart+7days の範囲を取得

Acceptance Criteria
- [ ] createTimeBlock で time_blocks テーブルにレコードが作成される
- [ ] end_at <= start_at の場合にバリデーションエラーが返る
- [ ] approveTimeBlocks で複数ブロックの is_approved が true になる
- [ ] getTimeBlocksForWeek が指定週のブロックを返す
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR6-02: 週間スケジュール画面（SCR-40）+ タイムライン表示

```text
[Task]
SPR6-02: 週間スケジュール画面（SCR-40）+ タイムライン表示コンポーネントの実装

Goal
- `/schedule` に週間タイムライン形式のスケジュール画面を実装する。
- ARDORS ブロック（青）と GCal イベント（水色）を色分けして表示する。
- ブロックの作成・編集・削除を UI から行える。

Context
- 参照: docs/01_要件定義/wireframes/SCR-40_schedule.md
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（4.7 SCR-40）
- 対応機能: FR-30, FR-31

Scope
- 変更OK:
  - `src/app/(protected)/schedule/page.tsx`
  - `src/features/schedule/components/WeeklyTimeline.tsx`（タイムライン本体）
  - `src/features/schedule/components/TimeBlockCard.tsx`（ブロック要素）
  - `src/features/schedule/components/TimeBlockSheet.tsx`（詳細・編集 Sheet）
  - `src/features/schedule/components/WeekNavigator.tsx`（週ナビゲーター）
- 変更NG:
  - GCal 関連（Sprint 7 が担当）

UI 要件
- 週ナビゲーター: [< 先週] 4/7〜4/13 [来週 >]
- 上部アクション: [AIで今週を組む] [GCal取得]（GCal は Sprint 7 で有効化）
- タイムライン（WeeklyTimeline）:
  - 縦軸: 時間（7時〜23時）
  - 横軸: 月〜日（7列）
  - ブロック色分け:
    - source='ardors' + is_approved=true: `bg-blue-500`
    - source='ardors' + is_approved=false: `bg-slate-300`（AI生成・未承認）
    - source='gcal': `bg-sky-400`
    - block_type='break': `bg-gray-100 border`
  - ブロッククリック: TimeBlockSheet（詳細・編集）表示
- [GCalに反映] [承認済みを確定] ボタン（GCal は Sprint 7）

タイムライン実装方針
- CSS Grid を使った自前実装（ライブラリ不使用）:
  ```
  grid-template-columns: 40px repeat(7, 1fr)
  grid-template-rows: repeat(96, 1fr)  ← 15分単位 × 24時間
  ```
  または `@fullcalendar/react` を使用（Bundle サイズ要確認）

Acceptance Criteria
- [ ] /schedule にタイムラインが表示される
- [ ] 週ナビゲーターで前後の週に移動できる
- [ ] ブロックをクリックすると詳細 Sheet が開く
- [ ] Sheet からブロックの編集・削除ができる
- [ ] PC / モバイル両方で表示できる（モバイルは日次表示に切り替え可）
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR6-03: AI タイムボクシング生成 Action

```text
[Task]
SPR6-03: AI タイムボクシング生成 Server Action の実装（generateWeeklyTimebox）

Goal
- AI（Haiku）が週間スケジュールを自動生成する `generateWeeklyTimebox` Action を実装する。
- ユーザーのプロジェクト・タスク・習慣・生活リズムを考慮したスケジュールを提案する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.7 generateWeeklyTimebox）
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（FR-30: 週間タイムボクシング）
- 対応機能: FR-30

Scope
- 変更OK:
  - `src/features/schedule/actions.ts`（generateWeeklyTimebox を追加）
- 変更NG:
  - UI（SPR6-02 / SPR6-04 が担当）

generateWeeklyTimebox Action
- 入力: weekStart（月曜日の日付）、preferences（focusHoursPerDay 等）
- AI への入力データを収集:
  1. ユーザーの生活リズム（profiles.life_rhythm）
  2. Active プロジェクトと ideal_weekly_hours
  3. 未完了タスク（優先度順）
  4. 今週の習慣定義
  5. GCal イベント（source='gcal' の time_blocks）
- AI プロンプト骨子:
  - 生活リズムを考慮してブロックを配置
  - ideal_weekly_hours に基づいてPJ別の時間を割り振る
  - 優先度高のタスクを早い時間帯に配置
  - 習慣を cue の時間帯に配置
  - 探索タイムを週1回組み込む（BR-35-01相当）
- AI が JSON で返す: TimeBlock[] の提案
- DB に is_approved=false で INSERT（ユーザーが承認するまで仮）
- 戻り値: { blocks: TimeBlock[], sessionId }

Acceptance Criteria
- [ ] generateWeeklyTimebox が time_blocks を is_approved=false で作成する
- [ ] 生活リズムとプロジェクトの情報を考慮したスケジュールが生成される
- [ ] ai_conversations に保存される
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR6-04: タイムブロック承認・評価 UI

```text
[Task]
SPR6-04: タイムブロック承認 + ブロック間評価（FR-54 部分対応）

Goal
- AI 生成ブロック（is_approved=false）の一括承認 UI を実装する。
- ブロック終了後の評価（focus_rating 1〜3）を1タップで入力できる UI を実装する。

Context
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（FR-54: ブロック間トランジション）
- 対応機能: FR-30（承認）, FR-54（評価・P1）

Scope
- 変更OK:
  - `src/features/schedule/components/ApprovalBanner.tsx`（未承認ブロック数 + 一括承認ボタン）
  - `src/features/schedule/components/BlockRatingDialog.tsx`（評価ダイアログ）
  - `src/app/(protected)/schedule/page.tsx`（ApprovalBanner 追加）
- 変更NG:
  - Server Actions（SPR6-01 が担当）

ApprovalBanner
- 未承認ブロックが存在する場合に表示
- 「X件の AI 提案ブロックがあります。[すべて承認] [個別に確認]」
- 「すべて承認」→ approveTimeBlocks（全未承認 blockIds を渡す）

BlockRatingDialog
- ブロック終了時刻を過ぎた場合に表示（ダッシュボードから通知）
- 「このブロックはどうでしたか？」
- 3択ボタン: 😊集中できた / 😐まあまあ / 😞集中できなかった
- 任意テキスト入力（transitionNote）
- 「記録する」→ rateTimeBlock Action

Acceptance Criteria
- [ ] 未承認ブロックがある場合に ApprovalBanner が表示される
- [ ] 「すべて承認」で is_approved=true になる
- [ ] BlockRatingDialog で評価が保存される（focus_rating 1〜3）
```

---

文書バージョン: 1.0
作成日: 2026-04-09
