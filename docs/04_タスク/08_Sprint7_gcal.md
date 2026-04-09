# Sprint 7: Google Calendar 連携
## ARDORS — FR-32（pull）, FR-33（push）

---

## 並列実行ガイド

```
[人間作業ゲート D: Google Cloud Console 設定 + ENV 設定が必須]

SPR7-01（GCal OAuth + gcal_tokens）← 先行必須
  ├─→ SPR7-02（GCal pull Action）  ┐
  ├─→ SPR7-03（GCal push Action）  ├─ 並列可（別ファイル）
  └─→ SPR7-04（GCal 設定 UI）      ┘
```

**注意**: Google Cloud Console での OAuth クライアント設定（人間作業）が前提。
GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET が未設定なら SPR7-01 を実行しても動作しない。

---

## SPR7-01: Google Calendar OAuth + gcal_tokens テーブル

```text
[Task]
SPR7-01: Google Calendar OAuth 連携 + gcal_tokens 管理の実装

Goal
- Google Calendar API の OAuth 2.0 認証フローを実装する。
- アクセストークン・リフレッシュトークンを gcal_tokens テーブルに保存する。
- トークンが期限切れの場合に自動リフレッシュする。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.8 Google Calendar）
- 参照: docs/02_外部設計/01_DB設計_database-design.md（3.14 gcal_tokens テーブル）
- 参照: docs/03_技術設計/03_外部サービス_external-services.md（Google Calendar API）
- 対応機能: FR-32, FR-33

Scope
- 変更OK:
  - `supabase/migrations/20260409000005_add_gcal_tokens.sql`
  - `src/features/schedule/gcal-actions.ts`（新規: connectGoogleCalendar / disconnectGoogleCalendar）
  - `src/app/api/auth/google-calendar/callback/route.ts`（OAuth コールバック処理）
  - `src/shared/lib/gcal/client.ts`（Google Calendar API クライアント）
  - `src/shared/lib/gcal/token-manager.ts`（トークン取得・リフレッシュ）
- 変更NG:
  - Supabase Auth の設定

DB マイグレーション
- `gcal_tokens` テーブル（docs/02_外部設計/01_DB設計_database-design.md 3.14 参照）

OAuth フロー
1. ユーザーが設定画面で「Google Calendarと連携」をクリック
2. `src/app/api/auth/google-calendar/route.ts` で Google の認証 URL を生成
   - scope: `https://www.googleapis.com/auth/calendar`
   - redirect_uri: `${NEXT_PUBLIC_APP_URL}/api/auth/google-calendar/callback`
3. Google 認証後に callback に code が返る
4. connectGoogleCalendar(code) Action でトークンを取得・保存

connectGoogleCalendar Action
- code を token エンドポイントに POST して access_token / refresh_token を取得
- gcal_tokens に UPSERT（既存なら更新）

token-manager.ts
- `getValidToken(userId)`: gcal_tokens から取得、期限切れなら refresh_token でリフレッシュ
- リフレッシュ後は gcal_tokens を更新

Implementation Hints
- google-auth-library または fetch で直接 Google token endpoint を呼ぶ。
- ENV: GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET（サーバーサイドのみ）。
- ENV が未設定の場合: 「Google Calendarと連携されていません。設定から連携してください」を返す。

Acceptance Criteria
- [ ] 連携ボタンで Google の認証画面にリダイレクトされる
- [ ] 認証完了後 gcal_tokens にトークンが保存される
- [ ] disconnectGoogleCalendar で gcal_tokens が削除される
- [ ] トークン期限切れ時にリフレッシュが自動で行われる
- [ ] GOOGLE_CLIENT_ID 未設定時は適切なエラーを返す（推測して追記しない）
```

---

## SPR7-02: GCal pull Action

```text
[Task]
SPR7-02: Google Calendar pull Server Action の実装（pullGoogleCalendarEvents）

Goal
- Google Calendar から今日〜28日先の予定を取得し、time_blocks（source='gcal'）に保存する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.8 pullGoogleCalendarEvents）
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（FR-32: GCal pull）
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（BR-32-01〜04）
- 対応機能: FR-32

Scope
- 変更OK:
  - `src/features/schedule/gcal-actions.ts`（pullGoogleCalendarEvents を追加）
- 変更NG:
  - UI（SPR7-04 が担当）

pullGoogleCalendarEvents Action
- getValidToken(user.id) でトークン取得
- Google Calendar API `events.list` を呼ぶ:
  - timeMin: 今日の 00:00:00
  - timeMax: 28日後の 23:59:59
  - singleEvents: true
  - orderBy: startTime
- 取得した各イベントを time_blocks にUPSERT:
  - source = 'gcal'
  - block_type = 'gcal_event'
  - gcal_event_id = event.id
  - title = event.summary
  - start_at / end_at
  - location = event.location（あれば）
- 既存の gcal_event_id が一致するレコードは UPDATE、新規は INSERT
- ARDORS 由来のブロック（source='ardors'）は変更しない（BR-32-03）

Acceptance Criteria
- [ ] pullGoogleCalendarEvents で Google Calendar の予定が time_blocks に保存される
- [ ] 既存の gcal イベントが重複作成されない（UPSERT）
- [ ] ARDORS ブロックは変更されない
- [ ] GCal 通信失敗時に 'Google Calendarとの通信に失敗しました' を返す
- [ ] `npm run lint` / `npm run type-check` が通る
```

---

## SPR7-03: GCal push Action

```text
[Task]
SPR7-03: Google Calendar push Server Action の実装（pushToGoogleCalendar）

Goal
- ARDORS の承認済みタイムブロックを Google Calendar に一括登録する。

Context
- 参照: docs/02_外部設計/02_API仕様_api-specification.md（3.8 pushToGoogleCalendar）
- 参照: docs/01_要件定義/03_機能一覧_feature-list.md（FR-33: GCal push / BR-33-01〜04）
- 対応機能: FR-33

Scope
- 変更OK:
  - `src/features/schedule/gcal-actions.ts`（pushToGoogleCalendar を追加）
- 変更NG:
  - pullGoogleCalendarEvents（別 Action）

pushToGoogleCalendar Action
- blockIds が指定されない場合: 今週の is_approved=true かつ source='ardors' のブロックを全て取得
- 各ブロックについて:
  - gcal_pushed_at が NULL → Google Calendar API `events.insert` で新規作成
  - gcal_pushed_at が非NULL → gcal_event_id で `events.update` で更新（BR-33-03）
- push 先カレンダー: user_settings.gcal_push_calendar_id（未設定なら primary）（BR-33-04）
- push 後: time_blocks の gcal_event_id / gcal_pushed_at を更新
- GCal 由来のブロック（source='gcal'）はpushしない（BR-33-02）

Acceptance Criteria
- [ ] pushToGoogleCalendar で ARDORS ブロックが GCal に登録される
- [ ] 2回目の push で既存イベントが更新される（重複しない）
- [ ] GCal 由来ブロックはpushされない
- [ ] push 後に gcal_pushed_at が更新される
```

---

## SPR7-04: GCal 連携設定 UI（SCR-90）

```text
[Task]
SPR7-04: ユーザー設定画面（SCR-90）の Google Calendar 連携セクション実装

Goal
- /settings に GCal 連携設定セクションを実装する。
- 連携状態の表示・連携/解除・push 先カレンダー選択を行える。

Context
- 参照: docs/01_要件定義/wireframes/SCR-90_settings.md
- 対応機能: FR-32, FR-33, FR-06（一部）

Scope
- 変更OK:
  - `src/app/(protected)/settings/page.tsx`（GCal セクション追加）
  - `src/features/settings/components/GCalSection.tsx`（新規）
- 変更NG:
  - gcal-actions.ts（SPR7-01〜03 が担当）

GCalSection UI
- 連携済み: 「✓ Google Calendarと連携済み」+ [連携解除] ボタン
- 未連携: 「連携されていません」+ [Google Calendarと連携] ボタン
- 連携済みの場合: Push先カレンダー選択ドロップダウン
  - Google Calendar API で取得したカレンダー一覧を表示
  - 選択後 updateUserSettings({ gcalPushCalendarId }) で保存

Acceptance Criteria
- [ ] 連携状態が正しく表示される
- [ ] 「連携」ボタンで Google 認証画面に遷移する
- [ ] 「連携解除」でトークンが削除され、未連携状態になる
- [ ] Push 先カレンダーを選択できる
```

---

文書バージョン: 1.0
作成日: 2026-04-09
