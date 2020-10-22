// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MAP{
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mapping', publish_id:'') }
    
    conda (params.enable_conda ? "bioconda::bwa-mem2=2.1 bioconda::samtools=1.10" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/bwa-mem2:2.0--he513fc3_0" //version does not match with conda, but conda version is more up to date
    } else {
        container "quay.io/biocontainers/bwa-mem2:2.0--he513fc3_0"//version does not match with conda, but conda version is more up to date
    }

    input:
        tuple val(name), path(read1), path(read2)
        path (reference)

    output:
        tuple val(name), path ("*.cram")

    script:
    def software = getSoftwareName(task.process)
    //        -R \"${readGroup}\" \
  //extra = meta.status == 1 ? "-B 3" : "" when tumor than allow for a smaller mismatch penalty...why? will leave by default for now
    """
    bwa-mem2 mem ${options.args} -t ${task.cpus} ${reference} ${read1} ${read2} | samtools sort -@ ${task.cpus} -O cram
    echo \$(bwa-mem2 version 2>&1) > bwa-mem2.version.txt
    """
    //samtools may need different memory setting
}