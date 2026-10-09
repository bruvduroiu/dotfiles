{ config, pkgs, ... }:

let
  conf = config.xdg.configHome;
  home = config.home.homeDirectory;
  # Databases live here, deliberately outside ~/Documents: that tree is the
  # "docs" Syncthing folder and a restic backup path, and hister holds both
  # files open read-write. Created by StateDirectory= on the unit below.
  stateDir = "${config.xdg.stateHome}/hister";
  yamlFormat = pkgs.formats.yaml { };

  settings = {
    app = {
      directory = "${conf}/hister";
      search_url = "https://google.com/search?q={query}";
      log_level = "info";
      debug_sql = false;
    };
    server = {
      address = "127.0.0.1:4433";
      # vectors.sqlite3 is not separately configurable: the sqlite vector store
      # joins "vectors.sqlite3" onto this file's own directory
      # (server/vectorstore/sqlite.go), so this one path relocates both.
      database = "${stateDir}/hister.db";
    };
    indexer = {
      detect_languages = true;
      keep_stopwords = false;
      directories = [
        { path = "${home}/Documents/Papers"; label = "Papers"; filetypes = [ "pdf" ]; }
        { path = "${home}/Documents/Personal"; label = "Personal"; filetypes = [ "pdf" "md" ]; }
        { path = "${home}/Documents/Work"; label = "Work"; filetypes = [ "pdf" "md" ]; }
      ];
    };
    crawler = {
      backend = "http";
    };
    # EmbeddingGemma 2 (llama.cpp on the LAN; the server ignores `model` and
    # serves whatever it loaded). One 768-dim space for text, code, images,
    # video and audio — but hister only ever sends text, so only that half is
    # used here. Changing model/dimensions needs a fresh vectors.sqlite3: the
    # vec0 table keeps its FLOAT[n] width and hister never re-creates it.
    semantic_search = {
      enable = true;
      embedding_endpoint = "http://192.168.1.193:11434/v1/embeddings";
      embedding_model = "embeddinggemma-2";
      embedding_timeout = 300;
      # Native width. MRL 512/256/128 would need client-side truncation and
      # re-normalisation, which hister doesn't do, and llama.cpp ignores the
      # OpenAI `dimensions` field.
      dimensions = 768;
      # Chunk size, not model capacity: the model accepts 8k, but a chunk that
      # large collapses a whole paper into a single vector. hister counts
      # approximate word-tokens and keeps 5% headroom; Gemma's 262k vocab
      # splits words less than Qwen's BPE did, so this is roughly ~1100 real
      # tokens.
      max_context_length = 1024;
      chunk_overlap = 128;
      max_embedding_batch_size = 8;
      max_embedding_concurrency = 2;
      # Model-card "SearchQuery" template. Its document side is
      # "title: {title} | text: {content}", but hister already writes
      # "title: …\nlanguage: …\ncontent:\n…" on every chunk, which is close
      # enough, so no document prefix is added.
      query_prefix = "task: search result | query: ";
      document_prefix = "";
      # Gemma scores sit higher than Qwen3's: measured with hister-shaped
      # inputs, related query/chunk pairs land around 0.73–0.77 and unrelated
      # ones around 0.45–0.55, so the old 0.5 would let in nearly everything.
      similarity_threshold = 0.62;
      result_limit = 10;
      semantic_weight = 0.4;
    };
    hotkeys = {
      "alt+k" = "select_previous_result";
      "alt+j" = "select_next_result";
      "/" = "focus_search_input";
      enter = "open_result";
      "alt+enter" = "open_result_in_new_tab";
      "alt+o" = "open_query_in_search_engine";
      "alt+v" = "view_result_popup";
      tab = "autocomplete";
      "?" = "show_hotkeys";
    };
  };
in
{
  home.packages = with pkgs; [
    hister
  ];

  xdg.configFile."hister/config.yml".source = yamlFormat.generate "hister-config.yml" settings;

  systemd.user.services.hister = {
    Unit = {
      Description = "Hister - Web history listener";
      After = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hister}/bin/hister listen";
      # Declaratively creates ${stateDir} (systemd >= 250 honours this for user
      # units, resolving it under $XDG_STATE_HOME) so the databases have a home
      # without an activation script.
      StateDirectory = "hister";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
