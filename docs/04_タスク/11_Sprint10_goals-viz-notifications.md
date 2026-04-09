# Sprint 10: ゴール可視化 + 通知 + 仕上げ
## ARDORS — FR-60〜62, FR-70〜71, FR-06, FR-07, FR-80

---

## 並列実行ガイド

```
全タスクは互いに独立しているため、すべて並列実行可。
ただし SPR10-06（E2E・仕上げ）は全タスク完了後に実施。

SPR10-01（ゴール・分析画面）   ┐
SPR10-02（通知 Actions + UI）  ├─ すべて並列可
SPR10-03（ユーザー設定画面）    │
SPR10-04（ナレッジ一覧）       │
SPR10-05（管理者画面）         ┘
  └─→ SPR10-06（E2E テスト + 全体仕上げ）← 最後に実施
```

---

## SPR10-01: ゴール・分析画面（SCR-70）

```text
[Task]
SPR10-01: ゴール・分析画面の実装（SCR-70）

Goal
- `/goals` にゴールジャーニーマップ（FR-61）と時間分析（FR-62）をタブで実装する。

Context
- 参照: docs/01_要件定義/wireframes/SCR-70_goals-analytics.md
- 参照: docs/02_外部設計/04_画面設計_screen-design.md（4.10 SCR-70）
- 対応機能: FR-61, FR-62

Scope
- 変更OK:
  - `src/app/(protected)/goals/page.tsx`
  - `src/features/goals/components/GoalJourneyMap.tsx`（ツリービジュアライゼーション）
  - `src/features/goals/components/GoalProgressNode.tsx`（各ノード）
  - `src/features/goals/components/TimeAnalysis.tsx`（時間配分グラフ）
- 変更NG:
  - goals Server Actions（Sprint 4 で実装済み）

ゴールジャーニーマップ（FR-61）
- タブ [ゴールマップ] [時間分析]
- GoalJourneyMap: ツリー構造の再帰コンポーネント
  - 長期ゴール → 中期目標 → 週次ゴール → タスク（最大3件）
  - 各ノード: タイトル + プログレスバー（`<Progress value={progressPct} />`）
  - ノードタップで詳細展開（配下タスク一覧）
- AI コンテキスト（FR-61 BR-61-04）:
  「この作業は X というゴールの達成に繋がっています」（generateMorningBriefing の流用）

時間分析（FR-62）
- TimeAnalysis コンポーネント:
  - Recharts の `<PieChart>` または `<BarChart>` を使用
  - PJ 別時間配分（time_blocks の集計）
  - 理想 vs 実際のギャップ表示
  - 日/週/月 切り替え

Acceptance Criteria
- [ ] /goals にゴールマップが表示される
- [ ] ゴール階層がツリー形式で表示される
- [ ] 各ノードにプログレスバーが表示される
- [ ] 時間分析タブでグラフが表示される
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR10-02: 通知 Server Actions + 通知 UI

```text
[Task]
SPR10-02: 通知 Server Actions + 通知ベル UI の実装（FR-70, FR-71）

Goal
- notifications テーブルに通知レコードを作成するロジックを実装する。
- ヘッダーの通知ベルに未読通知を表示する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.11 通知）
- 参照: docs/02_外部設計/01_DB設計_database-design.md（3.16 notifications）
- 対応機能: FR-70, FR-71

Scope
- 変更OK:
  - `supabase/migrations/20260409000008_add_notifications_energy.sql`
    （notifications + energy_checkins テーブル追加）
  - `src/features/notifications/actions.ts`（新規作成）
  - `src/features/notifications/types.ts`
  - `src/features/notifications/index.ts`
  - `src/shared/ui/nav/header.tsx`（通知ベルアイコン追加）
  - `src/features/notifications/components/NotificationDropdown.tsx`
- 変更NG:
  - 通知スケジューリング（本フェーズでは手動 or ダッシュボードロード時にトリガー）

DB マイグレーション
- `notifications` テーブル（docs/02_外部設計/01_DB設計_database-design.md 3.16 参照）
- `energy_checkins` テーブル（同 3.15 参照）

Actions to implement
1. getNotifications({ unreadOnly }) → Result<Notification[]>
2. markNotificationRead({ notificationId }) → Result<void>
3. markAllNotificationsRead() → Result<void>
4. createNotification（内部用）→ 通知レコードを作成するユーティリティ

通知生成トリガー（ダッシュボードロード時）
- デイリークローズ通知: 設定時刻を過ぎていて daily_reviews に今日のレコードがない場合
- ウィークリーレビュー通知: 設定曜日・時刻を過ぎていて weekly_reviews に今週のレコードがない場合

通知ベル UI（ヘッダー）
- `<Bell>` アイコン + 未読数バッジ（赤丸）
- クリックで NotificationDropdown 表示
- 各通知: タイトル + 相対時刻 + クリックで遷移（daily_close → /review）
- 「すべて既読にする」ボタン

Acceptance Criteria
- [ ] ヘッダーに通知ベルが表示される
- [ ] 未読通知がある場合にバッジが表示される
- [ ] 通知をクリックすると read_at が設定される
- [ ] 「すべて既読」で全通知が既読になる
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR10-03: ユーザー設定画面（SCR-90）完成

```text
[Task]
SPR10-03: ユーザー設定画面（SCR-90）の完成実装

Goal
- `/settings` に全設定項目を実装する（プロフィール / AIの設定 / 通知 / 生活リズム / 理想の時間配分）。

Context
- 参照: docs/01_要件定義/wireframes/SCR-90_settings.md
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.12 ユーザー設定）
- 対応機能: FR-06

Scope
- 変更OK:
  - `src/app/(protected)/settings/page.tsx`
  - `src/features/settings/actions.ts`（updateUserSettings / updateProfile / updateLifeRhythm）
  - `src/features/settings/components/` 配下（各設定セクションコンポーネント）
- 変更NG:
  - GCal セクション（Sprint 7 で実装済み）

設定セクション
1. プロフィール: 表示名・アバター URL・タイムゾーン
2. AIの設定: 厳しさレベル（コーチ/メンター/フレンド）+ 説明
3. 通知設定:
   - モーニングブリーフィング時刻
   - デイリークローズ時刻
   - ウィークリーレビュー曜日・時刻
   - 通知 ON/OFF
4. 生活リズム: 起床・就寝・勤務開始・勤務終了・昼休み
5. 理想の時間配分:
   - Active プロジェクト一覧 + 各スライダー（0〜100%）
   - 合計が 100% に近いことをガイド表示（超過は警告）

Actions to implement（docs/02_外部設計/02_API仕様_api-specification.md 3.12 参照）
- updateProfile(input) → Result<void>
- updateUserSettings(input) → Result<void>
- updateLifeRhythm(input) → Result<void>

Acceptance Criteria
- [ ] /settings に全セクションが表示される
- [ ] プロフィール更新が保存される
- [ ] AIの厳しさレベルを変更できる
- [ ] 通知時刻・曜日を設定できる
- [ ] 生活リズムを設定できる
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR10-04: ナレッジ一覧（SCR-80）+ notes Actions

```text
[Task]
SPR10-04: ナレッジ一覧（SCR-80）+ notes Server Actions の実装

Goal
- `/notes` にナレッジ・気づき一覧を実装する。
- テキスト検索・タグフィルタができる。

Context
- 参照: docs/01_要件定義/wireframes/SCR-80_notes.md
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.14 ノート）
- 対応機能: FR-80

Scope
- 変更OK:
  - `src/features/notes/actions.ts`（createNote / updateNote / deleteNote / getNotes）
  - `src/features/notes/schemas.ts`
  - `src/features/notes/types.ts`
  - `src/features/notes/index.ts`
  - `src/app/(protected)/notes/page.tsx`
  - `src/features/notes/components/NoteCard.tsx`
  - `src/features/notes/components/NoteForm.tsx`
  - `src/features/notes/components/NoteFilter.tsx`（検索・タグフィルタ）

Notes Actions（docs/02_外部設計/02_API仕様_api-specification.md 3.14 参照）
- createNote / updateNote / deleteNote（論理削除） / getNotes（ページネーション対応）
- getNotes の検索: `to_tsvector('japanese', title || content)` で全文検索
  （Supabase の `textSearch` メソッドを使用）

UI 要件（docs/02_外部設計/04_画面設計_screen-design.md 4.11 参照）
- 「+ メモを追加」ボタン（Dialog で NoteForm を開く）
- 検索入力（debounce 300ms）
- タグフィルタ（複数選択可）
- NoteCard: タイトル・本文プレビュー（100文字）・タグ・日付

Acceptance Criteria
- [ ] /notes にノート一覧が表示される
- [ ] テキスト検索が動作する
- [ ] タグフィルタが動作する
- [ ] ノートの作成・編集・削除ができる
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR10-05: 管理者画面（SCR-A1〜A2）

```text
[Task]
SPR10-05: 管理者画面の実装（SCR-A1 ダッシュボード + SCR-A2 ユーザー管理）

Goal
- `/admin` に管理者ダッシュボードを実装する。
- `/admin/users` にユーザー一覧・アカウント操作を実装する。

Context
- 参照: docs/01_要件定義/wireframes/SCR-A_admin.md
- 参照: docs/02_外部設計/03_権限設計_authorization.md（7. 管理者権限チェックパターン）
- 対応機能: FR-07

Scope
- 変更OK:
  - `src/app/(protected)/admin/page.tsx`
  - `src/app/(protected)/admin/users/page.tsx`
  - `src/features/admin/actions.ts`（getAdminUserList / suspendUser）
  - `src/features/admin/components/AdminDashboard.tsx`
  - `src/features/admin/components/UserManagementTable.tsx`
- 変更NG:
  - 一般ユーザー向け画面・Middleware（管理者チェックは既存）

管理者チェック
- 全 admin Actions で `getAdminUser()` を呼ぶ（UnauthorizedError で role !== 'admin'）
- Middleware で /admin パスを管理者のみに制限（Sprint 1 実装済み）

SCR-A1 ダッシュボード
- 統計カード: 総ユーザー数 / MAU（直近30日にログインしたユーザー）/ DAU
- データ: profiles テーブルから集計（created_at / updated_at で近似）

SCR-A2 ユーザー管理
- ユーザー一覧テーブル（ページネーション）
- 検索（メールアドレス・表示名）
- 各ユーザー行: ID・メール・登録日・ロール・アカウント状態
- 操作: [停止]（Supabase Admin API で ban）/ [復元]

getAdminUserList Action
- SUPABASE_SERVICE_ROLE_KEY を使った Admin クライアントで auth.users を参照
- `createClient(url, service_role_key, { auth: { autoRefreshToken: false } })` を使う

Acceptance Criteria
- [ ] /admin は管理者のみアクセス可（一般ユーザーは /dashboard にリダイレクト）
- [ ] /admin でユーザー統計が表示される
- [ ] /admin/users でユーザー一覧が表示される
- [ ] ユーザーを停止・復元できる
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR10-06: E2E テスト + 全体仕上げ

```text
[Task]
SPR10-06: Playwright E2E テスト + 全体仕上げ（コード品質・パフォーマンス）

Goal
- 主要フローの E2E テストを Playwright で作成する。
- 全体のコード品質を確認し、仕上げる。

Context
- 参照: docs/01_要件定義/05_受入基準_acceptance-criteria.md（各 FR の受入基準）
- 参照: docs/02_外部設計/05_非機能要件_non-functional-requirements.md（7.2 テスト戦略）

Scope
- 変更OK:
  - `tests/e2e/` 配下のすべての E2E テストファイル
  - パフォーマンス改善（必要な場合）
  - 軽微なバグ修正
- 変更NG:
  - 主要機能の大規模変更

E2E テストシナリオ（最低限）
1. 認証フロー: 登録 → メール確認 → ログイン → ダッシュボード
2. プロジェクト CRUD: PJ 作成 → タスク追加 → タスク完了 → PJ ステータス変更
3. 習慣チェック: ダッシュボードから習慣を 1 タップチェック
4. AI チャット: メッセージ送信 → 返答受信
5. ウィークリーレビュー: レビュー入力 → AI フィードバック表示

仕上げ項目
- `npm run lint` / `npm run type-check` / `npm run test` が全て通ることを確認
- Lighthouse スコア: Performance 70 以上 / Accessibility 90 以上
- 未実装のプレースホルダー UI を確認・対処

Acceptance Criteria
- [ ] 上記 E2E テストシナリオが全て通る
- [ ] `npm run lint` / `npm run type-check` / `npm run test` が全て通る
- [ ] Vercel Preview Deploy でエラーなくビルドが完了する
- [ ] Lighthouse Performance ≥ 70
```

---

文書バージョン: 1.0
作成日: 2026-04-09
