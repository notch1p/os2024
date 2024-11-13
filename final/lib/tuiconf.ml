let dark_gray = Spices.color "#767676"
let bold fmt = Spices.(default |> bold true |> build) fmt

let time fmt =
  Spices.(default |> italic true |> fg dark_gray |> max_width 22 |> build) fmt
;;

let dot = Spices.(default |> fg (color "236") |> build) " • "
let subtle fmt = Spices.(default |> fg (color "241") |> build) fmt
let keyword fmt = Spices.(default |> fg (color "211") |> build) fmt
let highlight fmt = Spices.(default |> fg (color "#FF06B7") |> build) fmt
let mint fmt = Spices.(default |> fg (color "#77e5b7") |> build) fmt