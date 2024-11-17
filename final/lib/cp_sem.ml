open Thread
open Sem

(* Shared buffer *)

let buffer_size = ref @@ Random.int_in_range ~min:10 ~max:50
let buffer = Queue.create ()
let buffer_mutex = Sem.mk 1
let delay_snd = ref 1.0
let logger, idx = Array.make 20 "", ref 0
let exiting = ref false
let empty_slots = Sem.mk !buffer_size
let full_slots = Sem.mk 0

let rec producer id =
  if !exiting
  then raise Thread.Exit
  else (
    let item = [%string "item_#$(id)"] in
    let open Sem in
    ~-empty_slots;
    ~-buffer_mutex;
    let open Tuiconf in
    output_to logger idx "[Producer %s]: awakened\n" (bold "%s" id);
    output_to logger idx "[Producer %s]: buffer is not full\n" (bold "%s" id);
    output_to
      logger
      idx
      "[Producer %s]: %s\n"
      (bold "%s" id)
      (mint "acquired mutex on buffer, producing");
    Queue.add item buffer;
    delay 0.2;
    output_to
      logger
      idx
      "[Producer %s]: produced, queue length = %s\n"
      (bold "%s" id)
      (mint "%d" @@ Queue.length buffer);
    delay !delay_snd;
    output_to logger idx "[Producer %s]: leaving\n" (bold "%s" id);
    ~+buffer_mutex;
    ~+full_slots;
    (producer [@tailcall]) @@ id)
;;

let rec consumer id =
  if !exiting
  then raise Thread.Exit
  else
    let open Sem in
    ~-full_slots;
    ~-buffer_mutex;
    let open Tuiconf in
    output_to logger idx "[Consumer %s]: awakened\n" (bold "%s" id);
    output_to logger idx "[Consumer %s]: buffer is not empty\n" (bold "%s" id);
    output_to
      logger
      idx
      "[Consumer %s]: %s\n"
      (bold "%s" id)
      (mint "acquired mutex on buffer, consuming");
    Queue.take buffer |> ignore;
    delay 0.2;
    output_to
      logger
      idx
      "[Consumer %s]: consumed, queue length = %s\n"
      (bold "%s" id)
      (mint "%d" @@ Queue.length buffer);
    delay !delay_snd;
    output_to logger idx "[Consumer %s]: leaving\n" (bold "%s" id);
    ~+buffer_mutex;
    ~+empty_slots;
    (consumer [@tailcall]) @@ id
;;

let run () =
  exiting := false;
  Array.map_inplace (fun _ -> "") logger;
  for i = 0 to 4 do
    let is = string_of_int @@ (i + 1) in
    create producer is |> ignore;
    create consumer is |> ignore
  done
;;

let down () = if !delay_snd > 0.0 then delay_snd := !delay_snd -. 0.5
let up () = delay_snd := !delay_snd +. 0.5
let exit () = exiting := true
