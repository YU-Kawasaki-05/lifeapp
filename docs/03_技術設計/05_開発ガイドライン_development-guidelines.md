# 開発ガイドライン
## プロジェクト名: ARDORS（アーダース）

---

## 1. TypeScript 方針

### 1.1 基本ルール

```typescript
// ✅ 良い: 明示的な型定義
type CreateProjectInput = {
  name: string;
  category: ProjectCategory[];
  deadline?: Date;
};

// ❌ 悪い: any を使わない
function processData(data: any) { ... }

// ✅ 良い: unknown + type guard
function processData(data: unknown) {
  if (isProject(data)) { ... }
}
```

### 1.2 Supabase の型安全

```bash
# Supabase CLIで型を自動生成（DB変更後に必ず実行）
npx supabase gen types typescript --project-id <project-id> \
  > src/shared/types/database.types.ts
```

```typescript
// database.types.ts は手動編集禁止（上書きされる）
// 使い方:
import type { Database } from '@shared/types/database.types';
type Project = Database['public']['Tables']['projects']['Row'];
type InsertProject = Database['public']['Tables']['projects']['Insert'];
```

### 1.3 Result型パターン（エラーハンドリング）

```typescript
// shared/lib/errors.ts
export type Result<T, E = string> =
  | { success: true; data: T }
  | { success: false; error: E };

// Server Actionの戻り値はResult型を使う
export async function createProjectAction(
  input: CreateProjectInput
): Promise<Result<Project>> {
  const parsed = createProjectSchema.safeParse(input);
  if (!parsed.success) {
    return { success: false, error: parsed.error.message };
  }
  // ...
}

// 呼び出し側
const result = await createProjectAction(input);
if (!result.success) {
  toast.error(result.error);
  return;
}
// result.data は Project 型で使える
```

---

## 2. Server Components / Server Actions の使い分け

### 2.1 Server Components（データ取得）

```typescript
// features/projects/components/ProjectList.tsx
// "use client" を書かない → Server Component

import { createServerClient } from '@shared/lib/supabase/server';

export async function ProjectList() {
  const supabase = await createServerClient();
  const { data: projects } = await supabase
    .from('projects')
    .select('*')
    .order('created_at', { ascending: false });

  return (
    <ul>
      {projects?.map(p => <ProjectCard key={p.id} project={p} />)}
    </ul>
  );
}
```

### 2.2 Server Actions（書き込み）

```typescript
// features/projects/actions/createProject.ts
'use server';

import { createServerClient } from '@shared/lib/supabase/server';
import { createProjectSchema } from '../schemas/projectSchema';
import type { Result } from '@shared/lib/errors';

export async function createProjectAction(
  formData: FormData
): Promise<Result<{ id: string }>> {
  const supabase = await createServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { success: false, error: '認証が必要です' };

  const parsed = createProjectSchema.safeParse({
    name: formData.get('name'),
    category: formData.getAll('category'),
    deadline: formData.get('deadline'),
  });
  if (!parsed.success) {
    return { success: false, error: '入力内容を確認してください' };
  }

  const { data, error } = await supabase
    .from('projects')
    .insert({ ...parsed.data, user_id: user.id })
    .select('id')
    .single();

  if (error) return { success: false, error: 'プロジェクトの作成に失敗しました' };
  return { success: true, data: { id: data.id } };
}
```

### 2.3 クライアントが必要なものだけ `'use client'`

```typescript
// "use client" が必要なケース:
// - useState / useEffect 等の React hooks を使う
// - ブラウザAPIを使う（Web Speech API等）
// - イベントハンドラを持つインタラクティブなUI
// - TanStack QueryのuseQuery等

// "use client" が不要なケース（Server Componentで書く）:
// - データを取得して表示するだけ
// - レイアウト
// - 静的なコンテンツ
```

---

## 3. AIプロンプト設計

### 3.1 システムプロンプトの管理

```typescript
// features/ai-chat/lib/prompts/brainDump.ts
export function getBrainDumpPrompt(context: {
  projects: Project[];
  recentTasks: Task[];
}): string {
  return `
あなたはARDORS（個人生産性管理アプリ）のAIアシスタントです。
ユーザーのブレインダンプ（自由な思考の書き出し）を受け取り、
以下のカテゴリに構造化してください。

【ユーザーの現在のプロジェクト】
${context.projects.map(p => `- ${p.name}（${p.status}）`).join('\n')}

【構造化のルール】
1. タスク的な内容: 既存PJへの振り分け + タスク抽出（タイトル・期限・優先度）
2. ビジョン的な内容: 展望の整理 + 既存目標との接続 + 新規PJ候補
3. 混在: 上記を同時処理

【出力フォーマット（JSON）】
{
  "tasks": [{ "title": "...", "project_id": "...", "deadline": "...", "priority": "high|medium|low" }],
  "new_projects": [{ "name": "...", "goal": "...", "initial_tasks": ["..."] }],
  "visions": [{ "content": "...", "related_goal_id": "..." }]
}

【重要ルール】
- ユーザーが承認するまでデータを変更しない（提案のみ）
- 建設的AIの原則: 目的達成に向けた客観的視点を提供する
- 単なる褒め言葉や同意だけで終わらない
`.trim();
}
```

### 3.2 モデル選択のロジック

```typescript
// features/ai-chat/lib/modelSelector.ts
import { AI_MODELS } from '@shared/lib/ai/models';

export type AIContextType =
  | 'general'        // 通常会話: Haiku
  | 'brain_dump'     // ブレインダンプ構造化: Haiku
  | 'timeboxing'     // スケジュール生成: Haiku
  | 'morning'        // モーニングブリーフィング: Haiku
  | 'weekly_review'  // 週次レビュー・コーチモード: Sonnet
  | 'monthly_review' // 月次レビュー: Sonnet

export function selectModel(contextType: AIContextType): string {
  const coachingContexts: AIContextType[] = ['weekly_review', 'monthly_review'];
  return coachingContexts.includes(contextType)
    ? AI_MODELS.coaching
    : AI_MODELS.default;
}
```

---

## 4. コンポーネント設計

### 4.1 コンポーネントの責務分割

```
Server Component（データ取得）
  └─ Client Component（インタラクション）
       └─ shadcn/ui プリミティブ（Button, Input等）
```

```typescript
// ✅ Server Component がデータ取得し、Client Componentに渡す
// features/habits/components/HabitList.tsx (Server Component)
export async function HabitList() {
  const habits = await fetchHabits(); // DB直接アクセス
  return <HabitChecklist habits={habits} />; // Client Componentに渡す
}

// features/habits/components/HabitChecklist.tsx (Client Component)
'use client';
export function HabitChecklist({ habits }: { habits: Habit[] }) {
  // useState でチェック状態を管理
  // Server Actionを呼び出す
}
```

### 4.2 フォームパターン

```typescript
'use client';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { createProjectSchema, type CreateProjectInput } from '../schemas/projectSchema';
import { createProjectAction } from '../actions/createProject';

export function ProjectForm() {
  const form = useForm<CreateProjectInput>({
    resolver: zodResolver(createProjectSchema),
  });

  async function onSubmit(data: CreateProjectInput) {
    const result = await createProjectAction(data);
    if (!result.success) {
      toast.error(result.error);
      return;
    }
    toast.success('プロジェクトを作成しました');
    router.push(`/projects/${result.data.id}`);
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* ... */}
    </form>
  );
}
```

---

## 5. テスト方針

### 5.1 テストの優先順位

| 優先度 | 対象 | ツール |
|--------|------|--------|
| 高 | Server Actions（ビジネスロジック） | Vitest |
| 高 | Zodスキーマ（バリデーション） | Vitest |
| 中 | カスタムhooks | Vitest + Testing Library |
| 中 | 主要E2Eフロー（登録〜ダッシュボード） | Playwright |
| 低 | UIコンポーネント（shadcn/ui使用なら最小限） | Testing Library |

### 5.2 Server Actionのテスト例

```typescript
// features/projects/actions/createProject.test.ts
import { describe, it, expect, vi } from 'vitest';
import { createProjectAction } from './createProject';

// Supabaseをモック
vi.mock('@shared/lib/supabase/server', () => ({
  createServerClient: vi.fn(() => ({
    auth: { getUser: vi.fn().mockResolvedValue({ data: { user: { id: 'user-1' } } }) },
    from: vi.fn(() => ({
      insert: vi.fn(() => ({
        select: vi.fn(() => ({
          single: vi.fn().mockResolvedValue({ data: { id: 'proj-1' }, error: null }),
        })),
      })),
    })),
  })),
}));

describe('createProjectAction', () => {
  it('正常系: 有効な入力でPJが作成される', async () => {
    const result = await createProjectAction({ name: '就活', category: ['就活'] });
    expect(result.success).toBe(true);
    if (result.success) expect(result.data.id).toBe('proj-1');
  });

  it('異常系: PJ名が空だとエラーになる', async () => {
    const result = await createProjectAction({ name: '', category: [] });
    expect(result.success).toBe(false);
  });
});
```

### 5.3 テスト実行

```bash
npx vitest              # ウォッチモード
npx vitest run          # CI用（1回実行）
npx playwright test     # E2Eテスト
```

---

## 6. コーディング規約

### 6.1 ESLint / Prettier 設定

```bash
# インストール
npm install -D eslint @typescript-eslint/eslint-plugin prettier eslint-config-prettier
```

```json
// .eslintrc.cjs
module.exports = {
  extends: [
    'next/core-web-vitals',
    'plugin:@typescript-eslint/recommended',
    'prettier'
  ],
  rules: {
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/no-explicit-any': 'error',
    'no-console': ['warn', { allow: ['warn', 'error'] }],
  }
};
```

```json
// .prettierrc
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
```

### 6.2 Git コミット規約

```
feat: AIモーニングブリーフィング機能を追加
fix: タスク完了時のプログレスバー計算ミスを修正
refactor: ProjectFormをReact Hook Formに移行
test: createProjectActionのテストを追加
docs: アーキテクチャ設計書を更新
chore: Supabase型定義を更新
```

### 6.3 コードレビュー（自己レビュー）チェックリスト

- [ ] `any` 型を使っていないか
- [ ] Server Actionに `'use server'` を付けているか
- [ ] ユーザー入力をZodでバリデーションしているか
- [ ] APIキーをクライアントコードで使っていないか（`NEXT_PUBLIC_` のみクライアント可）
- [ ] エラーハンドリングをしているか（Result型 or try-catch）
- [ ] RLSが設定されたテーブルに対して適切にクエリしているか

---

## 7. 開発環境セットアップ

```bash
# 1. リポジトリをクローン
git clone https://github.com/[username]/ardors.git
cd ardors

# 2. 依存関係インストール
npm install

# 3. 環境変数設定
cp .env.local.example .env.local
# .env.local を編集して各APIキーを設定

# 4. Supabase ローカル環境起動
npx supabase start
npx supabase db reset  # マイグレーション + シード適用

# 5. 型定義を生成
npx supabase gen types typescript --local > src/shared/types/database.types.ts

# 6. 開発サーバー起動
npm run dev
```

---

文書バージョン: 1.0
作成日: 2026-04-08
