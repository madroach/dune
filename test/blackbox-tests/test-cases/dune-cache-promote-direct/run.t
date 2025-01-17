  $ cat > dune-project <<EOF
  > (lang dune 2.0)
  > EOF
  $ cat > dune <<EOF
  > (rule
  >   (deps source)
  >   (targets target)
  >   (action (bash "touch beacon ; cat source source > target")))
  > EOF
  $ cat > source <<EOF
  > \_o< COIN
  > EOF
  $ env DUNE_CACHE=1 DUNE_CACHE_MODE=direct DUNE_CACHE_EXIT_NO_CLIENT=1 XDG_RUNTIME_DIR=$PWD/.xdg-runtime XDG_CACHE_HOME=$PWD/.xdg-cache dune build target
  $ ./stat.sh --format=%h _build/default/source
  2
  $ ./stat.sh --format=%h _build/default/target
  2
  $ ls _build/default/beacon
  _build/default/beacon
  $ rm -rf _build/default
  $ env DUNE_CACHE=1 DUNE_CACHE_MODE=direct DUNE_CACHE_EXIT_NO_CLIENT=1 XDG_RUNTIME_DIR=$PWD/.xdg-runtime XDG_CACHE_HOME=$PWD/.xdg-cache dune build target
  $ ./stat.sh --format=%h _build/default/source
  2
  $ ./stat.sh --format=%h _build/default/target
  2
  $ test -e _build/default/beacon
  [1]
  $ cat _build/default/source
  \_o< COIN
  $ cat _build/default/target
  \_o< COIN
  \_o< COIN


  $ cat > dune-project <<EOF
  > (lang dune 2.0)
  > EOF
  $ cat > dune-v1 <<EOF
  > (rule
  >   (targets t1)
  >   (action (bash "echo running; echo v1 > t1")))
  > (rule
  >   (deps t1)
  >   (targets t2)
  >   (action (bash "echo running; cat t1 t1 > t2")))
  > EOF
  $ cat > dune-v2 <<EOF
  > (rule
  >   (targets t1)
  >   (action (bash "echo running; echo v2 > t1")))
  > (rule
  >   (deps t1)
  >   (targets t2)
  >   (action (bash "echo running; cat t1 t1 > t2")))
  > EOF
  $ cp dune-v1 dune
  $ env DUNE_CACHE=1 DUNE_CACHE_MODE=direct DUNE_CACHE_EXIT_NO_CLIENT=1 XDG_RUNTIME_DIR=$PWD/.xdg-runtime XDG_CACHE_HOME=$PWD/.xdg-cache dune build t2
          bash t1
  running
          bash t2
  running
  $ cat _build/default/t2
  v1
  v1
  $ cp dune-v2 dune
  $ env DUNE_CACHE=1 DUNE_CACHE_MODE=direct DUNE_CACHE_EXIT_NO_CLIENT=1 XDG_RUNTIME_DIR=$PWD/.xdg-runtime XDG_CACHE_HOME=$PWD/.xdg-cache dune build t2
          bash t1
  running
          bash t2
  running
  $ cat _build/default/t2
  v2
  v2
  $ cp dune-v1 dune
  $ env DUNE_CACHE=1 DUNE_CACHE_MODE=direct DUNE_CACHE_EXIT_NO_CLIENT=1 XDG_RUNTIME_DIR=$PWD/.xdg-runtime XDG_CACHE_HOME=$PWD/.xdg-cache dune build t2
  $ cat _build/default/t1
  v1
  $ cat _build/default/t2
  v1
  v1
