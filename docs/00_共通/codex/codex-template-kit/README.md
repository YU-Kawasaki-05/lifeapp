# Codex Template Kit

このディレクトリは、Codex で `AGENTS.md` / Skills / Hooks / Rules / Subagents を運用するための雛形です。

## 含まれているもの
- `AGENTS.md`
- `.codex/config.toml`
- `.codex/hooks.json`
- `.codex/agents/*.toml`
- `.codex/hooks/*.py`
- `skills/*`
- `codex/rules/default.rules`
- `deprecated-prompts/draftpr.md`
- `GUIDE_ja.md`
- `SOURCES.md`

## おすすめの導入順
1. `AGENTS.md` を自分の repo に合わせて編集
2. `.codex/config.toml` の承認 / sandbox / model を調整
3. `skills/pr-review` を自分の開発フローに合わせて編集
4. `codex/rules/default.rules` を確認
5. 問題なければ hooks を有効化

## 注意
- Hooks は experimental
- Rules も段階的に導入した方が安全
- `deprecated-prompts/` は学習用の互換サンプルで、現在の推奨は Skills です
