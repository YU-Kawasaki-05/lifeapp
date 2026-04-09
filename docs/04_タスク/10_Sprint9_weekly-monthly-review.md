# Sprint 9: ウィークリー/月次レビュー + AIコーチモード
## ARDORS — FR-51, FR-52, FR-53

---

## 並列実行ガイド

```
SPR9-01（ウィークリーレビュー Action）┐
SPR9-03（月次レビュー Action）       ├─ 並列可（別 context_type・別 Action）
  └─→ SPR9-02（レビュー画面 週次タブ）← SPR9-01 後
  └─→ SPR9-04（レビュー画面 月次タブ + AIコーチ UI）← SPR9-01・03 後
```

---

## SPR9-01: ウィークリーレビュー Server Action（Sonnet 使用）

```text
[Task]
SPR9-01: ウィークリーレビュー Server Action の実装（saveWeeklyReview / approveWeeklyGoals）

Goal
- `saveWeeklyReview` Action を実装し、AI（Sonnet）が建設的・深い週次分析を行う。
- 来週の週次ゴールを承認し goals テーブルに登録する `approveWeeklyGoals` Action を実装する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.10 振り返り — saveWeeklyReview / approveWeeklyGoals）
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（FR-51 / BR-51-01〜04）
- 対応機能: FR-51

Scope
- 変更OK:
  - `src/features/review/actions.ts`（saveWeeklyReview / approveWeeklyGoals を追加）
  - `src/features/review/schemas.ts`
- 変更NG:
  - UI（SPR9-02 が担当）

saveWeeklyReview Action
- 使用モデル: AI_MODELS.coaching（Sonnet）
- UPSERT（user_id + week_start でユニーク）
- AI への入力データを収集（BR-51-03）:
  - 先週の time_blocks から時間配分を集計
  - 先週のタスク完了率（done / total）
  - 先週の習慣達成率
  - PJ ヘルススコアの変動
- AI プロンプト骨子（AIコーチモード・FR-53）:
  - 建設的で率直なフィードバック
  - 批判でなく問いかけ形式（「なぜだと思いますか？」）
  - 先延ばしパターン・探索時間ゼロ・睡眠不足等を指摘（BR-53-02）
  - ユーザーの厳しさレベル（profiles.ai_tone_level）を考慮
- AI が返す:
  - aiSummary: { time_distribution, task_completion_rate, habit_rate, pj_health_changes }
  - aiFeedback: コーチからのフィードバックテキスト
  - proposedGoals: 来週の週次ゴール提案（最大3件）

approveWeeklyGoals Action
- 承認されたゴールを goals テーブルに level='weekly' で INSERT
- weekly_reviews.weekly_goals を更新

Implementation Hints
- Sonnet は長い出力を生成するためストリーミング推奨。
- AI への入力コンテキストが大きくなりすぎないよう、集計済みデータ（数値）を中心に渡す。

Acceptance Criteria
- [ ] saveWeeklyReview で Sonnet（AI_MODEL_COACHING）が呼ばれる
- [ ] weekly_reviews にレコードが保存される
- [ ] aiSummary に時間配分・タスク完了率・習慣達成率が含まれる
- [ ] aiFeedback が建設的な内容を含む（問いかけ形式）
- [ ] approveWeeklyGoals で goals テーブルに level='weekly' で登録される
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR9-02: レビュー画面 週次タブ（SCR-60）

```text
[Task]
SPR9-02: レビュー画面の週次タブ実装（SCR-60 週次モード）

Goal
- `/review` の週次タブを実装する。
- AI サマリー表示 → ユーザー入力 → AI 分析・フィードバック → 週次ゴール決定 → タイムボクシング生成 の一連フローを UI で実現する。

Context
- 参照: docs/01_要件定義/wireframes/SCR-60_review.md（週次モード）
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（4.9 SCR-60）
- 対応機能: FR-51, FR-53

Scope
- 変更OK:
  - `src/features/review/components/WeeklyReviewTab.tsx`（新規）
  - `src/features/review/components/WeeklyGoalApprover.tsx`（週次ゴール承認 UI）
  - `src/app/(protected)/review/page.tsx`（週次タブに WeeklyReviewTab を組み込む）
- 変更NG:
  - Server Actions（SPR9-01 が担当）

UI フロー（docs/02_外部設計/04_画面設計_screen-design.md 4.9 参照）
1. 「AI が先週のサマリーを生成しています...」→ aiSummary 表示
2. テキストエリア + 音声入力「先週の振り返りを入力してください」
3. [AIコーチに分析してもらう] → saveWeeklyReview 呼び出し → Sonnet ストリーミング
4. AI フィードバック表示（AIコーチバッジ付き: 🎯）
5. 週次ゴール提案（WeeklyGoalApprover）:
   - AI 提案（最大3件）を編集・承認できる
   - [承認して来週の計画を立てる] → approveWeeklyGoals → generateWeeklyTimebox
6. [タイムボクシングを確認する →] → /schedule に遷移

AIコーチモード表示
- フィードバックカードに「🎯 AIコーチからのフィードバック」バッジ
- ai_tone_level に応じたトーン（coach: 厳しめ / mentor: バランス / friend: 優しめ）を
  UI のラベルで示す（ロジックは AI プロンプト内で制御）

Acceptance Criteria
- [ ] 週次タブで先週のサマリーが表示される
- [ ] 入力後に AI コーチからフィードバックが表示される（Sonnet ストリーミング）
- [ ] 週次ゴールを承認できる（goals テーブルに保存）
- [ ] [タイムボクシングを確認する] で /schedule に遷移する
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR9-03: 月次レビュー Server Action（Sonnet 使用）

```text
[Task]
SPR9-03: 月次・四半期レビュー Server Action の実装（saveMonthlyReview）

Goal
- `saveMonthlyReview` Action を実装し、AI（Sonnet）が中期視点での分析・提案を行う。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.10 振り返り — saveMonthlyReview）
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（FR-52 / BR-52-01〜03）
- 対応機能: FR-52

Scope
- 変更OK:
  - `src/features/review/actions.ts`（saveMonthlyReview を追加）
- 変更NG:
  - UI（SPR9-04 が担当）

saveMonthlyReview Action
- 使用モデル: AI_MODELS.coaching（Sonnet）
- UPSERT（user_id + month_start でユニーク）
- AI への入力データを収集（BR-52-02）:
  - 先月の time_blocks から時間配分集計（前月比）
  - PJ 全体の進捗（プロジェクトごとの完了タスク数・時間）
  - 目標達成度（goals の progressPct）
  - Warm 状態が X ヶ月続いているPJ（長期停滞判定）
- AI が返す:
  - aiReport: { pj_progress, time_trend, goal_achievement, stagnant_pjs }
  - aiFeedback: 中長期視点のコーチングフィードバック
- 特記事項（BR-52-03）:
  「このPJ、Xヶ月間 Warm のまま動いていません。Cold にしますか？」のような具体的提案

Acceptance Criteria
- [ ] saveMonthlyReview で Sonnet が呼ばれる
- [ ] monthly_reviews にレコードが保存される
- [ ] aiReport に長期停滞PJが含まれる
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR9-04: レビュー画面 月次タブ + AIコーチモード UI

```text
[Task]
SPR9-04: レビュー画面の月次タブ + AIコーチモード UI 実装

Goal
- `/review` の月次タブを実装する（月次 + 四半期の切り替え）。
- AIコーチモードの UI パターンを月次タブに統合する。

Context
- 参照: docs/01_要件定義/wireframes/SCR-60_review.md（月次モード）
- 対応機能: FR-52, FR-53

Scope
- 変更OK:
  - `src/features/review/components/MonthlyReviewTab.tsx`（新規）
  - `src/app/(protected)/review/page.tsx`（月次タブに組み込む）
- 変更NG:
  - Server Actions（SPR9-03 が担当）

UI フロー
1. AIレポート表示（先月の時間配分・目標達成度・長期停滞PJ）
2. テキストエリア + 音声「今月の振り返りを入力してください」
3. [AIコーチに分析してもらう] → saveMonthlyReview 呼び出し
4. AI フィードバック表示
5. 停滞PJへの対処提案（Cold にする / Active に戻す ボタン付き）
6. 月次 / 四半期 タブ切り替え（reviewType パラメータ）

停滞PJ対処 UI
- stagnant_pjs を一覧表示
- 各PJに「Cold にする」「このまま Warm で続ける」ボタン
- 「Cold にする」→ updateProjectStatus({ status: 'cold' })

Acceptance Criteria
- [ ] 月次タブで先月のレポートが表示される
- [ ] AI フィードバック（Sonnet）が表示される
- [ ] 停滞PJに対してステータス変更できる
- [ ] 月次 / 四半期の切り替えができる
```

---

文書バージョン: 1.0
作成日: 2026-04-09
