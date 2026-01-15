/* Imports. */

%{

open Type
open Ast.AstSyntax
%}


%token <int> ENTIER
%token <string> ID
%token RETURN
%token VIRG
%token PV
%token AO
%token AF
%token PF
%token PO
%token EQUAL
%token CONST
%token PRINT
%token IF
%token ELSE
%token WHILE
%token BOOL
%token INT
%token RAT
%token CO
%token CF
%token SLASH
%token NUM
%token DENOM
%token TRUE
%token FALSE
%token PLUS
%token MULT
%token INF
%token NEW
%token NULL
%token ESPERLUETTE
%token VOID
%token REF
%token ENUM 
%token <string> TID
%token EOF

(* Type de l'attribut synthétisé des non-terminaux *)
%type <programme> prog
%type <enumeration> enum
%type <enums> enums
%type <instruction list> bloc
%type <fonction> fonc
%type <instruction> i
%type <affectable> a
%type <typ> typ
%type <(typ*bool)*string> param
%type <expression> e 

(* Type et définition de l'axiome *)
%start <Ast.AstSyntax.enums*Ast.AstSyntax.programme> main

%%

main : en=enums lfi=prog EOF     {(en,lfi)}

enum : ENUM tid=TID AO le=separated_list(VIRG,TID) AF PV       {Enumeration (tid,le)}   

enums : len=enum*                    {Enums len}

prog : lf=fonc* ID li=bloc  {Programme (lf,li)}

fonc : t=typ n=ID PO lp=separated_list(VIRG,param) PF li=bloc {Fonction(t,n,lp,li)}

ref: 
| REF   {true}
|       {false}

param : r=ref t=typ n=ID  {((t,r),n)}

bloc : AO li=i* AF      {li}

i :
| n=ID PO lp=separated_list(VIRG,e) PF PV  {AppelProcedure (n,lp)}
| t=typ n=ID EQUAL e1=e PV          {Declaration (t,n,e1)}
| aff=a EQUAL e1=e PV               {Affectation (aff,e1)}
| CONST n=ID EQUAL e=ENTIER PV      {Constante (n,e)}
| PRINT e1=e PV                     {Affichage (e1)}
| IF exp=e li1=bloc ELSE li2=bloc   {Conditionnelle (exp,li1,li2)}
| WHILE exp=e li=bloc               {TantQue (exp,li)}
| RETURN exp=e PV                   {Retour (exp)}
| RETURN PV                         {FinVoid}

typ :
| BOOL          {Bool}
| INT           {Int}
| RAT           {Rat}
| VOID          {Void}
| t=typ MULT    {Pointeur(t)}
| tid=TID       {Tenum (tid)}

e : 
| n=ID PO lp=separated_list(VIRG,e) PF   {AppelFonction (n,lp)}
| CO e1=e SLASH e2=e CF   {Binaire(Fraction,e1,e2)}
| aff=a                   {Affectable aff} 
| ESPERLUETTE i=ID        {Adresse i}
| PO NEW t=typ PF         {New t}
| NULL                    {Null} 
| TRUE                    {Booleen true}
| FALSE                   {Booleen false}
| e=ENTIER                {Entier e}
| NUM e1=e                {Unaire(Numerateur,e1)}
| DENOM e1=e              {Unaire(Denominateur,e1)}
| PO e1=e PLUS e2=e PF    {Binaire (Plus,e1,e2)}
| PO e1=e MULT e2=e PF    {Binaire (Mult,e1,e2)}
| PO e1=e EQUAL e2=e PF   {Binaire (Equ,e1,e2)}
| PO e1=e INF e2=e PF     {Binaire (Inf,e1,e2)}
| PO exp=e PF             {exp}
| REF e1=e                {Reference e1} 
| tid=TID                 {Evaleur tid}


a :
| n=ID                     {Ident n} 
| PO MULT aff=a PF         {Deref aff}