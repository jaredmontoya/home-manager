{ writeScript, }:

writeScript "capture-foreign-env.nu" # nu
''
  def capture-foreign-env [
    --shell (-s): string = /bin/sh
    --arguments (-a): list<string> = []
  ] {
    let script_contents = $in;
    let env_out = with-env { SCRIPT_TO_SOURCE: $script_contents } {
      ^$shell ...$arguments -c `
      env -0
      echo -n '<ENV_CAPTURE_EVAL_FENCE>'
      eval "$SCRIPT_TO_SOURCE"
      echo -n '<ENV_CAPTURE_EVAL_FENCE>'
      env -0 -u _ -u _AST_FEATURES -u SHLVL`
    }
    | split row '<ENV_CAPTURE_EVAL_FENCE>'
    | {
      before: ($in | first | str trim --char (char -i 0) | split row (char -i 0))
      after: ($in | last | str trim --char (char -i 0) | split row (char -i 0))
    }

    $env_out.after
    | where { |line| $line not-in $env_out.before } # Only get changed lines
    | parse "{key}={value}"
    | transpose --header-row --as-record
  }
''
