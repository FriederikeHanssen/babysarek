
params.seqkit_options        = [:]
params.bwamem2_options       = [:]


include { SPLIT_FASTQ     } from '../local/splitfastq.nf' addParams( options: params.seqkit_options  )
include { MAP     } from '../local/mapping.nf' addParams( options: params.bwamem2_options  )

workflow PREPROCESSING {

    take:
        reads   // channel: [ val(name), [ reads ] ]

    main:
        SPLIT_FASTQ(reads)
        split_reads = SPLIT_FASTQ.out

        //MAP(split_reads)

    // Step 1

    // Step 2: Mapping

    // Step 3: MarkDuplicates
    emit:
        split_reads
}