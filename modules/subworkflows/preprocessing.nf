
params.seqkit_options        = [:]
params.bwamem2_options       = [:]


include { SPLIT_FASTQ     } from '../local/splitfastq.nf' addParams( options: params.seqkit_options  )
include { MAP     } from '../local/mapping.nf' addParams( options: params.bwamem2_options  )
include { BWAMEM2_INDEX   } from '../local/index.nf'
//include { MERGE_BAM } from '../local/merge.nf' addParams( options: params.bwamem2_options  )
// include { MD_GATK}
// include { MD_ADAM}
// include { MD_SAMBAMBA}

workflow PREPROCESSING {

    take:
        reads   // channel: [ val(name), [ reads ] ]
        fasta

    main:
        SPLIT_FASTQ(reads)
        split_reads = SPLIT_FASTQ.out.map{
            key, reads ->
                //TODO maybe this can be replaced by a regex to include part_001 etc.

                //sorts list of split fq files by :
                //[R1.part_001, R2.part_001, R1.part_002, R2.part_002,R1.part_003, R2.part_003,...]
                //TODO: determine whether it is possible to have an uneven number of parts, so remainder: true woud need to be used
                return [key, reads.sort{ a,b -> a.getName().tokenize('.')[ a.getName().tokenize('.').size() - 3] <=> b.getName().tokenize('.')[ b.getName().tokenize('.').size() - 3]}
                                        .collate(2)]
        }.transpose()

        BWAMEM2_INDEX(fasta)

        split_reads.dump()
        BWAMEM2_INDEX.out.dump()
        
        MAP(split_reads, fasta, BWAMEM2_INDEX.out) //BWAMEM2_MEM(reads_input, bwa, fasta, fai)



    // Step 1

    // Step 2: Mapping

    // Step 3: Merging Bams

    // Step 4: MarkDuplicates
    emit:
        split_reads
}