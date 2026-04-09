# Sprint 2: オンボーディング + ダッシュボード基盤
## ARDORS — 初回セットアップ・ホーム画面・グローバルナビ

---

## 並列実行ガイド

```
SPR2-01（グローバルレイアウト・ナビ）← 先行必須
  ├─→ SPR2-02（オンボーディング）  ┐
  └─→ SPR2-03（ダッシュボード基盤）├─ 並列可
        └─→ SPR2-04（AIフローティング）← SPR2-03 後
```

---

## SPR2-01: グローバルレイアウト・ナビゲーション

```text
[Task]
SPR2-01: (protected) レイアウト・グローバルナビゲーション実装

Goal
- 認証済みユーザー向けの共通レイアウトを実装する。
- PC: サイドバーナビ（240px）/ モバイル: ボトムナビ（5項目）。

Context
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（2. レイアウト構成）
- 参照: docs/01_要件定義/04_画面遷移図_screen-transition.md（グローバルナビ構成）

Scope
- 変更OK:
  - `src/app/(protected)/layout.tsx`（認証済みレイアウト）
  - `src/shared/ui/nav/sidebar-nav.tsx`（PC サイドバー）
  - `src/shared/ui/nav/bottom-nav.tsx`（モバイルボトムナビ）
  - `src/shared/ui/nav/header.tsx`（ヘッダー: ロゴ + 通知 + アバター）
- 変更NG:
  - 各 feature の画面コンポーネント

ナビ構成（5項目）
| 項目 | アイコン（Lucide） | URL |
|------|-----------------|-----|
| ホーム | Home | /dashboard |
| スケジュール | Calendar | /schedule |
| プロジェクト | FolderOpen | /projects |
| ゴール | Target | /goals |
| レビュー | BookOpen | /review |

Implementation Hints
- PC/モバイル切り替えは `lg:hidden` / `hidden lg:flex` で実装。
- アクティブナビアイテムは `usePathname()` で判定。
- レイアウト構造:
  ```tsx
  // src/app/(protected)/layout.tsx
  export default function ProtectedLayout({ children }: { children: React.ReactNode }) {
    return (
      <div className="flex h-screen">
        <SidebarNav className="hidden lg:flex" />
        <div className="flex flex-col flex-1 overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto p-4 lg:p-6">
            {children}
          </main>
        </div>
        <BottomNav className="lg:hidden" />
      </div>
    )
  }
  ```

Acceptance Criteria
- [ ] PC 表示でサイドバーが表示される
- [ ] モバイル表示でボトムナビが表示される
- [ ] 現在の URL に対応するナビアイテムがアクティブ状態になる
- [ ] `npm run type-check` が通る
```

---

## SPR2-02: オンボーディング（SCR-10）

```text
[Task]
SPR2-02: オンボーディング画面 + Server Action の実装（SCR-10）

Goal
- `/onboarding` に 3 ステップのオンボーディングフローを実装する。
- AI が入力を構造化し、初期プロジェクト・目標を作成する。
- 完了後 `profiles.onboarding_completed = true` にする。

Context
- 参照: docs/01_要件定義/wireframes/SCR-10_onboarding.md
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.2 オンボーディング）
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（4.3 SCR-10）
- 対応機能: FR-04

Scope
- 変更OK:
  - `src/app/(protected)/onboarding/page.tsx`
  - `src/features/onboarding/components/OnboardingWizard.tsx`
  - `src/features/onboarding/actions.ts`
  - `src/features/onboarding/schemas.ts`
  - `supabase/migrations/20260409000001_add_projects_goals.sql`
    （この Action で必要な projects / goals / tasks テーブルを先行追加）
- 変更NG:
  - Middleware（すでに onboarding_completed チェック済み）

DB マイグレーション（このタスクで追加）
- `projects` テーブル（docs/02_外部設計/01_DB設計_database-design.md 3.3 参照）
- `goals` テーブル（同 3.4 参照）
- `tasks` テーブル（同 3.5 参照）

UI フロー（3ステップ）
- Step 1: テキストエリア（自由記述）+ 音声入力ボタン（VoiceInputButton）+ 「AIに整理してもらう」ボタン
- Step 2: AI が構造化した結果を表示（プロジェクト一覧・生活リズム）→ 確認・編集 → 「次へ」
- Step 3: 完了画面 → 「ダッシュボードへ」ボタン

completeOnboarding Action
- AI（Haiku）に rawInput を送り構造化（プロジェクト名・カテゴリ・ゴール・生活リズム・初期ゴールを抽出）
- 承認後に projects レコードを作成
- `profiles.onboarding_completed = true` に更新
- 詳細は docs/02_外部設計/02_API仕様_api-specification.md 3.2 を参照

Implementation Hints
- Step 間の状態は `useState` で管理（ページ遷移不要）。
- AI 構造化は `sendMessage` を流用してもよい（context_type='onboarding'）。
- オンボーディングをスキップ可能にする（「スキップ」リンク → completeOnboarding に空データで呼ぶ）。

Acceptance Criteria
- [ ] /onboarding にアクセスするとステップ 1 が表示される
- [ ] テキスト入力後「AIに整理してもらう」でステップ 2 に進む
- [ ] ステップ 2 で AI が構造化した内容が確認できる
- [ ] 完了後 profiles.onboarding_completed = true になる
- [ ] 完了後 /dashboard にリダイレクトされる
- [ ] スキップでも /dashboard に遷移できる
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR2-03: ダッシュボード基盤（SCR-20）

```text
[Task]
SPR2-03: ダッシュボード基盤の実装（SCR-20）

Goal
- `/dashboard` に時間帯適応型ダッシュボードを実装する。
- 初期は静的なレイアウトでよい（AI ブリーフィングは Sprint 5 で統合）。

Context
- 参照: docs/01_要件定義/wireframes/SCR-20_dashboard.md
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（4.4 SCR-20）
- 対応機能: FR-60

Scope
- 変更OK:
  - `src/app/(protected)/dashboard/page.tsx`
  - `src/features/dashboard/components/` 配下
- 変更NG:
  - グローバルナビ（SPR2-01 が担当）

時間帯区分
- 朝モード（5時〜12時）: ブリーフィングプレースホルダー + エネルギーチェックイン + タイムライン + 習慣
- 日中モード（12時〜17時）: 現在ブロックカード + 次ブロックカード + タイムライン
- 夜モード（17時〜）: Done List プレースホルダー + デイリークローズ誘導

各セクションの初期実装
- ブリーフィングカード: 「AIブリーフィングを読み込んでいます...」プレースホルダー
- エネルギーチェックイン: 3項目（気分/体力/集中）各1〜5スケール、1タップ送信
- 今日のタイムライン: time_blocks が 0 件なら「スケジュールを作成してみましょう」
- 習慣チェックリスト: habits が 0 件なら「習慣を追加してみましょう」
- 今週のゴール: goals(level='weekly') 最大3件
- 進行中プロジェクト: projects(status='active') 一覧（ヘルススコアは後で実装）
- 長期ゴール: goals(level='long_term') 一覧

Implementation Hints
- 時間帯は `new Date().getHours()` で判定し、`useMemo` でキャッシュ。
- Server Component でデータを取得し、各セクションに props で渡す。
- エネルギーチェックインは Client Component（1タップで Server Action 呼び出し）。
- 各セクションはまず Skeleton で包んで後から実データに置き換えるパターン:
  ```tsx
  <Suspense fallback={<Skeleton className="h-32" />}>
    <ProjectList />
  </Suspense>
  ```

Acceptance Criteria
- [ ] /dashboard にアクセスするとダッシュボードが表示される
- [ ] 時間帯に応じてファーストビューが変わる
- [ ] エネルギーチェックインが送信できる（energy_checkins に保存）
- [ ] 進行中プロジェクト一覧が表示される（0 件時はガイドテキスト）
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR2-04: AI フローティングパネル

```text
[Task]
SPR2-04: AI フローティングボタン + サイドパネルの実装

Goal
- 全認証済みページに常駐する AI フローティングボタン（`MessageSquare` アイコン）を実装する。
- タップで `/chat` への全画面遷移を行う（サイドパネルは Sprint 4 以降で拡張）。

Context
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（2.3 グローバルナビ構成）
- 対応機能: FR-10（一部）

Scope
- 変更OK:
  - `src/shared/ui/ai-float-button.tsx`（フローティングボタン）
  - `src/app/(protected)/layout.tsx`（ボタンを layout に追加）
- 変更NG:
  - /chat ページ本体（Sprint 4 で実装）

UI 要件
- 固定位置: 画面右下（`fixed bottom-20 right-4 lg:bottom-6 lg:right-6`）
  - モバイル: ボトムナビの上
  - PC: 右下固定
- アイコン: `MessageSquare`（Lucide）
- ボタンサイズ: `size-14`（56px）、`rounded-full`、背景: `bg-brand-500`

Acceptance Criteria
- [ ] 全認証済みページ右下に AI ボタンが表示される
- [ ] ボタンタップで /chat に遷移する
- [ ] ボトムナビと重ならない位置に表示される
```

---

文書バージョン: 1.0
作成日: 2026-04-09
