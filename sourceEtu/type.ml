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

let%test _ = est_compatible Bool Bool
let%test _ = est_compatible Int Int
let%test _ = est_compatible Rat Rat
let%test _ = est_compatible (Pointeur Int) (Pointeur Int)
let%test _ = est_compatible (Pointeur Bool) (Pointeur Bool)
let%test _ = est_compatible (Pointeur Rat) (Pointeur Rat)
let%test _ = est_compatible (Pointeur (Tenum "tid")) (Pointeur (Tenum "tid"))
let%test _ = est_compatible (Tenum "tid") (Tenum "tid")
let%test _ = est_compatible (Pointeur Int) (Pointeur Undefined)
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
let%test _ = not (est_compatible (Pointeur Bool) (Pointeur (Tenum "tid")))
let%test _ = not (est_compatible (Pointeur Rat) (Pointeur Int))
let%test _ = not (est_compatible (Tenum "tid1") (Tenum "tid2"))
let%test _ = not (est_compatible (Pointeur Rat) (Tenum "Int"))
let%test _ = not (est_compatible (Rat) (Tenum "tid"))

let est_compatible_ref (t1,b1) (t2,b2) = 
  (est_compatible t1 t2)&&(b1 = b2)

let%test _ = est_compatible_ref (Bool,false) (Bool,false)
let%test _ = est_compatible_ref (Int,true) (Int,true)
let%test _ = est_compatible_ref (Rat,true) (Rat,true)
let%test _ = not (est_compatible_ref (Bool,false) (Bool,true))
let%test _ = not (est_compatible_ref (Int,true) (Int,false))
let%test _ = not (est_compatible_ref (Tenum "tid",true) ((Tenum "tid"),false))

let est_compatible_list lt1 lt2 =
  try
    List.for_all2 est_compatible_ref lt1 lt2
  with Invalid_argument _ -> false

let%test _ = est_compatible_list [] []
let%test _ = est_compatible_list [(Int,true) ; (Rat,true)] [(Int,true) ; (Rat,true)]
let%test _ = est_compatible_list [(Bool,false) ; (Rat,false) ; (Bool,true)] [(Bool,false) ; (Rat,false) ; (Bool,true)]
let%test _ = not (est_compatible_list [(Int,false)] [(Int,false) ; (Rat,false)])
let%test _ = not (est_compatible_list [(Int,false) ; (Rat,false)] [(Int,false)])
let%test _ = not (est_compatible_list [(Int,false) ; (Rat,false)] [(Rat,false) ; (Int,false)])

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
let%test _ = getTaille (Rat,true) = 1
let%test _ = getTaille (Tenum "tid",false) = 1
let%test _ = getTaille (Pointeur Rat,false) = 1
