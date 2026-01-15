type typ = Bool | Int | Rat | Undefined | Pointeur of typ | Void | Tenum of string

let rec string_of_type t = 
  match t with
  | Bool ->  "Bool"
  | Int  ->  "Int"
  | Rat  ->  "Rat"
  | Void -> "Void"
  | Undefined -> "Undefined" 
  | Pointeur(a) -> "Pointeur("^(string_of_type a)^")" 
  | Tenum(tid) -> "Tenum("^tid^")"


let rec est_compatible t1 t2 =
  match t1, t2 with
  | Bool, Bool -> true
  | Int, Int -> true
  | Rat, Rat -> true 
  | Pointeur Undefined, Pointeur Undefined -> false
  | Pointeur _, Pointeur Undefined -> true
  | Pointeur t1, Pointeur t2 -> est_compatible t1 t2
  | Tenum tid1, Tenum tid2 -> tid1 = tid2
  | _ -> false 

let est_compatible_ref (t1,b1) (t2,b2) = 
  (est_compatible t1 t2)&&(b1 = b2)

let%test _ = est_compatible Bool Bool
let%test _ = est_compatible Int Int
let%test _ = est_compatible Rat Rat
let%test _ = not (est_compatible Int Bool)
let%test _ = not (est_compatible Bool Int)
let%test _ = not (est_compatible Int Rat)
let%test _ = not (est_compatible Rat Int)
let%test _ = not (est_compatible Bool Rat)
let%test _ = not (est_compatible Rat Bool)
let%test _ = not (est_compatible Undefined Int)
let%test _ = not (est_compatible Int Undefined)
let%test _ = not (est_compatible Rat Undefined)
let%test _ = not (est_compatible Bool Undefined)
let%test _ = not (est_compatible Undefined Int)
let%test _ = not (est_compatible Undefined Rat)
let%test _ = not (est_compatible Undefined Bool)

let est_compatible_list lt1 lt2 =
  try
    List.for_all2 est_compatible_ref lt1 lt2
  with Invalid_argument _ -> false
(*
let%test _ = est_compatible_list [] []
let%test _ = est_compatible_list [Int ; Rat] [Int ; Rat]
let%test _ = est_compatible_list [Bool ; Rat ; Bool] [Bool ; Rat ; Bool]
let%test _ = not (est_compatible_list [Int] [Int ; Rat])
let%test _ = not (est_compatible_list [Int] [Rat ; Int])
let%test _ = not (est_compatible_list [Int ; Rat] [Rat ; Int])
let%test _ = not (est_compatible_list [Bool ; Rat ; Bool] [Bool ; Rat ; Bool ; Int])
*)
let getTailleType t =
  match t with
  | Int -> 1
  | Bool -> 1
  | Rat -> 2
  | Void -> 0
  | Undefined -> 0 
  | Pointeur _ -> 1
  | Tenum _ -> 1

let getTaille (t,b) =
  match t,b with
  | Undefined, _ -> 0
  | _, false -> getTailleType t
  | _, true -> 1
  
let%test _ = getTaille (Int,false) = 1
let%test _ = getTaille (Bool,false) = 1
let%test _ = getTaille (Rat,false) = 2
