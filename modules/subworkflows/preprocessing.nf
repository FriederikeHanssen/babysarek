
params.seqkit_options        = [:]

include { SPLIT_FASTQ     } from '../local/splitfastq.nf' addParams( options: params.seqkit_options  )

workflow PREPROCESSING {

    take:
        reads   // channel: [ val(name), [ reads ] ]

    main:
        SPLIT_FASTQ(reads)
        split_reads = SPLIT_FASTQ.out

    // Step 1

    // Step 2: Mapping

    // Step 3: MarkDuplicates
    emit:
        split_reads
}