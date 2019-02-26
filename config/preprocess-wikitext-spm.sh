#!/usr/bin/env bash

VOCAB_SIZE=$1
CORPORA_DIR=.data/wikitext-2/wikitext-2
DATA_DIR=.data/wikitext-2/${VOCAB_SIZE}
BPE_THRESHOLD=5
THREADS=16

if [ $# != 1 ]
then
    echo "You need to provide BPE vocab size as argument"
    exit
fi

rm -rf ${DATA_DIR}
mkdir -p ${DATA_DIR}
cp $0 ${DATA_DIR}/prepare.sh

cp .data/legal-chars.csv ${DATA_DIR}

for SPLIT in train valid test; do
    cat ${CORPORA_DIR}/wiki.${SPLIT}.tokens | replace-illegal-chars.py ${DATA_DIR}/legal-chars.csv > ${DATA_DIR}/${SPLIT}.raw.tokens
done

echo "Training spm model"
spm_train --input=${CORPORA_DIR}/wiki.train.tokens --model_prefix=${DATA_DIR}/spm \
          --model_type=bpe --vocab_size=${VOCAB_SIZE} --input_sentence_size=0 --num_threads=${THREADS} \
          --split_by_number=true --user_defined_symbols "<x>"

echo "Generating spm vocab"
spm_encode --model=${DATA_DIR}/spm.model --generate_vocabulary --output ${DATA_DIR}/spm.vocab ${DATA_DIR}/train.raw.tokens

echo "Encoding splits"
params="--model=${DATA_DIR}/spm.model --vocabulary_threshold=${BPE_THRESHOLD} --vocabulary=${DATA_DIR}/spm.vocab"
for SPLIT in train valid test; do
    spm_encode ${params} < ${DATA_DIR}/${SPLIT}.raw.tokens > ${DATA_DIR}/${SPLIT}.tokens
    rm ${DATA_DIR}/${SPLIT}.raw.tokens
done
