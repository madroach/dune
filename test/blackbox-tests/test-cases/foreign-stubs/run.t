----------------------------------------------------------------------------------
Testsuite for the (foreign_stubs ...) field.

  $ cat >sdune <<'EOF'
  > #!/usr/bin/env bash
  > DUNE_SANDBOX=symlink dune "$@"
  > EOF
  $ chmod +x sdune

----------------------------------------------------------------------------------
* Error when using both (self_build_stubs_archive ...) and (c_names ...) before 2.0.

  $ echo "(lang dune 1.0)" > dune-project

  $ cat >dune <<EOF
  > (library
  >  (name foo)
  >  (c_names foo)
  >  (self_build_stubs_archive (bar)))
  > EOF

  $ ./sdune build
  File "dune", line 4, characters 1-33:
  4 |  (self_build_stubs_archive (bar)))
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: A library cannot use (self_build_stubs_archive ...) and (c_names ...)
  simultaneously. This is supported starting from Dune 2.0.
  [1]

----------------------------------------------------------------------------------
* Error when using (c_names ...) in (library ...) in Dune 2.0.

  $ echo "(lang dune 2.0)" > dune-project

  $ ./sdune build
  File "dune", line 3, characters 1-14:
  3 |  (c_names foo)
       ^^^^^^^^^^^^^
  Error: 'c_names' was deleted in version 2.0 of the dune language. Use the
  (foreign_stubs ...) field instead.
  [1]

----------------------------------------------------------------------------------
* Error when using (c_names ...) in (executable ...) in Dune 2.0.

  $ cat >dune <<EOF
  > (executable
  >  (name foo)
  >  (c_names bar))
  > EOF

  $ ./sdune build
  File "dune", line 3, characters 2-9:
  3 |  (c_names bar))
        ^^^^^^^
  Error: Unknown field c_names
  [1]

----------------------------------------------------------------------------------
* Error when using (self_build_stubs_archive ...) in (library ...) in Dune 2.0.

  $ cat >dune <<EOF
  > (library
  >  (name foo)
  >  (foreign_stubs (language c) (names foo))
  >  (self_build_stubs_archive (bar)))
  > EOF

  $ ./sdune build
  File "dune", line 4, characters 1-33:
  4 |  (self_build_stubs_archive (bar)))
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: 'self_build_stubs_archive' was deleted in version 2.0 of the dune
  language. Use the (foreign_archives ...) field instead.
  [1]

----------------------------------------------------------------------------------
* Error when using (self_build_stubs_archive ...) in (executable ...) in Dune 2.0.

  $ cat >dune <<EOF
  > (executable
  >  (name foo)
  >  (foreign_stubs (language c) (names bar))
  >  (self_build_stubs_archive (baz)))
  > EOF

  $ ./sdune build
  File "dune", line 4, characters 2-26:
  4 |  (self_build_stubs_archive (baz)))
        ^^^^^^^^^^^^^^^^^^^^^^^^
  Error: Unknown field self_build_stubs_archive
  [1]

----------------------------------------------------------------------------------
* Error when a C source file is missing.

  $ cat >dune <<EOF
  > (library
  >  (name foo)
  >  (foreign_stubs (language c) (names foo))
  >  (foreign_archives bar))
  > EOF

  $ ./sdune build
  File "dune", line 3, characters 36-39:
  3 |  (foreign_stubs (language c) (names foo))
                                          ^^^
  Error: Object "foo" has no source; "foo.c" must be present.
  [1]

----------------------------------------------------------------------------------
* Error when a self-built archive is missing.

  $ cat >foo.c <<EOF
  > #include <caml/mlvalues.h>
  > value foo(value unit) { return Val_int(9); }
  > EOF

  $ ./sdune build
  Error: No rule found for libbar$ext_lib
  [1]

----------------------------------------------------------------------------------
* Build succeeds when a self-built archive exists.

  $ cat >bar.c <<EOF
  > #include <caml/mlvalues.h>
  > value bar(value unit) { return Val_int(10); }
  > EOF

  $ cat >dune <<EOF
  > (library
  >  (name foo)
  >  (foreign_stubs (language c) (names foo))
  >  (foreign_archives bar))
  > (rule
  >  (targets bar%{ext_obj})
  >  (deps bar.c)
  >  (action (run %{ocaml-config:c_compiler} -c -I %{ocaml-config:standard_library} -o %{targets} %{deps})))
  > (rule
  >  (targets libbar.a)
  >  (deps bar%{ext_obj})
  >  (action (run ar rcs %{targets} %{deps})))
  > EOF

  $ ./sdune build

----------------------------------------------------------------------------------
* Error when specifying an (archive_name ...) in (foreign_stubs ...) stanza.

  $ cat >dune <<EOF
  > (library
  >  (name foo)
  >  (foreign_stubs (archive_name baz) (language c) (names foo))
  >  (foreign_archives bar))
  > (rule
  >  (targets bar%{ext_obj})
  >  (deps bar.c)
  >  (action (run %{ocaml-config:c_compiler} -c -I %{ocaml-config:standard_library} -o %{targets} %{deps})))
  > (rule
  >  (targets libbar_stubs.a)
  >  (deps bar%{ext_obj})
  >  (action (run ar rcs %{targets} %{deps})))
  > EOF

  $ ./sdune build
  File "dune", line 3, characters 16-34:
  3 |  (foreign_stubs (archive_name baz) (language c) (names foo))
                      ^^^^^^^^^^^^^^^^^^
  Error: The field "archive_name" is not allowed in the (foreign_stubs ...)
  stanza. For named foreign archives use the (foreign_library ...) stanza.
  [1]

----------------------------------------------------------------------------------
* Foreign stubs in C and C++ language.
* Multiple foreign stub archives.

  $ cat >baz.cpp <<EOF
  > #include <caml/mlvalues.h>
  > extern "C" value baz(value unit) { return Val_int(0); }
  > EOF

  $ cat >qux.cpp <<EOF
  > #include <caml/mlvalues.h>
  > extern "C" value qux(value unit) { return Val_int(2000); }
  > EOF

  $ cat >quad.ml <<EOF
  > external foo : unit -> int = "foo"
  > external bar : unit -> int = "bar"
  > external baz : unit -> int = "baz"
  > external qux : unit -> int = "qux"
  > let quad x = foo x + bar x + baz x + qux x
  > EOF

  $ cat >quad.mli <<EOF
  > val quad : unit -> int
  > EOF

  $ cat >main.ml <<EOF
  > let () = Printf.printf "%d" (Quad.quad ())
  > EOF

  $ cat >dune <<EOF
  > (library
  >  (name quad)
  >  (modules quad)
  >  (foreign_stubs (language c) (names foo))
  >  (foreign_archives bar qux)
  >  (foreign_stubs (language cxx) (names baz)))
  > (rule
  >  (targets bar%{ext_obj})
  >  (deps bar.c)
  >  (action (run %{ocaml-config:c_compiler} -c -I %{ocaml-config:standard_library} -o %{targets} %{deps})))
  > (rule
  >  (targets libbar.a)
  >  (deps bar%{ext_obj})
  >  (action (run ar rcs %{targets} %{deps})))
  > (rule
  >  (targets dllbar%{ext_dll})
  >  (deps bar%{ext_obj})
  >  (action (run %{ocaml-config:c_compiler} -shared -o %{targets} %{deps})))
  > (rule
  >  (targets qux%{ext_obj})
  >  (deps qux.cpp)
  >  (action (run %{ocaml-config:c_compiler} -c -I %{ocaml-config:standard_library} -o %{targets} %{deps})))
  > (rule
  >  (targets libqux.a)
  >  (deps qux%{ext_obj})
  >  (action (run ar rcs %{targets} %{deps})))
  > (rule
  >  (targets dllqux%{ext_dll})
  >  (deps qux%{ext_obj})
  >  (action (run %{ocaml-config:c_compiler} -shared -o %{targets} %{deps})))
  > (executable
  >  (name main)
  >  (libraries quad)
  >  (modules main))
  > EOF

  $ rm -rf _build
  $ ./sdune build

  $ ./sdune exec ./main.exe
  2019

  $ (cd _build/default && ocamlrun -I . ./main.bc)
  2019

----------------------------------------------------------------------------------
* Unused foreign sources are ignored.

  $ touch foo.cpp
  $ touch foo.cxx

  $ ./sdune build

----------------------------------------------------------------------------------
* Fails when (extra_deps ...) is missing

  $ cat >foo.c <<EOF
  > #include <caml/mlvalues.h>
  > #include "eight.h"
  > value foo(value unit) { return Val_int(1 + EIGHT); }
  > EOF

  $ ./sdune build 2> /dev/null
  [1]

----------------------------------------------------------------------------------
* Succeeds when (extra_deps ...) is present

  $ cat >eight.h <<EOF
  > #define EIGHT 8
  > EOF

  $ cat >dune <<EOF
  > (library
  >  (name quad)
  >  (modules quad)
  >  (foreign_stubs (language c) (names foo) (extra_deps eight.h))
  >  (foreign_archives bar qux)
  >  (foreign_stubs (language cxx) (names baz)))
  > (rule
  >  (targets bar%{ext_obj})
  >  (deps bar.c)
  >  (action (run %{ocaml-config:c_compiler} -c -I %{ocaml-config:standard_library} -o %{targets} %{deps})))
  > (rule
  >  (targets libbar.a)
  >  (deps bar%{ext_obj})
  >  (action (run ar rcs %{targets} %{deps})))
  > (rule
  >  (targets dllbar%{ext_dll})
  >  (deps bar%{ext_obj})
  >  (action (run %{ocaml-config:c_compiler} -shared -o %{targets} %{deps})))
  > (rule
  >  (targets qux%{ext_obj})
  >  (deps qux.cpp)
  >  (action (run %{ocaml-config:c_compiler} -c -I %{ocaml-config:standard_library} -o %{targets} %{deps})))
  > (rule
  >  (targets libqux.a)
  >  (deps qux%{ext_obj})
  >  (action (run ar rcs %{targets} %{deps})))
  > (rule
  >  (targets dllqux%{ext_dll})
  >  (deps qux%{ext_obj})
  >  (action (run %{ocaml-config:c_compiler} -shared -o %{targets} %{deps})))
  > (executable
  >  (name main)
  >  (libraries quad)
  >  (modules main))
  > EOF

  $ ./sdune exec ./main.exe
  2019

  $ (cd _build/default && ocamlrun -I . ./main.bc)
  2019

----------------------------------------------------------------------------------
* Fails when (include_dirs ...) is missing

  $ cat >foo.c <<EOF
  > #include <caml/mlvalues.h>
  > #include "eight.h"
  > #include "another/dir/one.h"
  > value foo(value unit) { return Val_int(ONE + EIGHT); }
  > EOF

  $ ./sdune build 2> /dev/null
  [1]

----------------------------------------------------------------------------------
* Succeeds when (include_dirs ...) is present

  $ mkdir -p another/dir
  $ cat >another/dir/one.h <<EOF
  > #define ONE 1
  > EOF

  $ cat >dune <<EOF
  > (library
  >  (name quad)
  >  (modules quad)
  >  (foreign_stubs (language c) (names foo) (extra_deps eight.h) (include_dirs another/dir))
  >  (foreign_archives bar qux)
  >  (foreign_stubs (language cxx) (names baz)))
  > (rule
  >  (targets bar%{ext_obj})
  >  (deps bar.c)
  >  (action (run %{ocaml-config:c_compiler} -c -I %{ocaml-config:standard_library} -o %{targets} %{deps})))
  > (rule
  >  (targets libbar.a)
  >  (deps bar%{ext_obj})
  >  (action (run ar rcs %{targets} %{deps})))
  > (rule
  >  (targets dllbar%{ext_dll})
  >  (deps bar%{ext_obj})
  >  (action (run %{ocaml-config:c_compiler} -shared -o %{targets} %{deps})))
  > (rule
  >  (targets qux%{ext_obj})
  >  (deps qux.cpp)
  >  (action (run %{ocaml-config:c_compiler} -c -I %{ocaml-config:standard_library} -o %{targets} %{deps})))
  > (rule
  >  (targets libqux.a)
  >  (deps qux%{ext_obj})
  >  (action (run ar rcs %{targets} %{deps})))
  > (rule
  >  (targets dllqux%{ext_dll})
  >  (deps qux%{ext_obj})
  >  (action (run %{ocaml-config:c_compiler} -shared -o %{targets} %{deps})))
  > (executable
  >  (name main)
  >  (libraries quad)
  >  (modules main))
  > EOF

  $ ./sdune exec ./main.exe
  2019

  $ (cd _build/default && ocamlrun -I . ./main.bc)
  2019

----------------------------------------------------------------------------------
* Fails when using standard names in foreign stubs due to multiple C++ sources

  $ cat >dune <<EOF
  > (library
  >  (name quad)
  >  (modules quad)
  >  (foreign_stubs (language cxx)))
  > EOF

  $ ./sdune build
  File "dune", line 4, characters 1-31:
  4 |  (foreign_stubs (language cxx)))
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: Multiple sources map to the same object name "foo":
  - foo.cpp
  - foo.cxx
  This is not allowed; please rename them or remove "foo" from object names.
  Hint: You can also avoid the name clash by placing the objects into different
  foreign archives and building them in different directories. Foreign archives
  can be defined using the (foreign_library ...) stanza.
  [1]

----------------------------------------------------------------------------------
* Succeeds when using a subset of standard names

  $ cat >dune <<EOF
  > (library
  >  (name quad)
  >  (modules quad)
  >  (foreign_stubs (language cxx) (names :standard \ foo)))
  > EOF

  $ ./sdune clean
  $ ./sdune build
