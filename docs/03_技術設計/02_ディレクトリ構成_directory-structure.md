# ディレクトリ構成定義書
## プロジェクト名: ARDORS（アーダース）

---

## 1. 全体構成

```
ardors/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                        # PR時: lint + test
│   │   └── deploy.yml                    # main merge時: Vercelへデプロイ
│   └── PULL_REQUEST_TEMPLATE.md
├── public/
│   ├── images/
│   └── favicon.ico
├── src/
│   ├── app/                              # App Router（ルーティング定義のみ。ロジックは持たない）
│   │   ├── (public)/                     # 認証不要グループ
│   │   │   ├── page.tsx                  # LP（/）
│   │   │   ├── login/
│   │   │   │   └── page.tsx              # SCR-03
│   │   │   ├── signup/
│   │   │   │   └── page.tsx              # SCR-02
│   │   │   ├── forgot-password/
│   │   │   │   └── page.tsx              # SCR-04
│   │   │   ├── reset-password/
│   │   │   │   └── page.tsx              # SCR-05
│   │   │   └── layout.tsx
│   │   ├── (protected)/                  # 認証必須グループ
│   │   │   ├── onboarding/
│   │   │   │   └── page.tsx              # SCR-10
│   │   │   ├── dashboard/
│   │   │   │   └── page.tsx              # SCR-20
│   │   │   ├── ai-chat/
│   │   │   │   └── page.tsx              # SCR-21
│   │   │   ├── schedule/
│   │   │   │   └── page.tsx              # SCR-40
│   │   │   ├── projects/
│   │   │   │   ├── page.tsx              # SCR-30
│   │   │   │   ├── [id]/
│   │   │   │   │   └── page.tsx          # SCR-31
│   │   │   │   └── [id]/tasks/
│   │   │   │       └── [taskId]/
│   │   │   │           └── page.tsx      # SCR-32（タスク詳細）
│   │   │   ├── habits/
│   │   │   │   └── page.tsx              # SCR-50
│   │   │   ├── review/
│   │   │   │   └── page.tsx              # SCR-60（日次/週次/月次 タブ切替）
│   │   │   ├── goals/
│   │   │   │   └── page.tsx              # SCR-70（ジャーニーマップ/時間分析 タブ切替）
│   │   │   ├── notes/
│   │   │   │   └── page.tsx              # SCR-80
│   │   │   ├── settings/
│   │   │   │   └── page.tsx              # SCR-90
│   │   │   └── layout.tsx                # グローバルナビ・フローティングAIパネル
│   │   ├── (admin)/                      # 管理者専用
│   │   │   ├── admin/
│   │   │   │   ├── page.tsx              # SCR-A1
│   │   │   │   └── users/
│   │   │   │       └── page.tsx          # SCR-A2
│   │   │   └── layout.tsx
│   │   ├── api/
│   │   │   └── auth/
│   │   │       └── callback/
│   │   │           └── route.ts          # Google OAuth コールバックURL
│   │   ├── error.tsx
│   │   ├── not-found.tsx
│   │   ├── layout.tsx                    # ルートレイアウト（フォント・メタデータ等）
│   │   └── globals.css
│   │
│   ├── features/                         # 機能単位の高凝集モジュール
│   │   ├── auth/                         # FR-01, FR-02, FR-03
│   │   │   ├── components/
│   │   │   │   ├── LoginForm.tsx
│   │   │   │   ├── SignUpForm.tsx
│   │   │   │   ├── ForgotPasswordForm.tsx
│   │   │   │   └── ResetPasswordForm.tsx
│   │   │   ├── actions/
│   │   │   │   ├── signUp.ts
│   │   │   │   ├── signIn.ts
│   │   │   │   ├── signOut.ts
│   │   │   │   └── resetPassword.ts
│   │   │   ├── schemas/
│   │   │   │   └── authSchemas.ts        # Zodスキーマ
│   │   │   ├── types.ts
│   │   │   └── index.ts                  # 公開API（外部からはindex.tsを経由）
│   │   │
│   │   ├── onboarding/                   # FR-04
│   │   │   ├── components/
│   │   │   │   ├── OnboardingWizard.tsx
│   │   │   │   ├── StepProjects.tsx
│   │   │   │   ├── StepLifestyle.tsx
│   │   │   │   ├── StepGoals.tsx
│   │   │   │   └── StepConfirm.tsx
│   │   │   ├── actions/
│   │   │   │   └── completeOnboarding.ts
│   │   │   ├── types.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── ai-chat/                      # FR-10, FR-11, FR-12, FR-13
│   │   │   ├── components/
│   │   │   │   ├── ChatWindow.tsx        # フルスクリーンチャット
│   │   │   │   ├── ChatMessage.tsx
│   │   │   │   ├── ChatInput.tsx         # テキスト入力 + 音声ボタン
│   │   │   │   ├── VoiceInputButton.tsx  # Web Speech API
│   │   │   │   ├── ActionProposal.tsx    # 承認/却下ボタン付きカード
│   │   │   │   ├── FloatingAIPanel.tsx   # SCR-21F: フローティングパネル
│   │   │   │   └── MorningBriefing.tsx   # SCR-20内のブリーフィング表示
│   │   │   ├── hooks/
│   │   │   │   ├── useAIChat.ts
│   │   │   │   └── useVoiceInput.ts
│   │   │   ├── actions/
│   │   │   │   ├── sendMessage.ts        # LLM API呼び出し
│   │   │   │   ├── brainDump.ts          # ブレインダンプ構造化
│   │   │   │   └── getMorningBriefing.ts
│   │   │   ├── lib/
│   │   │   │   ├── anthropicClient.ts    # Anthropic SDK初期化
│   │   │   │   ├── prompts/              # システムプロンプト集
│   │   │   │   │   ├── brainDump.ts
│   │   │   │   │   ├── morningBriefing.ts
│   │   │   │   │   └── weeklyCoach.ts
│   │   │   │   └── modelSelector.ts     # モデル切り替えロジック
│   │   │   ├── types.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── projects/                     # FR-20, FR-21, FR-22, FR-23, FR-24
│   │   │   ├── components/
│   │   │   │   ├── ProjectList.tsx
│   │   │   │   ├── ProjectCard.tsx
│   │   │   │   ├── ProjectDetail.tsx
│   │   │   │   ├── ProjectForm.tsx
│   │   │   │   ├── TaskList.tsx
│   │   │   │   ├── TaskCard.tsx
│   │   │   │   ├── TaskForm.tsx
│   │   │   │   └── StatusBadge.tsx       # Active/Warm/Cold バッジ
│   │   │   ├── hooks/
│   │   │   │   ├── useProjects.ts
│   │   │   │   └── useTasks.ts
│   │   │   ├── actions/
│   │   │   │   ├── createProject.ts
│   │   │   │   ├── updateProject.ts
│   │   │   │   ├── deleteProject.ts
│   │   │   │   ├── createTask.ts
│   │   │   │   ├── updateTask.ts
│   │   │   │   ├── completeTask.ts
│   │   │   │   └── deleteTask.ts
│   │   │   ├── schemas/
│   │   │   │   ├── projectSchema.ts
│   │   │   │   └── taskSchema.ts
│   │   │   ├── types.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── schedule/                     # FR-30, FR-31, FR-32, FR-33
│   │   │   ├── components/
│   │   │   │   ├── Timeline.tsx          # タイムライン表示（日/週切替）
│   │   │   │   ├── TimeBlock.tsx
│   │   │   │   ├── GCalSyncButtons.tsx   # pull/pushボタン
│   │   │   │   └── TimeboxingPreview.tsx # AIが生成したスケジュールのプレビュー
│   │   │   ├── hooks/
│   │   │   │   └── useTimeline.ts
│   │   │   ├── actions/
│   │   │   │   ├── generateTimeboxing.ts # AI呼び出し
│   │   │   │   ├── pullGoogleCalendar.ts
│   │   │   │   └── pushGoogleCalendar.ts
│   │   │   ├── lib/
│   │   │   │   └── googleCalendarClient.ts
│   │   │   ├── types.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── habits/                       # FR-40, FR-41
│   │   │   ├── components/
│   │   │   │   ├── HabitList.tsx
│   │   │   │   ├── HabitCard.tsx
│   │   │   │   ├── HabitForm.tsx
│   │   │   │   ├── HabitHeatmap.tsx      # カレンダーヒートマップ
│   │   │   │   └── HabitChecklist.tsx    # ダッシュボード用1タップチェック
│   │   │   ├── actions/
│   │   │   │   ├── createHabit.ts
│   │   │   │   ├── logHabit.ts
│   │   │   │   └── deleteHabitLog.ts
│   │   │   ├── types.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── reviews/                      # FR-50, FR-51, FR-52, FR-53
│   │   │   ├── components/
│   │   │   │   ├── ReviewTabs.tsx        # 日次/週次/月次 タブ切替
│   │   │   │   ├── DailyClose.tsx
│   │   │   │   ├── WeeklyReview.tsx
│   │   │   │   ├── MonthlyReview.tsx
│   │   │   │   └── CoachFeedback.tsx     # AIコーチモードのフィードバック表示
│   │   │   ├── actions/
│   │   │   │   ├── submitDailyClose.ts
│   │   │   │   ├── submitWeeklyReview.ts
│   │   │   │   └── submitMonthlyReview.ts
│   │   │   ├── types.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── goals/                        # FR-61, FR-62
│   │   │   ├── components/
│   │   │   │   ├── GoalsTabs.tsx         # ジャーニーマップ/時間分析 タブ
│   │   │   │   ├── JourneyMap.tsx        # 階層ツリー + タイムライン
│   │   │   │   ├── GoalNode.tsx
│   │   │   │   ├── TimeAnalysis.tsx      # 円グラフ + 棒グラフ
│   │   │   │   └── IdealVsActualBar.tsx  # 理想vs実績バー
│   │   │   ├── actions/
│   │   │   │   ├── createGoal.ts
│   │   │   │   └── updateGoal.ts
│   │   │   ├── types.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── dashboard/                    # FR-60, FR-13
│   │   │   ├── components/
│   │   │   │   ├── DashboardLayout.tsx   # 時間帯適応型ファーストビュー
│   │   │   │   ├── MorningSection.tsx
│   │   │   │   ├── DaytimeSection.tsx
│   │   │   │   ├── EveningSection.tsx
│   │   │   │   └── ScrollBelowSection.tsx # PJ・ゴール常時表示
│   │   │   ├── hooks/
│   │   │   │   └── useDashboard.ts
│   │   │   ├── types.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── notifications/                # FR-70, FR-71
│   │   │   ├── lib/
│   │   │   │   └── webPushClient.ts
│   │   │   ├── actions/
│   │   │   │   └── scheduleNotification.ts
│   │   │   ├── types.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── settings/                     # FR-06（P1）
│   │   │   ├── components/
│   │   │   │   └── SettingsForm.tsx
│   │   │   ├── actions/
│   │   │   │   └── updateSettings.ts
│   │   │   ├── types.ts
│   │   │   └── index.ts
│   │   │
│   │   └── admin/                        # FR-07（P1）
│   │       ├── components/
│   │       │   ├── AdminDashboard.tsx
│   │       │   └── UserTable.tsx
│   │       ├── actions/
│   │       │   └── manageUser.ts
│   │       ├── types.ts
│   │       └── index.ts
│   │
│   └── shared/                           # 機能横断の共有リソース
│       ├── components/
│       │   ├── ui/                       # shadcn/ui プリミティブ（自動生成）
│       │   │   ├── button.tsx
│       │   │   ├── input.tsx
│       │   │   ├── dialog.tsx
│       │   │   ├── toast.tsx
│       │   │   └── ...
│       │   ├── ConfirmDialog.tsx          # 削除確認ダイアログ共通
│       │   ├── LoadingSpinner.tsx
│       │   ├── ErrorMessage.tsx
│       │   └── GlobalNav.tsx             # グローバルナビ（PC/スマホ共通）
│       ├── hooks/
│       │   ├── useDebounce.ts
│       │   └── useNetworkStatus.ts
│       ├── lib/
│       │   ├── supabase/
│       │   │   ├── client.ts             # ブラウザ用クライアント（シングルトン）
│       │   │   ├── server.ts             # Server Components / Server Actions用
│       │   │   └── middleware.ts         # Next.js Middleware用
│       │   ├── ai/
│       │   │   └── models.ts             # AIモデル切り替え（環境変数）
│       │   ├── errors.ts                 # AppError 統一エラー型
│       │   └── utils.ts
│       ├── types/
│       │   ├── database.types.ts         # Supabase CLI 自動生成（手動編集禁止）
│       │   └── common.ts                 # 共通型（Result型・Page型等）
│       └── constants.ts                  # アプリ全体の定数
│
├── supabase/
│   ├── migrations/
│   │   ├── 001_create_profiles.sql
│   │   ├── 002_create_projects.sql
│   │   ├── 003_create_tasks.sql
│   │   ├── 004_create_goals.sql
│   │   ├── 005_create_habits.sql
│   │   ├── 006_create_time_blocks.sql
│   │   ├── 007_create_reviews.sql
│   │   ├── 008_create_notes.sql
│   │   └── 009_create_rls_policies.sql
│   ├── seed.sql                          # 開発用サンプルデータ
│   └── config.toml
│
├── .env.local.example                    # 環境変数テンプレート（コミット可）
├── .env.local                            # 実際の環境変数（.gitignore必須）
├── .eslintrc.cjs
├── .prettierrc
├── components.json                       # shadcn/ui 設定
├── middleware.ts                         # 認証チェック（全ルート対象）
├── next.config.ts
├── package.json
├── tailwind.config.ts
├── tsconfig.json
└── vitest.config.ts
```

---

## 2. ディレクトリ設計思想

### 2.1 features単位の機能凝集（コロケーション）

**原則: 「この機能を削除したい」ときに、フォルダごと削除できる構造**

```
features/habits/
├── components/   ← Habitsにしか使わないコンポーネント
├── hooks/        ← Habitsにしか使わないhook
├── actions/      ← Habitsの書き込み処理
├── schemas/      ← Habitsのバリデーション
├── types.ts      ← Habitsの型定義
└── index.ts      ← 外部に公開するAPIを明示
```

**配置判断フロー:**

```
新しいコードをどこに置く？
   ↓
1つのfeatureでしか使わない？
   YES → features/{name}/ に置く
   NO
   ↓
2つ以上のfeatureで使う？
   YES → shared/ に昇格させる
   NO  → まだ features/{name}/ に置く（必要になったら移動）
```

### 2.2 app/ ディレクトリはルーティングのみ

`app/dashboard/page.tsx` の中身は最小限にする:

```tsx
// app/(protected)/dashboard/page.tsx
import { DashboardLayout } from '@features/dashboard';

export default async function DashboardPage() {
  return <DashboardLayout />;
}
```

ロジックは全て `features/dashboard/` に置く。

---

## 3. 命名規則

| 対象 | ルール | 例 |
|------|--------|-----|
| コンポーネントファイル | PascalCase | `ProjectCard.tsx` |
| ロジックファイル | camelCase | `createProject.ts` |
| コンポーネント名（関数） | PascalCase | `function ProjectCard()` |
| 関数名 | camelCase | `getProjectById` |
| 定数 | UPPER_SNAKE_CASE | `MAX_ACTIVE_PROJECTS` |
| 型名 | PascalCase | `ProjectWithTasks` |
| Zodスキーマ | camelCase + Schema | `createProjectSchema` |
| Server Action | camelCase + Action | `createProjectAction` |
| テストファイル | *.test.ts | `createProject.test.ts` |
| カスタムhook | use + PascalCase | `useProjects` |
| Supabase migration | NNN_verb_noun.sql | `001_create_profiles.sql` |

---

## 4. インポートルール

### パスエイリアス（tsconfig.json）

```json
{
  "compilerOptions": {
    "paths": {
      "@features/*": ["./src/features/*"],
      "@shared/*":   ["./src/shared/*"],
      "@app/*":      ["./src/app/*"]
    }
  }
}
```

### インポート順序（ESLintで強制）

```typescript
// 1. React / Next.js
import { useState } from 'react';
import { redirect } from 'next/navigation';

// 2. 外部ライブラリ
import { z } from 'zod';

// 3. @shared/* （共通）
import { createServerClient } from '@shared/lib/supabase/server';
import { AppError } from '@shared/lib/errors';

// 4. @features/* （feature間参照）
import { getActiveProjects } from '@features/projects';

// 5. 相対パス（同一feature内）
import { projectSchema } from './schemas/projectSchema';
import type { Project } from './types';
```

### ルール

- **features間の直接importは禁止**（必ず `index.ts` の公開APIを経由）
- `features/auth` が `features/projects` の内部ファイルを直接参照しない
- バレルエクスポート（`index.ts`）は各featureと `shared/components/ui/` のみ許可
- `database.types.ts` は Supabase CLI が自動生成するため手動編集禁止

---

文書バージョン: 1.0
作成日: 2026-04-08
