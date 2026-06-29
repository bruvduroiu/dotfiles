-- octo.nvim — in-editor GitHub PR review (threads, inline comments, submit).
-- Requires `gh` on PATH (added in default.nix) and `gh auth login` once; the
-- token lives in the OS keyring by default, not on disk.
--
-- Review actions are <localleader>-prefixed (localleader = "," set in init.lua):
--   ,ca add comment   ,sa add suggestion   ,vs start/submit review
--   ,vr resume review  ,po checkout PR
-- and ]t/[t (next/prev thread), ]q/[q (next/prev changed file) inside reviews.
return {
  picker = "telescope", -- reuse the existing telescope + fzf-native install
  enable_builtin = true,
}
