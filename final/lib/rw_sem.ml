open Thread
open Sem

(** 表示当前正在读取文件的读者数目. 对这个变量的操作须是原子性的 *)
let read_count = ref 0

(** 读者互斥锁, 对上面 [read_count] 的原子操作通过加这个锁实现 *)
let read_mutex = Sem.mk 1

(** 文件锁(也是互斥锁), 某一时刻内只能有读者/写者其中之一访问文件.
    同时只能有一个写者或多个读者访问文件. *)
let resource_access = Sem.mk 1

(** 线程延迟时间, 用于调整程序执行速度 *)
let delay_snd = ref 1.0

(** 控制线程是否退出 *)
let exiting = ref false

(** 输出缓冲和输出位移 *)
let logger, idx = Array.make 20 "", ref 0

let rec reader id =
  if !exiting
     (* OCaml 只允许结束当前线程 (即不能从一个线程结束其他的线程),
        通过设置 `exiting` flag 实现这一点 *)
  then raise Thread.Exit
  else
    let open Sem in
    let open Tuiconf in
    (* 加读者锁以便原子性修改 `read_count` *)
    ~-read_mutex;
    (* 关于 `read_count` 的原子性操作需要在读者锁内进行 *)
    read_count := !read_count + 1;
    output_to
      logger
      idx
      "[Reader %s]: awakened\n"
      (bold "%s" id);
    delay 0.1;
    if !read_count = 1
       (* 如果是第一个访问文件的读者, 则加文件锁.
          表示读者对文件的独占访问. 之后的读者可跳过这一步. *)
    then (
      ~-resource_access;
      output_to
        logger
        idx
        "[Reader %s]: %s\n"
        (bold "%s" id)
        (highlight "first reader, locking file"));
    (* 对 `read_count` 的修改结束, 释放读者锁 *)
    ~+read_mutex;
    output_to
      logger
      idx
      "[Reader %s]: reading, read_count = %s\n"
      (bold "%s" id)
      (mint "%d" !read_count);
    (* 这里的 `delay` 模拟读取所消耗的时间, 此时可以存在一个或多个读者读取文件 *)
    delay !delay_snd;
    (* 读完文件, 需要再次加读者锁, 修改 `read_count -= 1`, 表示读者减少了一个 *)
    ~-read_mutex;
    output_to
      logger
      idx
      "[Reader %s]: %s\n"
      (bold "%s" id)
      (mint "finished reading");
    delay 0.1;
    read_count := !read_count - 1;
    if !read_count = 0 (* 如果是最后一个读完的读者, 需要释放文件锁, 以便写者写文件 *)
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
    (* ML 系语言中更习惯用递归而不是迭代, 此处等效 `while(true)`
       `[@tailrec]` 显式地表明我们的递归是尾递归, 告诉编译器做 tailcall optimization *)
    (reader [@tailrec]) @@ id
;;

let rec writer id =
  if !exiting
  then raise Thread.Exit
  else
    let open Sem in
    let open Tuiconf in
    (* 加文件锁, 表示写者对文件的独占访问 *)
    ~-resource_access;
    output_to logger idx "[Writer %s]: awakened\n" (bold "%s" id);
    output_to logger idx "[Writer %s]: %s\n" (bold "%s" id) (mint "acquired lock on file");
    output_to logger idx "[Writer %s]: writing\n" (bold "%s" id);
    (* 模拟写文件 *)
    delay !delay_snd;
    output_to logger idx "[Writer %s]: finished, releasing lock on file\n" (bold "%s" id);
    (* 文件写完, 释放文件锁 *)
    ~+resource_access;
    delay !delay_snd;
    (writer [@tailrec]) @@ id
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
