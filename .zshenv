# npm global binaries (prefix configured in .npmrc). Exported before the
# .local/bin line below on purpose: .zshrc prepends .local/bin again for
# interactive shells, so keeping it last here makes .local/bin win in both
# interactive and non-interactive shells.
export PATH="$HOME/.npm-global/bin:$PATH"

# uv
export PATH="$HOME/.local/bin:$PATH"
