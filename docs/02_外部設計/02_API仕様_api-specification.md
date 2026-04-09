# API仕様（Server Actions 仕様書）
## プロジェクト名: ARDORS（アーダース）

---

## 1. 概要

ARDORS は Next.js 15 App Router を採用しており、REST API は持たない。
全データ操作は **Next.js Server Actions**（`'use server'` ディレクティブを持つ関数）経由で行う。

### 1.1 基本設計方針

| 項目 | 内容 |
|------|------|
| 実行環境 | Node.js サーバーサイド（Vercel Serverless Functions） |
| 認証 | 全 Action で `getAuthenticatedUser()` を最初に呼び出す |
| バリデーション | Zod スキーマで入力を検証してから DB アクセス |
| 戻り値型 | 必ず `Result<T>` 型を返す |
| エラー処理 | try/catch で全エラーを捕捉し `{ success: false, error: string }` で返す |
| API キー | `ANTHROPIC_API_KEY` 等は Server Actions 内のみで使用（クライアント非公開） |

### 1.2 共通型定義

```typescript
// src/shared/types/result.ts
export type Result<T> =
  | { success: true; data: T }
  | { success: false; error: string }

// src/shared/types/pagination.ts
export type PaginationInput = {
  page: number    // 1始まり
  limit: number   // デフォルト 20
}

export type PaginatedResult<T> = {
  items: T[]
  total: number
  page: number
  limit: number
}
```

### 1.3 標準エラーメッセージ

| エラー種別 | メッセージ（日本語） |
|----------|-------------------|
| 未認証 | `'ログインが必要です'` |
| リソース不在 / 権限なし | `'データが見つかりません'` |
| Zod バリデーション失敗 | 各フィールドのエラーメッセージ（日本語化） |
| AI API エラー | `'AI処理中にエラーが発生しました。しばらく待ってから再度お試しください'` |
| レートリミット超過 | `'リクエスト数の上限に達しました。しばらく待ってから再度お試しください'` |
| GCal 連携なし | `'Google Calendarと連携されていません。設定から連携してください'` |
| 汎用失敗 | 機能名 + `'に失敗しました'`（例: `'プロジェクトの作成に失敗しました'`） |

---

## 2. 実装テンプレート

```typescript
'use server'

import { z } from 'zod'
import { createServerClient } from '@/shared/lib/supabase/server'
import { getAuthenticatedUser, UnauthorizedError } from '@/shared/lib/auth/get-user'
import type { Result } from '@/shared/types/result'

// 1. Zod スキーマ定義
const exampleSchema = z.object({
  name: z.string().min(1).max(100),
})

// 2. Server Action
export async function exampleAction(
  input: z.infer<typeof exampleSchema>
): Promise<Result<{ id: string }>> {
  try {
    // 3. 認証確認（必須・最初）
    const user = await getAuthenticatedUser()

    // 4. 入力バリデーション
    const validated = exampleSchema.parse(input)

    // 5. DB 操作
    const supabase = createServerClient()
    const { data, error } = await supabase
      .from('some_table')
      .insert({ ...validated, user_id: user.id })
      .select('id')
      .single()

    if (error) throw error

    return { success: true, data: { id: data.id } }
  } catch (e) {
    if (e instanceof UnauthorizedError) {
      return { success: false, error: 'ログインが必要です' }
    }
    if (e instanceof z.ZodError) {
      return { success: false, error: e.errors[0].message }
    }
    return { success: false, error: '処理に失敗しました' }
  }
}
```

---

## 3. 機能別 Server Actions 仕様

---

### 3.1 認証 (`src/features/auth/actions.ts`)

#### `signUp`

| 項目 | 内容 |
|------|------|
| 説明 | メールアドレス+パスワードで新規アカウント作成 |
| 副作用 | Supabase Auth にユーザー作成 → トリガーで profiles/user_settings 作成 → 確認メール送信 |

```typescript
// 入力
const signUpSchema = z.object({
  email: z.string().email('有効なメールアドレスを入力してください'),
  password: z.string().min(8, 'パスワードは8文字以上にしてください'),
  displayName: z.string().min(1).max(50, '表示名は50文字以内にしてください'),
})

// 戻り値
type SignUpResult = Result<{ userId: string }>

// エラー: email already in use → 'このメールアドレスは既に登録されています'
```

#### `signIn`

| 項目 | 内容 |
|------|------|
| 説明 | メール+パスワードでログイン。セッション作成 |
| 副作用 | Supabase セッション Cookie を設定 |

```typescript
const signInSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
})
type SignInResult = Result<{ redirectUrl: string }>
// redirectUrl: クエリパラメータ redirectTo があればそこへ、なければ '/dashboard'
```

#### `signOut`

```typescript
type SignOutResult = Result<void>
// 副作用: Supabase セッション削除
```

#### `sendPasswordResetEmail`

```typescript
const resetSchema = z.object({
  email: z.string().email(),
})
type ResetResult = Result<void>
// 常に success: true（メール存在有無を漏らさない）
```

#### `updatePassword`

```typescript
const updatePasswordSchema = z.object({
  password: z.string().min(8),
})
type UpdatePasswordResult = Result<void>
// リセットトークン認証は Supabase Auth が処理済みの前提
```

---

### 3.2 オンボーディング (`src/features/onboarding/actions.ts`)

#### `completeOnboarding`

| 項目 | 内容 |
|------|------|
| 説明 | オンボーディング入力を保存し、初期 PJ/目標を作成 |
| 副作用 | projects レコード作成 / goals レコード作成 / profiles.onboarding_completed = true |

```typescript
const projectInputSchema = z.object({
  name: z.string().min(1).max(100),
  category: z.string().optional(),
  goal: z.string().optional(),
})

const completeOnboardingSchema = z.object({
  rawInput: z.string(),
  structuredData: z.object({
    projects: z.array(projectInputSchema).max(10),
    lifeRhythm: z.object({
      wakeTime: z.string(),       // "HH:MM"
      sleepTime: z.string(),      // "HH:MM"
      workStartTime: z.string().optional(),
      workEndTime: z.string().optional(),
    }),
    initialGoals: z.array(z.string()).max(5),
  }),
})

type CompleteOnboardingResult = Result<{ projectIds: string[] }>
```

---

### 3.3 プロジェクト (`src/features/projects/actions.ts`)

#### `createProject`

```typescript
const createProjectSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().optional(),
  goal: z.string().optional(),
  status: z.enum(['active', 'warm', 'cold']).default('active'),
  category: z.string().optional(),
  deadline: z.string().date().optional(),  // ISO date: "YYYY-MM-DD"
  idealWeeklyHours: z.number().min(0).max(168).optional(),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(),
})

type CreateProjectResult = Result<{ projectId: string }>
```

#### `updateProject`

```typescript
const updateProjectSchema = createProjectSchema.partial().extend({
  projectId: z.string().uuid(),
})
type UpdateProjectResult = Result<void>
// 所有者確認後に更新
```

#### `updateProjectStatus`

```typescript
const updateStatusSchema = z.object({
  projectId: z.string().uuid(),
  status: z.enum(['active', 'warm', 'cold', 'completed']),
})
type UpdateStatusResult = Result<void>
```

#### `deleteProject`（論理削除）

```typescript
const deleteProjectSchema = z.object({ projectId: z.string().uuid() })
type DeleteProjectResult = Result<void>
// deleted_at = now() を設定。配下の tasks も同時に deleted_at を設定
```

#### `getProjects`

```typescript
const getProjectsSchema = z.object({
  status: z.enum(['active', 'warm', 'cold', 'completed', 'archived']).optional(),
  includeDeleted: z.boolean().default(false),
})
type GetProjectsResult = Result<Project[]>
```

#### `getProjectById`

```typescript
const getProjectByIdSchema = z.object({ projectId: z.string().uuid() })
// タスク一覧・目標・直近タイムブロックを含む詳細情報
type GetProjectByIdResult = Result<ProjectWithDetails>
```

---

### 3.4 タスク (`src/features/tasks/actions.ts`)

#### `createTask`

```typescript
const createTaskSchema = z.object({
  projectId: z.string().uuid(),
  goalId: z.string().uuid().optional(),
  title: z.string().min(1).max(200),
  description: z.string().optional(),
  priority: z.enum(['high', 'medium', 'low']).default('medium'),
  estimatedMinutes: z.number().int().positive().optional(),
  dueDate: z.string().date().optional(),
})
type CreateTaskResult = Result<{ taskId: string }>
```

#### `updateTask`

```typescript
const updateTaskSchema = createTaskSchema.partial().extend({
  taskId: z.string().uuid(),
})
type UpdateTaskResult = Result<void>
```

#### `completeTask`

```typescript
const completeTaskSchema = z.object({
  taskId: z.string().uuid(),
  actualMinutes: z.number().int().min(0).optional(),
})
type CompleteTaskResult = Result<void>
// status = 'done', completed_at = now()
```

#### `deleteTask`（論理削除）

```typescript
const deleteTaskSchema = z.object({ taskId: z.string().uuid() })
type DeleteTaskResult = Result<void>
```

#### `getTasksByProject`

```typescript
const getTasksByProjectSchema = z.object({
  projectId: z.string().uuid(),
  status: z.enum(['todo', 'in_progress', 'done', 'cancelled']).optional(),
})
type GetTasksByProjectResult = Result<Task[]>
```

---

### 3.5 目標 (`src/features/goals/actions.ts`)

#### `createGoal`

```typescript
const createGoalSchema = z.object({
  projectId: z.string().uuid().optional(),
  parentGoalId: z.string().uuid().optional(),
  title: z.string().min(1).max(200),
  description: z.string().optional(),
  level: z.enum(['long_term', 'mid_term', 'weekly']),
  targetDate: z.string().date().optional(),
})
type CreateGoalResult = Result<{ goalId: string }>
```

#### `updateGoal`

```typescript
const updateGoalSchema = createGoalSchema.partial().extend({
  goalId: z.string().uuid(),
})
type UpdateGoalResult = Result<void>
```

#### `updateGoalProgress`

```typescript
const updateProgressSchema = z.object({
  goalId: z.string().uuid(),
  progressPct: z.number().min(0).max(100),
})
type UpdateProgressResult = Result<void>
```

#### `deleteGoal`

```typescript
const deleteGoalSchema = z.object({ goalId: z.string().uuid() })
type DeleteGoalResult = Result<void>
// deleted_at = now(). 配下の子目標も再帰的に deleted_at を設定
```

#### `getGoalHierarchy`

```typescript
const getGoalHierarchySchema = z.object({
  projectId: z.string().uuid().optional(),
})
// ネスト構造で返す: GoalTree = Goal & { children: GoalTree[] }
type GetGoalHierarchyResult = Result<GoalTree[]>
```

---

### 3.6 習慣 (`src/features/habits/actions.ts`)

#### `createHabit`

```typescript
const createHabitSchema = z.object({
  name: z.string().min(1).max(100),
  cue: z.string().min(1),
  minimumAction: z.string().min(1),
  ifThenPlan: z.string().optional(),
  frequencyType: z.enum(['daily', 'weekdays', 'weekly_n', 'custom']),
  frequencyDays: z.array(z.number().int().min(0).max(6)).optional(),
  // weekly_n: [N] / custom: 曜日番号の配列
  projectId: z.string().uuid().optional(),
})
type CreateHabitResult = Result<{ habitId: string }>
```

#### `updateHabit`

```typescript
const updateHabitSchema = createHabitSchema.partial().extend({
  habitId: z.string().uuid(),
  isActive: z.boolean().optional(),
})
type UpdateHabitResult = Result<void>
```

#### `deleteHabit`（論理削除）

```typescript
const deleteHabitSchema = z.object({ habitId: z.string().uuid() })
type DeleteHabitResult = Result<void>
```

#### `logHabit`

| 項目 | 内容 |
|------|------|
| 説明 | 習慣の実行を記録（UPSERT） |
| 副作用 | habit_logs にレコード作成/更新 |

```typescript
const logHabitSchema = z.object({
  habitId: z.string().uuid(),
  loggedDate: z.string().date().default(() => new Date().toISOString().slice(0, 10)),
  completed: z.boolean().default(true),
  note: z.string().optional(),
})
type LogHabitResult = Result<{ logId: string }>
// ON CONFLICT (habit_id, logged_date) → DO UPDATE SET completed, note, updated_at
```

#### `unlogHabit`

```typescript
const unlogHabitSchema = z.object({
  habitId: z.string().uuid(),
  loggedDate: z.string().date(),
})
type UnlogHabitResult = Result<void>
// 当日分のログのみ削除可能（loggedDate === today でなければエラー）
```

#### `getHabitsWithTodayLogs`

```typescript
// 入力: なし
// アクティブな習慣 + 今日のログ状況を JOIN して返す
type HabitWithLog = Habit & { todayLog: HabitLog | null }
type GetHabitsResult = Result<HabitWithLog[]>
```

---

### 3.7 タイムボクシング・スケジュール (`src/features/schedule/actions.ts`)

#### `createTimeBlock`

```typescript
const createTimeBlockSchema = z.object({
  title: z.string().min(1).max(200),
  startAt: z.string().datetime({ offset: true }),
  endAt: z.string().datetime({ offset: true }),
  projectId: z.string().uuid().optional(),
  taskId: z.string().uuid().optional(),
  blockType: z.enum(['work', 'break', 'commute', 'personal']).default('work'),
  location: z.string().optional(),
}).refine(d => new Date(d.endAt) > new Date(d.startAt), {
  message: '終了時刻は開始時刻より後にしてください',
})
type CreateTimeBlockResult = Result<{ blockId: string }>
```

#### `updateTimeBlock`

```typescript
const updateTimeBlockSchema = createTimeBlockSchema.partial().extend({
  blockId: z.string().uuid(),
})
type UpdateTimeBlockResult = Result<void>
```

#### `deleteTimeBlock`

```typescript
const deleteTimeBlockSchema = z.object({ blockId: z.string().uuid() })
type DeleteTimeBlockResult = Result<void>
// deleted_at = now()
```

#### `approveTimeBlocks`

```typescript
const approveTimeBlocksSchema = z.object({
  blockIds: z.array(z.string().uuid()).min(1),
})
type ApproveTimeBlocksResult = Result<void>
// is_approved = true に一括更新
```

#### `rateTimeBlock`

```typescript
const rateTimeBlockSchema = z.object({
  blockId: z.string().uuid(),
  focusRating: z.union([z.literal(1), z.literal(2), z.literal(3)]),
  transitionNote: z.string().optional(),
})
type RateTimeBlockResult = Result<void>
// FR-54: ブロック間トランジション評価
```

#### `getTimeBlocksForWeek`

```typescript
const getTimeBlocksForWeekSchema = z.object({
  weekStart: z.string().date(),  // 月曜日の日付 "YYYY-MM-DD"
})
// start_at が weekStart 〜 weekStart+7days のブロックを取得
type GetTimeBlocksResult = Result<TimeBlock[]>
```

#### `generateWeeklyTimebox` （AI Action）

| 項目 | 内容 |
|------|------|
| 説明 | AI（Haiku）が週間タイムボクシングを自動生成 |
| 使用モデル | `AI_MODEL_DEFAULT`（Claude Haiku） |
| 副作用 | time_blocks レコード作成（is_approved=false） / ai_conversations レコード作成 |

```typescript
const generateWeeklyTimeboxSchema = z.object({
  weekStart: z.string().date(),
  preferences: z.object({
    focusHoursPerDay: z.number().min(1).max(12).optional(),
  }).optional(),
})
type GenerateWeeklyTimeboxResult = Result<{
  blocks: TimeBlock[]
  sessionId: string
  // ユーザーは blocks を確認後 approveTimeBlocks() を呼ぶ
}>
```

---

### 3.8 Google Calendar (`src/features/schedule/gcal-actions.ts`)

#### `pullGoogleCalendarEvents`

| 項目 | 内容 |
|------|------|
| 説明 | Google Calendar の予定を取得し time_blocks に保存 |
| 取得範囲 | 今日から28日先（BR-32-01） |
| 副作用 | source='gcal' の time_blocks を UPSERT（gcal_event_id で判断） |

```typescript
// 入力: なし
type PullGCalResult = Result<{ imported: number }>
// エラー: gcal_tokens 未存在 → 'Google Calendarと連携されていません'
```

#### `pushToGoogleCalendar`

| 項目 | 内容 |
|------|------|
| 説明 | 承認済み ARDORS ブロックを Google Calendar に一括登録 |
| 副作用 | gcal_event_id / gcal_pushed_at を time_blocks に保存 |

```typescript
const pushGCalSchema = z.object({
  blockIds: z.array(z.string().uuid()).optional(),
  // 未指定の場合: 今週の is_approved=true かつ source='ardors' のブロックを全て push
})
type PushGCalResult = Result<{ pushed: number }>
```

#### `connectGoogleCalendar`

```typescript
const connectGCalSchema = z.object({
  code: z.string(),  // Google OAuth 認可コード
})
type ConnectGCalResult = Result<void>
// トークン取得後 gcal_tokens に保存
```

#### `disconnectGoogleCalendar`

```typescript
// 入力: なし
type DisconnectGCalResult = Result<void>
// gcal_tokens レコードを削除
```

---

### 3.9 AI対話 (`src/features/ai-chat/actions.ts`)

#### `sendMessage`

| 項目 | 内容 |
|------|------|
| 説明 | AI にメッセージを送信し、返信を取得 |
| 使用モデル | context_type が `weekly_review`/`monthly_review` → Sonnet / その他 → Haiku |
| レート制限 | 1時間あたり最大100リクエスト/ユーザー |
| 副作用 | user/assistant の会話を ai_conversations に保存 |

```typescript
const sendMessageSchema = z.object({
  message: z.string().min(1).max(10000),
  sessionId: z.string().uuid().optional(),
  // 省略時は新規セッション（gen_random_uuid()）
  contextType: z.enum([
    'chat', 'braindump', 'morning_briefing',
    'daily_close', 'weekly_review', 'monthly_review', 'onboarding'
  ]).default('chat'),
})

type SendMessageResult = Result<{
  reply: string
  sessionId: string
  metadata?: Record<string, unknown>
  // metadata: ブレインダンプ時はタスク候補等を含む
}>
```

#### `braindump`

| 項目 | 内容 |
|------|------|
| 説明 | 自由入力をAIが構造化（タスク候補・ビジョン候補の抽出） |
| 使用モデル | Haiku |
| 副作用 | ai_conversations に保存（metadata に構造化データ） |

```typescript
const braindumpSchema = z.object({
  rawInput: z.string().min(1).max(10000),
  inputType: z.enum(['text', 'voice_transcript']),
})

type ProposedTask = {
  title: string
  projectId?: string     // AI が推定したPJ
  goalId?: string
  priority?: 'high' | 'medium' | 'low'
  dueDate?: string
  estimatedMinutes?: number
}

type ProposedVision = {
  content: string
  type: 'goal' | 'note' | 'new_project'
  projectName?: string   // type='new_project' の場合
}

type BraindumpResult = Result<{
  tasks: ProposedTask[]
  visions: ProposedVision[]
  sessionId: string
}>
```

#### `approveBraindumpItems`

| 項目 | 内容 |
|------|------|
| 説明 | ブレインダンプの確認・承認後に実際のレコードを作成 |
| 副作用 | tasks/goals/notes レコードを作成 |

```typescript
const approveBraindumpSchema = z.object({
  sessionId: z.string().uuid(),
  approvedTasks: z.array(z.object({
    title: z.string().min(1).max(200),
    projectId: z.string().uuid(),
    goalId: z.string().uuid().optional(),
    priority: z.enum(['high', 'medium', 'low']).default('medium'),
    dueDate: z.string().date().optional(),
    estimatedMinutes: z.number().int().positive().optional(),
  })),
  approvedVisions: z.array(z.object({
    content: z.string().min(1),
    type: z.enum(['goal', 'note', 'new_project']),
    projectName: z.string().optional(),
  })),
})

type ApproveBraindumpResult = Result<{
  taskIds: string[]
  noteIds: string[]
  goalIds: string[]
}>
```

#### `generateMorningBriefing`

| 項目 | 内容 |
|------|------|
| 説明 | 今日の予定・タスク・前日レビューをもとにAIが朝のブリーフィングを生成 |
| 使用モデル | Haiku |
| 副作用 | ai_conversations に context_type='morning_briefing' で保存 |

```typescript
// 入力: なし（ユーザーのデータをサーバー側で自動取得）
type MorningBriefingResult = Result<{
  briefing: string
  sessionId: string
}>
```

---

### 3.10 振り返り (`src/features/review/actions.ts`)

#### `saveDailyReview`

| 項目 | 内容 |
|------|------|
| 説明 | デイリークローズを保存し、AI分析・フィードバックを取得 |
| 使用モデル | Haiku |
| 副作用 | daily_reviews に UPSERT / ai_conversations に保存 |

```typescript
const saveDailyReviewSchema = z.object({
  reviewDate: z.string().date(),
  userInput: z.string().optional(),
  skip: z.boolean().default(false),
})

type SaveDailyReviewResult = Result<{
  reviewId: string
  aiFeedback: string
  doneList: Array<{ taskId: string; title: string; projectName: string }>
  sessionId: string
}>
```

#### `saveWeeklyReview`

| 項目 | 内容 |
|------|------|
| 説明 | ウィークリーレビューを保存。AIコーチモード（Sonnet）で深い分析 |
| 使用モデル | **Sonnet**（coaching） |
| 副作用 | weekly_reviews に UPSERT / ai_conversations に保存 |

```typescript
const saveWeeklyReviewSchema = z.object({
  weekStart: z.string().date(),
  userInput: z.string().optional(),
  skip: z.boolean().default(false),
})

type SaveWeeklyReviewResult = Result<{
  reviewId: string
  aiSummary: WeeklyAISummary
  aiFeedback: string
  proposedGoals: Array<{ title: string; projectId?: string }>
  sessionId: string
}>
```

#### `approveWeeklyGoals`

```typescript
const approveWeeklyGoalsSchema = z.object({
  reviewId: z.string().uuid(),
  goals: z.array(z.object({
    title: z.string().min(1).max(200),
    projectId: z.string().uuid().optional(),
  })).max(3),
})
type ApproveWeeklyGoalsResult = Result<{ goalIds: string[] }>
// goals テーブルに level='weekly' でレコード作成
```

#### `saveMonthlyReview`

| 項目 | 内容 |
|------|------|
| 使用モデル | **Sonnet**（coaching） |

```typescript
const saveMonthlyReviewSchema = z.object({
  monthStart: z.string().date(),
  reviewType: z.enum(['monthly', 'quarterly']),
  userInput: z.string().optional(),
  skip: z.boolean().default(false),
})

type SaveMonthlyReviewResult = Result<{
  reviewId: string
  aiReport: MonthlyAIReport
  aiFeedback: string
  sessionId: string
}>
```

#### `getReviewHistory`

```typescript
const getReviewHistorySchema = z.object({
  type: z.enum(['daily', 'weekly', 'monthly']),
  limit: z.number().int().min(1).max(52).default(10),
})
type GetReviewHistoryResult = Result<Review[]>
```

---

### 3.11 通知 (`src/features/notifications/actions.ts`)

#### `getNotifications`

```typescript
const getNotificationsSchema = z.object({
  unreadOnly: z.boolean().default(false),
})
type GetNotificationsResult = Result<Notification[]>
// scheduled_at <= now() のもののみ返す（未来の通知は非表示）
```

#### `markNotificationRead`

```typescript
const markReadSchema = z.object({ notificationId: z.string().uuid() })
type MarkReadResult = Result<void>
// read_at = now()
```

#### `markAllNotificationsRead`

```typescript
// 入力: なし
type MarkAllReadResult = Result<void>
```

---

### 3.12 ユーザー設定 (`src/features/settings/actions.ts`)

#### `updateUserSettings`

```typescript
const updateUserSettingsSchema = z.object({
  dailyCloseTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/).optional(),
  weeklyReviewDay: z.number().int().min(0).max(6).optional(),
  weeklyReviewTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/).optional(),
  morningBriefingTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/).optional(),
  notificationEnabled: z.boolean().optional(),
  gcalPushCalendarId: z.string().optional(),
  idealTimeAllocation: z.record(z.string().uuid(), z.number().min(0).max(100)).optional(),
})
type UpdateUserSettingsResult = Result<void>
```

#### `updateProfile`

```typescript
const updateProfileSchema = z.object({
  displayName: z.string().min(1).max(50).optional(),
  avatarUrl: z.string().url().optional(),
  aiToneLevel: z.enum(['coach', 'mentor', 'friend']).optional(),
  timezone: z.string().optional(),
})
type UpdateProfileResult = Result<void>
```

#### `updateLifeRhythm`

```typescript
const timeRegex = /^([01]\d|2[0-3]):([0-5]\d)$/
const updateLifeRhythmSchema = z.object({
  wakeTime: z.string().regex(timeRegex).optional(),
  sleepTime: z.string().regex(timeRegex).optional(),
  workStartTime: z.string().regex(timeRegex).optional(),
  workEndTime: z.string().regex(timeRegex).optional(),
  lunchStart: z.string().regex(timeRegex).optional(),
  lunchEnd: z.string().regex(timeRegex).optional(),
})
type UpdateLifeRhythmResult = Result<void>
// profiles.life_rhythm JSONB を更新
```

---

### 3.13 エネルギーチェックイン (`src/features/energy/actions.ts`)

#### `logEnergyCheckin`

```typescript
const logEnergyCheckinSchema = z.object({
  energyLevel: z.union([z.literal(1), z.literal(2), z.literal(3), z.literal(4), z.literal(5)]),
  moodLevel: z.union([z.literal(1), z.literal(2), z.literal(3), z.literal(4), z.literal(5)]),
  focusLevel: z.union([z.literal(1), z.literal(2), z.literal(3), z.literal(4), z.literal(5)]),
  note: z.string().optional(),
})
type LogEnergyCheckinResult = Result<{ checkinId: string }>
```

#### `getTodayCheckins`

```typescript
// 入力: なし
// 今日分のチェックイン一覧（複数回可）
type GetTodayCheckinsResult = Result<EnergyCheckin[]>
```

---

### 3.14 ノート (`src/features/notes/actions.ts`)

#### `createNote`

```typescript
const createNoteSchema = z.object({
  content: z.string().min(1).max(10000),
  title: z.string().optional(),
  tags: z.array(z.string().max(50)).max(20).default([]),
  relatedProjectIds: z.array(z.string().uuid()).max(10).default([]),
  source: z.enum(['manual', 'braindump', 'ai_chat', 'voice']).default('manual'),
})
type CreateNoteResult = Result<{ noteId: string }>
```

#### `updateNote`

```typescript
const updateNoteSchema = createNoteSchema.partial().extend({
  noteId: z.string().uuid(),
})
type UpdateNoteResult = Result<void>
```

#### `deleteNote`（論理削除）

```typescript
const deleteNoteSchema = z.object({ noteId: z.string().uuid() })
type DeleteNoteResult = Result<void>
```

#### `getNotes`

```typescript
const getNotesSchema = z.object({
  search: z.string().optional(),      // タイトル・本文の全文検索
  tags: z.array(z.string()).optional(),
  projectId: z.string().uuid().optional(),
  limit: z.number().int().min(1).max(100).default(20),
  offset: z.number().int().min(0).default(0),
})
type GetNotesResult = Result<PaginatedResult<Note>>
```

---

### 3.15 管理者 (`src/features/admin/actions.ts`)

#### `getAdminUserList`

```typescript
const getAdminUserListSchema = z.object({
  search: z.string().optional(),
  page: z.number().int().min(1).default(1),
  limit: z.number().int().min(1).max(100).default(20),
})
type GetAdminUserListResult = Result<PaginatedResult<AdminUserView>>
// getAdminUser() で管理者確認必須
```

#### `suspendUser`

```typescript
const suspendUserSchema = z.object({ userId: z.string().uuid() })
type SuspendUserResult = Result<void>
// Supabase Admin API でユーザーを ban
```

---

## 4. Supabase クライアント設定

```typescript
// src/shared/lib/supabase/server.ts
import { createServerClient as createClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '@/shared/types/supabase'

export function createServerClient() {
  const cookieStore = cookies()
  return createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return cookieStore.getAll() },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          )
        },
      },
    }
  )
}
```

---

## 5. AI プロンプト管理

```typescript
// src/shared/lib/ai/models.ts
import Anthropic from '@anthropic-ai/sdk'

export const AI_MODELS = {
  default:  process.env.AI_MODEL_DEFAULT  ?? 'claude-haiku-4-5-20251001',
  coaching: process.env.AI_MODEL_COACHING ?? 'claude-sonnet-4-6',
} as const

export type AIModelKey = keyof typeof AI_MODELS

export function getModelId(key: AIModelKey = 'default'): string {
  return AI_MODELS[key]
}

// src/shared/lib/ai/client.ts
export function createAIClient() {
  return new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY!,
  })
}
```

---

文書バージョン: 1.0
作成日: 2026-04-09
最終更新日: 2026-04-09
