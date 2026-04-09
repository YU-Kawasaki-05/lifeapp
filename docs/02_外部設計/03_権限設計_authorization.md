# 権限設計
## プロジェクト名: ARDORS（アーダース）

---

## 1. 権限モデル概要

ARDORS の権限制御は3層で構成される。

| 層 | 場所 | 役割 |
|----|------|------|
| **ルート保護** | `src/middleware.ts` | 未認証ユーザーを /login へリダイレクト |
| **権限チェック** | Server Actions | 認証済み確認 + リソース所有者確認 |
| **データ分離** | Supabase RLS | DBレベルでユーザーデータを物理分離 |

---

## 2. ロール定義

| ロールID | 名称 | 説明 | 付与条件 |
|---------|------|------|---------|
| anonymous | 未認証 | ログインしていない状態 | デフォルト |
| user | 一般ユーザー | 自分のデータのみ操作可能 | ユーザー登録後 |
| admin | 管理者 | profiles.role = 'admin' のユーザー | 手動でDB設定 |

ロールは `profiles.role` カラム（`TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin'))`）で管理する。

---

## 3. 画面アクセス制御

| 画面ID | URL | anonymous | user | admin | 認証なし時のリダイレクト先 |
|--------|-----|-----------|------|-------|--------------------------|
| SCR-01 | `/` | ✅ | ✅ | ✅ | — |
| SCR-02 | `/signup` | ✅ | → /dashboard | → /dashboard | — |
| SCR-03 | `/login` | ✅ | → /dashboard | → /dashboard | — |
| SCR-04 | `/reset-password` | ✅ | → /dashboard | → /dashboard | — |
| SCR-05 | `/reset-password/:token` | ✅ | ✅ | ✅ | — |
| SCR-10 | `/onboarding` | → /login | ✅（未完了時のみ） | ✅ | /login |
| SCR-20 | `/dashboard` | → /login | ✅ | ✅ | /login |
| SCR-21 | `/chat` | → /login | ✅ | ✅ | /login |
| SCR-30 | `/projects` | → /login | ✅ | ✅ | /login |
| SCR-31 | `/projects/:id` | → /login | ✅（所有者のみ） | ✅ | /login |
| SCR-32 | `/projects/:id/tasks/:taskId` | → /login | ✅（所有者のみ） | ✅ | /login |
| SCR-40 | `/schedule` | → /login | ✅ | ✅ | /login |
| SCR-50 | `/habits` | → /login | ✅ | ✅ | /login |
| SCR-60 | `/review` | → /login | ✅ | ✅ | /login |
| SCR-70 | `/goals` | → /login | ✅ | ✅ | /login |
| SCR-80 | `/notes` | → /login | ✅ | ✅ | /login |
| SCR-90 | `/settings` | → /login | ✅ | ✅ | /login |
| SCR-A1 | `/admin` | → /login | → /dashboard | ✅ | /login |
| SCR-A2 | `/admin/users` | → /login | → /dashboard | ✅ | /login |

---

## 4. Next.js Middleware 実装

```typescript
// src/middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

const PUBLIC_PATHS = ['/', '/login', '/signup', '/reset-password']
const ADMIN_PATHS = ['/admin']

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: { headers: request.headers },
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          response = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // セッションのリフレッシュ（必須）
  const { data: { user } } = await supabase.auth.getUser()
  const pathname = request.nextUrl.pathname

  // 1. ゲスト専用ページ（ログイン済みはダッシュボードへ）
  const isGuestOnlyPath = ['/login', '/signup'].some(p => pathname.startsWith(p))
  if (isGuestOnlyPath && user) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  // 2. 認証必須ページ（未ログインはログインへ）
  const isPublicPath = PUBLIC_PATHS.some(p =>
    pathname === p || pathname.startsWith('/reset-password')
  )
  if (!isPublicPath && !user) {
    const loginUrl = new URL('/login', request.url)
    loginUrl.searchParams.set('redirectTo', pathname)
    return NextResponse.redirect(loginUrl)
  }

  // 3. 管理者専用ページ
  if (ADMIN_PATHS.some(p => pathname.startsWith(p)) && user) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (!profile || profile.role !== 'admin') {
      return NextResponse.redirect(new URL('/dashboard', request.url))
    }
  }

  // 4. オンボーディング未完了チェック
  if (user && !pathname.startsWith('/onboarding') && !isPublicPath) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('onboarding_completed')
      .eq('id', user.id)
      .single()

    if (profile && !profile.onboarding_completed) {
      return NextResponse.redirect(new URL('/onboarding', request.url))
    }
  }

  return response
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

---

## 5. 認証ユーティリティ

### 5.1 認証済みユーザー取得

```typescript
// src/shared/lib/auth/get-user.ts
import { createServerClient } from '@/shared/lib/supabase/server'

export class UnauthorizedError extends Error {
  constructor() {
    super('Unauthorized')
    this.name = 'UnauthorizedError'
  }
}

/**
 * Server Actions 内で認証済みユーザーを取得する。
 * 未認証の場合は UnauthorizedError をスロー。
 */
export async function getAuthenticatedUser() {
  const supabase = createServerClient()
  const { data: { user }, error } = await supabase.auth.getUser()

  if (error || !user) {
    throw new UnauthorizedError()
  }

  return user
}

/**
 * 管理者ユーザーを取得する。
 * 未認証または管理者でない場合は UnauthorizedError をスロー。
 */
export async function getAdminUser() {
  const user = await getAuthenticatedUser()
  const supabase = createServerClient()

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (!profile || profile.role !== 'admin') {
    throw new UnauthorizedError()
  }

  return user
}
```

### 5.2 Server Actions での使用パターン

```typescript
// src/features/projects/actions.ts
'use server'

import { getAuthenticatedUser, UnauthorizedError } from '@/shared/lib/auth/get-user'
import type { Result } from '@/shared/types/result'

export async function createProject(input: CreateProjectInput): Promise<Result<{ projectId: string }>> {
  try {
    const user = await getAuthenticatedUser()  // ← 必ず最初に呼ぶ
    // ... DBへの書き込み（user.id を使用）
  } catch (e) {
    if (e instanceof UnauthorizedError) {
      return { success: false, error: 'ログインが必要です' }
    }
    return { success: false, error: 'プロジェクトの作成に失敗しました' }
  }
}
```

---

## 6. Supabase RLS ポリシー（全テーブル）

### 6.1 管理者判定ヘルパー関数

```sql
-- 全 RLS ポリシーで使用する管理者判定関数
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

### 6.2 profiles

```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 自分のプロフィールを参照
CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- 管理者は全ユーザーのプロフィールを参照可能
CREATE POLICY "profiles_select_admin" ON profiles
  FOR SELECT USING (is_admin());

-- 自分のプロフィールのみ更新可能
CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- INSERT はトリガーのみ（RLS 対象外）
```

### 6.3 user_settings

```sql
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_settings_all_own" ON user_settings
  FOR ALL USING (auth.uid() = user_id);
```

### 6.4 projects

```sql
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "projects_all_own" ON projects
  FOR ALL USING (auth.uid() = user_id);
```

### 6.5 goals

```sql
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "goals_all_own" ON goals
  FOR ALL USING (auth.uid() = user_id);
```

### 6.6 tasks

```sql
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tasks_all_own" ON tasks
  FOR ALL USING (auth.uid() = user_id);
```

### 6.7 habits

```sql
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "habits_all_own" ON habits
  FOR ALL USING (auth.uid() = user_id);
```

### 6.8 habit_logs

```sql
ALTER TABLE habit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "habit_logs_all_own" ON habit_logs
  FOR ALL USING (auth.uid() = user_id);
```

### 6.9 time_blocks

```sql
ALTER TABLE time_blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "time_blocks_all_own" ON time_blocks
  FOR ALL USING (auth.uid() = user_id);
```

### 6.10 ai_conversations

```sql
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_conversations_all_own" ON ai_conversations
  FOR ALL USING (auth.uid() = user_id);
```

### 6.11 daily_reviews

```sql
ALTER TABLE daily_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "daily_reviews_all_own" ON daily_reviews
  FOR ALL USING (auth.uid() = user_id);
```

### 6.12 weekly_reviews

```sql
ALTER TABLE weekly_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "weekly_reviews_all_own" ON weekly_reviews
  FOR ALL USING (auth.uid() = user_id);
```

### 6.13 monthly_reviews

```sql
ALTER TABLE monthly_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "monthly_reviews_all_own" ON monthly_reviews
  FOR ALL USING (auth.uid() = user_id);
```

### 6.14 notes

```sql
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notes_all_own" ON notes
  FOR ALL USING (auth.uid() = user_id);
```

### 6.15 gcal_tokens

```sql
ALTER TABLE gcal_tokens ENABLE ROW LEVEL SECURITY;

-- Server Actions 経由のみアクセス（クライアントから直接参照不可）
CREATE POLICY "gcal_tokens_all_own" ON gcal_tokens
  FOR ALL USING (auth.uid() = user_id);
```

### 6.16 energy_checkins

```sql
ALTER TABLE energy_checkins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "energy_checkins_all_own" ON energy_checkins
  FOR ALL USING (auth.uid() = user_id);
```

### 6.17 notifications

```sql
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_all_own" ON notifications
  FOR ALL USING (auth.uid() = user_id);
```

---

## 7. リソース所有者検証

Server Actions でリソースを更新・削除する前に、所有者確認を行う。RLS でも防げるが、より明示的なエラーメッセージを返すために二重チェックする。

```typescript
// src/shared/lib/auth/verify-ownership.ts
import { createServerClient } from '@/shared/lib/supabase/server'

/**
 * 指定リソースがログインユーザーのものかを確認する。
 * @returns true: 所有者一致 / false: 所有者不一致またはリソース不存在
 */
export async function verifyProjectOwnership(
  userId: string,
  projectId: string
): Promise<boolean> {
  const supabase = createServerClient()
  const { data } = await supabase
    .from('projects')
    .select('id')
    .eq('id', projectId)
    .eq('user_id', userId)
    .is('deleted_at', null)
    .single()
  return !!data
}

export async function verifyTaskOwnership(
  userId: string,
  taskId: string
): Promise<boolean> {
  const supabase = createServerClient()
  const { data } = await supabase
    .from('tasks')
    .select('id')
    .eq('id', taskId)
    .eq('user_id', userId)
    .is('deleted_at', null)
    .single()
  return !!data
}

// 習慣・目標・タイムブロック等も同様パターンで実装
```

### 使用例

```typescript
export async function updateProject(input: UpdateProjectInput): Promise<Result<void>> {
  try {
    const user = await getAuthenticatedUser()

    const isOwner = await verifyProjectOwnership(user.id, input.projectId)
    if (!isOwner) {
      return { success: false, error: 'プロジェクトが見つかりません' }
    }

    const supabase = createServerClient()
    const { error } = await supabase
      .from('projects')
      .update({ name: input.name, updated_at: new Date().toISOString() })
      .eq('id', input.projectId)
      .eq('user_id', user.id)  // RLS + 明示的フィルタ

    if (error) throw error
    return { success: true, data: undefined }
  } catch (e) {
    if (e instanceof UnauthorizedError) {
      return { success: false, error: 'ログインが必要です' }
    }
    return { success: false, error: 'プロジェクトの更新に失敗しました' }
  }
}
```

---

## 8. AIエンドポイントのレート制限

AI API（Anthropic）の呼び出しは Server Actions 内でのみ実施。クライアントには API キーを露出しない。

```typescript
// src/shared/lib/ai/rate-limit.ts
import { createServerClient } from '@/shared/lib/supabase/server'

const AI_RATE_LIMIT = 100        // リクエスト数
const AI_RATE_WINDOW = 60 * 60  // ウィンドウ: 1時間（秒）

/**
 * 直近1時間のAI使用回数をチェックし、超過の場合 false を返す。
 */
export async function checkAIRateLimit(userId: string): Promise<boolean> {
  const supabase = createServerClient()
  const windowStart = new Date(Date.now() - AI_RATE_WINDOW * 1000).toISOString()

  const { count } = await supabase
    .from('ai_conversations')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('role', 'user')
    .gte('created_at', windowStart)

  return (count ?? 0) < AI_RATE_LIMIT
}
```

---

## 9. セキュリティ注意事項

| 項目 | 対策 |
|------|------|
| APIキー漏洩 | `ANTHROPIC_API_KEY`, `GOOGLE_CLIENT_SECRET` 等は Server Actions のみで使用。`NEXT_PUBLIC_` 接頭辞を付けない |
| SQLインジェクション | Supabase クライアントのパラメータバインディングを使用。生SQL は `supabase.rpc()` + prepared statement のみ |
| CSRF | Server Actions は Next.js が CSRF トークンを自動管理 |
| セッション固定攻撃 | Supabase Auth がセッション管理。ログイン後にセッションIDが再生成される |
| 権限昇格 | `profiles.role` の更新は Server Actions で `getAdminUser()` を通過した場合のみ許可 |
| トークン保護 | `gcal_tokens` の access_token は本番環境で Supabase Vault に保存 |
| XSS | Next.js のデフォルトエスケープ + DOMPurify でユーザー入力をサニタイズ |
| ログ | `ai_conversations` の `content` にはユーザーの個人情報が含まれうるため、サードパーティログサービスには送らない |

---

文書バージョン: 1.0
作成日: 2026-04-09
最終更新日: 2026-04-09
