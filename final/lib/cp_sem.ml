open Thread
open Sem

(* Shared buffer *)

let buffer_size = ref @@ Random.int_in_range ~min:10 ~max:50
let buffer = Queue.create ()
let buffer_mutex = Sem.mk 1
let delay_snd = ref 0.5
let logger, idx = Array.make 10 "", ref 0
let exiting = ref false
let empty_slots = Sem.mk !buffer_size
let full_slots = Sem.mk 0

let rec rotate_inplace arr n =
  let len = Array.length arr in
  if len = 0
  then ()
  else (
    let n =
      let m = n mod len in
      if m < 0 then m + len else m
    in
    if n = 0
    then ()
    else (
      reverse_subarray arr 0 (n - 1);
      reverse_subarray arr n (len - 1);
      reverse_subarray arr 0 (len - 1)))

and reverse_subarray arr i j =
  if i >= j
  then ()
  else (
    let temp = arr.(i) in
    arr.(i) <- arr.(j);
    arr.(j) <- temp;
    reverse_subarray arr (i + 1) (j - 1))
;;

let rec producer id =
  if !exiting
  then raise Thread.Exit
  else (
    let item = [%string "item_#$(string_of_int id)"] in
    let open Sem in
    ~-empty_slots;
    ~-buffer_mutex;
    Queue.add item buffer;
    if !idx < 9 then idx := !idx + 1 else rotate_inplace logger 1;
    let open Tuiconf in
    logger.(!idx)
    <- Format.sprintf
         "Producer %s produced, queue length = %s\n"
         (bold "%d" id)
         (mint "%d" @@ Queue.length buffer);
    ~+buffer_mutex;
    ~+full_slots;
    producer id)
;;

let rec consumer id =
  if !exiting
  then raise Thread.Exit
  else
    let open Sem in
    ~-full_slots;
    ~-buffer_mutex;
    let _ = Queue.take buffer in
    if !idx < 9 then idx := !idx + 1 else rotate_inplace logger 1;
    let open Tuiconf in
    logger.(!idx)
    <- Format.sprintf
         "Consumer %s consumed, queue length = %s\n"
         (bold "%d" id)
         (mint "%d" @@ Queue.length buffer);
    delay !delay_snd;
    ~+buffer_mutex;
    ~+empty_slots;
    consumer id
;;

let run () =
  exiting := false;
  Array.map_inplace (fun _ -> "") logger;
  for i = 0 to 4 do
    create producer (i + 1) |> ignore;
    create consumer (i + 1) |> ignore
  done
;;

let down () = delay_snd := Float.sub !delay_snd 0.5
let up () = delay_snd := Float.add 0.5 !delay_snd

let exit () =
  exiting := true;
  logger.(9) <- "Exiting...\n%!"
;;
