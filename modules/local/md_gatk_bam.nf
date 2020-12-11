// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MD_GATK_BAM{
    label 'process_md'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mark_duplicates', publish_id:'') }

    conda (params.enable_conda ? "bioconda::gatk4-spark=4.1.9.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/gatk4-spark:4.1.9.0--0 "
        
    } else {
        container "quay.io/biocontainers/gatk4-spark:4.1.9.0--0"
    }

    input:
        tuple val(name), path(bam)
        path(dict) //need to be present in the path
        path(fai)  //need to be present in the path

    output:
        tuple val(name), path('*.md.bam')

    script:
    def software = getSoftwareName(task.process)
    markdup_java_options = "\"-Xms" +  (task.memory.toGiga() / 2   ).trunc() + "g -Xmx" + (task.memory.toGiga() - 1) + "g\""
    //markdup_java_options = task.memory.toGiga() > 8 ? params.markdup_java_options : "\"-Xms" +  (task.memory.toGiga() / 2).trunc() + "g -Xmx" + (task.memory.toGiga() - 1) + "g\""

    """
    gatk --java-options ${markdup_java_options} \
        MarkDuplicates \
        --MAX_RECORDS_IN_RAM 50000 \
        --I ${bam} \
        -M ${bam.simpleName}.md.metrics \
        --TMP_DIR . \
        --ASSUME_SORT_ORDER coordinate \
        -O ${bam.simpleName}.md.bram \
    """
   // there is a lot to unpack here
   //        --MAX_RECORDS_IN_RAM 50000 \ is this benchmarked somewhere? -> the number here seems to be 10x lower than the default number, whhy is that? try at least once with the default options

}