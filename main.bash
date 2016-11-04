#!/bin/bash

HASH_FILE="/tmp/bighash"
MAIN_FIRST_DIR="$PWD"
FIRST_DIR="dossier_1"
MAIN_SECOND_DIR="$PWD"
SECOND_DIR="dossier_2"

#si l'utilisateur veut comparer des dossiers spécifiques, sinon c'est dossier_1 et dossier_2 qui sont utilisés
if [[ -d "$1" && -d "$2" ]]; then
  MAIN_FIRST_DIR="$(dirname "$(realpath "$1")")"
  FIRST_DIR="$(basename "$1")"
  MAIN_SECOND_DIR="$(dirname "$(realpath "$2")")"
  SECOND_DIR="$(basename "$2")"
fi

export HASH_FILE
export MAIN_FIRST_DIR
export FIRST_DIR
export MAIN_SECOND_DIR
export SECOND_DIR

if [ -f "$HASH_FILE" ]; then
  rm "$HASH_FILE"
fi

#hach tous les fichiers contenuent dans le repertoire donné en parametre et irra meme visiter les sous dossiers !
function make_hash {
  local path
  for path in "$1"/*; do
    if [ -d "$path" ]; then
      if [ "$(ls -A "$path")" ]; then
        #si c'est un dossier pas vide alors on part hacher les fichiers qui sont à l'interieur
        make_hash "$path"
      else
        #si c'est un dossier vide alors on le rajoute au hach parce qu'il a besoin d'exister
        echo "" | md5sum | sed "s|-|$path/|g" >> "$HASH_FILE"
      fi
    else
      if [ -f "$path" ]; then
        #si c'est un fichier alors on le hache
        md5sum "$(realpath "$path")" >> "$HASH_FILE"
      fi
    fi
  done
}

function compare_hash {
  #contient la liste des fichiers qui peuvent être modifiés ou qui existent que d'un seul coté
  different_files="$(cat "$HASH_FILE" | sed -e "s|$MAIN_FIRST_DIR/$FIRST_DIR||g" -e "s|$MAIN_SECOND_DIR/$SECOND_DIR||g" | sort | uniq -u)"

  #liste des fichiers modifiés
  modified_files="$(echo "$different_files" | cut -d ' ' -f 3 | sort | uniq -d)"

  #liste des fichiers qui existent que dans un seul des deux repertoires
  new_files="$(echo "$different_files" | cut -d ' ' -f 3 | sort | uniq -u)"

  echo "modified_files:"
  echo "$modified_files"

  echo "new_files:"
  if [[ ! -z "$new_files" ]]; then
    while read line; do
      cat "$HASH_FILE" | grep "^[[:alnum:]]\{32\}[[:space:]]\{2\}\($MAIN_FIRST_DIR/$FIRST_DIR\|$MAIN_SECOND_DIR/$SECOND_DIR\)$line$" | cut -d ' ' -f 3 | sed -e "s|$MAIN_FIRST_DIR||g" -e "s|$MAIN_SECOND_DIR||g"
    done < <(echo "$new_files")
  fi
}

function print_tree {
  local path sub_file sub_dir nb_files i
  sub_file="├── "
  sub_dir="│   "
  nb_files="$(ls -1 $1 | wc -l)"
  i=1
  for path in "$1"/*; do

    file_name="$(basename "$path")"
    if [ "$(echo "$path" | grep "$modified_files")" ]; then
      file_name="\e[33m$file_name\e[0m"
    else
      if [ "$(echo "$path" | grep "$new_files")" ]; then
         file_name="\e[32m$file_name\e[0m"
      fi
    fi

    if [ "$i" -eq "$nb_files" ]; then
      sub_file="└── "
      sub_dir="    "
    fi

    echo -e "$3$sub_file$file_name"

    if [ -d "$path" ]; then
      print_tree "$path" "$(expr "$2" + 1)" "$3$sub_dir"
    fi
    i=$(expr "$i" + 1)
  done
}

function print_result {
  #alex voila là où tu vas faire tes devoirs :)
  #comme je peux pas laisser la fonction qu'avec des com j'affiche un truc
  echo "les dossiers sont identiques"
}

make_hash "$MAIN_FIRST_DIR/$FIRST_DIR"
make_hash "$MAIN_SECOND_DIR/$SECOND_DIR"

compare_hash
#print_result
echo "$FIRST_DIR"
print_tree "$MAIN_FIRST_DIR/$FIRST_DIR" 0 ""
