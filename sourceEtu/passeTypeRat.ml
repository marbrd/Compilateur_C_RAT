open Type
open Tds
open Exceptions
open Ast

type t1 = Ast.AstTds.programme
type t2 = Ast.AstType.programme

let rec analyse_type_affectable aff =
  match aff with
  | AstTds.Ident info -> 
     begin
      match info_ast_to_info info with
      | InfoVar (_,t,_,_) -> (AstType.Ident info, t)
      | InfoConst _ -> (AstType.Ident info, Int)
      | _ -> failwith "erreur interne"
    end
  | AstTds.Deref aff -> 
    let (naff, t) = analyse_type_affectable aff in
    match t with
    | Pointeur tt -> (AstType.Deref naff, tt)
    | _ -> raise (TypeInattendu ((Pointeur Undefined),t))

let rec analyse_type_expression e = 
  match e with
  | AstTds.AppelFonction (info, le) -> 
    let nle = List.map analyse_type_expression le in
    let (lp, tlp) = List.split nle in
    begin
      match (info_ast_to_info info) with
      | InfoFun (_,tr,tp) -> 
        if est_compatible_list tp tlp then (AstType.AppelFonction (info, lp), tr)
        else raise (TypesParametresInattendus(tp,tlp))
      | _ -> failwith "erreur interne"
    end
  | AstTds.Affectable aff -> 
    let (naff, t) = analyse_type_affectable aff in
    (AstType.Affectable naff, t)
  | AstTds.Unaire (op, e1) -> 
    let (ne1, te1) = analyse_type_expression e1 in
    if (est_compatible te1 Rat) then 
    begin
      match op with
      | Numerateur -> (AstType.Unaire (Numerateur, ne1), Int)
      | Denominateur -> (AstType.Unaire (Denominateur, ne1), Int)
    end
    else raise (TypeInattendu (te1, Rat))
  | AstTds.Binaire (op, e1, e2) -> 
    let (ne1, te1) = analyse_type_expression e1 in 
    let (ne2, te2) = analyse_type_expression e2 in
    begin
      match op, te1, te2 with
      | Plus, Int, Int -> (AstType.Binaire (PlusInt, ne1, ne2), Int)
      | Plus, Rat, Rat -> (AstType.Binaire (PlusRat, ne1, ne2), Rat)
      | Mult, Int, Int -> (AstType.Binaire (MultInt, ne1, ne2), Int)
      | Mult, Rat, Rat -> (AstType.Binaire (MultRat, ne1, ne2), Rat)
      | Fraction, Int, Int -> (AstType.Binaire (Fraction, ne1, ne2), Rat)
      | Equ, Int, Int -> (AstType.Binaire (EquInt, ne1, ne2), Bool)
      | Equ, Bool, Bool -> (AstType.Binaire (EquBool, ne1, ne2), Bool)
      | Inf, Int, Int -> (AstType.Binaire (Inf, ne1, ne2), Bool)
      | _,_,_ -> raise (TypeBinaireInattendu (op, te1, te2))
    end
  | AstTds.Booleen b -> (AstType.Booleen b, Bool)
  | AstTds.Entier i -> (AstType.Entier i, Int)
  | AstTds.Adresse info -> 
    begin
      match info_ast_to_info info with
      | InfoVar (_,t,_,_) -> (AstType.Adresse info, Pointeur t)
      | _ -> failwith "erreur interne"
    end
  | AstTds.New t -> (AstType.New t, Pointeur t)
  | AstTds.Null -> (AstType.Null, Pointeur Undefined)
let rec analyse_type_instruction i = 
  match i with
  | AstTds.Declaration (t, info, e) -> 
    let (ne,te) = analyse_type_expression e in
    if est_compatible t te then (modifier_type_variable t info; AstType.Declaration (info, ne))
    else raise (TypeInattendu (te, t))
  | AstTds.Affectation (aff, e) -> 
    let (ne,te) = analyse_type_expression e in
    let (naff,t) = analyse_type_affectable aff in
    if est_compatible t te then AstType.Affectation (naff, ne)
    else raise (TypeInattendu (te, t))
  | AstTds.Affichage e -> 
    let (ne, te) = analyse_type_expression e in
    begin
      match te with
      | Int -> AstType.AffichageInt ne  
      | Bool -> AstType.AffichageBool ne
      | Rat -> AstType.AffichageRat ne
      | _ -> raise (TypeInattendu (te, Int))
    end
  | AstTds.Conditionnelle (c, t, e) -> 
    let (nc, te) = analyse_type_expression c in
    let nt = analyse_type_bloc t and ne = analyse_type_bloc e in
    if est_compatible te Bool then AstType.Conditionnelle (nc, nt, ne)
    else raise (TypeInattendu (te, Bool))
  | AstTds.TantQue (c, b) -> 
    let (nc, te) = analyse_type_expression c in
    let nb = analyse_type_bloc b  in
    if est_compatible te Bool then AstType.TantQue (nc, nb)
    else raise (TypeInattendu (te, Bool))
  | AstTds.Retour (e, ia) -> 
    let (ne, te) = analyse_type_expression e in
    begin
      match info_ast_to_info ia with
      | InfoFun(_,tr,_) -> 
        if (est_compatible te tr) then AstType.Retour (ne, ia)
        else raise (TypeInattendu (te, tr))
      | _ -> failwith "errer interne"
    end 
  | AstTds.Empty -> AstType.Empty
  | AstTds.AppelProcedure (info, le) -> 
    let nle = List.map analyse_type_expression le in
    let (lp, tlp) = List.split nle in
    begin
      match (info_ast_to_info info) with
      | InfoFun (_,Void,tp) -> 
        if est_compatible_list tp tlp then AstType.AppelProcedure (info, lp)
        else raise (TypesParametresInattendus(tp,tlp))
      | _ -> failwith "erreur interne"
    end
  | AstTds.FinVoid -> AstType.FinVoid
  
and analyse_type_bloc li = 
  List.map analyse_type_instruction li


let analyse_type_fonction (AstTds.Fonction(t,info,lp,li)) = 
  let (tp,_) = List.split lp in
  let np = List.map (fun (t,infop) -> modifier_type_variable t infop; infop) lp in
  modifier_type_fonction t tp info;
  let nli = analyse_type_bloc li in
  AstType.Fonction (info,np,nli)

let analyse_type_fonctions lf = 
  List.map analyse_type_fonction lf


let analyser (AstTds.Programme (fonctions, prog)) =
  let nfs = analyse_type_fonctions fonctions in
  let nprog = analyse_type_bloc prog in
  AstType.Programme (nfs, nprog) 