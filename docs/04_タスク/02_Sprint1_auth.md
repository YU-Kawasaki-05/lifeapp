# Sprint 1: 認証基盤
## ARDORS — LP・ユーザー登録・ログイン・パスワードリセット・Middleware

---

## 並列実行ガイド

```
SPR1-01（プロジェクト初期セットアップ）
  └─→ SPR1-02（DB マイグレーション）
        └─→ SPR1-03（Supabase クライアント・Middleware）
              ├─→ SPR1-04（LP）              ┐
              ├─→ SPR1-05（認証画面群）       ├─ 並列可
              └─→ SPR1-06（認証 Server Actions）┘
```

- **SPR1-01 〜 SPR1-03 は直列**（後続タスクの前提となるため）。
- **SPR1-04 / SPR1-05 / SPR1-06 は並列可**（別ファイルを触る）。

---

## SPR1-01: プロジェクト初期セットアップ

```text
[Task]
SPR1-01: Next.js + Supabase の開発環境初期セットアップ

Goal
- Next.js 15 App Router プロジェクトの初期設定を完了させ、
  Tailwind CSS / shadcn/ui / ESLint / Vitest / Playwright が使えるようにする。
- ディレクトリ構成を docs/03_技術設計/02_ディレクトリ構成_directory-structure.md に合わせる。

Context
- 参照: docs/03_技術設計/02_ディレクトリ構成_directory-structure.md
- 参照: docs/03_技術設計/05_開発ガイドライン_development-guidelines.md
- 参照: docs/03_技術設計/03_外部サービス_external-services.md（環境変数一覧）
- 現在の状態: プロジェクトルートが空（または Next.js ボイラープレートのみ）

Scope
- 変更OK:
  - `package.json`（依存関係追加）
  - `tailwind.config.ts` / `src/app/globals.css`（Tailwind + shadcn テーマ設定）
  - `tsconfig.json`（パスエイリアス: `@/*` → `src/*`）
  - `.env.local.example`（必要な環境変数のサンプルファイル作成）
  - `src/shared/` 配下の基本ディレクトリ作成
  - `vitest.config.ts` / `playwright.config.ts`
  - `eslint.config.js`（Next.js 推奨 + strict モード）
- 変更NG:
  - Supabase プロジェクトの設定（人間作業ゲート A で実施）

Packages to install
- `@supabase/ssr` `@supabase/supabase-js`
- `tailwindcss` `@tailwindcss/forms`
- shadcn/ui: `npx shadcn@latest init`（必要コンポーネント: button, card, input, textarea, select, dialog, sheet, tabs, badge, progress, skeleton, toast, avatar, separator, alert-dialog）
- `lucide-react`
- `zustand` `@tanstack/react-query`
- `react-hook-form` `@hookform/resolvers` `zod`
- `@anthropic-ai/sdk`
- `vitest` `@testing-library/react` `@testing-library/user-event`
- `@playwright/test`

Implementation Hints
- `src/shared/types/result.ts` に `Result<T>` 型を定義する:
  ```typescript
  export type Result<T> =
    | { success: true; data: T }
    | { success: false; error: string }
  ```
- `tsconfig.json` の paths に `"@/*": ["./src/*"]` を追加。
- `.env.local.example` に以下を記載（値はダミー）:
  NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
  NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
  SUPABASE_SERVICE_ROLE_KEY=eyJ...
  ANTHROPIC_API_KEY=sk-ant-...
  AI_MODEL_DEFAULT=claude-haiku-4-5-20251001
  AI_MODEL_COACHING=claude-sonnet-4-6
  GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
  GOOGLE_CLIENT_SECRET=GOCSPX-...
  NEXT_PUBLIC_APP_URL=http://localhost:3000

Acceptance Criteria
- [ ] `npm run dev` でエラーなく起動する
- [ ] `npm run lint` が通る
- [ ] `npm run type-check` が通る
- [ ] `npm run test` が通る（テストファイルが 0 件でも OK）
- [ ] shadcn/ui の Button コンポーネントが import できる
- [ ] `@/shared/types/result` が import できる
- [ ] `.env.local.example` が存在する
```

---

## SPR1-02: DB マイグレーション（初期スキーマ）

```text
[Task]
SPR1-02: Supabase 初期 DB マイグレーション（Sprint 1 で必要なテーブル）

Goal
- Sprint 1 で必要な `profiles` / `user_settings` テーブルを作成する。
- RLS ポリシー・トリガーを設定する。

Context
- 参照: docs/02_外部設計/01_DB設計_database-design.md（3.1 profiles / 3.2 user_settings）
- 参照: docs/02_外部設計/03_権限設計_authorization.md（6.2 profiles RLS / 6.3 user_settings RLS）
- Supabase プロジェクトは人間が事前に作成済みの前提

Scope
- 変更OK:
  - `supabase/migrations/20260409000000_initial_auth_schema.sql`（新規作成）
- 変更NG:
  - アプリケーションコード

Migration SQL 内容（以下を実装すること）
1. profiles テーブル（docs/02_外部設計/01_DB設計_database-design.md 3.1 を参照）
2. user_settings テーブル（同 3.2 を参照）
3. handle_new_user() トリガー（同 4.1 を参照）
4. update_updated_at() トリガー関数 + profiles / user_settings への適用（同 4.2 を参照）
5. profiles の RLS ポリシー（docs/02_外部設計/03_権限設計_authorization.md 6.2 を参照）
6. user_settings の RLS ポリシー（同 6.3 を参照）

Implementation Hints
- ファイル先頭にロールバック手順をコメントで記載:
  -- Rollback: DROP TABLE IF EXISTS user_settings; DROP TABLE IF EXISTS profiles CASCADE;
- `auth.users` への参照は `REFERENCES auth.users(id)` で行う（Supabase 標準）。

Acceptance Criteria
- [ ] `supabase db push` がエラーなく完了する
- [ ] Supabase Dashboard で profiles / user_settings テーブルが確認できる
- [ ] auth.users に新規ユーザーを作成すると profiles / user_settings が自動作成される（トリガー確認）
- [ ] RLS が有効になっている（Dashboard で確認）
```

---

## SPR1-03: Supabase クライアント・Middleware

```text
[Task]
SPR1-03: Supabase SSR クライアント設定と Next.js Middleware（認証ガード）

Goal
- `@supabase/ssr` を使ったサーバーサイド Supabase クライアントを実装する。
- Next.js Middleware で認証チェック・リダイレクトを実装する。
- 認証済みユーザー取得ユーティリティを実装する。

Context
- 参照: docs/02_外部設計/03_権限設計_authorization.md（4. Next.js Middleware 実装 / 5. 認証ユーティリティ）
- 参照: docs/03_技術設計/04_認証フロー_auth-flow.md

Scope
- 変更OK:
  - `src/shared/lib/supabase/server.ts`（createServerClient）
  - `src/shared/lib/supabase/client.ts`（createBrowserClient）
  - `src/shared/lib/auth/get-user.ts`（getAuthenticatedUser / getAdminUser）
  - `src/middleware.ts`（認証ガード・リダイレクト）
- 変更NG:
  - 各 feature のコード

Key Files to Create

1. `src/shared/lib/supabase/server.ts`:
   - `createServerClient()` 関数（docs/02_外部設計/02_API仕様_api-specification.md 4. の実装を参照）
   - cookies() から読み書きする SSR クライアント

2. `src/shared/lib/supabase/client.ts`:
   - `createBrowserClient()` 関数（Client Components 用）

3. `src/shared/lib/auth/get-user.ts`:
   - `UnauthorizedError` クラス
   - `getAuthenticatedUser()` 関数
   - `getAdminUser()` 関数
   （docs/02_外部設計/03_権限設計_authorization.md 5.1 の実装を参照）

4. `src/middleware.ts`:
   - 公開パス: `/`, `/login`, `/signup`, `/reset-password`
   - 管理者パス: `/admin`
   - ゲスト専用（ログイン済みは /dashboard へ）: `/login`, `/signup`
   - オンボーディング強制: onboarding_completed=false → /onboarding
   （docs/02_外部設計/03_権限設計_authorization.md 4. の実装を参照）

Acceptance Criteria
- [ ] `createServerClient()` が Server Actions から import できる
- [ ] `getAuthenticatedUser()` が未認証時に UnauthorizedError をスローする
- [ ] Middleware が `/dashboard` へのアクセスを未認証時に `/login` にリダイレクトする
- [ ] Middleware がログイン済みユーザーの `/login` アクセスを `/dashboard` にリダイレクトする
- [ ] `npm run type-check` が通る
```

---

## SPR1-04: LP（SCR-01）

```text
[Task]
SPR1-04: LP（ランディングページ）の実装（SCR-01）

Goal
- `/` に ARDORS のランディングページを実装する。
- 認証不要。登録・ログインへの導線を提供する。

Context
- 参照: docs/01_要件定義/wireframes/SCR-01_LP.md（レイアウト詳細）
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（4.1 SCR-01）
- 対応機能: FR-05

Scope
- 変更OK:
  - `src/app/(public)/page.tsx`（LP ページ）
  - `src/app/(public)/layout.tsx`（公開系レイアウト: 最小ヘッダー）
- 変更NG:
  - 認証系コード / Middleware

UI 要件
- ヘッダー: ロゴ（ARDORS） + ログインボタン + 登録ボタン
- ヒーローセクション: キャッチコピー「AIとともに、毎日を前へ進める」+ サブコピー + 登録CTA
- 特徴紹介（3項目）:
  1. AIパートナー（音声・テキストで対話）
  2. タイムボクシング（AIが週間スケジュールを生成）
  3. 振り返り（デイリー・ウィークリー・月次レビュー）
- フッター: コピーライト表示

Implementation Hints
- shadcn/ui の `<Button>` を使用（CTAは `variant="default"`、ログインは `variant="outline"`）。
- 画像は使わず、Lucide アイコン + テキストのみでシンプルに実装。
- `<Link href="/signup">` と `<Link href="/login">` で遷移。

Acceptance Criteria
- [ ] `/` にアクセスすると LP が表示される
- [ ] 登録ボタンで `/signup` に遷移する
- [ ] ログインボタンで `/login` に遷移する
- [ ] PC / モバイル両方でレイアウトが崩れない
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR1-05: 認証画面群（SCR-02〜05）

```text
[Task]
SPR1-05: 認証画面の実装（ユーザー登録・ログイン・パスワードリセット）

Goal
- SCR-02（/signup）・SCR-03（/login）・SCR-04（/reset-password）・SCR-05（/reset-password/:token）を実装する。
- フロントエンドの UI とバリデーション（React Hook Form + Zod）を実装する。
- Server Actions（SPR1-06 で実装）を呼び出す UI 部分を実装する。

Context
- 参照: docs/01_要件定義/wireframes/SCR-02-05_auth.md
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（4.2 SCR-02〜05）
- 対応機能: FR-01〜03

Scope
- 変更OK:
  - `src/app/(public)/signup/page.tsx`
  - `src/app/(public)/login/page.tsx`
  - `src/app/(public)/reset-password/page.tsx`
  - `src/app/(public)/reset-password/[token]/page.tsx`
  - `src/features/auth/components/` 配下（SignUpForm, SignInForm, ResetPasswordForm 等）
- 変更NG:
  - Server Actions（SPR1-06 が担当）
  - Middleware

UI 要件（共通）
- 画面中央にカード（shadcn `<Card>`）
- Google OAuth ボタン（[Googleでログイン]）+ セパレーター + メール/パスワードフォーム
- フォームバリデーション:
  - email: z.string().email()
  - password: z.string().min(8, 'パスワードは8文字以上にしてください')
  - displayName（登録のみ）: z.string().min(1).max(50)
- エラー表示: フィールド下にインラインエラー（`text-destructive text-xs`）
- 送信中: ボタン disabled + Loader2 アイコン spin
- ページ間リンク:
  - /signup: 「すでにアカウントをお持ちの方 → /login」
  - /login: 「新規登録はこちら → /signup」「パスワードを忘れた → /reset-password」

Implementation Hints
- Action が未実装の場合は仮の `console.log` で代替し、後で SPR1-06 と統合。
- `useTransition` + Server Action の呼び出しパターン:
  ```typescript
  const [isPending, startTransition] = useTransition()
  const onSubmit = (data: FormData) => {
    startTransition(async () => {
      const result = await signIn(data)
      if (!result.success) toast({ title: result.error, variant: 'destructive' })
    })
  }
  ```
- Google OAuth は Supabase の `signInWithOAuth` を使用（リダイレクト方式）。

Acceptance Criteria
- [ ] /signup でフォームが表示され、バリデーションが動作する
- [ ] /login でフォームが表示される
- [ ] /reset-password でメールアドレス入力フォームが表示される
- [ ] PC / モバイル両方でレイアウトが崩れない
- [ ] フィールド未入力時にエラーメッセージが表示される
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR1-06: 認証 Server Actions

```text
[Task]
SPR1-06: 認証 Server Actions の実装（signUp / signIn / signOut / パスワードリセット）

Goal
- `src/features/auth/actions.ts` に認証関連の全 Server Actions を実装する。
- Supabase Auth を使ったメール+パスワード認証・Google OAuth・パスワードリセットを実装する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.1 認証）
- 参照: docs/03_技術設計/04_認証フロー_auth-flow.md
- 対応機能: FR-01〜03

Scope
- 変更OK:
  - `src/features/auth/actions.ts`（新規作成）
  - `src/features/auth/schemas.ts`（Zod スキーマ）
  - `src/features/auth/index.ts`（公開 API）
- 変更NG:
  - UI コンポーネント（SPR1-05 が担当）
  - Middleware

Actions to implement

1. `signUp(input)` → `Result<{ userId: string }>`
   - Supabase `auth.signUp()` でアカウント作成
   - エラー: email already in use → 'このメールアドレスは既に登録されています'
   - 成功: 確認メール送信（Supabase が自動）

2. `signIn(input)` → `Result<{ redirectUrl: string }>`
   - Supabase `auth.signInWithPassword()` でログイン
   - 成功: redirectUrl = '/dashboard'（onboarding_completed=false なら '/onboarding'）
   - エラー: 'メールアドレスまたはパスワードが正しくありません'

3. `signOut()` → `Result<void>`
   - Supabase `auth.signOut()` でセッション削除

4. `sendPasswordResetEmail(input)` → `Result<void>`
   - Supabase `auth.resetPasswordForEmail()` を呼ぶ
   - 常に success: true（メール存在有無を漏らさない）

5. `updatePassword(input)` → `Result<void>`
   - Supabase `auth.updateUser({ password })` でパスワード更新

Implementation Hints
- 全 Actions は `'use server'` ディレクティブを持つ。
- 共通パターン:
  ```typescript
  'use server'
  import { createServerClient } from '@/shared/lib/supabase/server'
  import type { Result } from '@/shared/types/result'

  export async function signOut(): Promise<Result<void>> {
    try {
      const supabase = createServerClient()
      const { error } = await supabase.auth.signOut()
      if (error) throw error
      return { success: true, data: undefined }
    } catch {
      return { success: false, error: 'ログアウトに失敗しました' }
    }
  }
  ```
- signIn の redirectUrl 判定:
  ```typescript
  const { data: profile } = await supabase
    .from('profiles')
    .select('onboarding_completed')
    .eq('id', user.id)
    .single()
  const redirectUrl = profile?.onboarding_completed ? '/dashboard' : '/onboarding'
  ```

Acceptance Criteria
- [ ] signUp で Supabase にユーザーが作成される（確認メール送信）
- [ ] signIn で正しい認証情報でログインできる
- [ ] signIn で誤った認証情報でエラーメッセージが返る
- [ ] signOut でセッションが破棄される
- [ ] sendPasswordResetEmail でリセットメールが送信される
- [ ] updatePassword でパスワードが更新される
- [ ] `npm run lint` / `npm run type-check` / `npm run test` が通る

---
[共通制約・品質バー を 01_共通ブロック_common-blocks.md の「共通ブロック A」からコピーして追記すること]
```

---

文書バージョン: 1.0
作成日: 2026-04-09
