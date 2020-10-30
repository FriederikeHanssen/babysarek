// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MD_ADAM{
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mark_duplicates', publish_id:'') }
    
    conda (params.enable_conda ? "bioconda::adam=0.32.0--0" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/adam:0.32.0--0"
    } else {
        container "quay.io/biocontainers/adam:0.32.0--0"
    }

    input:
        tuple val(name), path(cram)
        path(reference)

    output:

    script:
    def software = getSoftwareName(task.process)
   
    """
    adam-submit \
       --master local[${task.cpus}] \
       --driver-memory ${task.memory.toGiga()}g \
       -- \
       transformAlignments \
       -mark_duplicate_reads \
       -single \
       ${cram} \
       ${cram.simpleName}.md.cram
    """
    //--master <mysparkmaster> 
    //\ --deploy-mode cluster \ --driver-memory 20g \ --executor-memory 20g \ --conf spark.driver.cores=16 \ --conf spark.executor.cores=16 \ --conf spark.yarn.executor.memoryOverhead=2048 \ --conf spark.executor.instances=3 \
    //  touch ${idSample}.bam.metrics
    //  samtools index ${idSample}.md.bam
}