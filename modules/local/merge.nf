include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MERGE_BAM {
    label 'process_medium'

    publishDir params.outdir, mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::samtools=1.10" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/samtools:1.10--h2e538c0_3" //version does not match with conda, but conda version is more up to date
    } else {
        container "quay.io/biocontainers/samtools:1.10--h2e538c0_3"//version does not match with conda, but conda version is more up to date
    }

    input:
        tuple val(name), path(cram)

    output:
        tuple val(name), path("*.cram"), emit: cram

    script:
    def name_2 = options.suffix ? "${name}.${options.suffix}" : "${name}"
    """
    samtools merge --threads ${task.cpus} ${name_2}.cram ${cram}
    """
}
