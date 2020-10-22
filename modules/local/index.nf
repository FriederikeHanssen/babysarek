
include { initOptions; saveFiles; getSoftwareName } from './functions'

process BWAMEM2_INDEX {
    tag "${fasta}"
    label 'process_high'
    //publishDir "${params.outdir}",
     //   mode: params.publish_dir_mode,
      //  saveAs: { params.save_reference ? filename -> saveFiles(filename:filename, options:params.options, publish_dir:'reference_genome/BWAIndex/${it}', publish_id:'') : null}
    
    conda (params.enable_conda ? "bioconda::bwa-mem2=2.1" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/bwa-mem2:2.0--he513fc3_0" //version does not match with conda, but conda version is more up to date
    } else {
        container "quay.io/biocontainers/bwa-mem2:2.0--he513fc3_0"//version does not match with conda, but conda version is more up to date
    }

    input:
        path fasta

    output:
        path "${fasta}.*"

    script:
    """
    bwa-mem2 index ${fasta}
    """
}