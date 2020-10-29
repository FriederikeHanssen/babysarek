// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MD_GATK{
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mark_duplicates', publish_id:'') }
    
    conda (params.enable_conda ? "bioconda::gatk=3.8--7" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/gatk:3.8--py36_4"
    } else {
        container "quay.io/biocontainers/gatk:3.8--7"
    }

    input:
        tuple val(name), path(cram)

    output:

    script:
    def software = getSoftwareName(task.process)
   
    """
    
    """
}