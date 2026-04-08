# CLAUDE.md

## Git Workflow (Claude Code)

このリポジトリでは、以下の Git 運用を必須とします。

- `main` / `master` へ直接 commit / push しない。
- 作業は必ず `feature/*` ブランチで行う。
- `feature/*` を push し、`main` 向け PR を作成してマージする。

## Standard Steps

```bash
# 1) main を最新化
git checkout main
git pull origin main

# 2) 作業ブランチ作成
git checkout -b feature/<task-name>

# 3) 変更を commit
git add .
git commit -m "<type>: <summary>"

# 4) feature ブランチを push
git push -u origin feature/<task-name>
```

## Notes

- `pre-commit` の `no-commit-to-branch` により `main/master` への commit はブロックされます。
- `pre-push` hook により `main/master` への push もブロックされます。
- 例外対応（緊急運用など）が必要な場合は、必ず事前に人間の明示承認を取ってください。

---

## プロジェクト概要

**ARDORS（アーダース）** — AIを搭載した個人向け生産性・タスク・プロジェクト・習慣・内省の統合管理パートナーアプリ。
SaaS（Webファースト・レスポンシブ）。個人開発・趣味プロジェクト。

---

## 技術スタック

| カテゴリ | 技術 |
|----------|------|
| フレームワーク | Next.js 15 App Router + TypeScript |
| スタイリング | Tailwind CSS 4.x + shadcn/ui |
| 状態管理 | Zustand（クライアント）+ TanStack Query（サーバー） |
| フォーム | React Hook Form + Zod |
| DB / Auth | Supabase（PostgreSQL + Auth + RLS） |
| AI（通常） | Anthropic Claude Haiku 4.5（`AI_MODEL_DEFAULT` 環境変数） |
| AI（コーチ） | Anthropic Claude Sonnet 4.6（`AI_MODEL_COACHING` 環境変数） |
| STT | Web Speech API（ブラウザ標準・無料） |
| カレンダー連携 | Google Calendar API v3（手動pull / 一括push） |
| ホスティング | Vercel Hobby（無料） |
| テスト | Vitest + Testing Library + Playwright |

---

## 現在の状態

- **フェーズ**: 要件定義・技術設計が完了。実装未着手
- **次のアクション**: Sprint 1（認証基盤）から開始

---

## Sprint 計画（概要）

| Sprint | 主な機能 |
|--------|---------|
| 1 | 認証基盤（登録・ログイン・パスワードリセット・LP） |
| 2 | オンボーディング + ダッシュボード基盤 |
| 3 | PJ・タスク管理（CRUD + Active/Warm/Cold） |
| 4 | 目標階層 + AI対話基盤（テキスト・音声） |
| 5 | ブレインダンプ + 新規PJ作成AI + モーニングブリーフィング |
| 6 | タイムボクシング + タイムライン |
| 7 | Google Calendar連携（pull/push） |
| 8 | 習慣管理 + デイリークローズ |
| 9 | ウィークリー/月次レビュー + AIコーチモード |
| 10 | ゴール可視化 + 通知 + 仕上げ |

---

## ディレクトリ構成（概要）

```
src/
├── app/              # ルーティングのみ（ロジックは持たない）
│   ├── (public)/     # 認証不要（LP・ログイン・登録）
│   └── (protected)/  # 認証必須（ダッシュボード〜設定）
├── features/         # 機能単位の高凝集モジュール
│   ├── auth/         # FR-01〜03
│   ├── ai-chat/      # FR-10〜13
│   ├── projects/     # FR-20〜24
│   ├── schedule/     # FR-30〜33
│   ├── habits/       # FR-40〜41
│   ├── reviews/      # FR-50〜53
│   ├── goals/        # FR-61〜62
│   └── dashboard/    # FR-60
└── shared/           # 機能横断リソース（UI・lib・型）
```

---

## コーディング規則（必ず守る）

1. **Server Actions は `Result<T>` 型を返す**
   ```typescript
   type Result<T> = { success: true; data: T } | { success: false; error: string }
   ```

2. **`any` 型を使わない** — `unknown` + type guard を使う

3. **全 Server Action に Zod バリデーションを入れる**

4. **APIキーはサーバーのみ** — `ANTHROPIC_API_KEY` 等は `NEXT_PUBLIC_` を付けない

5. **features間の直接importは禁止** — 必ず `index.ts` の公開APIを経由する

---

## AIモデルの使い分け

```bash
AI_MODEL_DEFAULT=claude-haiku-4-5-20251001   # 通常会話・ブレインダンプ・スケジュール生成
AI_MODEL_COACHING=claude-sonnet-4-6          # 週次/月次レビュー・コーチモード
```

---

## 主要ドキュメント

| ドキュメント | パス |
|-------------|------|
| 機能一覧（P0/P1/P2） | `docs/01_要件定義/03_機能一覧_feature-list.md` |
| 画面遷移図 | `docs/01_要件定義/04_画面遷移図_screen-transition.md` |
| ワイヤーフレーム | `docs/01_要件定義/wireframes/` |
| 受入基準（Gherkin） | `docs/01_要件定義/05_受入基準_acceptance-criteria.md` |
| アーキテクチャ | `docs/03_技術設計/01_アーキテクチャ_architecture.md` |
| ディレクトリ構成 | `docs/03_技術設計/02_ディレクトリ構成_directory-structure.md` |
| 外部サービス・環境変数 | `docs/03_技術設計/03_外部サービス_external-services.md` |
| 認証フロー | `docs/03_技術設計/04_認証フロー_auth-flow.md` |
| 開発ガイドライン | `docs/03_技術設計/05_開発ガイドライン_development-guidelines.md` |
| Sprint計画 | `docs/03_技術設計/06_Sprint計画_sprint-and-ai-workflow.md` |
| 用語集 | `docs/00_共通/用語集_glossary.md` |
| 決定ログ | `docs/00_共通/決定事項ログ_decision-log.md` |
