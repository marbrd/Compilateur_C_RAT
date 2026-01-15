(* Module de la passe de gestion des identifiants *)
(* doit être conforme à l'interface Passe *)
open Tds
open Exceptions
open Ast
open Type

type t1 = Ast.AstSyntax.enums*Ast.AstSyntax.programme
type t2 = Ast.AstTds.enums*Ast.AstTds.programme

 (*l'analyse d'un affectable*)
let rec analyse_tds_affectable tds a lec =
    match a with
    | AstSyntax.Ident n -> 
      begin
        match chercherGlobalement tds n with
        | None -> raise (IdentifiantNonDeclare n)
        | Some a -> 
        begin 
          match (info_ast_to_info a) with 
          | InfoVar _ -> AstTds.Ident a
          | InfoConst _ -> if lec then AstTds.Ident a else raise (MauvaiseUtilisationIdentifiant n)
          | _ -> raise (MauvaiseUtilisationIdentifiant n)
        end 
      end
    | AstSyntax.Deref r -> 
      let nr = analyse_tds_affectable tds r lec in 
      AstTds.Deref nr
    

(* analyse_tds_expression : tds -> AstSyntax.expression -> AstTds.expression *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre e : l'expression à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme l'expression
en une expression de type AstTds.expression *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_expression tds e = 
  match e with
  | AstSyntax.Booleen b -> AstTds.Booleen b

  | AstSyntax.Entier i -> AstTds.Entier i
  
  | AstSyntax.Affectable aff -> 
    AstTds.Affectable (analyse_tds_affectable tds aff true)

  | AstSyntax.New t -> AstTds.New t

  | AstSyntax.Null -> AstTds.Null
  
  | AstSyntax.Adresse n -> 
    begin
      match chercherGlobalement tds n with
      | None -> raise (IdentifiantNonDeclare n)
      | Some a -> 
        begin 
          match (info_ast_to_info a) with 
          | InfoVar _ -> AstTds.Adresse a
          | _ -> raise (MauvaiseUtilisationIdentifiant n)
        end 
    end

  | AstSyntax.Binaire (b, e1, e2) -> 
    let ne1 = analyse_tds_expression tds e1 and 
    ne2 = analyse_tds_expression tds e2 in 
      AstTds.Binaire (b, ne1, ne2)
  
  | AstSyntax.Unaire (op , e1) -> 
    let ne1 = analyse_tds_expression tds e1 in 
      AstTds.Unaire (op, ne1)
  
  | AstSyntax.AppelFonction (id, le) -> 
    begin
      match chercherGlobalement tds id with
      | None -> raise (IdentifiantNonDeclare id)
      | Some a -> 
      begin 
        match info_ast_to_info a with
        | InfoFun (_,_,_) -> let nle = List.map (analyse_tds_expression tds) le in
          AstTds.AppelFonction (a,nle)
        | _ -> raise (MauvaiseUtilisationIdentifiant id)
      end
    end
  | AstSyntax.Reference e1 -> 
    begin
      match e1 with
      | AstSyntax.Affectable aff ->
        begin
          match aff with
          | AstSyntax.Ident _ ->
            let ne = analyse_tds_expression tds e1 in
            AstTds.Reference ne
          | _ -> raise MauvaiseUtilisationReference
        end
      | _ -> raise MauvaiseUtilisationReference
    end
  | AstSyntax.Evaleur n -> 
    begin
      match chercherGlobalement tds n with
      | None -> raise (IdentifiantNonDeclare n)
      | Some a -> 
      begin 
        match info_ast_to_info a with
        | InfoValeurEnum (_,_,_) -> AstTds.Evaleur a
        | _ -> raise (MauvaiseUtilisationIdentifiant n)
      end
    end
 
let analyse_tds_expression_not_ref tds e =
  match e with
  | AstSyntax.Reference _ -> raise MauvaiseUtilisationReference
  | _ -> analyse_tds_expression tds e 

(* analyse_tds_instruction : tds -> info_ast option -> AstSyntax.instruction -> AstTds.instruction *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre oia : None si l'instruction i est dans le bloc principal,
                   Some ia où ia est l'information associée à la fonction dans laquelle est l'instruction i sinon *)
(* Paramètre i : l'instruction à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme l'instruction
en une instruction de type AstTds.instruction *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_instruction tds oia i =
  match i with
  | AstSyntax.Declaration (t, n, e) ->
      begin
        match chercherLocalement tds n with
        | None ->
            (* L'identifiant n'est pas trouvé dans la tds locale,
            il n'a donc pas été déclaré dans le bloc courant *)
            (* Vérification de la bonne utilisation des identifiants dans l'expression *)
            (* et obtention de l'expression transformée *)
            let ne = analyse_tds_expression_not_ref tds e in
            (* Création de l'information associée à l'identfiant *)
            let info = InfoVar (n,(Undefined,false), 0, "") in
            (* Création du pointeur sur l'information *)
            let ia = info_to_info_ast info in
            (* Ajout de l'information (pointeur) dans la tds *)
            ajouter tds n ia;
            (* Renvoie de la nouvelle déclaration où le nom a été remplacé par l'information
            et l'expression remplacée par l'expression issue de l'analyse *)
            AstTds.Declaration (t, ia, ne)
        | Some _ ->
            (* L'identifiant est trouvé dans la tds locale,
            il a donc déjà été déclaré dans le bloc courant *)
            raise (DoubleDeclaration n)
      end
  | AstSyntax.Constante (n,v) ->
      begin
        match chercherLocalement tds n with
        | None ->
          (* L'identifiant n'est pas trouvé dans la tds locale,
             il n'a donc pas été déclaré dans le bloc courant *)
          (* Ajout dans la tds de la constante *)
          ajouter tds n (info_to_info_ast (InfoConst (n,v)));
          (* Suppression du noeud de déclaration des constantes devenu inutile *)
          AstTds.Empty
        | Some _ ->
          (* L'identifiant est trouvé dans la tds locale,
          il a donc déjà été déclaré dans le bloc courant *)
          raise (DoubleDeclaration n)
      end
  | AstSyntax.Affichage e ->
      (* Vérification de la bonne utilisation des identifiants dans l'expression *)
      (* et obtention de l'expression transformée *)
      let ne = analyse_tds_expression_not_ref tds e in
      (* Renvoie du nouvel affichage où l'expression remplacée par l'expression issue de l'analyse *)
      AstTds.Affichage (ne)
  | AstSyntax.Conditionnelle (c,t,e) ->
      (* Analyse de la condition *)
      let nc = analyse_tds_expression_not_ref tds c in
      (* Analyse du bloc then *)
      let tast = analyse_tds_bloc tds oia t in
      (* Analyse du bloc else *)
      let east = analyse_tds_bloc tds oia e in
      (* Renvoie la nouvelle structure de la conditionnelle *)
      AstTds.Conditionnelle (nc, tast, east)
  | AstSyntax.TantQue (c,b) ->
      (* Analyse de la condition *)
      let nc = analyse_tds_expression_not_ref tds c in
      (* Analyse du bloc *)
      let bast = analyse_tds_bloc tds oia b in
      (* Renvoie la nouvelle structure de la boucle *)
      AstTds.TantQue (nc, bast)
  | AstSyntax.Retour (e) ->
      begin
      (* On récupère l'information associée à la fonction à laquelle le return est associée *)
      match oia with
        (* Il n'y a pas d'information -> l'instruction est dans le bloc principal : erreur *)
      | None -> raise RetourDansMain
        (* Il y a une information -> l'instruction est dans une fonction *)
      | Some ia ->
        (* Analyse de l'expression *)
        let ne = analyse_tds_expression_not_ref tds e in
        AstTds.Retour (ne,ia)
      end
  | AstSyntax.Affectation (aff,e) ->
    let naff = analyse_tds_affectable tds aff false in
    let ne = analyse_tds_expression_not_ref tds e in
    AstTds.Affectation (naff, ne) 
  | AstSyntax.AppelProcedure (id, le) -> 
    begin
      match chercherGlobalement tds id with
      | None -> raise (IdentifiantNonDeclare id)
      | Some a -> 
      begin 
        match info_ast_to_info a with
        | InfoFun (_,Void,_) -> let nle = List.map (analyse_tds_expression tds) le in
          AstTds.AppelProcedure (a,nle)
        | _ -> raise (MauvaiseUtilisationIdentifiant id)
      end
    end
  | AstSyntax.FinVoid ->
    begin
      match oia with
      | None -> raise RetourDansMain
      | Some ia ->
        AstTds.FinVoid ia
      end



(* analyse_tds_bloc : tds -> info_ast option -> AstSyntax.bloc -> AstTds.bloc *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre oia : None si le bloc li est dans le programme principal,
                   Some ia où ia est l'information associée à la fonction dans laquelle est le bloc li sinon *)
(* Paramètre li : liste d'instructions à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme le bloc en un bloc de type AstTds.bloc *)
(* Erreur si mauvaise utilisation des identifiants *)
and analyse_tds_bloc tds oia li =
  (* Entrée dans un nouveau bloc, donc création d'une nouvelle tds locale
  pointant sur la table du bloc parent *)
  let tdsbloc = creerTDSFille tds in
  (* Analyse des instructions du bloc avec la tds du nouveau bloc.
     Cette tds est modifiée par effet de bord *)
   let nli = List.map (analyse_tds_instruction tdsbloc oia) li in
   (* afficher_locale tdsbloc ; *) (* décommenter pour afficher la table locale *)
   nli


(* analyse_tds_fonction : tds -> AstSyntax.fonction -> AstTds.fonction *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre : la fonction à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme la fonction
en une fonction de type AstTds.fonction *)
(* Erreur si mauvaise utilisation des identifiants *)
let analyse_tds_fonction maintds (AstSyntax.Fonction(t,n,lp,li))  =
  match chercherLocalement maintds n with
    | Some _ -> raise (DoubleDeclaration n)
    | None -> 
      let (tp,_) = List.split lp in
      let tt = if t = Void then t else Undefined in
      let infofonction = info_to_info_ast (InfoFun (n, tt, List.map (fun _ -> (Undefined,false)) tp)) in
      let _ = ajouter maintds n infofonction in
      let tdsfonction = creerTDSFille maintds in
      let nlp = List.map 
        (fun (t,n) -> 
        begin
          match chercherLocalement tdsfonction n with
          | Some _ -> raise (DoubleDeclaration n)
          | None ->
          let infopara = info_to_info_ast (InfoVar (n, (Undefined,false), 0, "")) in 
          ajouter tdsfonction n infopara;
          (t, infopara)
        end) 
        lp 
      in
      let nli = analyse_tds_bloc tdsfonction (Some infofonction) li in 
      AstTds.Fonction(t, infofonction, nlp, nli)

let analyse_tds_enumeration maintds (AstSyntax.Enumeration(tid,le)) =
  match chercherGlobalement maintds tid with
  | Some _ -> raise (DoubleDeclaration tid)
  | None ->
    let check v = 
      begin
        match chercherGlobalement maintds v with
        | Some _ -> raise (DoubleDeclaration v)
        | None -> true
      end
    in 
    let _ = List.map check le in
    let infotid = info_to_info_ast (InfoEnum (tid,le)) in ajouter maintds tid infotid;
    let infovenum = 
      List.mapi 
      (fun i v -> 
        let info = info_to_info_ast (InfoValeurEnum (v,tid,i)) in 
        ajouter maintds v info; info
      ) le in
    AstTds.Enumeration (infotid,infovenum)

(* analyser : AstSyntax.programme -> AstTds.programme *)
(* Paramètre : le programme à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme le programme
en un programme de type AstTds.programme *)
(* Erreur si mauvaise utilisation des identifiants *)
let analyser (AstSyntax.Enums tids,AstSyntax.Programme (fonctions,prog)) =
  let tds = creerTDSMere () in
  let nenum = List.map (analyse_tds_enumeration tds) tids in
  let nf = List.map (analyse_tds_fonction tds) fonctions in
  let nb = analyse_tds_bloc tds None prog in
  (AstTds.Enums nenum,AstTds.Programme (nf,nb))
