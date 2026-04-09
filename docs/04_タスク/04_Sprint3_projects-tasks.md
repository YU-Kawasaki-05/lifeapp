# Sprint 3: PJ・タスク管理
## ARDORS — プロジェクト CRUD・タスク CRUD・Active/Warm/Cold 状態管理

---

## 並列実行ガイド

```
SPR3-01（プロジェクト Actions）┐
SPR3-04（PJ状態管理 UI）      ├─ 並列可（別ファイル）
  └─→ SPR3-02（PJ一覧・詳細画面）← SPR3-01 後（型に依存）
        └─→ SPR3-03（タスク Actions + 詳細画面）← SPR3-01〜02 後
```

---

## SPR3-01: プロジェクト Server Actions

```text
[Task]
SPR3-01: プロジェクト Server Actions の実装

Goal
- `src/features/projects/actions.ts` にプロジェクト CRUD の全 Server Actions を実装する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.3 プロジェクト）
- 参照: docs/02_外部設計/01_DB設計_database-design.md（3.3 projects テーブル）
- 対応機能: FR-20, FR-22

Scope
- 変更OK:
  - `src/features/projects/actions.ts`（新規作成）
  - `src/features/projects/schemas.ts`（Zod スキーマ）
  - `src/features/projects/types.ts`（Project 型定義）
  - `src/features/projects/index.ts`（公開 API）
  - `src/shared/lib/auth/verify-ownership.ts`（verifyProjectOwnership 追加）
- 変更NG:
  - UI コンポーネント（SPR3-02 が担当）

Actions to implement（docs/02_外部設計/02_API仕様_api-specification.md 3.3 参照）
1. createProject(input) → Result<{ projectId: string }>
2. updateProject(input) → Result<void>  ← 所有者確認必須
3. updateProjectStatus(input) → Result<void>  ← status: active/warm/cold/completed
4. deleteProject(input) → Result<void>  ← 論理削除（deleted_at = now()）
5. getProjects(input) → Result<Project[]>
6. getProjectById(input) → Result<ProjectWithDetails>

Implementation Hints
- 全 Actions: `getAuthenticatedUser()` → Zod バリデーション → DB 操作 の順。
- updateProject / deleteProject: `verifyProjectOwnership(user.id, projectId)` で所有者確認後に操作。
- getProjectById: projects + tasks（最新5件）+ goals + time_blocks（直近3件）を JOIN して返す。
- 論理削除時: 配下の tasks も同時に `deleted_at = now()` を設定。

Acceptance Criteria
- [ ] createProject で projects テーブルにレコードが作成される
- [ ] updateProject で自分のプロジェクトのみ更新できる（他人のは 'データが見つかりません'）
- [ ] deleteProject で deleted_at が設定される（物理削除しない）
- [ ] getProjects が deleted_at IS NULL のものだけ返す
- [ ] `npm run lint` / `npm run type-check` / `npm run test` が通る
```

---

## SPR3-02: プロジェクト一覧・詳細画面（SCR-30〜31）

```text
[Task]
SPR3-02: プロジェクト一覧・詳細画面の実装（SCR-30, SCR-31）

Goal
- `/projects` にプロジェクト一覧（Active/Warm/Cold タブ）を実装する。
- `/projects/:id` にプロジェクト詳細（タスク一覧・目標・進捗）を実装する。
- プロジェクトの作成・ステータス変更が UI からできる。

Context
- 参照: docs/01_要件定義/wireframes/SCR-30-32_projects.md
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（4.6 SCR-30〜32）
- 対応機能: FR-20, FR-22

Scope
- 変更OK:
  - `src/app/(protected)/projects/page.tsx`
  - `src/app/(protected)/projects/[id]/page.tsx`
  - `src/features/projects/components/` 配下
    - ProjectCard.tsx（一覧カード）
    - ProjectList.tsx（状態別グループ）
    - ProjectStatusBadge.tsx（Active/Warm/Cold バッジ）
    - ProjectForm.tsx（作成・編集フォーム、Dialog 内）
    - ProjectDetail.tsx（詳細ページ）
- 変更NG:
  - Server Actions（SPR3-01 が担当）

SCR-30 一覧 UI
- 上部: 「+ 新規作成」ボタン（Dialog で ProjectForm を開く）
- タブ: [Active] [Warm] [Cold]
- プロジェクトカード（ProjectCard）:
  - 名前・カテゴリ・ステータスバッジ
  - プログレスバー（タスク完了率: done/total）
  - 期限表示
  - ステータス変更ドロップダウン（Active/Warm/Cold/完了）
- ヘルススコア: 後の Sprint で実装（現在はプレースホルダー）

SCR-31 詳細 UI
- タブ: [タスク] [目標] [進捗]
- タスクタブ: 未完了タスク一覧 + 「+ タスク追加」ボタン + 完了タスク（折りたたみ）
- 目標タブ: goals 一覧（レベル別）
- 進捗タブ: time_blocks の集計（後 Sprint で完成）

Acceptance Criteria
- [ ] /projects に Active プロジェクト一覧が表示される
- [ ] 「+ 新規作成」でフォームが開き、プロジェクトを作成できる
- [ ] プロジェクト名クリックで /projects/:id に遷移する
- [ ] ステータス変更（Active/Warm/Cold）が UI から行える
- [ ] PC / モバイル両方でレイアウトが崩れない
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR3-03: タスク Server Actions + タスク詳細画面（SCR-32）

```text
[Task]
SPR3-03: タスク Server Actions + タスク詳細画面の実装

Goal
- `src/features/tasks/actions.ts` にタスク CRUD の Server Actions を実装する。
- `/projects/:id/tasks/:taskId` にタスク詳細画面を実装する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.4 タスク）
- 参照: docs/02_外部設計/01_DB設計_database-design.md（3.5 tasks テーブル）
- 参照: docs/01_要件定義/wireframes/SCR-30-32_projects.md（SCR-32）
- 対応機能: FR-23

Scope
- 変更OK:
  - `src/features/tasks/actions.ts`
  - `src/features/tasks/schemas.ts`
  - `src/features/tasks/types.ts`
  - `src/features/tasks/index.ts`
  - `src/app/(protected)/projects/[id]/tasks/[taskId]/page.tsx`
  - `src/features/tasks/components/TaskForm.tsx`
  - `src/features/tasks/components/TaskDetail.tsx`
- 変更NG:
  - projects の Server Actions

Actions to implement
1. createTask(input) → Result<{ taskId: string }>
2. updateTask(input) → Result<void>
3. completeTask(input) → Result<void>  ← status='done', completed_at=now()
4. deleteTask(input) → Result<void>  ← 論理削除
5. getTasksByProject(input) → Result<Task[]>

タスク詳細画面（SCR-32）
- タスク名・説明・優先度・見積もり時間・期限・紐付くPJ・紐付く目標
- 「完了にする」ボタン（completeTask Action）
- 「編集」「削除」ボタン

Acceptance Criteria
- [ ] プロジェクト詳細の「+ タスク追加」からタスクを作成できる
- [ ] タスクを完了にするとステータスが done になる
- [ ] 論理削除後はタスク一覧に表示されない
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR3-04: PJ 状態管理 UI（Active/Warm/Cold）詳細化

```text
[Task]
SPR3-04: PJ 状態管理（Active/Warm/Cold）の UX 強化

Goal
- プロジェクトの状態変更（Active/Warm/Cold）を直感的に操作できる UI にする。
- 状態ごとの意味をユーザーに伝えるツールチップ・説明を追加する。

Context
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（FR-22: PJ状態管理）
- Active: 今週前進させる / Warm: 止めないが本格着手しない / Cold: 明確に保留

Scope
- 変更OK:
  - `src/features/projects/components/ProjectStatusSelector.tsx`（新規）
  - SCR-30 の ProjectCard（ステータス変更 UI）

UI 要件
- ドロップダウン（shadcn Select）で Active/Warm/Cold/完了 を選択
- 各選択肢にツールチップで説明を表示:
  - Active: 「今週前進させる」
  - Warm: 「止めないが本格着手しない」
  - Cold: 「明確に保留」
  - 完了: 「完了済み」
- 変更後に Toast で「ステータスを更新しました」を表示

Acceptance Criteria
- [ ] ProjectCard でステータスをドロップダウンから変更できる
- [ ] 変更後に Toast が表示される
- [ ] 変更後に一覧の表示グループが更新される（楽観的更新 or リフレッシュ）
```

---

文書バージョン: 1.0
作成日: 2026-04-09
