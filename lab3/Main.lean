import Lab3

open IO(rand)
open Array(mkArray)
open Function(const)

abbrev ℕ := Nat
abbrev ℕₙ:= Array ℕ in
def genRandArray (lo hi : ℕ) : ℕ -> StdGen -> ℕₙ
  | i, gen =>
    let rec genRandArrayHelper lo hi cnt gen l :=
      match cnt with
      | 0     => (l, gen)
      | n + 1 =>
      let (n', gen') := randNat gen lo hi
      genRandArrayHelper lo hi n gen' (l.push n')
    genRandArrayHelper lo hi i gen #[] |> Prod.fst
-- just noticed there's an IO.rand. dumb dumb.

def gen2dArray row col lo hi :=
  mkArray row #[] |>.mapM (const (Array Int) <| genCol col)
  where
    genCol col :=
      mkArray col 0 |>.mapM (const Int (rand lo hi : IO Int))

open String(toInt!)
def main : IO Unit := do
  let stdin <- IO.getStdin
  println! s!"Enter request matrix shape (ROW; COL) e.g. 5; 3 : "
  let (row,col) : RequestShape :=
    match (<-stdin.getLine).trim.splitOn ";" with
    | row :: col :: _ => (row.toNat!,col.toNat!)
    | _ => panic!"Invalid Input"
  println! s!"n_processes : {row}, n_resource_types : {col}"
  let available : Array Int <- mkArray col 0 |>.mapM (const Int <| rand 1 10)
  let allocation : Array (Array Int) <- gen2dArray row col 0 4
  let maximum : Array (Array Int) <- gen2dArray row col 1 6
  let mut b : Banker := {
    available,
    allocation,
    maximum,
    }
  println! b
  let (safe?_init, safeseq) := b.check (row,col) |>.run (Array.mkArray row false, b.available.map id)
  if safe?_init then println! s!"System is safe initially. Safe sequence: {safeseq}"
  else println! s!"System is not safe initially. {safeseq}"
  println! "Enter (PROCESS-ID : Nat; REQUEST : Array Nat) e.g. 0; 1,2,3,4  or <C-d> to exit: "
  repeat do
    match (<-stdin.getLine).trim with
    | "" => return ()
    | s  =>
      let (reqId, req) : (Nat × Array Int) :=
        match s.splitOn ";" with
        | ids :: (r :: _) =>
          match ids.toNat!, r.splitOn "," |>.map toInt! |>.toArray with
          | id, req => (id,req)
        | _ => panic!"Invalid Input"
      println! s!"Requesting: PROC{reqId}:{req}"
      match <- bankers b (row,col) req reqId with
      | (false, _) =>
        println! s!"Allocation for PROC{reqId}: {req} is unsafe."
        println! s!"Restoring..."
        IO.sleep 1000
        b := { b with
          available := b.available + allocation[reqId]!,
          allocation := b.allocation.set! reqId (allocation[reqId]! - req),
          need := b.need.set! reqId req
        }
      | (true, ss) =>
        println! s!"Allocation for PROC{reqId}: {req} is safe."
        println! b
        println! s!"Safe Sequence: {ss}"
