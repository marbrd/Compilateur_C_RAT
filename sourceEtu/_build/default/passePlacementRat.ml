open Type
open Tds
open Ast

type t1 = Ast.AstType.enums*Ast.AstType.programme
type t2 = Ast.AstPlacement.enums*Ast.AstPlacement.programme

let rec analyse_placement_instruction i depl reg =
  match i with 
  | AstType.Declaration (info,e) -> 
    begin
      match info_ast_to_info info with
      | InfoVar (_,t,_,_) -> modifier_adresse_variable depl reg info; (AstPlacement.Declaration (info,e), getTaille t)
      | _ -> failwith "erreur interne"
    end
  | AstType.Conditionnelle (c, t, e) -> 
    let nt = analyse_placement_bloc t depl reg in
    let ne = analyse_placement_bloc e depl reg in
    (AstPlacement.Conditionnelle (c, nt, ne), 0)
  | AstType.TantQue (c, b) -> 
    let nb = analyse_placement_bloc b depl reg in
    (AstPlacement.TantQue (c, nb), 0)
  | AstType.Retour (e, ia) ->
    begin
      match info_ast_to_info ia with
      | InfoFun (_,tr,tp) -> (AstPlacement.Retour (e, getTaille (tr,false), List.fold_right (fun t q -> q + (getTaille t)) tp 0), 0)
      | _ -> failwith "erreur interne"
    end
  | AstType.Affectation (aff, e) -> (AstPlacement.Affectation (aff, e), 0)
  | AstType.AffichageInt e -> (AstPlacement.AffichageInt e, 0)
  | AstType.AffichageRat e -> (AstPlacement.AffichageRat e, 0)
  | AstType.AffichageBool e -> (AstPlacement.AffichageBool e, 0)
  | AstType.Empty -> (AstPlacement.Empty, 0)
  | AstType.AppelProcedure (info, le) -> (AstPlacement.AppelProcedure (info, le), 0)
  | AstType.FinVoid info -> 
    begin
      match info_ast_to_info info with
      | InfoFun (_,_,tp) -> (AstPlacement.FinVoid (List.fold_right (fun t q -> q + (getTaille t)) tp 0), 0)
      | _ -> failwith "erreur interne"
    end

and analyse_placement_bloc li depl reg = 
  begin
    match li with
    | [] -> ([],0)
    | i::q -> 
      let (ni, ti) = analyse_placement_instruction i depl reg in
      let (nq, tq) = analyse_placement_bloc q (depl+ti) reg in
      (ni::nq, ti+tq)
  end
  
let analyse_placement_fonction (AstType.Fonction (info, lp, li)) = 
  let rec aux l n = 
    match l with
    | [] -> ()
    | t::q -> 
      begin 
        match info_ast_to_info t with
        | InfoVar (_,ty,_,_) -> 
          let dep = n - (getTaille ty) in 
          modifier_adresse_variable dep "LB" t; 
          aux q dep 
        | _ -> failwith "erreur interne"
      end 
  in 
  let nli = analyse_placement_bloc li 3 "LB" in
  aux (List.rev lp) 0;
  (AstPlacement.Fonction(info, lp, nli))
  
let analyser (AstTds.Enums tids,AstType.Programme (fonctions, prog)) =
  let nfs = List.map analyse_placement_fonction fonctions in 
  let nprog = analyse_placement_bloc prog 0 "SB" in
  (AstTds.Enums tids, AstPlacement.Programme (nfs, nprog))