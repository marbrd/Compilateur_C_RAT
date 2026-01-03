open Tam
open Code
open Type
open Ast
open Tds

type t1 = Ast.AstPlacement.programme
type t2 = string

let rec analyse_code_affectable aff lec = 
  match aff with
  | AstType.Ident info ->
    begin
      match info_ast_to_info info with
      | InfoVar (_,t,dep,reg) -> 
        let len = (getTaille t) in
        if not lec then (store len dep reg, len) 
        else (load len dep reg , len)
      | InfoConst (_,n) -> (loadl_int n, 1)
      | _ -> failwith "erreur interne"
    end
  | AstType.Deref r -> 
    let (an,l) = (analyse_code_affectable r true) in
      let trait = 
        if lec then loadi l 
        else storei l in
          (an
          ^ trait, 0)

let rec analyse_code_expression e = 
  match e with
  | AstType.AppelFonction (info, le) -> 
    let cle = List.fold_right (fun e acc -> (analyse_code_expression e)^acc) le "" in
    begin
      match info_ast_to_info info with 
      | InfoFun (n,_,_) -> cle^(call "SB" n)
      | _ -> failwith "erreur interne"
    end
  | AstType.Affectable aff -> 
    fst (analyse_code_affectable aff true)
  | AstType.Booleen b -> if b then loadl_int 1 else loadl_int 0
  | AstType.Entier i -> loadl_int i
  | AstType.Binaire (op, e1, e2) -> 
    analyse_code_expression e1  
    ^ analyse_code_expression e2
    ^ (
      begin 
        match op with 
        | PlusInt -> subr "IAdd"
        | PlusRat -> call "SB" "radd"
        | MultInt -> subr "IMul"
        | MultRat -> call "SB" "rmul"
        | Fraction -> call "SB" "norm"
        | EquInt -> subr "IEq"
        | EquBool -> subr "IEq"
        | Inf -> subr "ILss"
      end)
  | AstType.Unaire (op, e1) -> 
    analyse_code_expression e1
    ^ (
      match op with
      | Numerateur -> pop 0 1
      | Denominateur -> pop 1 1
    )
  | AstType.Null -> subr "MVoid"
  | AstType.New t -> 
    loadl_int (getTaille t)
    ^ subr "MAlloc"
  | AstType.Adresse info -> 
    begin
      match info_ast_to_info info with
      | InfoVar(_,_,dep,reg) -> loada dep reg
      | _ -> failwith "erreur interne"
    end 

let rec analyse_code_instruction i =
  match i with 
  | AstPlacement.Declaration (info, e) -> 
    begin
      match info_ast_to_info info with
      | InfoVar(_,t,dep,reg) -> 
        push (getTaille t)
        ^ analyse_code_expression e
        ^ store (getTaille t) dep reg
      | _ -> failwith "erreur interne"
    end
  | AstPlacement.Affectation (aff, e) -> 
    analyse_code_expression e
    ^ fst (analyse_code_affectable aff false)
  | AstPlacement.AffichageInt e -> 
    analyse_code_expression e
    ^ subr "IOut"
  | AstPlacement.AffichageRat e ->
    analyse_code_expression e
    ^ call "SB" "rout"
  | AstPlacement.AffichageBool e ->
    analyse_code_expression e
    ^ subr "BOut" 
  | AstPlacement.Conditionnelle (c, t, e) ->
    analyse_code_expression c
    ^ (let els = getEtiquette () in
      let endif = getEtiquette () in
      jumpif 0 els
    ^ analyse_code_bloc t
    ^ jump endif
    ^ label els
    ^ analyse_code_bloc e
    ^ label endif)
  | AstPlacement.TantQue (c, b) ->
      (let tq = getEtiquette () in
      let ftq = getEtiquette () in
      label tq 
      ^ analyse_code_expression c 
      ^ jumpif 0 ftq
      ^ analyse_code_bloc b
      ^ jump tq
      ^ label ftq
    )
  | AstPlacement.Retour (e, tailleRet, tailleParam) -> 
    analyse_code_expression e
    ^ return tailleRet tailleParam
  | AstPlacement.Empty -> ""

and analyse_code_bloc (li, taille) = 
  List.fold_right (fun e acc -> (analyse_code_instruction e)^acc) li "" 
  ^ pop 0 taille

let analyse_code_fonction (AstPlacement.Fonction(info,_,(li,_))) = 
  match info_ast_to_info info with
  | InfoFun(n,_,_) -> 
    label n
    ^ (List.fold_right (fun e acc -> (analyse_code_instruction e)^acc) li "")
    ^ halt
  | _ -> failwith "erreur interne"

let analyser (AstPlacement.Programme (fonctions, prog)) =
  getEntete()
  ^ (List.fold_right (fun f acc -> (analyse_code_fonction f)^acc) fonctions "") 
  ^ label "main"
  ^ analyse_code_bloc prog
  ^ halt

