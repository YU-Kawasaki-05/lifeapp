# 共通ブロック
## プロジェクト名: ARDORS（アーダース）

このファイルは **全 PR プロンプトの末尾に追記する共通テキスト** である。
コピーして各タスクプロンプトの末尾に貼り付けること。

---

## 共通ブロック A: 全タスク共通

```text
---
[共通制約・品質バー]

Git 運用:
- main/master へ直接 commit/push しない。
- 作業ブランチ: feature/<task-id>-<short-name>
- PR を作成して main へマージする。

If blocked:
- 外部サービス/ENV/Secrets が必要で失敗する場合、値を推測して追加しない。
- 代わりに、どのコマンドで何が不足しているかを PR 本文に明記して停止する。

Quality bar:
- 変更は最小限。既存の実装パターン・命名・型定義に合わせる。
- スコープ外の修正は行わない。必要なら「次PR提案」として PR 本文に記載する。
- `any` 型を使わない（`unknown` + type guard を使う）。
- Server Actions は必ず `Result<T>` 型を返す。
- 全 Server Actions の先頭で `getAuthenticatedUser()` を呼ぶ。
- 全 Server Actions に Zod バリデーションを入れる。
- `ANTHROPIC_API_KEY` 等の機密環境変数に `NEXT_PUBLIC_` 接頭辞を付けない。
- features 間の直接 import 禁止（必ず index.ts の公開 API 経由）。

PR report format（必須）:
1) What（何を変えたか）
2) Why（なぜ必要か — 対応する FR-xx / SPR-xx を明記）
3) How to test（実行コマンドと結果）
4) Risks / Follow-ups
5) Human action required（手動作業の有無・ENV 設定等）

Self-review（3行）:
- 1PR スコープを守れているか
- Done が機械判定可能か（テストや lint が通るか）
- ENV/外部依存で詰まりそうな点がないか

Validation commands:
- 基本: `npm run lint` / `npm run type-check` / `npm run test`
- 可能なら: `npm run build`（失敗時は Secrets を推測せず不足 ENV を PR 本文に記載）
```

---

## 共通ブロック B: AI 機能を含むタスク用（追加で貼り付ける）

```text
---
[AI 機能 追加制約]

- AI モデルは環境変数から取得する。ハードコード禁止:
  ```typescript
  import { AI_MODELS } from '@/shared/lib/ai/models'
  // 通常: AI_MODELS.default / コーチ: AI_MODELS.coaching
  ```
- `ANTHROPIC_API_KEY` は Server Actions 内のみで使用。クライアントコンポーネントから直接参照禁止。
- AI 応答失敗時は `{ success: false, error: 'AI処理中にエラーが発生しました。しばらく待ってから再度お試しください' }` を返す。
- レート制限チェック: `checkAIRateLimit(user.id)` を AI 呼び出し前に実行する。
- 会話は必ず `ai_conversations` テーブルに保存する（role='user' と role='assistant' の2行）。
- ストリーミング応答は `StreamingTextResponse` を使用してトークン単位で返す。
```

---

## 共通ブロック C: DB マイグレーションを含むタスク用（追加で貼り付ける）

```text
---
[DB マイグレーション 追加制約]

- マイグレーションファイルは `supabase/migrations/YYYYMMDDHHMMSS_<説明>.sql` に作成する。
- 全テーブルに RLS を有効化し、適切なポリシーを設定する。
- `updated_at` 自動更新トリガーを適用する（`update_updated_at()` 関数を使用）。
- ローカルでの確認: `supabase db push` を実行し、エラーがないことを確認。
- ロールバック手順をコメントで記載する。
- 本番適用前にステージング環境で検証（現フェーズは個人開発のため省略可）。
```

---

## 共通ブロック D: 画面実装を含むタスク用（追加で貼り付ける）

```text
---
[画面実装 追加制約]

- スタイリング: Tailwind CSS 4.x のユーティリティクラスを使用。
- コンポーネント: shadcn/ui を優先使用（Button, Card, Input, Dialog 等）。
- アイコン: Lucide React を使用。
- レスポンシブ必須: モバイル（< 1024px）とPC（≥ 1024px）の両方に対応。
- PC: サイドバーナビ / モバイル: ボトムナビ。
- ローディング状態: `<Skeleton>` でカードの形を維持、ボタンは `disabled + animate-spin`。
- エラー表示: フォームフィールド下はインラインエラー（`text-destructive text-xs`）、Action 失敗は `<Toast>`。
- Server Components でデータを取得し、Client Components に props で渡す。
- `'use client'` は必要最小限（ユーザーインタラクションがある部分のみ）。
```

---

## 参照ドキュメント一覧

各タスクの Context セクションで参照するドキュメントの一覧。

| ドキュメント名 | パス |
|-------------|------|
| 機能一覧 | `docs/01_要件定義/03_機能一覧_feature-list.md` |
| 画面遷移図 | `docs/01_要件定義/04_画面遷移図_screen-transition.md` |
| 受入基準 | `docs/01_要件定義/05_受入基準_acceptance-criteria.md` |
| ワイヤーフレーム（各画面） | `docs/01_要件定義/wireframes/SCR-*.md` |
| DB設計 | `docs/02_外部設計/01_DB設計_database-design.md` |
| API仕様（Server Actions） | `docs/02_外部設計/02_API仕様_api-specification.md` |
| 権限設計 | `docs/02_外部設計/03_権限設計_authorization.md` |
| 画面設計 | `docs/02_外部設計/04_画面設計_screen-design.md` |
| 非機能要件 | `docs/02_外部設計/05_非機能要件_non-functional-requirements.md` |
| アーキテクチャ | `docs/03_技術設計/01_アーキテクチャ_architecture.md` |
| ディレクトリ構成 | `docs/03_技術設計/02_ディレクトリ構成_directory-structure.md` |
| 外部サービス・ENV | `docs/03_技術設計/03_外部サービス_external-services.md` |
| 認証フロー | `docs/03_技術設計/04_認証フロー_auth-flow.md` |
| 開発ガイドライン | `docs/03_技術設計/05_開発ガイドライン_development-guidelines.md` |

---

文書バージョン: 1.0
作成日: 2026-04-09
