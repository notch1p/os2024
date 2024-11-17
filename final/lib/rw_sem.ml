open Thread
open Sem

let read_count = ref 0
let read_mutex = Sem.mk 1
let resource_access = Sem.mk 1
let delay_snd = ref 1.0
let exiting = ref false
let logger, idx = Array.make 20 "", ref 0

let rec reader id =
  if !exiting
  then raise Thread.Exit
  else
    let open Sem in
    let open Tuiconf in
    ~-read_mutex;
    read_count := !read_count + 1;
    output_to
      logger
      idx
      "[Reader %s]: %s\n"
      (bold "%s" id)
      (mint "acquired mutex on read_count");
    delay 0.1;
    output_to
      logger
      idx
      "[Reader %s]: reading, read_count = %s\n"
      (bold "%s" id)
      (mint "%d" !read_count);
    if !read_count = 1
    then (
      ~-resource_access;
      output_to
        logger
        idx
        "[Reader %s]: %s\n"
        (bold "%s" id)
        (highlight "first reader, locking file"));
    ~+read_mutex;
    delay !delay_snd;
    ~-read_mutex;
    output_to
      logger
      idx
      "[Reader %s]: %s\n"
      (bold "%s" id)
      (mint "finished, releasing mutex on read_count");
    delay 0.1;
    read_count := !read_count - 1;
    if !read_count = 0
    then (
      ~+resource_access;
      output_to
        logger
        idx
        "[Reader %s]: %s\n"
        (bold "%s" id)
        (highlight "last reader, unlocking file"));
    ~+read_mutex;
    delay !delay_snd;
    reader id
;;

let rec writer id =
  if !exiting
  then raise Thread.Exit
  else
    let open Sem in
    let open Tuiconf in
    ~-resource_access;
    output_to logger idx "[Writer %s]: awakened\n" (bold "%s" id);
    output_to logger idx "[Writer %s]: %s\n" (bold "%s" id) (mint "acquired lock on file");
    output_to logger idx "[Writer %s]: writing\n" (bold "%s" id);
    delay !delay_snd;
    output_to logger idx "[Writer %s]: finished, releasing lock on file\n" (bold "%s" id);
    ~+resource_access;
    delay !delay_snd;
    writer id
;;

let run () =
  exiting := false;
  Array.map_inplace (fun _ -> "") logger;
  for i = 0 to 4 do
    let is = string_of_int @@ (i + 1) in
    create reader is |> ignore
  done;
  for i = 0 to 1 do
    let is = string_of_int @@ (i + 1) in
    create writer is |> ignore
  done
;;

let down () = if !delay_snd > 0.0 then delay_snd := !delay_snd -. 0.5
let up () = delay_snd := !delay_snd +. 0.5
let exit () = exiting := true
