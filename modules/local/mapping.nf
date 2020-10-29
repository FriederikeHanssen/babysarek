// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MAP{
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mapping', publish_id:'') }
    
    conda (params.enable_conda ? "bioconda::bwa-mem2=2.0 bioconda::samtools=1.10" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:876eb6f1d38fbf578296ea94e5aede4e317939e7-0" //version does not match with conda, but conda version is more up to date
    } else {
        container "quay.io/biocontainers/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:876eb6f1d38fbf578296ea94e5aede4e317939e7-0"//version does not match with conda, but conda version is more up to date
    }

    input:
        tuple val(name), path(reads)
        path(fasta)
        path (reference)

    output:
        tuple val(name), path ("*.bam")

    script:
    def software = getSoftwareName(task.process)
    //        -R \"${readGroup}\" \
    //extra = meta.status == 1 ? "-B 3" : "" when tumor than allow for a smaller mismatch penalty...why? will leave by default for now
    def name = reads.get(0).simpleName
    def part = reads.get(0).name.findAll(/part_([0-9]+)?/).last()
    """
    bwa-mem2 mem ${options.args} -t ${task.cpus} ${fasta} ${reads} | samtools sort -@ ${task.cpus} -m 2G -o${name}.${part}.bam -
    echo \$(bwa-mem2 version 2>&1) > bwa-mem2.version.txt
    """
    //samtools may need different memory setting -m 2G why not use task.memory
    //  samtools sort -O bam -l 0 -T /tmp - | \
//samtools view -T yeast.fasta -C -o yeast.cram - apparently crams can't be merged so do cram conversion after merging

}