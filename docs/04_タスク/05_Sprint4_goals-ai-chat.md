# Sprint 4: 目標階層 + AI 対話基盤
## ARDORS — 目標 CRUD・Anthropic SDK 統合・AI チャット画面・音声入力

---

## 並列実行ガイド

```
SPR4-01（目標 Actions + UI）  ┐
SPR4-02（AI クライアント設定）  ├─ 並列可
SPR4-04（レート制限）          ┘
  └─→ SPR4-03（AI 対話画面 + 音声）← SPR4-02 後
```

---

## SPR4-01: 目標 Server Actions + 目標 UI

```text
[Task]
SPR4-01: 目標 Server Actions + プロジェクト詳細の目標タブ実装

Goal
- `src/features/goals/actions.ts` に目標 CRUD の Server Actions を実装する。
- プロジェクト詳細（SCR-31）の「目標」タブに目標階層を表示する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.5 目標）
- 参照: docs/02_外部設計/01_DB設計_database-design.md（3.4 goals テーブル）
- 対応機能: FR-21

Scope
- 変更OK:
  - `src/features/goals/actions.ts`
  - `src/features/goals/schemas.ts`
  - `src/features/goals/types.ts`（GoalTree = Goal & { children: GoalTree[] }）
  - `src/features/goals/index.ts`
  - `src/features/goals/components/GoalTree.tsx`（ネストツリー表示）
  - `src/features/goals/components/GoalForm.tsx`（作成・編集 Dialog）
- 変更NG:
  - /goals ページ（Sprint 10 で完成）

Actions to implement
1. createGoal(input) → Result<{ goalId: string }>
   - level: 'long_term' | 'mid_term' | 'weekly'
   - parentGoalId: オプション（階層構造用）
2. updateGoal(input) → Result<void>
3. updateGoalProgress(input) → Result<void>  ← progressPct: 0-100
4. deleteGoal(input) → Result<void>  ← deleted_at = now()、配下も再帰的に設定
5. getGoalHierarchy(input) → Result<GoalTree[]>
   - SQL: goals を再帰 WITH で取得してネスト構造に変換

目標 UI（プロジェクト詳細の目標タブ内）
- ツリー表示（GoalTree コンポーネント）
- 各ノードにプログレスバー（`<Progress value={progressPct} />`）
- 「+ 目標を追加」ボタン（Dialog で GoalForm を開く）

Acceptance Criteria
- [ ] createGoal で目標を作成できる（長期/中期/週次の各レベル）
- [ ] 親目標を指定して子目標を作成できる
- [ ] deleteGoal で deleted_at が設定される
- [ ] getGoalHierarchy がネスト構造を返す
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR4-02: AI クライアント設定 + sendMessage Action

```text
[Task]
SPR4-02: Anthropic SDK 設定 + sendMessage Server Action の実装

Goal
- `@anthropic-ai/sdk` を使った AI クライアントを設定する。
- `sendMessage` Server Action を実装する（ストリーミング対応）。
- レート制限チェックを組み込む。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.9 AI対話 / 5. AI プロンプト管理）
- 参照: docs/03_技術設計/05_開発ガイドライン_development-guidelines.md
- 参照: docs/02_外部設計/03_権限設計_authorization.md（8. AIエンドポイントのレート制限）
- 対応機能: FR-10

Scope
- 変更OK:
  - `src/shared/lib/ai/models.ts`（AI_MODELS 定数）
  - `src/shared/lib/ai/client.ts`（createAIClient）
  - `src/shared/lib/ai/rate-limit.ts`（checkAIRateLimit）
  - `src/features/ai-chat/actions.ts`（sendMessage Action）
  - `src/features/ai-chat/schemas.ts`
  - `src/features/ai-chat/index.ts`
  - `supabase/migrations/20260409000002_add_ai_conversations.sql`
    （ai_conversations テーブルを追加）
- 変更NG:
  - UI コンポーネント（SPR4-03 が担当）

DB マイグレーション
- `ai_conversations` テーブル（docs/02_外部設計/01_DB設計_database-design.md 3.9 参照）

sendMessage Action の実装
- 入力バリデーション（Zod）
- getAuthenticatedUser()
- checkAIRateLimit(user.id) → false なら 'リクエスト数の上限に達しました'
- context_type に応じてモデルを選択（weekly_review/monthly_review → Sonnet、他 → Haiku）
- Anthropic API でメッセージ送信
- user / assistant の両メッセージを ai_conversations に保存
- Result<{ reply, sessionId }> を返す

ストリーミング対応
- Route Handler（`src/app/api/chat/route.ts`）でストリーミングを実装:
  ```typescript
  // Server Action は非ストリーミング版（完了後に全文返す）
  // ストリーミング版は API Route で実装
  export async function POST(req: Request) {
    // ... auth check
    const stream = await client.messages.stream({...})
    return stream.toReadableStream()
  }
  ```

Implementation Hints
- src/shared/lib/ai/models.ts:
  ```typescript
  export const AI_MODELS = {
    default:  process.env.AI_MODEL_DEFAULT  ?? 'claude-haiku-4-5-20251001',
    coaching: process.env.AI_MODEL_COACHING ?? 'claude-sonnet-4-6',
  } as const
  ```
- checkAIRateLimit:
  直近1時間の ai_conversations（role='user'）件数が 100 未満なら true を返す。

Acceptance Criteria
- [ ] sendMessage で Anthropic API と通信し reply が返る
- [ ] ai_conversations テーブルに user/assistant の2行が保存される
- [ ] レート制限: 100回/時間を超えるとエラーを返す
- [ ] context_type='weekly_review' では Sonnet モデルを使用する
- [ ] ANTHROPIC_API_KEY が未設定の場合エラーを返す（値を推測しない）
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR4-03: AI 対話画面（SCR-21）+ 音声入力

```text
[Task]
SPR4-03: AI 対話全画面（SCR-21）+ VoiceInputButton コンポーネントの実装

Goal
- `/chat` に AI との全画面チャット UI を実装する。
- テキスト入力 + 音声入力（Web Speech API）に対応する。
- ストリーミング応答を文字単位で表示する。

Context
- 参照: docs/01_要件定義/wireframes/SCR-21_ai-chat.md
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（4.5 SCR-21）
- 対応機能: FR-10, FR-11

Scope
- 変更OK:
  - `src/app/(protected)/chat/page.tsx`
  - `src/features/ai-chat/components/ChatInterface.tsx`（メッセージ一覧 + 入力エリア）
  - `src/features/ai-chat/components/MessageBubble.tsx`（メッセージ気泡）
  - `src/features/ai-chat/components/StreamingMessage.tsx`（ストリーミング表示）
  - `src/shared/ui/voice-input-button.tsx`（Web Speech API ラッパー）
- 変更NG:
  - Server Actions（SPR4-02 が担当）

UI 要件（docs/02_外部設計/04_画面設計_screen-design.md 4.5 参照）
- ヘッダー: 「AIパートナー」タイトル
- メッセージ一覧: ユーザー（右）/ AI（左）の気泡形式
- 入力エリア: テキストエリア + VoiceInputButton + 送信ボタン
- クイックアクション: [ブレインダンプ] [今日の計画]（モード切り替え用プリセット）

VoiceInputButton（docs/02_外部設計/04_画面設計_screen-design.md 6. 参照）
- Web Speech API (SpeechRecognition) を使用
- 録音中: ボタンが `text-red-500 animate-pulse` に
- 認識結果をテキストエリアに挿入（送信は手動）
- 非対応ブラウザ: alert で案内

ストリーミング表示
- `fetch('/api/chat', { method: 'POST', body: ... })` でストリーム取得
- `ReadableStream` を `TextDecoder` で読みながら state に追記
- 完了後に ai_conversations に保存

Acceptance Criteria
- [ ] /chat にアクセスするとチャット画面が表示される
- [ ] テキストを入力して送信するとAIの返答が表示される
- [ ] AIの返答がストリーミングで逐次表示される
- [ ] VoiceInputButton で音声を入力し、テキストエリアに挿入できる（Chrome）
- [ ] 非対応ブラウザでは案内メッセージが表示される
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR4-04: AI レート制限（checkAIRateLimit 強化）

```text
[Task]
SPR4-04: AI API レート制限の強化（SPR4-02 が基本実装済みの場合の強化版）

Goal
- レート制限を HTTP ヘッダーでクライアントに伝える。
- 残り回数を UI に表示する（オプション）。

Context
- 参照: docs/02_外部設計/03_権限設計_authorization.md（8. AIエンドポイントのレート制限）
- SPR4-02 の checkAIRateLimit が実装済みであること

Scope
- 変更OK:
  - `src/app/api/chat/route.ts`（レスポンスヘッダーに X-RateLimit-Remaining を追加）
  - `src/features/ai-chat/components/ChatInterface.tsx`（残り回数表示、オプション）
- 変更NG:
  - checkAIRateLimit 関数本体（変更不要なら）

Acceptance Criteria
- [ ] レート制限超過時に適切なエラーメッセージが表示される
- [ ] レスポンスヘッダーに X-RateLimit-Remaining が含まれる
```

---

文書バージョン: 1.0
作成日: 2026-04-09
