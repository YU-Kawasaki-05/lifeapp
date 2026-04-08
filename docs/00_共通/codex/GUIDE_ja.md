# Codex版 `.claude/` テンプレ一式ガイド

このガイドは、Claude Code の

```text
.claude/
  skills/
  hooks/
  agents/
  commands/
  rules/
```

に近い考え方を、**現在の Codex の公式仕様**に沿って並べ替えたものです。  
下のテンプレート群は、そのままコピーして使える最小構成を意識しています。

---

## 1. まず結論: Claude Code との対応表

| Claude Code 側 | Codex 側で近いもの | 役割 |
|---|---|---|
| `rules/` | `codex/rules/*.rules` | 外で実行するコマンドの許可・拒否・要承認を制御 |
| `skills/` | `skills/<name>/SKILL.md` + `scripts/` + `references/` | 再利用ワークフロー、業務知識、定型手順 |
| `hooks/` | `.codex/hooks.json` + `.codex/hooks/*` | セッション開始時、ツール実行前後、停止時などの自動処理 |
| `agents/` | `.codex/agents/*.toml` | 役割別の専門サブエージェント |
| `commands/` | built-in slash commands / Skills / （旧）Custom Prompts | 再利用コマンド相当。ただし現在は Skills が推奨 |
| `rules + global instructions` | `AGENTS.md` | 毎回守ってほしい repo ルール、完了条件、レビュー基準 |

### 重要な整理
Codex では **Custom Prompts は deprecated** です。  
再利用可能な「コマンドっぽいもの」を作りたいときは、今は **Skills に寄せる** のが推奨です。

---

## 2. 各ファイル群の役割と、何を書くべきか

## `AGENTS.md`
**役割**  
この repo で Codex に毎回守らせたい恒常ルールを書く場所です。

**向いている内容**
- 使用するパッケージマネージャ
- lint/test/build の標準手順
- 変更してはいけない public API や危険な領域
- PR までに満たすべき完了条件
- ディレクトリ別の注意事項

**向いていない内容**
- 長大な設計資料
- まれにしか使わない手順
- 出力テンプレートの詳細
- variant ごとの細かい例

そういうものは Skills の `references/` に逃がした方が、`AGENTS.md` が太りすぎず扱いやすくなります。

**書き方のコツ**
- 毎回必ず効いてほしいものだけを書く
- ルールは短く、曖昧語を減らす
- 「やること」だけでなく「やらないこと」も書く
- ディレクトリ固有ルールはネストした `AGENTS.override.md` で局所化する

---

## `skills/<name>/SKILL.md`
**役割**  
特定タスク用の再利用ワークフローです。  
「何をするときに使うか」「どう進めるか」「どんな出力で返すか」をまとめます。

**向いている内容**
- PRレビュー手順
- バグ修正フロー
- ドキュメント調査フロー
- デプロイ手順
- 脅威モデリング
- フロントエンド作業の品質基準

**書き方のコツ**
- frontmatter の `name` と `description` を必ず書く
- `description` に「いつ使うか / いつ使わないか」を明記する
- body には順番付きの workflow を書く
- 最後に output 形式を固定する
- 詳細資料は `references/` に逃がす
- 決まりきった処理は `scripts/` に逃がす

### Skill はどう分けるべきか
1 skill = 1 job が基本です。  
「全部入り万能 skill」より、次のように分ける方が安定します。

- `pr-review`
- `backend-bugfix`
- `docs-research`
- `render-deploy`
- `security-threat-model`

---

## `skills/<name>/scripts/*`
**役割**  
AI に毎回書かせる必要がない、決まりきった処理を deterministic にするための場所です。

**向いている内容**
- lint/test 実行
- 変換スクリプト
- seed データ投入
- 検証処理
- フォーマット補助

**コツ**
- 「判断」は SKILL.md に書く
- 「固定処理」は script に書く
- script は単独でも読めるようにしておく

---

## `skills/<name>/references/*`
**役割**  
長めの資料・規約・業務知識を置く場所です。

**向いている内容**
- API仕様メモ
- 命名規約
- DBスキーマの説明
- 運用ポリシー
- テスト観点表
- 画面設計メモ

**コツ**
- SKILL.md に重複して全文を書かない
- 「いつこの reference を読むべきか」を SKILL.md 側に明記する
- 参照専用の情報をここに寄せる

---

## `skills/<name>/agents/openai.yaml`
**役割**  
UI metadata / invocation policy / tool dependency の宣言に使う補助メタデータです。

**向いている内容**
- 表示名
- 短い説明
- この skill が依存するツールや周辺設定
- 呼び出しポリシーの補助情報

これ自体が主役というより、**Skill をより運用しやすくする補助ファイル**です。

---

## `.codex/agents/*.toml`
**役割**  
役割別の専門 subagent を定義します。

**向いている agent の分割例**
- `reviewer` : 指摘専用
- `docs_researcher` : 仕様確認専用
- `code_mapper` : コード位置特定専用
- `browser_debugger` : UI再現・証拠採取専用
- `ui_fixer` : 修正専用

**書き方のコツ**
- 1 agent 1責務に絞る
- `description` に使いどころを書く
- `developer_instructions` は役割に徹する
- 必要に応じて `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers` を追加する

---

## `.codex/hooks.json` と `.codex/hooks/*`
**役割**  
セッションやツール実行のライフサイクルに、自動スクリプトを差し込む仕組みです。

**向いている内容**
- セッション開始時に repo メモを注入
- Bash 実行前に危険コマンドを拒否
- Bash 実行後に結果チェック
- Stop 時に要約やログを書き出す
- プロンプト送信前に秘密情報っぽい文字列を検出する

**注意**
- Hooks は experimental
- 有効化には `config.toml` の feature flag が必要
- 現在の `PreToolUse` / `PostToolUse` は実質 Bash 向けガードとして考えるのが安全
- Windows では hooks が無効

---

## `codex/rules/*.rules`
**役割**  
サンドボックス外で実行されるコマンドに対して、許可・拒否・要承認のルールを書く場所です。

**向いている内容**
- `rm -rf` 系の拒否
- `gh pr view` のようなコマンドは prompt
- `git push --force` は deny
- 一部の読み取り系コマンドのみ allow

**コツ**
- まずは deny / prompt 中心にする
- `match` / `not_match` を書いておくと将来の事故を減らせる
- ルールは厳しめに始めて、必要に応じて緩める

---

## `deprecated-prompts/*`
**役割**  
これは今の推奨ではありません。  
ただし Claude Code の `commands/` 的な発想を移行する際に、**昔の Custom Prompts が何だったのか**を理解するための参考例として入れています。

**現在の考え方**
- 再利用コマンドっぽいもの → Skills
- その場の操作切り替え → built-in slash commands
- 古い Markdown ベース再利用 prompt → deprecated

---

## 3. 推奨ディレクトリ構成

```text
.
├─ AGENTS.md
├─ GUIDE_ja.md
├─ SOURCES.md
├─ .codex/
│  ├─ config.toml
│  ├─ hooks.json
│  ├─ agents/
│  │  ├─ reviewer.toml
│  │  ├─ docs_researcher.toml
│  │  └─ code_mapper.toml
│  └─ hooks/
│     ├─ session_start.py
│     ├─ check_bash_command.py
│     ├─ post_bash_review.py
│     └─ stop_summary.py
├─ skills/
│  ├─ pr-review/
│  │  ├─ SKILL.md
│  │  ├─ references/
│  │  │  └─ review-checklist.md
│  │  └─ agents/
│  │     └─ openai.yaml
│  ├─ backend-bugfix/
│  │  ├─ SKILL.md
│  │  ├─ scripts/
│  │  │  └─ verify.sh
│  │  ├─ references/
│  │  │  └─ test-policy.md
│  │  └─ agents/
│  │     └─ openai.yaml
│  └─ docs-research/
│     ├─ SKILL.md
│     ├─ references/
│     │  └─ research-checklist.md
│     └─ agents/
│        └─ openai.yaml
├─ codex/
│  └─ rules/
│     └─ default.rules
└─ deprecated-prompts/
   └─ draftpr.md
```

---

## 4. どう使い分けるか

### `AGENTS.md` に書く
- 毎回守るルール
- 完了条件
- 共通 test/lint/build
- 禁則
- ディレクトリ固有の基本ポリシー

### Skill に書く
- 特定タスクの手順
- 判断順序
- 出力フォーマット
- 参照先資料
- 決まりきった script 呼び出し

### Hook に書く
- 自動チェック
- セッション開始時の補助
- 実行前後の監視
- ログや要約

### Rule に書く
- 外で走らせるコマンドの許可制御

### Subagent に書く
- 役割分担
- モデル
- sandbox
- 専門指示

---

## 5. 最初に入れるべき最小セット

最初から全部を盛る必要はありません。  
最初はこれだけで十分です。

1. `AGENTS.md`
2. `.codex/config.toml`
3. `.codex/agents/reviewer.toml`
4. `skills/pr-review/SKILL.md`
5. `codex/rules/default.rules`

そのあと必要に応じて、
- Hooks
- 追加 Skill
- 追加 Subagent
- MCP
を増やしていくのが安全です。

---

## 6. このテンプレートでやっている設計思想

- **AGENTS.md は短く強く**
- **Skill は 1 job 1 skill**
- **詳細資料は references へ**
- **反復コードは scripts へ**
- **危険操作は rules / hooks で防ぐ**
- **subagent は責務分離**
- **deprecated な Custom Prompts は学習用サンプルだけ残す**

---

## 7. 参考にした公式 / 実例 / 技術記事

詳細は `SOURCES.md` にまとめています。特に重要なのは次です。

- OpenAI Codex Customization
- OpenAI Codex AGENTS.md guide
- OpenAI Codex Skills docs
- OpenAI Codex Hooks docs
- OpenAI Codex Subagents docs
- OpenAI Codex Rules docs
- OpenAI Codex Slash Commands docs
- OpenAI Codex Custom Prompts docs
- OpenAI blog: Using skills to accelerate OSS maintenance
- OpenAI blog: Testing Agent Skills Systematically with Evals
- GitHub: `openai/skills`
- GitHub: `ComposioHQ/awesome-codex-skills`

---

## 8. すぐに触る順番

1. `AGENTS.md` を自分の repo ルールに合わせて直す  
2. `.codex/config.toml` の sandbox / approval / model を自分の環境に合わせる  
3. `skills/pr-review` と `skills/backend-bugfix` を自分の開発フローに寄せる  
4. `codex/rules/default.rules` を厳しめに保つ  
5. その後に hooks を有効化する  

最初からフルオートにしない方が安定します。
