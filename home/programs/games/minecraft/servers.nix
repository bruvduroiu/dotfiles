# Declarative Minecraft Server List
# Generates servers.dat (NBT format) from Nix configuration
{ pkgs, lib, ... }:

let
  # Define your servers here
  servers = [
    {
      name = "Home Server";
      ip = "tthome.tail6c0d62.ts.net";
      # hideAddress = false;  # Optional: hide IP in UI
      # acceptTextures = 1;   # Optional: 0=prompt, 1=enabled, 2=disabled
    }
  ];

  # Python script to generate servers.dat using nbtlib
  generateServersDat = pkgs.writers.writePython3Bin "generate-servers-dat" {
    libraries = [ pkgs.python3Packages.nbtlib ];
  } ''
    import sys
    import json
    from nbtlib import File, Compound, List, String, Byte

    servers_json = sys.argv[1]
    output_path = sys.argv[2]

    servers = json.loads(servers_json)

    server_list = List[Compound]([
        Compound({
            'name': String(s['name']),
            'ip': String(s['ip']),
            'hideAddress': Byte(s.get('hideAddress', 0)),
            **({"acceptTextures": Byte(s['acceptTextures'])}
               if 'acceptTextures' in s else {})
        })
        for s in servers
    ])

    nbt_file = File({'servers': server_list})
    nbt_file.save(output_path, gzipped=False)
    print(f"Generated {output_path} with {len(servers)} server(s)")
  '';

  # JSON representation of servers for the script
  serversJson = builtins.toJSON servers;

in {
  inherit servers generateServersDat serversJson;

  # Setup script fragment to generate servers.dat
  setupScript = ''
    SERVERS_DAT="$INSTANCE_DIR/.minecraft/servers.dat"
    
    # Only generate if servers.dat doesn't exist (preserve user additions)
    if [ ! -f "$SERVERS_DAT" ]; then
      echo "Generating servers.dat..."
      ${generateServersDat}/bin/generate-servers-dat '${serversJson}' "$SERVERS_DAT"
    else
      echo "servers.dat exists, skipping (delete to regenerate)"
    fi
  '';
}
