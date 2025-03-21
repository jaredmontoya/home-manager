{ pkgs, config, ... }:

{
  programs = {
    nix-your-shell = {
      enable = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };
    fish.enable = true;
    nushell.enable = true;
    zsh.enable = true;
  };

  nmt.script = let
    nushellConfigDir = if pkgs.stdenv.isDarwin && !config.xdg.enable then
      "home-files/Library/Application Support/nushell"
    else
      "home-files/.config/nushell";
  in ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@nix-your-shell@/bin/nix-your-shell fish | source'

    assertFileExists ${nushellConfigDir}/config.nu
    assertFileRegex \
      ${nushellConfigDir}/config.nu \
      'source .*nix-your-shell-nushell-config'

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      '@nix-your-shell@/bin/nix-your-shell zsh | source /dev/stdin'
  '';
}
