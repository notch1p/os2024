(** Using native monitors to implement semaphores.
    @param x value of a semaphore

    @param mutex : ensure the atomicity of any semaphore operation

    @param x_positive : Condition on whether x is positive *)
type semaphore =
  { mutable x : int
  ; mutex : Mutex.t
  ; x_positive : Condition.t
  }

type t = semaphore

module Sem : sig
  (** make a semaphore with given value *)
  val mk : int -> t

  (** the {b P} operation*)
  val p_op : t -> unit

  (** the {b V} operation*)
  val v_op : t -> unit

  (** alias for [p_op] *)
  val ( ~+ ) : t -> unit

  (** alias for [v_op] *)
  val ( ~- ) : t -> unit
end
