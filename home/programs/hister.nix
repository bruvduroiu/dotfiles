{ config, pkgs, ... }:

let
  conf = config.xdg.configHome;
  home = config.home.homeDirectory;
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
      database = "${home}/Documents/hister.db";
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
    # Octen-Embedding-0.6B, a Qwen3-Embedding-0.6B fine-tune, served on the LAN.
    semantic_search = {
      enable = true;
      embedding_endpoint = "http://192.168.1.193:11434/v1/embeddings";
      embedding_model = "octen-embedding-0.6b";
      embedding_timeout = 300;
      # 0.6B variant: 1024-dim vectors (the 4B/8B are 2560/4096).
      dimensions = 1024;
      # Chunk size, not model capacity: the model accepts 32k, but a chunk that
      # large collapses a whole paper into a single vector. hister counts
      # approximate word-tokens (a word or punctuation mark each, so ~1.3x fewer
      # than Qwen3's BPE) and keeps 5% headroom, putting this near ~1250 real
      # tokens per chunk.
      max_context_length = 1024;
      chunk_overlap = 128;
      max_embedding_batch_size = 8;
      max_embedding_concurrency = 2;
      # Qwen3-Embedding is instruction-tuned on the query side only. Documents
      # are embedded bare, apart from the "- " prefix Octen recommends to dodge
      # the upstream Qwen3 unprefixed-document bug.
      query_prefix = "Instruct: Given a search query, retrieve relevant passages that answer the query\nQuery: ";
      document_prefix = "- ";
      similarity_threshold = 0.5;
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
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
