open Rat
open Compilateur
open Exceptions

exception ErreurNonDetectee

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../../tests/gestion_id/sans_fonction/fichiersRat/"

(**********)
(*  TESTS *)
(**********)

(* test Pointeur *)

let%test_unit "testPointeurSujet.rat" =
  let _ = compiler (pathFichiersRat^"testPointeurSujet.rat") in ()

let%test_unit "testDeref.rat" =
  let _ = compiler (pathFichiersRat^"testDeref.rat") in ()

let%test_unit "testPointeurSurPointeur.rat" =
  let _ = compiler (pathFichiersRat^"testPointeurSurPointeur.rat") in ()

let%test_unit "testPointeur1.rat" =
  let _ = compiler (pathFichiersRat^"testPointeur1.rat") in ()

let%test_unit "testPointeur2.rat" =
  try 
    let _ = compiler (pathFichiersRat^"testPointeur2.rat") 
    in raise ErreurNonDetectee
  with
  | MauvaiseUtilisationIdentifiant ("x") -> ()

let%test_unit "testPointeur3.rat" =
  try 
    let _ = compiler (pathFichiersRat^"testPointeur3.rat") 
    in raise ErreurNonDetectee
  with
  | MauvaiseUtilisationIdentifiant ("foo") -> ()

let%test_unit "testPointeur4.rat" =
  try 
    let _ = compiler (pathFichiersRat^"testPointeur4.rat") 
    in raise ErreurNonDetectee
  with
  | MauvaiseUtilisationIdentifiant ("c") -> ()

(* test Procedure *)

let%test_unit "testVoidSujet.rat" =
  let _ = compiler (pathFichiersRat^"testVoidSujet.rat") in ()

let%test_unit "testVoid1.rat" =
  let _ = compiler (pathFichiersRat^"testVoid1.rat") in ()

let%test_unit "testVoid2.rat" =
  let _ = compiler (pathFichiersRat^"testVoid2.rat") in ()

let%test_unit "testVoid3.rat" =
  try 
    let _ = compiler (pathFichiersRat^"testVoid3.rat") 
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare ("afficher") -> ()

let%test_unit "testVoid4.rat" =
  try 
    let _ = compiler (pathFichiersRat^"testVoid4.rat") 
    in raise ErreurNonDetectee
  with
  | DoubleDeclaration ("test") -> ()

let%test_unit "testVoid5.rat" =
  try 
    let _ = compiler (pathFichiersRat^"testVoid5.rat") 
    in raise ErreurNonDetectee
  with
  | RetourDansProcedure -> ()

let%test_unit "testVoid6.rat" =
  try 
    let _ = compiler (pathFichiersRat^"testVoid6.rat") 
    in raise ErreurNonDetectee
  with
  | RetourDansMain -> ()

let%test_unit "testVoid7.rat" =
  try 
    let _ = compiler (pathFichiersRat^"testVoid7.rat") 
    in raise ErreurNonDetectee
  with
  | MauvaiseUtilisationIdentifiant ("test") -> ()

(* test passage des patamètres par références *)

let%test_unit "testRef1.rat" =
  let _ = compiler (pathFichiersRat^"testRef1.rat") in ()

let%test_unit "testRef2.rat" =
  try
    let _ = compiler (pathFichiersRat^"testRef2.rat") 
    in raise ErreurNonDetectee
  with
  | MauvaiseUtilisationReference -> ()

let%test_unit "testRef3.rat" =
  try
    let _ = compiler (pathFichiersRat^"testRef3.rat") 
    in raise ErreurNonDetectee
  with
  | MauvaiseUtilisationIdentifiant("c") -> ()

let%test_unit "testRef4.rat" =
  try
    let _ = compiler (pathFichiersRat^"testRef4.rat") 
    in raise ErreurNonDetectee
  with
  | DoubleDeclaration ("x") -> ()

(* tests des types énumérés *)

let%test_unit "testEnum1.rat" =
  let _ = compiler (pathFichiersRat^"testEnum1.rat") in ()

let%test_unit "testEnum2.rat" =
  let _ = compiler (pathFichiersRat^"testEnum2.rat") in ()

let%test_unit "testEnum3.rat" =
  try
    let _ = compiler (pathFichiersRat^"testEnum3.rat") 
    in raise ErreurNonDetectee
  with
  | DoubleDeclaration ("Couleur") -> ()

let%test_unit "testEnum4.rat" =
  try
    let _ = compiler (pathFichiersRat^"testEnum4.rat") 
    in raise ErreurNonDetectee
  with
  | DoubleDeclaration ("Rouge") -> ()

let%test_unit "testEnum5.rat" =
  try
    let _ = compiler (pathFichiersRat^"testEnum5.rat") 
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare ("Jaune") -> ()

(*****************)

let%test_unit "testAffectation1" = 
  let _ = compiler (pathFichiersRat^"testAffectation1.rat") in ()

let%test_unit "testAffectation2"= 
  try 
    let _ = compiler (pathFichiersRat^"testAffectation2.rat") 
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("y") -> ()

let%test_unit "testAffectation3" = 
  let _ = compiler (pathFichiersRat^"testAffectation3.rat") in ()

let%test_unit "testAffectation4" = 
  try 
    let _ = compiler (pathFichiersRat^"testAffectation4.rat")
    in raise ErreurNonDetectee
  with
  | MauvaiseUtilisationIdentifiant("x") -> ()

let%test_unit "testUtilisation1" = 
  let _ = compiler (pathFichiersRat^"testUtilisation1.rat") in ()

  let%test_unit "testUtilisationConstante" = 
    let _ = compiler (pathFichiersRat^"testUtilisationConstante.rat") in ()

let%test_unit "testUtilisation2" = 
  let _ = compiler (pathFichiersRat^"testUtilisation2.rat") in ()

let%test_unit "testUtilisation3" = 
  try 
    let _ = compiler (pathFichiersRat^"testUtilisation3.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("y") -> ()

let%test_unit "testUtilisation10" = 
  try 
    let _ = compiler (pathFichiersRat^"testUtilisation10.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("x") -> ()

let%test_unit "testUtilisation11" = 
  try 
    let _ = compiler (pathFichiersRat^"testUtilisation11.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("z") -> ()

let%test_unit "testUtilisation12" = 
  try 
    let _ = compiler (pathFichiersRat^"testUtilisation12.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("z") -> ()

let%test_unit "testUtilisation13" = 
  try 
    let _ = compiler (pathFichiersRat^"testUtilisation13.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("z") -> ()

let%test_unit "testUtilisation14" = 
  try 
    let _ = compiler (pathFichiersRat^"testUtilisation14.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("z") -> ()

let%test_unit "testUtilisation15" = 
  try 
    let _ = compiler (pathFichiersRat^"testUtilisation15.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("z") -> ()

let%test_unit "testUtilisation16" = 
  try 
    let _ = compiler (pathFichiersRat^"testUtilisation16.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("y") -> ()

let%test_unit "testUtilisation17" = 
  try 
    let _ = compiler (pathFichiersRat^"testUtilisation17.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("y") -> ()

let%test_unit "testUtilisation18" = 
  try 
    let _ = compiler (pathFichiersRat^"testUtilisation18.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("y") -> ()

let%test_unit "testUtilisation19" = 
  try 
    let _ = compiler (pathFichiersRat^"testUtilisation19.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("y") -> ()

let%test_unit "testRecursiviteVariable" = 
  try 
    let _ = compiler (pathFichiersRat^"testRecursiviteVariable.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare("x") -> ()

(* Fichiers de tests de la génération de code -> doivent passer la TDS *)
open Unix
open Filename

let rec test d p_tam = 
  try 
    let file = readdir d in
    if (check_suffix file ".rat") 
    then
    (
     try
       let _ = compiler  (p_tam^file) in (); 
     with e -> print_string (p_tam^file); print_newline(); raise e;
    )
    else ();
    test d p_tam
  with End_of_file -> ()

let%test_unit "all_tam" =
  let p_tam = "../../../../../tests/tam/sans_fonction/fichiersRat/" in
  let d = opendir p_tam in
  test d p_tam
