open Thread
open Sem

(** 共享缓冲区大小. 10 ~ 50 *)
let buffer_size = ref @@ Random.int_in_range ~min:10 ~max:50

(** 共享缓冲区, 用队列模拟 *)
let buffer = Queue.create ()

(** 缓冲区互斥锁, 某一时刻只能有一个生产者/消费者修改缓冲区 *)
let buffer_mutex = Sem.mk 1

let delay_snd = ref 1.0
let logger, idx = Array.make 20 "", ref 0
let exiting = ref false

(** 记录型信号量: 表示缓冲区有多少空位可供生产者用于生产, 是同步锁 *)
let empty_slots = Sem.mk !buffer_size

(** 记录型信号量: 表示缓冲区有多少位置可供消费者消费, 是同步锁 *)
let full_slots = Sem.mk 0

(* 这里我们设置 empty_slots = n; full_slots = 0, 表明缓冲区一开始没有任何产品, 因此生产者最先运行. 而反过来设置 `(empty_slots, full_slots) = 0, n` 也是可以的. *)

let rec producer id =
  if !exiting
  then raise Thread.Exit
  else (
    let item = [%string "item_#$(id)"] in
    let open Sem in
    (* 先后对同步锁, 互斥锁上锁, 表示生产者对缓冲区的独占. 反过来会造成死锁. *)
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
    (* 模拟生产者生产 *)
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
    (* 生产完毕, 先后释放互斥锁, 同步锁 *)
    ~+buffer_mutex;
    ~+full_slots;
    (producer [@tailcall]) @@ id)
;;

let rec consumer id =
  if !exiting
  then raise Thread.Exit
  else
    let open Sem in
    (* 表示消费者对缓冲区的独占. *)
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
    (* 模拟消费者消费 *)
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
    (* 消费完毕 *)
    ~+buffer_mutex;
    ~+empty_slots;
    (consumer [@tailcall]) @@ id
;;

let run () =
  buffer_size := Random.int_in_range ~min:10 ~max:50;
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
