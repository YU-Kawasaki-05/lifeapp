# Claude Commands Compatibility (for Codex)

`.claude/commands` を Codex でそのまま運用したい場合、互換手段として
`CODEX_HOME/prompts/` へ変換して配置できます。

このリポジトリのスクリプト既定値では、`CODEX_HOME` 未指定時に
`./.codex-home` を利用します。

## Why this approach
- Codex は `.claude/commands` を直接コマンドとしては読みません。
- 互換性を高く保つには、Markdown コマンドを custom prompt として登録するのが最短です。
- ただし custom prompts は deprecated 扱いのため、将来的には skills への移行が推奨です。

## Install
```bash
cd /home/yukawasaki/develop/lifeapp
bash codex/scripts/install_claude_commands_as_prompts.sh
```

上記で、次の prompt コマンドが `./.codex-home/prompts/` に生成されます。
- `/prompts:req-phase1`
- `/prompts:req-phase2`
- `/prompts:req-phase3`

## Usage examples
```text
/prompts:req-phase1 DOCS_ROOT=./docs PROJECT_NAME=ARDORS
/prompts:req-phase2 DOCS_ROOT=./docs
/prompts:req-phase3 DOCS_ROOT=./docs
```

## Update flow
`.claude/commands/` の内容を修正したら、同じ install スクリプトを再実行してください。
生成先の prompt が上書き更新されます。
