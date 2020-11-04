include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process SAMTOOLS_FAIDX {

    publishDir params.outdir, mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:"false") }

    conda (params.enable_conda ? "bioconda::samtools=1.10" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/samtools:1.10--h2e538c0_3"
    } else {
        container "quay.io/biocontainers/samtools:1.10--h2e538c0_3"
    }

    input:
        path fasta

    output:
        path "${fasta}.fai"

    script:
    def software = getSoftwareName(task.process)
    def ioptions = initOptions(options)
    """
    samtools faidx ${fasta}

    echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/ Using.*\$//' > ${software}.version.txt
    """
}