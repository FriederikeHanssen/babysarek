
params.seqkit_options        = [:]
params.dict_options          = [:]
params.fai_options          = [:]
params.bwamem2_options       = [:]
params.md_gatk_options       = [:] 
params.md_adam_options       = [:] 
params.md_sambamba_options       = [:] 

include { SPLIT_FASTQ     } from '../local/splitfastq.nf' addParams( options: params.seqkit_options  )
include { DICT }            from '../local/gatk_createsequencedictionary' addParams( options: params.dict_options  )
include { SAMTOOLS_FAIDX }  from '../local/create_fai.nf' addParams( options: params.fai_options  )

include { MAP     } from '../local/mapping.nf' addParams( options: params.bwamem2_options  )
include { BWAMEM2_INDEX   } from '../local/index.nf'
include { MERGE_CRAM } from '../local/merge_samtools.nf' addParams()
include { MERGE_SAMTOOLS_BAM } from '../local/merge_samtools_standalone.nf' addParams()
include { MERGE_SAMBAMBA_BAM } from '../local/merge_sambamba_standalone.nf' addParams()

include { MD_GATK} from '../local/md_gatk.nf' addParams( options: params.md_gatk_options  )
include { MD_ADAM} from '../local/md_adam.nf' addParams( options: params.md_adam_options  )

include { MD_GATK_BAM} from '../local/md_gatk_bam.nf' addParams( )
include { MD_ADAM_BAM} from '../local/md_adam_bam.nf' addParams( )
include { MD_SAMBAMBA} from '../local/md_sambamba.nf' addParams( )
include { MD_SAMBLASTER} from '../local/md_samblaster.nf' addParams(  )

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

        // Step 2: Mapping
        
        index  = params.index      ? file(params.index)       :   BWAMEM2_INDEX(fasta).out
        MAP(split_reads, fasta, index) //BWAMEM2_MEM(reads_input, bwa, fasta, fai)

        //Does the channel have to be merged somehow?
        mapped = MAP.out

        //TODO apparently not grouped correctly, all normal and tumor dsmaple were grouped together on AWS
        mapped_grouped = mapped.groupTuple()
        mapped_grouped.dump()

        // Step 3: Merging Bams
        
        

        // Step 4: MarkDuplicates
        duplicate_marked = Channel.empty()
        if (params.cram) {

            merge_cram_out = MERGE_CRAM(mapped_grouped, fasta)
            if(params.md_gatk){
                dict = params.dict ? file(params.dict) : DICT(fasta)
                faidx = params.faidx ? file(params.faidx) : SAMTOOLS_FAIDX(fasta)

                duplicate_marked = MD_GATK(merge_bam_out, fasta, dict, faidx)
            }else{
                if(params.md_adam){
                    duplicate_marked = MD_ADAM(merge_bam_out, fasta)
                }
            }
        } else{
            merge_bam_out = params.merge_samtools ? MERGE_SAMTOOLS_BAM(mapped_grouped).out : MERGE_SAMBAMBA_BAM(mapped_grouped).out
            //merge_bam_out.dump()
            if (params.md_gatk){
                dict = params.dict ? file(params.dict) : DICT(fasta)
                faidx = params.faidx ? file(params.faidx) : SAMTOOLS_FAIDX(fasta)

                duplicate_marked = MD_GATK_BAM()
            }else {
                if (params.md_adam){
                    duplicate_marked = MD_ADAM_BAM()
                }else{
                    if(params.md_sambamba){
                            duplicate_marked = MD_SAMBAMBA()
                        else { 
                            duplicate_marked = MD_SAMBLASTER()
                        }
                    }
                }
            }
        }





    emit:
        split_reads
}