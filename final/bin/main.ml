open Minttea
open Final
open Leaves

type screen =
  | Cp
  | Rw
  | Menu

type model =
  { choices : string list
  ; cursor : int
  ; running : bool
  ; buf : Text_input.t
  ; buf_activate : bool
  ; current : screen
  ; spinner : Sprite.t
  }

let initial_model =
  { cursor = 0
  ; choices = [ "Run Consumer-Producer Demo"; "Run Reader-Writer Demo"; "Exit" ]
  ; running = false
  ; buf = Text_input.make "" ()
  ; buf_activate = false
  ; current = Menu
  ; spinner = Spinner.moon
  }
;;

let init _model = Command.Noop

let choose model = function
  | 0 ->
    let _ = Domain.spawn Cp_sem.run in
    { model with running = true; current = Cp }, Command.Enter_alt_screen
  | 1 ->
    let _ = Domain.spawn Rw_sem.run in
    { model with running = true; current = Rw }, Command.Enter_alt_screen
  | 2 -> model, Command.Quit
  | _ -> model, Command.Noop
;;

let return model =
  match model.current with
  | Menu -> model, Command.Quit
  | Cp ->
    let _ = Cp_sem.exit () in
    { model with current = Menu; running = false }, Command.Exit_alt_screen
  | Rw ->
    let _ = Rw_sem.exit () in
    { model with current = Menu; running = false }, Command.Exit_alt_screen
;;

(* it's a mess. truly spaghetti *)
let update event model =
  match event with
  | Event.Frame now ->
    let spinner = model.spinner in
    { model with spinner = Sprite.update ~now spinner }, Command.Noop
  | Event.KeyDown (Key "q" | Escape) -> return model
  | Event.KeyDown (Key "k") ->
    let cursor =
      if model.cursor = 0 then List.length model.choices - 1 else model.cursor - 1
    in
    { model with cursor }, Command.Noop
  | Event.KeyDown (Key "j") ->
    let cursor =
      if model.cursor = List.length model.choices - 1 then 0 else model.cursor + 1
    in
    { model with cursor }, Command.Noop
  | Event.KeyDown Down ->
    (match model.current with
     | Cp ->
       Cp_sem.down ();
       model, Command.Noop
     | Rw ->
       Rw_sem.down ();
       model, Command.Noop
     | _ ->
       let cursor =
         if model.cursor = List.length model.choices - 1 then 0 else model.cursor + 1
       in
       { model with cursor }, Command.Noop)
  | Event.KeyDown Up ->
    (match model.current with
     | Cp ->
       Cp_sem.up ();
       model, Command.Noop
     | Rw ->
       Rw_sem.up ();
       model, Command.Noop
     | _ ->
       let cursor =
         if model.cursor = List.length model.choices - 1 then 0 else model.cursor - 1
       in
       { model with cursor }, Command.Noop)
  | Event.KeyDown (Key "b") ->
    let toggle_buf model =
      match model.current, model.buf_activate with
      | Cp, true -> { model with buf_activate = false }, Command.Hide_cursor
      | Cp, false -> { model with buf_activate = true }, Command.Show_cursor
      | _, _ -> model, Command.Show_cursor
    in
    toggle_buf model
  | e ->
    (match e with
     | Event.KeyDown Enter ->
       if not model.running
       then choose model model.cursor
       else (
         match model.current with
         | Cp ->
           let _ =
             Cp_sem.buffer_size
             := let buf = Text_input.current_text model.buf in
                if buf = "" then !Cp_sem.buffer_size else int_of_string buf
           in
           { model with buf_activate = false }, Command.Hide_cursor
         | _ -> { model with buf_activate = false }, Command.Hide_cursor)
     | _ ->
       let buf = Text_input.update model.buf e in
       { model with buf }, Command.Noop)
;;

let view model =
  if model.running
  then
    let open Tuiconf in
    let logger =
      Array.mapi
        (fun ix e -> if e = "" then "" else Format.sprintf "%s%d\t%s" (bold "|") ix e)
        (match model.current with
         | Cp -> Cp_sem.logger
         | Rw -> Rw_sem.logger
         | _ -> failwith "invalid state")
    in
    let msg = Format.sprintf "%s" @@ Array.fold_left ( ^ ) "" logger in
    Format.sprintf
      {|
%s   Running %s:
  %s
  %s

==========================

%s
==========================

%s

Keybinds:

  %s to adjust delay; 
  %s to enter new buffer size (if available); 
  %s to kill this demo and return 1 level up.
  |}
      (Tuiconf.mint "%s" @@ Sprite.view model.spinner)
      (if model.current = Cp then Tuiconf.bold "Consumer-Producer" else "Reader-Writer")
      (if model.current = Cp
       then [%string "Buffer size = $(string_of_int !Cp_sem.buffer_size)"]
       else "")
      (if model.current = Cp
       then Format.sprintf "Delay = %.1f" !Cp_sem.delay_snd
       else Format.sprintf "Delay = %.1f" !Rw_sem.delay_snd)
      msg
      (if model.buf_activate then Text_input.view model.buf else "")
      (Tuiconf.keyword "Arrow Up/Down")
      (Tuiconf.keyword "b")
      (Tuiconf.keyword "q")
  else (
    (* we create our options by mapping over them *)
    let options =
      model.choices
      |> List.mapi (fun idx name ->
        if model.cursor = idx
        then Tuiconf.highlight "%s" (Format.sprintf "> %s" name)
        else Format.sprintf "  %s" name)
      |> String.concat "\n"
    in
    (* and we send the UI for rendering! *)
    Format.sprintf
      {|
What to do ?

%s

Navigate with j/k/up/down; q to quit; Return to confirm selection.
  
|}
      options)
;;

let app = Minttea.app ~init ~update ~view ()
let () = Minttea.start app ~initial_model
