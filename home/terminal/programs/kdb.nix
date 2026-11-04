{ pkgs, ... }:

let
  # Run any command against hetzner-1's Postgres cluster, as the
  # `cluster_admin` role, through an SSH tunnel that lives exactly as long as the
  # command:
  #
  #   kdb pgcli            libpq tools read the exported PG* variables
  #   kdb lazysql          gets the connection URL appended
  #   kdb psql @url        @url in any argument expands to it (not {url}:
  #                        fish brace-expands that to a bare "url")
  #   kdb -d postgres …    pick the database (default: kratos)
  #
  # The forward rides the shared /tmp/claude-<uid> ControlMaster (one YubiKey
  # touch per 4h, shared with agent sessions) and is cancelled on exit; the
  # master itself stays up. `-L 0:` is rejected by mux clients, hence the scan
  # for a free local port.
  #
  # Postgres wants a password on the loopback. KDB_PASSWORD_FILE names a file
  # holding it, so it is passed by reference, never typed into a command line;
  # framework13 points it at the hetzner1_pg_admin_password sops secret.
  kdb = pkgs.writeShellApplication {
    name = "kdb";
    runtimeInputs = with pkgs; [
      openssh
      iproute2 # ss
      coreutils
      jq # URL-encode the password
      lazysql
      pgcli
      postgresql # psql
    ];
    text = ''
      host=root@88.198.180.41
      port=2222
      sock="/tmp/claude-$(id -u)/hetzner-1.sock"
      user=cluster_admin
      db=kratos

      usage() {
        echo "usage: kdb [-d database] <command> [args...]   (@url expands to the connection URL)" >&2
        exit 2
      }
      while getopts d: opt; do
        case $opt in
          d) db=$OPTARG ;;
          *) usage ;;
        esac
      done
      shift $((OPTIND - 1))
      [ $# -gt 0 ] || usage

      [ -d "''${sock%/*}" ] || mkdir -m 0700 "''${sock%/*}"
      ssh -S "$sock" -O check -p "$port" "$host" 2>/dev/null \
        || ssh -M -S "$sock" -o ControlPersist=4h -p "$port" -fN "$host"

      lport=""
      for p in $(seq 15432 15531); do
        if ! ss -Hltn "sport = :$p" | grep -q .; then lport=$p; break; fi
      done
      [ -n "$lport" ] || { echo "kdb: no free local port in 15432-15531" >&2; exit 1; }

      fwd="$lport:127.0.0.1:5432"
      ssh -S "$sock" -O forward -p "$port" -L "$fwd" "$host"
      trap 'ssh -S "$sock" -O cancel -p "$port" -L "$fwd" "$host" 2>/dev/null' EXIT

      export PGHOST=127.0.0.1 PGPORT=$lport PGUSER=$user PGDATABASE=$db PGSSLMODE=disable
      auth=$user
      if [ -n "''${KDB_PASSWORD_FILE:-}" ]; then
        PGPASSWORD="$(cat "$KDB_PASSWORD_FILE")"
        export PGPASSWORD
        auth="$user:$(printf %s "$PGPASSWORD" | jq -sRr @uri)"
      fi
      url="postgres://$auth@127.0.0.1:$lport/$db?sslmode=disable"

      if [ $# -eq 1 ] && [ "$1" = lazysql ]; then set -- lazysql @url; fi
      args=()
      for a in "$@"; do args+=("''${a//@url/$url}"); done
      "''${args[@]}"
    '';
  };
in
{
  home.packages = [ kdb ];
}
