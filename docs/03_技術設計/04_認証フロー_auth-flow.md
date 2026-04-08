# 認証フロー設計書
## プロジェクト名: ARDORS（アーダース）

---

## 1. 認証方式まとめ

| 方式 | 画面 | 実装 |
|------|------|------|
| Google OAuth | SCR-02/03 | Supabase Auth + Google Provider |
| メールアドレス + パスワード | SCR-02/03 | Supabase Auth（signUp / signInWithPassword） |
| パスワードリセット | SCR-04/05 | Supabase Auth（resetPasswordForEmail） |
| セッション管理 | 全画面 | Supabase SSR（`@supabase/ssr`）+ Cookie |
| 認可（権限分離） | 全DBアクセス | Supabase RLS（Row Level Security） |

---

## 2. Google OAuth フロー

```mermaid
sequenceDiagram
  actor U as ユーザー
  participant B as ブラウザ
  participant NX as Next.js (Vercel)
  participant SB as Supabase Auth
  participant GG as Google OAuth

  U->>B: 「Googleで登録/ログイン」クリック
  B->>SB: signInWithOAuth({ provider: 'google' })
  SB-->>B: Googleの認証URLにリダイレクト
  B->>GG: Google認証画面を表示
  U->>GG: Googleアカウントを選択・許可
  GG-->>SB: 認証コード + ユーザー情報をコールバックURLへ
  Note over SB: /auth/v1/callback で処理
  SB-->>NX: コード付きでリダイレクト
  Note over NX: /api/auth/callback/route.ts
  NX->>SB: exchangeCodeForSession(code)
  SB-->>NX: セッション（access_token + refresh_token）
  NX->>B: Cookie にセッションをセット
  NX-->>B: /onboarding（初回）or /dashboard にリダイレクト
  B-->>U: ダッシュボードが表示される
```

**実装ポイント:**

```typescript
// app/api/auth/callback/route.ts
import { createServerClient } from '@shared/lib/supabase/server';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get('code');
  const next = searchParams.get('next') ?? '/dashboard';

  if (code) {
    const supabase = await createServerClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      // 初回ログインかどうかでオンボーディングへ分岐
      return NextResponse.redirect(new URL(next, request.url));
    }
  }
  return NextResponse.redirect(new URL('/login?error=oauth_failed', request.url));
}
```

---

## 3. メールアドレス + パスワード登録フロー

```mermaid
sequenceDiagram
  actor U as ユーザー
  participant B as ブラウザ（SignUpForm）
  participant SA as Server Action (signUp.ts)
  participant SB as Supabase Auth
  participant Mail as メールサーバー

  U->>B: メール・パスワードを入力して「登録」
  B->>SA: signUpAction({ email, password })
  SA->>SA: Zodスキーマでバリデーション
  SA->>SB: supabase.auth.signUp({ email, password })
  SB->>Mail: 確認メールを送信
  SB-->>SA: { user, session: null }（メール未確認）
  SA-->>B: { success: true, message: '確認メールを送信しました' }
  B-->>U: 「確認メールを送信しました」メッセージ表示

  U->>Mail: 確認メールを開く
  U->>B: メール内の確認リンクをクリック
  B->>SB: メール確認処理（Supabase管理）
  SB-->>B: セッション発行
  B-->>U: /onboarding にリダイレクト
```

---

## 4. メールアドレス + パスワード ログインフロー

```mermaid
sequenceDiagram
  actor U as ユーザー
  participant B as ブラウザ（LoginForm）
  participant SA as Server Action (signIn.ts)
  participant SB as Supabase Auth

  U->>B: メール・パスワードを入力して「ログイン」
  B->>SA: signInAction({ email, password })
  SA->>SB: supabase.auth.signInWithPassword({ email, password })
  alt 認証成功
    SB-->>SA: { user, session }
    SA->>B: Cookieにセッションをセット
    SA-->>B: redirect('/dashboard')
    B-->>U: ダッシュボードを表示
  else 認証失敗
    SB-->>SA: error
    SA-->>B: { error: 'メールアドレスまたはパスワードが正しくありません' }
    B-->>U: エラーメッセージ表示
  end
```

---

## 5. パスワードリセットフロー

```mermaid
sequenceDiagram
  actor U as ユーザー
  participant B as ブラウザ
  participant SA as Server Action (resetPassword.ts)
  participant SB as Supabase Auth
  participant Mail as メールサーバー

  Note over U,B: SCR-04: パスワードリセット要求
  U->>B: メールアドレスを入力して「送信」
  B->>SA: requestPasswordResetAction({ email })
  SA->>SB: supabase.auth.resetPasswordForEmail(email, { redirectTo })
  Note over SB: 登録済みでも未登録でも同じ処理（セキュリティ上）
  SB->>Mail: リセットメールを送信（登録済みの場合のみ）
  SB-->>SA: 成功（常に成功を返す）
  SA-->>B: { success: true }
  B-->>U: 「パスワードリセットリンクを送信しました」

  Note over U,B: SCR-05: 新パスワード設定
  U->>Mail: リセットメールを開く
  U->>B: メール内のリンクをクリック（有効期限24時間）
  B->>SB: トークン検証（Supabase管理）
  SB-->>B: セッション発行（パスワード変更用）
  U->>B: 新パスワードを入力して「変更する」
  B->>SA: updatePasswordAction({ newPassword })
  SA->>SB: supabase.auth.updateUser({ password: newPassword })
  SB-->>SA: 成功
  SA->>SB: 既存の全セッションを無効化
  SA-->>B: redirect('/login?message=password_updated')
  B-->>U: 「パスワードを変更しました」
```

---

## 6. セッション管理

### 6.1 Cookie-based セッション（@supabase/ssr）

```typescript
// shared/lib/supabase/server.ts
import { createServerClient as createSupabaseServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { Database } from '@shared/types/database.types';

export async function createServerClient() {
  const cookieStore = await cookies();
  return createSupabaseServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return cookieStore.getAll(); },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          );
        },
      },
    }
  );
}
```

```typescript
// shared/lib/supabase/client.ts （ブラウザ用）
import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '@shared/types/database.types';

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

### 6.2 Middleware（認証チェック）

```typescript
// middleware.ts（プロジェクトルート）
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return request.cookies.getAll(); },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            supabaseResponse.cookies.set(name, value, options);
          });
        },
      },
    }
  );

  // セッション取得（自動でリフレッシュされる）
  const { data: { user } } = await supabase.auth.getUser();

  // 未認証ユーザーをprotectedルートからリダイレクト
  if (!user && request.nextUrl.pathname.startsWith('/(protected)')) {
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    return NextResponse.redirect(url);
  }

  // 管理者チェック
  if (request.nextUrl.pathname.startsWith('/admin')) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user?.id)
      .single();
    if (profile?.role !== 'admin') {
      return NextResponse.redirect(new URL('/dashboard', request.url));
    }
  }

  return supabaseResponse;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
```

---

## 7. Supabase RLS ポリシー（主要テーブル）

RLS（Row Level Security）により、**DBレベルでユーザー間のデータ分離を強制**する。

```sql
-- 全テーブル共通パターン: 自分のデータのみ操作可能

-- profiles テーブル
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- projects テーブル
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own projects"
  ON projects FOR ALL USING (auth.uid() = user_id);

-- tasks テーブル
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own tasks"
  ON tasks FOR ALL USING (auth.uid() = user_id);

-- (他テーブルも同様のパターンで定義)
```

---

## 8. セキュリティチェックリスト

| 項目 | 対策 |
|------|------|
| SQLインジェクション | Supabaseの型付きクライアント + Zodバリデーション |
| XSS | Next.jsのJSXが自動エスケープ |
| CSRF | Server Actionsはnonce付きで自動保護 |
| APIキー漏洩 | `ANTHROPIC_API_KEY`等は`NEXT_PUBLIC_`プレフィックスなし。サーバーのみ |
| 他ユーザーのデータ参照 | Supabase RLSで二重防衛 |
| パスワード保存 | Supabase Authがbcryptでハッシュ化（実装不要） |
| セッション固定攻撃 | ログイン成功時にセッション再生成（Supabase Auth管理） |

---

文書バージョン: 1.0
作成日: 2026-04-08
