(* using monitor to implement semaphore... who would've thought*)

type semaphore =
  { mutable x : int
  ; mutex : Mutex.t
  ; x_positive : Condition.t
  }

type t = semaphore

module Sem = struct
  let mk x =
    if x < 0
    then invalid_arg "semaphore must be initialized w/ non-negatives"
    else { x; mutex = Mutex.create (); x_positive = Condition.create () }
  ;;

  let p_op s =
    match s with
    | { mutex; x_positive; _ } ->
      let open Mutex in
      let open Condition in
      (* r/w on semaphore should be atomic*)
      lock mutex;
      while s.x = 0 do
        (* wait until semaphore is positive *)
        wait x_positive mutex
      done;
      s.x <- s.x - 1;
      unlock mutex
  ;;

  let v_op s =
    match s with
    | { mutex; x_positive; _ } ->
      let open Mutex in
      let open Condition in
      lock mutex;
      s.x <- s.x + 1;
      (* A positive semaphore means there are resources left. Signal a thread *)
      signal x_positive;
      unlock mutex
  ;;

  let ( ~+ ) = v_op
  let ( ~- ) = p_op
end
