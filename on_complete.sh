#!/usr/bin/env bash

DOWNLOAD_DIR="/mnt/nvme/data/transmission/completed"

TV_DIR="/mnt/nvme/data/media/TVShows"
MOVIES_DIR="/mnt/nvme/data/media/Movies"
MUSIC_DIR="/mnt/nvme/data/media/Music"
BOOKS_DIR="/mnt/nvme/data/media/Books"
OTHER_DIR="/mnt/nvme/data/media/Others"

mkdir -p "$TV_DIR" "$MOVIES_DIR" "$MUSIC_DIR" "$BOOKS_DIR" "$OTHER_DIR"

move_to_dir() {
    local item="$1"
    local target_dir="$2"
    echo "Moving '$item' -> '$target_dir'"
    mv "$item" "$target_dir"
}

is_tv_show() {
    local item="$1"
    if [ -d "$item" ]; then
        if find "$item" -type f -iname '*[sS][0-9][0-9][-:]*[eE][0-9][0-9]*' | grep -q .; then
            return 0
        else
            return 1
        fi
    else
        if [[ "$(basename "$item")" =~ [sS][0-9][0-9][-:]?[eE][0-9][0-9] ]]; then
            return 0
        else
            return 1
        fi
    fi
}

is_movie() {
    local item="$1"
    if [ -d "$item" ]; then
        if find "$item" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) | grep -q .; then
            return 0
        else
            return 1
        fi
    else
        [[ "$item" =~ \.(mkv|mp4|avi)$ ]] && return 0 || return 1
    fi
}

is_music() {
    local item="$1"
    if [ -d "$item" ]; then
        if find "$item" -type f \( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.wav' \) | grep -q .; then
            return 0
        else
            return 1
        fi
    else
        [[ "$item" =~ \.(mp3|flac|wav)$ ]] && return 0 || return 1
    fi
}

is_book() {
    local item="$1"
    if [ -d "$item" ]; then
        if find "$item" -type f \( -iname '*.pdf' -o -iname '*.epub' -o -iname '*.mobi' \) | grep -q .; then
            return 0
        else
            return 1
        fi
    else
        [[ "$item" =~ \.(pdf|epub|mobi)$ ]] && return 0 || return 1
    fi
}


shopt -s nullglob
for item in "$DOWNLOAD_DIR"/*; do
    [ -e "$item" ] || continue

    if is_tv_show "$item"; then
        move_to_dir "$item" "$TV_DIR"
    elif is_movie "$item"; then
        move_to_dir "$item" "$MOVIES_DIR"
    elif is_music "$item"; then
        move_to_dir "$item" "$MUSIC_DIR"
    elif is_book "$item"; then
        move_to_dir "$item" "$BOOKS_DIR"
    else
        move_to_dir "$item" "$OTHER_DIR"
    fi
done
