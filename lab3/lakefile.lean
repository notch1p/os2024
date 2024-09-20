import Lake
open Lake DSL

package "lab3" where
  -- add package configuration options here

lean_lib «Lab3» where
  -- add library configuration options here

@[default_target]
lean_exe "lab3" where
  root := `Main
