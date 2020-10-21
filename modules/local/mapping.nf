// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MAP{
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mapping', publish_id:'') }
    
    conda (params.enable_conda ? "bioconda::bwa-mem2=2.1" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/bwa-mem2:2.0--he513fc3_0"
    } else {
        container "quay.io/biocontainers/bwa-mem2:2.0--he513fc3_0"
    }

    input:
        tuple val(name), path(read1), path(read2)

    output:
        tuple val(name), path ("*.gz")

    script:
    def software = getSoftwareName(task.process)
    """
    bwa split2 -1 $read1 -2 $read2 $options.args
    echo \$(seqkit --version 2>&1) > ${software}.version.txt
    """
}