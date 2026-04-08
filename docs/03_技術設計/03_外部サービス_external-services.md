# 外部サービス選定書
## プロジェクト名: ARDORS（アーダース）

---

## 1. サービス一覧

| # | 目的 | 選定サービス | 月額見込み | 補足 |
|---|------|------------|-----------|------|
| 1 | ホスティング | Vercel Hobby | **$0** | 個人・趣味プロジェクト対象 |
| 2 | DB / Auth / BaaS | Supabase Free | **$0** | 500MB DB, 50k MAU, 2GB storage |
| 3 | AI（通常） | Anthropic API (Claude Haiku 4.5) | **~$1〜3** | 日常会話・ブレインダンプ・タイムボクシング生成 |
| 4 | AI（詳細分析） | Anthropic API (Claude Sonnet 4.6) | **~$0〜1** | 週次/月次レビュー・コーチモード（週1回程度） |
| 5 | 音声入力（STT） | Web Speech API（ブラウザ標準） | **$0** | Chrome/Edge対応。APIキー不要 |
| 6 | カレンダー連携 | Google Calendar API v3 | **$0** | 1M req/day まで無料 |
| 7 | ソースコード管理 | GitHub Free | **$0** | Private repoも無料 |
| 8 | メール送信 | Supabase（内包） | **$0** | 認証メール・パスワードリセットはSupabase管理 |
| **合計** | | | **~$1〜5/月** | |

---

## 2. 各サービス詳細

### 2.1 Vercel Hobby

| 項目 | 内容 |
|------|------|
| 用途 | Next.jsアプリのホスティング・CDN・Edge Network |
| プラン | Hobby（無料・個人利用前提） |
| デプロイ | GitHub連携で `main` ブランチへのpushで自動デプロイ |
| プレビュー | PRごとにプレビューURLが自動生成される |
| 制限 | 商用利用は有料プラン必要。趣味・個人なら無料で十分 |
| 注意 | 将来SaaS公開・課金導入時はPro（$20/月）に移行が必要 |

### 2.2 Supabase（DB / Auth / BaaS）

| 項目 | 内容 |
|------|------|
| 用途 | PostgreSQL DB + 認証 + RLS |
| プラン | Free tier |
| DB容量 | 500MB（個人ユーザー1人なら数年は問題ない） |
| MAU上限 | 50,000（現フェーズでは無制限に等しい） |
| Edge Functions | 500k回/月（バックグラウンド処理に将来使用可能） |
| Auth機能 | Google OAuth + Email/Password + パスワードリセット + メール確認 |
| 接続方式 | `@supabase/ssr`（SSR/Server Components対応の公式ライブラリ） |
| 注意 | 無料プロジェクトは7日間非アクティブで一時停止。週1回アクセスで回避可 |
| 将来 | ユーザー増加時はPro（$25/月）に移行。500MB→8GBに拡張 |

**Supabase 無料tier 主要制限まとめ:**

```
PostgreSQL: 500MB
Auth MAU:   50,000
Storage:    1GB
Bandwidth:  5GB/月
Edge Func:  500,000 回/月
```

### 2.3 Anthropic API（AI）

| 項目 | 内容 |
|------|------|
| 用途 | AI対話・ブレインダンプ構造化・タイムボクシング生成・レビューコーチング |
| 認証 | APIキー（`ANTHROPIC_API_KEY`）。**サーバーサイドのみ使用**（クライアントに露出させない） |
| SDK | `@anthropic-ai/sdk`（公式TypeScript SDK） |

**モデル切り替え戦略（環境変数制御）:**

```bash
# .env.local
AI_MODEL_DEFAULT=claude-haiku-4-5-20251001
AI_MODEL_COACHING=claude-sonnet-4-6
```

```typescript
// src/shared/lib/ai/models.ts
export const AI_MODELS = {
  /** 通常の対話・ブレインダンプ・タイムボクシング生成・モーニングブリーフィング */
  default: process.env.AI_MODEL_DEFAULT ?? 'claude-haiku-4-5-20251001',
  /** 週次/月次レビュー・コーチモード（深い分析が必要な場面） */
  coaching: process.env.AI_MODEL_COACHING ?? 'claude-sonnet-4-6',
} as const;

export type AIModelKey = keyof typeof AI_MODELS;
```

**モデル別コスト比較:**

| モデル | Input | Output | 推奨用途 |
|--------|-------|--------|---------|
| Claude Haiku 4.5 | $0.80/1M | $4/1M | 日常会話・ブレインダンプ・スケジュール生成 |
| Claude Sonnet 4.6 | $3/1M | $15/1M | 週次/月次レビュー・コーチモード |

**月間コスト試算（個人ユーザー1人の想定）:**

```
Haiku（日常会話）:
  - 1日3回対話 × 平均1000トークン × 30日 = 90,000 tokens/月
  - Input: 60k × $0.80/1M ≈ $0.05
  - Output: 30k × $4/1M   ≈ $0.12
  → Haiku合計: ~$0.17/月

Sonnet（週次レビュー）:
  - 週1回 × 平均5000トークン × 4週 = 20,000 tokens/月
  - Input: 10k × $3/1M   ≈ $0.03
  - Output: 10k × $15/1M ≈ $0.15
  → Sonnet合計: ~$0.18/月

月額AI費用合計: ~$0.35〜1（使い方によって変動）
```

### 2.4 Web Speech API（STT）

| 項目 | 内容 |
|------|------|
| 用途 | 音声→テキスト変換（STT）。ARDORSのマイクボタン |
| 費用 | 完全無料（ブラウザ標準API） |
| 対応ブラウザ | Chrome, Edge（Safari・Firefoxは非対応または制限あり） |
| 実装 | `window.SpeechRecognition` / `window.webkitSpeechRecognition` |
| 制限 | インターネット接続必須（音声処理はGoogleサーバーで実行） |
| 代替案 | 非対応ブラウザでは「テキスト入力してください」と案内 |

```typescript
// features/ai-chat/hooks/useVoiceInput.ts のイメージ
const SpeechRecognition =
  window.SpeechRecognition || window.webkitSpeechRecognition;

if (!SpeechRecognition) {
  // Firefox等非対応ブラウザへのフォールバック
  showError('お使いのブラウザは音声入力に対応していません。テキストで入力してください。');
  return;
}
```

### 2.5 Google Calendar API v3

| 項目 | 内容 |
|------|------|
| 用途 | ユーザーのGCal予定のpull（取得）とARDORSスケジュールのpush（書き込み） |
| 認証 | OAuth2（ユーザーごとのアクセストークン）。Supabase Auth経由でGoogleトークンを取得 |
| スコープ | `https://www.googleapis.com/auth/calendar`（読み取り+書き込み） |
| 無料枠 | 1,000,000 queries/day（個人利用なら絶対超えない） |
| 環境変数 | Google Cloud ConsoleでOAuth2クライアントを作成して取得 |

**Google Cloud設定手順:**
1. Google Cloud Console で新規プロジェクト作成
2. Google Calendar API を有効化
3. OAuth 2.0 クライアントIDを作成（Webアプリケーション）
4. 承認済みリダイレクトURIに `https://[project].supabase.co/auth/v1/callback` を追加
5. Supabase Dashboard → Auth → Providers → Google にクライアントID/シークレットを設定

---

## 3. コスト試算（フェーズ別）

| フェーズ | 期間 | 内容 | 月額 |
|---------|------|------|------|
| 開発中 | 〜6ヶ月 | 個人使用のみ。AI APIのテスト利用 | ~$1〜3 |
| β公開後 | 6ヶ月〜 | ユーザー数増加。Supabase Free tier上限に注意 | ~$3〜10 |
| 商用化時 | - | Vercel Pro + Supabase Pro へ移行 | ~$45〜 |

---

## 4. 環境変数一覧

```bash
# .env.local.example（コミット可能なテンプレート）

# ─── Supabase ───────────────────────────────────────────
NEXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co          # クライアントに公開可
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJxxxx...                   # クライアントに公開可（RLSで保護）
SUPABASE_SERVICE_ROLE_KEY=eyJxxxx...                       # サーバーのみ。絶対に公開しない

# ─── Anthropic API ──────────────────────────────────────
ANTHROPIC_API_KEY=sk-ant-xxxx                              # サーバーのみ
AI_MODEL_DEFAULT=claude-haiku-4-5-20251001                 # 通常会話・ブレインダンプ用モデル
AI_MODEL_COACHING=claude-sonnet-4-6                        # 週次/月次レビュー用モデル

# ─── Google Calendar API ────────────────────────────────
# ※ OAuthはSupabase Auth経由なので、追加設定はSupabase DashboardのGoogleプロバイダ設定で行う
# Google Cloud Consoleで取得したクライアントID/シークレットをSupabase側に登録
```

| 変数名 | サービス | 用途 | 公開範囲 |
|--------|---------|------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase | SupabaseプロジェクトURL | クライアント可 |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase | 匿名キー（RLSで保護済み） | クライアント可 |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase | 管理者権限（RLS無視）。管理者機能のみ | **サーバーのみ** |
| `ANTHROPIC_API_KEY` | Anthropic | AI API認証 | **サーバーのみ** |
| `AI_MODEL_DEFAULT` | Anthropic | デフォルトAIモデル指定 | サーバーのみ |
| `AI_MODEL_COACHING` | Anthropic | コーチングAIモデル指定 | サーバーのみ |

---

## 5. リスクと代替策

| リスク | 発生確率 | 影響 | 対策 |
|--------|---------|------|------|
| Anthropic API障害 | 低 | 全AI機能停止 | AI非依存フォールバック（手動CRUD）を全AI機能に実装済み（FR-10 BR-10-04） |
| Supabase無料枠の一時停止 | 中（7日非アクティブで停止） | 全機能停止 | 定期的なアクセスで回避。重要期はPro移行 |
| Google Calendar API制限 | 極低 | GCal機能停止 | 手動スケジュール入力でフォールバック |
| Web Speech API非対応ブラウザ | 中（Firefox等） | 音声入力不可 | テキスト入力を常に代替手段として提供 |
| Vercel Hobby商用禁止 | - | SaaS課金導入時に違反 | 商用化時はVercel Proに移行（$20/月） |
| AI APIコスト急増 | 低（個人利用）| 想定外の費用 | Anthropic Consoleでスペンド上限を設定（月$10等） |

---

文書バージョン: 1.0
作成日: 2026-04-08
