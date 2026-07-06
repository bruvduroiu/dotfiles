-- octo.nvim — in-editor GitHub PR lifecycle (browse, comment, review, approve,
-- merge). Requires `gh` on PATH (added in default.nix) and `gh auth login` once.
--
-- Entry points live on <leader>r in the plugin spec. Inside octo buffers the
-- builtin <localleader>-maps (localleader = "," set in init.lua) cover the rest:
--
--   PR buffer:      ,po checkout    ,pm merge    ,psm squash-merge
--                   ,prm rebase-merge    ,ca add comment    <C-b> browser
--   Review diff:    ]q/[q next/prev file    ]t/[t next/prev thread
--                   ,ca comment    ,sa suggestion    ,rt resolve thread
--                   ,vs submit review (then <C-a> approve / <C-m> comment /
--                   <C-r> request changes in the submit window)
--
-- `enable_builtin` gives the bare :Octo command a picker over all subcommands —
-- the discoverable fallback for anything unbound.
return {
  picker = "telescope", -- reuse the existing telescope + fzf-native install
  enable_builtin = true,
}
