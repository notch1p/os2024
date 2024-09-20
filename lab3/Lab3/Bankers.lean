
abbrev RequestShape := Nat × Nat
abbrev Request := Array Int

structure Banker where
  available  : Array Int         := #[3,3,2]
  allocation : Array (Array Int) := #[#[0,1,0], #[2,0,0], #[3,0,2], #[2,1,1], #[0,0,2]]
  maximum    : Array (Array Int) := #[#[7,5,3], #[3,2,2], #[9,0,2], #[2,2,2], #[4,3,3]]
  need       : Array (Array Int) :=
    maximum.zipWith allocation (λ ms as => ms.zipWith as (· - ·))
deriving Repr, BEq

@[inline]
def anyArrayGT (xs ys : Array Int) : Bool :=
  xs.zipWith ys (λ x y => x - y) |>.any (· >= 1)

@[inline]
def anyArrayGE (xs ys : Array Int) : Bool :=
  xs.zipWith ys (λ x y => x - y) |>.any (· >= 0)

@[inline]
def allArrayLT (xs ys : Array Int) : Bool :=
  xs.zipWith ys (λ x y => y - x) |>.all (· >= 1)

@[inline]
def allArrayLE (xs ys : Array Int) : Bool :=
  xs.zipWith ys (λ x y => y - x) |>.all (· >= 0)

@[inline] def arraySub [Sub α] (xs ys : Array α) : Array α :=
  xs.zipWith ys (· - ·)

@[inline] def arrayAdd [Add α] (xs ys : Array α) : Array α :=
  xs.zipWith ys (· + ·)

instance : HAdd (Array Int) (Array Int) (Array Int) := ⟨arrayAdd⟩
instance : HSub (Array Int) (Array Int) (Array Int) := ⟨arraySub⟩
instance : ToString Banker where
  toString b := s!"Available : {b.available};\nAllocation : {b.allocation};\nneed : {b.need}"

@[inline] def Banker.allocate (b : Banker) (req : Request) (reqId : Nat) : Banker :=
  {
  b with
    available := b.available - req,
    allocation := b.allocation.set! reqId ((b.allocation.get! reqId) + req)
    need := b.need.set! reqId ((b.need.get! reqId) - req)
  }

open List(range) in
def Banker.check (b : Banker) (s : RequestShape) : ReaderM ((Array Bool) × (Array Int)) (Bool × List Nat) := do
  let mut (finish, work) <- read
  let mut exists1 := true
  let mut safeseq := []
  let mut range   := range s.1
  while exists1 do
    exists1 := false
    for i in range do
      if !(finish.get! i) && (allArrayLE (b.need.get! i) work) then
          finish := finish.set! i true
          work := work + b.allocation.get! i
          exists1 := true
          safeseq := i :: safeseq
          range := range.removeAll safeseq
  pure (finish.all id, safeseq.reverse)

open Array(mkArray) in
def bankers (b : Banker) (s : RequestShape) (req : Request) (reqId : Nat) : IO (Bool × List Nat) := do
  println! s!"requesting allocation for PROC{reqId}: {req}"
  if anyArrayGT req (b.need.get! reqId) then
    println! s!"ERROR: Process {reqId} is requesting more than it needs"
    pure (false, [])
  else
    if anyArrayGT req b.available then
      println! s!"ERROR: Process {reqId} is requesting more than available resources"
      pure (false, [])
    else
      return b
          |>.allocate req reqId
          |>.check s
          |>.run (mkArray s.1 false, b.available.map id)
