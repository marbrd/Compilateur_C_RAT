open Type
open Tds
open Exceptions
open Ast

type t1 = Ast.AstTds.enums*Ast.AstTds.programme
type t2 = Ast.AstType.programme

let rec analyse_type_affectable aff =
  match aff with
  | AstTds.Ident info -> 
     begin
      match info_ast_to_info info with
      | InfoVar (_,t,_,_) -> (AstType.Ident info, t)
      | InfoConst _ -> (AstType.Ident info, (Int,false))
      | _ -> failwith "erreur interne"
    end
  | AstTds.Deref aff -> 
    let (naff, (t,_)) = analyse_type_affectable aff in
    begin
      match t with
      | Pointeur tt -> (AstType.Deref naff, (tt,false))
      | _ -> raise (TypeInattendu (Pointeur Undefined,t))
    end

let rec analyse_type_expression e = 
  match e with
  | AstTds.AppelFonction (info, le) -> 
    let nle = List.map analyse_type_expression le in
    let (lp, tlp) = List.split nle in
    begin
      match (info_ast_to_info info) with
      | InfoFun (_,tr,tp) -> 
        if est_compatible_list tp tlp then (AstType.AppelFonction (info, lp), (tr,false))
        else raise (TypesParametresInattendus(tlp,tp))
      | _ -> failwith "erreur interne"
    end
  | AstTds.Affectable aff -> 
    let (naff, t) = analyse_type_affectable aff in
    (AstType.Affectable naff, t)
  | AstTds.Unaire (op, e1) -> 
    let (ne1, (te1,_)) = analyse_type_expression e1 in
    if (est_compatible te1 Rat) then 
    begin
      match op with
      | Numerateur -> (AstType.Unaire (Numerateur, ne1), (Int,false))
      | Denominateur -> (AstType.Unaire (Denominateur, ne1), (Int,false))
    end
    else raise (TypeInattendu (te1, Rat))
  | AstTds.Binaire (op, e1, e2) -> 
    let (ne1, (te1,_)) = analyse_type_expression e1 in 
    let (ne2, (te2,_)) = analyse_type_expression e2 in
    begin
      match op, te1, te2 with
      | Plus, Int, Int -> (AstType.Binaire (PlusInt, ne1, ne2), (Int,false))
      | Plus, Rat, Rat -> (AstType.Binaire (PlusRat, ne1, ne2), (Rat,false))
      | Mult, Int, Int -> (AstType.Binaire (MultInt, ne1, ne2), (Int,false))
      | Mult, Rat, Rat -> (AstType.Binaire (MultRat, ne1, ne2), (Rat,false))
      | Fraction, Int, Int -> (AstType.Binaire (Fraction, ne1, ne2), (Rat,false))
      | Equ, Int, Int -> (AstType.Binaire (EquInt, ne1, ne2), (Bool,false))
      | Equ, Bool, Bool -> (AstType.Binaire (EquBool, ne1, ne2), (Bool,false))
      | Inf, Int, Int -> (AstType.Binaire (Inf, ne1, ne2), (Bool,false))
      | Equ, Tenum t1, Tenum t2 ->
        if t1 = t2 then (AstType.Binaire (EquTenum, ne1, ne2), (Bool,false))
        else raise (TypeBinaireInattendu (op,Tenum t1,Tenum t2))
      | _,_,_ -> raise (TypeBinaireInattendu (op, te1, te2))
    end
  | AstTds.Booleen b -> (AstType.Booleen b, (Bool,false))
  | AstTds.Entier i -> (AstType.Entier i, (Int,false))
  | AstTds.Adresse info -> 
    begin
      match info_ast_to_info info with
      | InfoVar (_,(t,_),_,_) -> (AstType.Adresse info, (Pointeur t, false))
      | _ -> failwith "erreur interne"
    end
  | AstTds.New t -> (AstType.New t, (Pointeur t, false))
  | AstTds.Null -> (AstType.Null, (Pointeur Undefined, false))
  | AstTds.Reference e1 -> 
    let (ne, (t,_)) = analyse_type_expression e1 in
    begin
      match ne with 
      | AstType.Affectable (AstType.Ident info) -> 
      (AstType.Adresse info, (t,true))
      | _ -> failwith "erreur interne"
    end
  | AstTds.Evaleur info ->
    begin 
      match info_ast_to_info info with
      | InfoValeurEnum (_,tid,i) -> (AstType.Entier i, (Tenum tid, false))
      | _ -> failwith "erreur interne"
    end

let rec analyse_type_instruction i = 
  match i with
  | AstTds.Declaration (t, info, e) -> 
    let (ne,(te,_)) = analyse_type_expression e in
    if est_compatible t te then (modifier_type_variable (t,false) info; AstType.Declaration (info, ne))
    else raise (TypeInattendu (te, t))
  | AstTds.Affectation (aff, e) -> 
    let (ne,(te,_)) = analyse_type_expression e in
    let (naff,(t,_)) = analyse_type_affectable aff in
    if est_compatible t te then AstType.Affectation (naff, ne)
    else raise (TypeInattendu (te, t))
  | AstTds.Affichage e -> 
    let (ne, (te,_)) = analyse_type_expression e in
    begin
      match te with
      | Int -> AstType.AffichageInt ne  
      | Bool -> AstType.AffichageBool ne
      | Rat -> AstType.AffichageRat ne
      | _ -> raise (TypeInattendu (te, Int))
    end
  | AstTds.Conditionnelle (c, t, e) -> 
    let (nc, (te,_)) = analyse_type_expression c in
    let nt = analyse_type_bloc t and ne = analyse_type_bloc e in
    if est_compatible te Bool then AstType.Conditionnelle (nc, nt, ne)
    else raise (TypeInattendu (te, Bool))
  | AstTds.TantQue (c, b) -> 
    let (nc, (te,_)) = analyse_type_expression c in
    let nb = analyse_type_bloc b  in
    if est_compatible te Bool then AstType.TantQue (nc, nb)
    else raise (TypeInattendu (te, Bool))
  | AstTds.Retour (e, ia) -> 
    let (ne, (te,_)) = analyse_type_expression e in
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
        else raise (TypesParametresInattendus(tlp,tp))
      | _ -> failwith "erreur interne"
    end
  | AstTds.FinVoid info -> AstType.FinVoid info
  
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

let analyser (_,AstTds.Programme (fonctions, prog)) =
  let nfs = analyse_type_fonctions fonctions in
  let nprog = analyse_type_bloc prog in
  AstType.Programme (nfs, nprog)