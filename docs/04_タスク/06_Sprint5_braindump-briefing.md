# Sprint 5: ブレインダンプ + 新規PJ作成AI + モーニングブリーフィング
## ARDORS — FR-12, FR-13, FR-24

---

## 並列実行ガイド

```
SPR5-01（ブレインダンプ Action）┐
SPR5-03（新規PJ作成 AI）       ├─ 並列可（別ファイル）
SPR5-04（モーニングブリーフィング）┘
  └─→ SPR5-02（ブレインダンプ UI）← SPR5-01 の型に依存
```

---

## SPR5-01: ブレインダンプ Server Action + 承認フロー

```text
[Task]
SPR5-01: ブレインダンプ Server Actions の実装（braindump / approveBraindumpItems）

Goal
- 自由入力テキストを AI が構造化し、タスク候補・ビジョン候補を返す。
- ユーザー承認後に実際の tasks/goals/notes レコードを作成する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.9 AI対話 — braindump / approveBraindumpItems）
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（FR-12: ブレインダンプ）
- 対応機能: FR-12

Scope
- 変更OK:
  - `src/features/ai-chat/actions.ts`（braindump / approveBraindumpItems を追加）
  - `src/features/ai-chat/schemas.ts`（ProposedTask / ProposedVision 型）
  - `supabase/migrations/20260409000003_add_notes.sql`（notes テーブル追加）
- 変更NG:
  - UI（SPR5-02 が担当）

DB マイグレーション
- `notes` テーブル（docs/02_外部設計/01_DB設計_database-design.md 3.13 参照）

braindump Action
- 入力: rawInput（自由テキスト / 音声文字起こし）、inputType
- AI（Haiku）への指示（プロンプト骨子）:
  ```
  以下の入力を分析し、タスク的内容とビジョン的内容に分類してください。
  タスク的内容: プロジェクト振り分け・タスク抽出・期限検出
  ビジョン的内容: 展望整理・目標との接続・新規PJ候補
  JSON で返してください: { tasks: [...], visions: [...] }
  ```
- 戻り値: ProposedTask[] + ProposedVision[]（ユーザーが承認するまで DB に保存しない）
- ai_conversations に metadata として構造化データを保存

approveBraindumpItems Action
- 承認されたタスクを tasks テーブルに一括 INSERT
- 承認されたビジョンを type に応じて goals/notes/projects に INSERT
- 戻り値: { taskIds, noteIds, goalIds }

Acceptance Criteria
- [ ] braindump でタスク候補・ビジョン候補が返る
- [ ] approveBraindumpItems で承認したアイテムが DB に保存される
- [ ] ai_conversations に保存される（context_type='braindump'）
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR5-02: ブレインダンプ UI（SCR-21 内のブレインダンプモード）

```text
[Task]
SPR5-02: ブレインダンプ UI の実装（/chat のブレインダンプモード）

Goal
- `/chat` 画面の「ブレインダンプ」クイックアクションからブレインダンプモードに切り替える。
- AI が返した候補一覧を確認・承認できる UI を実装する。

Context
- 参照: docs/01_要件定義/wireframes/SCR-21_ai-chat.md
- 対応機能: FR-12

Scope
- 変更OK:
  - `src/features/ai-chat/components/BraindumpMode.tsx`（新規）
  - `src/features/ai-chat/components/BraindumpReview.tsx`（候補確認・承認画面）
  - `src/features/ai-chat/components/ChatInterface.tsx`（モード切り替え追加）
- 変更NG:
  - Server Actions（SPR5-01 が担当）

UI フロー
1. [ブレインダンプ] ボタンタップ → モード切り替え
2. 入力エリア（テキスト + 音声）+ 「AIに整理してもらう」ボタン
3. ローディング中: 「AIが分析しています...」表示
4. 結果表示（BraindumpReview）:
   - タスク候補リスト（各行にチェックボックス + 内容 + PJ・期限・優先度の編集フィールド）
   - ビジョン候補リスト（各行にチェックボックス + 内容 + タイプ選択）
   - 「選択したものを追加する」ボタン → approveBraindumpItems 呼び出し
   - 成功後: Toast「XX件のタスクと YY 件のメモを追加しました」

Acceptance Criteria
- [ ] /chat でブレインダンプモードに切り替えられる
- [ ] 入力後にタスク候補・ビジョン候補が表示される
- [ ] チェックボックスで承認するアイテムを選べる
- [ ] 承認後に Toast が表示され、モードがリセットされる
```

---

## SPR5-03: 新規PJ作成 AI 対話

```text
[Task]
SPR5-03: 新規プロジェクト作成 AI 対話の実装（FR-24）

Goal
- /projects の「AIと一緒に作成」ボタンで AI 対話からプロジェクトを作成できる。
- AI がゴール・マイルストーン・初期タスクを提案し、承認後に作成する。

Context
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（FR-24: 新規PJ作成AI対話）
- 対応機能: FR-24

Scope
- 変更OK:
  - `src/features/projects/components/AIProjectCreator.tsx`（新規: Dialog 内チャット）
  - `src/features/projects/actions.ts`（createProjectFromAI 追加）
- 変更NG:
  - /chat 画面

createProjectFromAI Action
- 入力: ユーザーの意図テキスト
- AI（Haiku）が提案: { name, goal, category, milestones: string[], initialTasks: string[] }
- 承認後に projects + tasks を一括作成
- 戻り値: Result<{ projectId: string }>

UI フロー（Dialog 内）
1. ユーザーが「どんなプロジェクトを作りたいですか？」に回答
2. AI が提案を表示（名前・ゴール・初期タスク3件）
3. ユーザーが編集・承認
4. 「プロジェクトを作成」ボタンで createProjectFromAI 呼び出し

Acceptance Criteria
- [ ] 「AIと一緒に作成」で Dialog が開く
- [ ] 入力後に AI がプロジェクト提案を表示する
- [ ] 承認後にプロジェクトと初期タスクが作成される
- [ ] 作成後に /projects/:id に遷移する
```

---

## SPR5-04: モーニングブリーフィング Action + ダッシュボード統合

```text
[Task]
SPR5-04: モーニングブリーフィング Server Action + ダッシュボード統合

Goal
- `generateMorningBriefing` Action を実装し、ダッシュボードの AIブリーフィングカードに表示する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.9 AI対話 — generateMorningBriefing）
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（FR-13: モーニングブリーフィング）
- 対応機能: FR-13

Scope
- 変更OK:
  - `src/features/ai-chat/actions.ts`（generateMorningBriefing を追加）
  - `src/features/dashboard/components/AIBriefingCard.tsx`（プレースホルダー → 実データ）
- 変更NG:
  - ダッシュボードレイアウト（SPR2-03 が担当）

generateMorningBriefing Action
- 認証チェック → レートリミットチェック
- AI（Haiku）への入力として以下を収集:
  - 今日の time_blocks（/schedule のデータ）
  - 直近の daily_review（昨日分）
  - 未完了タスク（優先度高、今日期限）
  - 今日の habits（達成状況）
- ブリーフィング生成例:
  「おはようございます。今日は 14時 に面接があります。
   移動を考えると 13:15 出発。午前は開発の API 設計に集中するのがおすすめです。
   昨日の振り返りで『テスト書き終わった』とあったので、次は API 設計ですね。」
- ai_conversations に context_type='morning_briefing' で保存

AIBriefingCard（ダッシュボード）
- Server Component として実装（ページロード時に生成）
- キャッシュ: `cache()` で1日1回のみ生成（同日中は再取得しない）
- ブリーフィングが未生成なら「おはようございます。今日も一日がんばりましょう。」

Acceptance Criteria
- [ ] generateMorningBriefing が今日のデータをもとにブリーフィングを返す
- [ ] ダッシュボードにブリーフィングが表示される
- [ ] ai_conversations に保存される（context_type='morning_briefing'）
```

---

文書バージョン: 1.0
作成日: 2026-04-09
