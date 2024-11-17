let dark_gray = Spices.color "#767676"
let bold fmt = Spices.(default |> bold true |> build) fmt
let dot = Spices.(default |> fg (color "236") |> build) " • "
let subtle fmt = Spices.(default |> fg (color "241") |> build) fmt
let keyword fmt = Spices.(default |> fg (color "211") |> build) fmt
let highlight fmt = Spices.(default |> fg (color "#FF06B7") |> build) fmt
let mint fmt = Spices.(default |> fg (color "#77e5b7") |> build) fmt

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

let output_to logger idx fmt =
  Thread.delay 0.1;
  (* I sure love hardcoding *)
  Format.ksprintf
    (fun str ->
      if !idx < Array.length logger - 1 then idx := !idx + 1 else rotate_inplace logger 1;
      logger.(!idx) <- str)
    fmt
;;
