open Thread
open Sem

let read_count = ref 0
let read_mutex = Sem.mk 1
let resource_access = Sem.mk 1
let delay_snd = ref 0.5
let exiting = ref false
let logger, idx = Array.make 10 "", ref 0

let rec reader id =
  if !exiting
  then raise Thread.Exit
  else
    let open Sem in
    let open Tuiconf in
    ~-read_mutex;
    read_count := !read_count + 1;
    if !idx < 9 then idx := !idx + 1 else Cp_sem.rotate_inplace logger 1;
    logger.(!idx) <- Format.sprintf "Reader %s is reading\n" (bold "%d" id);
    if !read_count = 1 then ~-resource_access;
    ~+read_mutex;
    delay !delay_snd;
    ~-read_mutex;
    read_count := !read_count - 1;
    if !read_count = 0 then ~+resource_access;
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
    if !idx < 9 then idx := !idx + 1 else Cp_sem.rotate_inplace logger 1;
    logger.(!idx) <- Format.sprintf "Writer %s is writing\n" (bold "%d" id);
    delay !delay_snd;
    ~+resource_access;
    delay !delay_snd;
    writer id
;;

let run () =
  exiting := false;
  Array.map_inplace (fun _ -> "") logger;
  for i = 0 to 4 do
    create reader (i + 1) |> ignore
  done;
  for i = 0 to 2 do
    create writer (i + 1) |> ignore
  done
;;

let down () = delay_snd := Float.sub !delay_snd 0.5
let up () = delay_snd := Float.add 0.5 !delay_snd

let exit () =
  exiting := true;
  logger.(9) <- "Exiting...\n%!"
;;
