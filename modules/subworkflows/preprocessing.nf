
params.seqkit_options        = [:]
params.bwamem2_options       = [:]


include { SPLIT_FASTQ     } from '../local/splitfastq.nf' addParams( options: params.seqkit_options  )
include { MAP     } from '../local/mapping.nf' addParams( options: params.bwamem2_options  )
include { BWAMEM2_INDEX   } from '../local/index.nf'
//include { MERGE_BAM }
// include { MD_GATK}
// include { MD_ADAM}
// include { MD_SAMBAMBA}

workflow PREPROCESSING {

    take:
        reads   // channel: [ val(name), [ reads ] ]
        fasta

    main:
        SPLIT_FASTQ(reads)
        split_reads = SPLIT_FASTQ.out

        BWAMEM2_INDEX(fasta)
        MAP(split_reads, BWAMEM2_INDEX.out) //BWAMEM2_MEM(reads_input, bwa, fasta, fai)



    // Step 1

    // Step 2: Mapping

    // Step 3: Merging Bams

    // Step 4: MarkDuplicates
    emit:
        split_reads
}