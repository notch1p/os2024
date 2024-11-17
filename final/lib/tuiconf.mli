val bold : ('a, Format.formatter, unit, unit, unit, string) format6 -> 'a
val subtle : ('a, Format.formatter, unit, unit, unit, string) format6 -> 'a
val keyword : ('a, Format.formatter, unit, unit, unit, string) format6 -> 'a
val highlight : ('a, Format.formatter, unit, unit, unit, string) format6 -> 'a
val mint : ('a, Format.formatter, unit, unit, unit, string) format6 -> 'a

(** {b destructively} rotates an array.
    @param n positive for left rotation; negative otherwise *)
val rotate_inplace : 'a array -> int -> unit

val reverse_subarray : 'a array -> int -> int -> unit
val output_to : string array -> int ref -> ('a, unit, string, unit) format4 -> 'a
