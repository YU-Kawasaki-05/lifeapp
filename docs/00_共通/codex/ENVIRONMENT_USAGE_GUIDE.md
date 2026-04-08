# lifeapp Codex Environment Usage Guide

このドキュメントは、このリポジトリで整備した Codex 開発環境の
「何があるか / どう使うか / どこで制御しているか」を一箇所にまとめた運用ガイドです。

## 1. 最短セットアップ（推奨）

```bash
cd /home/yukawasaki/develop/lifeapp
bash codex/scripts/bootstrap_dev_environment.sh
```

この1コマンドで次を実行します。
- `pre-commit` の導入（未導入時）
- `.claude/commands` 互換 prompt の生成
- prompt 生成先を `./.codex-home/prompts/` に統一（`CODEX_HOME` 未指定時）
- Gitリポジトリの場合のみ:
  - `pre-commit` / `pre-push` フックのインストール
  - 全ファイルへの pre-commit チェック実行

## 2. 構成マップ（役割別）

### 2.1 全体ルール
- `AGENTS.md`
- `docs/AGENTS.override.md`
- `docs/01_要件定義/AGENTS.override.md`
- `docs/01_要件定義/wireframes/AGENTS.override.md`

用途:
- 常時適用される開発方針、完了基準、ドキュメント配下の局所ルールを定義。

### 2.2 Codex本体設定
- `.codex/config.toml`
- `.codex/hooks.json`
- `.codex/hooks/*.py`
- `.codex/agents/*.toml`

用途:
- モデル・承認・sandbox・hook・サブエージェント定義を管理。

### 2.3 コマンド実行ガード
- `codex/rules/default.rules`
- `.codex/hooks/check_bash_command.py`

用途:
- 破壊的コマンドを `prompt` / `forbidden` / `deny` で制御。

### 2.4 Skills（再利用ワークフロー）
- `.agents/skills/*`（canonical）
- `skills -> .agents/skills`（互換symlink）

用途:
- タスク種別ごとの実行手順と判断基準を再利用。

### 2.5 `.claude/commands` 互換レイヤー
- `codex/scripts/install_claude_commands_as_prompts.sh`
- `.codex-home/prompts/req-phase1.md`
- `.codex-home/prompts/req-phase2.md`
- `.codex-home/prompts/req-phase3.md`

用途:
- 既存 `.claude/commands` の Markdown を Codex prompt command として利用。

### 2.6 Git品質ゲート
- `.pre-commit-config.yaml`
- `.githooks/pre_push_protect_main.sh`

用途:
- 秘密鍵検出、yaml/toml整合、マージ競合痕跡検出、main/master保護。

## 3. 日常運用コマンド

### 3.1 Codex起動
```bash
cd /home/yukawasaki/develop/lifeapp
bash codex/scripts/run_codex_local.sh
```

プロファイル指定:
```bash
bash codex/scripts/run_codex_local.sh --profile fast
bash codex/scripts/run_codex_local.sh --profile review
bash codex/scripts/run_codex_local.sh --profile explore
```

使い分け:
- `fast`: 実装速度優先
- `review`: 読み取り・レビュー向き（read-only）
- `explore`: 調査向き（read-only）

### 3.2 `.claude/commands` 互換 prompt 実行
Codex セッション内で:
```text
/prompts:req-phase1 DOCS_ROOT=./docs PROJECT_NAME=ARDORS
/prompts:req-phase2 DOCS_ROOT=./docs
/prompts:req-phase3 DOCS_ROOT=./docs
```

更新時:
```bash
bash codex/scripts/install_claude_commands_as_prompts.sh
```

### 3.3 Skills の使い方
トリガー例（自然言語でOK）:
- 「PRレビューして」→ `pr-review`
- 「公式ドキュメントで確認して」→ `docs-research`
- 「CI失敗を調査して」→ `gh-fix-ci`

## 4. 安全ポリシー（実際の挙動）

### 4.1 Codex Rules
- `git push`（feature系）: `allow`
- `git push origin main|master`: `prompt`
- `git push --force/-f/--force-with-lease`: `forbidden`
- `rm`: `prompt`
- `sudo rm -rf`: `forbidden`

### 4.2 Hook追加ガード
- 保護ブランチ (`main/master`) 上で曖昧 push（`git push`, `git push origin`）は `deny`
- `git reset --hard` は `deny`
- `git clean -fdx` は `deny`

### 4.3 Git Hook（pre-push）
- `refs/heads/main` / `refs/heads/master` への push をローカルでブロック。

## 5. pre-commit 運用

初回（Gitリポジトリ内で実行）:
```bash
pre-commit install
pre-commit install --hook-type pre-push
```

手動実行:
```bash
pre-commit run --all-files
```

補足:
- `no-commit-to-branch` は `main/master` での commit を止めます。
- 保守作業で全体検査だけしたい場合は次を使用:
```bash
SKIP=no-commit-to-branch pre-commit run --all-files
```

## 6. GitHub リモート運用

現在の推奨:
- `origin` は SSH (`git@github.com:...`) を使用。
- HTTPS 認証問題で詰まりにくい。
- `main` / `master` へ直接 commit / push しない。`feature/*` ブランチ経由で PR マージする。

### 6.1 標準ブランチ運用（推奨）

```bash
# 1) main を最新化
git checkout main
git pull origin main

# 2) 作業ブランチを切る（例）
git checkout -b feature/update-codex-docs

# 3) 変更をコミット
git add .
git commit -m "docs: codex運用ドキュメントを更新"

# 4) feature ブランチを push
git push -u origin feature/update-codex-docs
```

その後、GitHub 上で `feature/update-codex-docs` -> `main` の PR を作成してマージします。

確認:
```bash
git remote -v
git branch -vv
```

## 7. トラブルシュート

### 7.1 `/prompts:req-phase*` が出ない
```bash
bash codex/scripts/install_claude_commands_as_prompts.sh
ls ./.codex-home/prompts
```

### 7.2 pre-commit が見つからない
```bash
python3 -m pip install --user pre-commit
~/.local/bin/pre-commit --version
```

### 7.3 hook でコマンドが弾かれる
- 想定挙動か `codex/rules/default.rules` と `.codex/hooks/check_bash_command.py` を確認。
- 必要ならルールを tighten/relax する。

### 7.4 `git failed. Is it installed, and are you in a Git repository directory?` が出る
- `.git` がないディレクトリでは `pre-commit install` は失敗します。
- 現在の `bootstrap_dev_environment.sh` はこの場合、hook のインストールだけを自動スキップします。
- Git管理したい場合は、先に `git init` または既存リポジトリで作業してください。

## 8. 変更時のおすすめ手順

1. `git checkout -b feature/<task-name>` で作業ブランチを作成
2. `.claude/commands` を更新
3. `bash codex/scripts/install_claude_commands_as_prompts.sh`
4. `SKIP=no-commit-to-branch pre-commit run --all-files`
5. `git push -u origin feature/<task-name>` で push
6. 影響範囲を `docs/00_共通/codex/` 配下ドキュメントへ反映し、PR を作成
