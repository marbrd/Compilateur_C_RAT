# Compilateur RAT → TAM

Ce projet est un **compilateur pour le langage Rat**, un langage proche du C, écrit en **OCaml**. Il traduit un fichier source `.rat` en code assembleur **TAM** (Three Address Machine), exécutable ensuite via une machine virtuelle Java.

## Fonctionnalités du langage Rat

D'après le code source (`ast.ml`, `type.ml`, `tds.ml`, `passe*.ml`) et les fichiers de test, le langage supporte :

- **Types** : `int`, `bool`, `rat` (nombres rationnels, ex. `[4/5]`), `void`, pointeurs (`int*`, ...), et types énumérés (`enum`)
- **Déclarations et affectations** de variables
- **Structures de contrôle** : `if / else`, `while`
- **Fonctions et procédures** : déclaration, appel, récursivité, passage de paramètres, valeur de retour
- **Pointeurs** : allocation dynamique (`new`), déréférencement (`*p`), adresse (`&x`)
- **Énumérations** (`enum`)
- **Affichage** (`print`)
- Opérateurs arithmétiques, booléens et de comparaison

## Architecture du compilateur

Le compilateur est organisé en pipeline de passes successives, assemblées dans `compilateur.ml` :

```
fichier .rat
    │  Lexer (lexer.mll) + Parser (parser.mly / Menhir)
    ▼
   AST
    │  PasseTdsRat        → résolution des identifiants (table des symboles)
    ▼
  AST typé (tds)
    │  PasseTypeRat       → vérification et inférence de type
    ▼
  AST typé
    │  PassePlacementRat  → calcul du placement mémoire des variables
    ▼
  AST placé
    │  PasseCodeRatToTam  → génération de code
    ▼
  code TAM (string)
```

### Fichiers principaux (`sourceEtu/`)

| Fichier | Rôle |
|---|---|
| `lexer.mll` | Analyseur lexical |
| `parser.mly` | Analyseur syntaxique (grammaire Menhir) |
| `ast.ml` | Définition de l'arbre de syntaxe abstraite (aux différentes étapes) |
| `tds.ml` / `tds.mli` | Table des symboles |
| `type.ml` / `type.mli` | Système de types |
| `passe.ml` | Signature générique d'une passe |
| `passeTdsRat.ml` | Passe de gestion des identifiants |
| `passeTypeRat.ml` | Passe de typage |
| `passePlacementRat.ml` | Passe de placement mémoire |
| `passeCodeRatToTam.ml` | Passe de génération de code TAM |
| `code.ml` / `code.mli` | Génération des instructions TAM |
| `tam.ml` / `tam.mli` | Utilitaires liés à la machine TAM |
| `printerAst.ml` | Affichage/débogage de l'AST |
| `exceptions.ml` | Exceptions du compilateur (erreurs de typage, d'identifiants, etc.) |
| `compilateur.ml` | Point d'entrée : assemble les passes et expose `compiler` / `compilerVersFichier` |

## Prérequis

- OCaml et [dune](https://dune.build/)
- [Menhir](http://gallium.inria.fr/~fpottier/menhir/) et `ocamllex`
- `ppx_inline_test` et `ppx_expect` (pour les tests)
- Java (pour exécuter le code TAM généré via `tests/runtam.jar`)

Installation des dépendances via opam :

```bash
opam install dune menhir ppx_inline_test ppx_expect
```

## Compilation du projet

```bash
cd sourceEtu
dune build
```

## Utilisation

Depuis un toplevel OCaml lancé avec `dune utop`, en ouvrant le module `Compilateur` :

```bash
cd sourceEtu
dune utop .
```

```ocaml

> open Rat;;
> open Compilateur ;;
> compiler "fichiersRat/test.rat" ;;
> compilerVersFichier "fichiersRat/test.rat" "out.tam";;
```

```bash
java -jar sourceEtu/tests/runtam.jar sortie.tam
```

## Tests

Le projet contient une suite de tests `dune`/`ppx_expect`, organisée en plusieurs familles.

Lancer un ensemble des tests spécifiques:

```bash
dune runtest tests/XXX/XXX
```

Lancer l'ensemble des tests :

```bash
cd sourceEtu
dune runtest
```


## Exemple

```rat
int fact (int i, int n){
  int res = 0;
  if (i=n){
    res = i;
  } else {
    res = (i * fact((i+1), n));
  }
  return res;
}

test{
  int x = fact(1, 5);
  print x;
}
```

Compile en code TAM affichant `120`.
