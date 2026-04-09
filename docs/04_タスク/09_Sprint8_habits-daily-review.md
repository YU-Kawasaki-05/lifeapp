# Sprint 8: 習慣管理 + デイリークローズ
## ARDORS — FR-40, FR-41, FR-50

---

## 並列実行ガイド

```
SPR8-01（習慣 Actions）← 先行推奨
  ├─→ SPR8-02（習慣管理画面）          ┐ 並列可
  └─→ SPR8-03（デイリークローズ Action + 画面）┘
        └─→ SPR8-04（ダッシュボード統合）← SPR8-01〜02 後
```

---

## SPR8-01: habits / habit_logs Server Actions

```text
[Task]
SPR8-01: 習慣 Server Actions の実装（habits / habit_logs）

Goal
- `src/features/habits/actions.ts` に習慣 CRUD + 実行ログ記録の Server Actions を実装する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.6 習慣）
- 参照: docs/02_外部設計/01_DB設計_database-design.md（3.6 habits / 3.7 habit_logs）
- 対応機能: FR-40, FR-41

Scope
- 変更OK:
  - `src/features/habits/actions.ts`（新規作成）
  - `src/features/habits/schemas.ts`
  - `src/features/habits/types.ts`（Habit / HabitLog / HabitWithLog 型）
  - `src/features/habits/index.ts`
  - `supabase/migrations/20260409000006_add_habits.sql`
- 変更NG:
  - UI コンポーネント

DB マイグレーション
- `habits` テーブル（docs/02_外部設計/01_DB設計_database-design.md 3.6 参照）
- `habit_logs` テーブル（同 3.7 参照）

Actions to implement
1. createHabit(input) → Result<{ habitId: string }>
2. updateHabit(input) → Result<void>（isActive も更新可能）
3. deleteHabit(input) → Result<void>  ← deleted_at = now()
4. logHabit(input) → Result<{ logId: string }>
   - UPSERT: ON CONFLICT (habit_id, logged_date) DO UPDATE SET completed, note, updated_at
5. unlogHabit(input) → Result<void>
   - loggedDate === today でなければ 'キャンセルは当日のみ可能です' を返す
6. getHabitsWithTodayLogs() → Result<HabitWithLog[]>
   - habits LEFT JOIN habit_logs ON habit_id AND logged_date = today
   - is_active = true かつ deleted_at IS NULL のものだけ返す

ストリーク計算（getHabitsWithTodayLogs に含める）
- habit_logs の連続達成日数を計算して HabitWithLog に streak フィールドとして追加

Acceptance Criteria
- [ ] createHabit で habits テーブルにレコードが作成される
- [ ] logHabit で habit_logs に UPSERT される（同日再実行で重複しない）
- [ ] unlogHabit で当日のログのみ削除できる（翌日以降はエラー）
- [ ] getHabitsWithTodayLogs が今日のログ状況付きで返す
- [ ] `npm run lint` / `npm run type-check` / `npm run test` が通る
```

---

## SPR8-02: 習慣管理画面（SCR-50）

```text
[Task]
SPR8-02: 習慣管理画面の実装（SCR-50）

Goal
- `/habits` に習慣の管理（作成・編集・削除・履歴確認）画面を実装する。

Context
- 参照: docs/01_要件定義/wireframes/SCR-50_habits.md
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（4.8 SCR-50）
- 対応機能: FR-40, FR-41（管理部分）

Scope
- 変更OK:
  - `src/app/(protected)/habits/page.tsx`
  - `src/features/habits/components/HabitCard.tsx`（習慣カード + ストリーク表示）
  - `src/features/habits/components/HabitForm.tsx`（作成・編集 Dialog）
  - `src/features/habits/components/HabitHeatmap.tsx`（カレンダーヒートマップ）
  - `src/features/habits/components/HabitList.tsx`
- 変更NG:
  - ダッシュボードの習慣チェック（SPR8-04 が担当）

UI 要件（docs/02_外部設計/04_画面設計_screen-design.md 4.8 参照）
- 上部: 「+ 新規習慣」ボタン
- 習慣カード（HabitCard）:
  - 名前・ストリーク数（🔥 N日連続）
  - cue（きっかけ）・最小行動
  - 今週の達成状況（✓✓✓○○ 形式）
  - [編集] [削除] ボタン
- 月間ヒートマップ（HabitHeatmap）:
  - habit_logs を日付別にグループ化
  - 達成日は `bg-green-400`、未達成日は `bg-gray-100`

HabitForm フィールド
- 名前（必須）・cue（必須）・最小行動（必須）
- if-then plan（任意）
- 頻度（毎日 / 平日のみ / 週N回 / カスタム）
- 紐付くプロジェクト（任意・Select）

Acceptance Criteria
- [ ] /habits に習慣一覧が表示される（0 件時はガイドテキスト）
- [ ] 「+ 新規習慣」でフォームが開き、習慣を作成できる
- [ ] ストリーク数が正しく計算・表示される
- [ ] カレンダーヒートマップが表示される
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR8-03: デイリークローズ Action + レビュー日次タブ（SCR-60）

```text
[Task]
SPR8-03: デイリークローズ Server Action + レビュー画面（日次タブ）の実装

Goal
- `saveDailyReview` Action を実装し、AI（Haiku）が振り返りを構造化・フィードバックする。
- `/review` に日次レビュータブを実装する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.10 振り返り — saveDailyReview）
- 参照: docs/01_要件定義/wireframes/SCR-60_review.md（日次モード）
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（FR-50 / BR-50-01〜04）
- 対応機能: FR-50

Scope
- 変更OK:
  - `src/features/review/actions.ts`（saveDailyReview を追加）
  - `src/features/review/schemas.ts`
  - `src/features/review/types.ts`
  - `src/features/review/index.ts`
  - `src/app/(protected)/review/page.tsx`（タブ切り替え: 日次 / 週次 / 月次）
  - `src/features/review/components/DailyReviewTab.tsx`
  - `supabase/migrations/20260409000007_add_reviews.sql`
    （daily_reviews / weekly_reviews / monthly_reviews テーブルを追加）
- 変更NG:
  - 週次・月次（Sprint 9 が担当）

DB マイグレーション
- `daily_reviews` テーブル（docs/02_外部設計/01_DB設計_database-design.md 3.10 参照）
- `weekly_reviews` テーブル（同 3.11 参照）
- `monthly_reviews` テーブル（同 3.12 参照）

saveDailyReview Action
- UPSERT（review_date でユニーク）
- userInput が空 / skip=true の場合: AI が行動ログから Done List を自動生成（BR-50-01）
- AI（Haiku）への入力: userInput + 今日完了したタスク + 習慣達成状況
- AI が返す: { wins, struggles, tomorrow_plan } + aiFeedback
- 翌朝のブリーフィングのために ai_structured をそのまま保存

DailyReviewTab UI
- AIサマリープレースホルダー（今日の実績）
- 「今日の振り返りを入力してください」テキストエリア + 音声入力ボタン
- [AIに分析してもらう] ボタン → saveDailyReview 呼び出し
- AI フィードバック表示（ストリーミング）
- Done List（今日完了したタスク一覧）
- [スキップ] リンク（skip=true で saveDailyReview を呼ぶ）

Acceptance Criteria
- [ ] saveDailyReview で daily_reviews にレコードが保存される
- [ ] skip=true でも Done List が自動生成される（行動ログから）
- [ ] AI フィードバックが表示される
- [ ] /review に 3 タブ（日次/週次/月次）が表示される
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR8-04: ダッシュボードへの習慣チェック統合

```text
[Task]
SPR8-04: ダッシュボードの習慣チェックリストを本実装する

Goal
- ダッシュボード（SCR-20）の習慣チェックリストを実データで動作させる。
- 1タップでチェック/解除できるようにする。

Context
- 参照: docs/01_要件定義/wireframes/SCR-20_dashboard.md（習慣チェックリスト部分）
- 対応機能: FR-41（ダッシュボード上の操作）

Scope
- 変更OK:
  - `src/features/dashboard/components/HabitChecklist.tsx`（プレースホルダー → 実実装）
  - `src/features/habits/components/HabitCheckItem.tsx`（1タップチェックコンポーネント）
- 変更NG:
  - habits/habit_logs Server Actions（SPR8-01 が担当）

HabitCheckItem（Client Component）
- 習慣名 + ストリーク表示
- チェックボックス（1タップで logHabit / unlogHabit を呼ぶ）
- チェック後: 楽観的更新でチェックマークを即表示
- チェック取り消し（同日のみ）

Acceptance Criteria
- [ ] ダッシュボードに今日の習慣チェックリストが表示される
- [ ] 1タップでチェックできる（habit_logs に保存）
- [ ] チェック後にストリーク数が更新される
- [ ] 当日中なら取り消しできる
```

---

文書バージョン: 1.0
作成日: 2026-04-09
