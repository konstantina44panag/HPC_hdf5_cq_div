#!/bin/bash
set -eu

export PATH=$PATH:/users/pa24/kpanag/.local/bin

if [ -z "${LD_LIBRARY_PATH+x}" ]; then
    export LD_LIBRARY_PATH=/users/pa24/kpanag/local/lib
else
    export LD_LIBRARY_PATH=/users/pa24/kpanag/local/lib:$LD_LIBRARY_PATH
fi

# Function to process a single month
process_month() {
    year=$1
    month=$(printf "%02d" $((10#$2)))
    hdf5_file="/work/pa24/kpanag/output/${year}${month}.h5"
    SAS_FILES=()
    declare -A SAS_FILES_GROUP
    declare -A SAS_FILES_TYPE
    y=$(printf '%02d' $(expr $year \% 100))
    for d in $(seq -f "%02g" 1 1 10); do
        for type in cq ; do
            file_pattern="/work/pa24/kpanag/taq${year}taq${y}*/m${year}${month}/${type}_${year}${month}${d}.sas7bdat.*"
            for file_name in $file_pattern; do
                if [ -e "$file_name" ]; then
                    SAS_FILES+=("$file_name")
                    SAS_FILES_GROUP["$file_name"]="${d}"
                    SAS_FILES_TYPE["$file_name"]="$type"
                fi
            done
        done
    done
    for type in div ; do
        file_pattern="/work/pa24/kpanag/taq${year}taq${y}*/m${year}${month}/${type}_${year}${month}.sas7bdat.*"
        for file_name in $file_pattern; do
            if [ -e "$file_name" ]; then
                SAS_FILES+=("$file_name")
                SAS_FILES_GROUP["$file_name"]="monthly"
                SAS_FILES_TYPE["$file_name"]="$type"
            fi
        done
    done

    for SAS_FILE in "${SAS_FILES[@]}"; do
        BASE_NAME="${SAS_FILE%.*}"
        TYPE_NAME="${SAS_FILES_TYPE["$SAS_FILE"]}"
        if [[ $TYPE_NAME == "cq" ]]; then
            GROUP_NAME="day${SAS_FILES_GROUP["$SAS_FILE"]}"
        else
            GROUP_NAME="${SAS_FILES_GROUP["$SAS_FILE"]}"
        fi

        if [[ $SAS_FILE == *.bz2 ]]; then
            bzip2 -dk "$SAS_FILE"
        elif [[ $SAS_FILE == *.gz ]]; then
            gzip -dk "$SAS_FILE"
        fi

        readstat "$BASE_NAME" - |python3.11 /work/pa24/kpanag/scripts/corrected_run/taq93_06/hdf_struct2.py "$hdf5_file" "$GROUP_NAME" "$TYPE_NAME"
        echo "$SAS_FILE to $hdf5_file."
        rm "$BASE_NAME"
        rm "$SAS_FILE"
    done
}

process_month "$1" "$2"
