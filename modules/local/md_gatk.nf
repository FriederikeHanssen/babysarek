// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MD_GATK{
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
        tuple val(name), path(cram)
        path(reference)
        path(dict) //need to be present in the path
        path(fai)  //need to be present in the path

    output:
        tuple val(name), path('*.md.cram')

    script:
    def software = getSoftwareName(task.process)
    markdup_java_options = "\"-Xms" +  (task.memory.toGiga() / 2   ).trunc() + "g -Xmx" + (task.memory.toGiga() - 1) + "g\""

    """
    export SPARK_LOCAL_IP=127.0.0.1
    export SPARK_PUBLIC_DNS=127.0.0.1

    gatk  \
        MarkDuplicatesSpark \
        -I ${cram} \
        -O ${cram.simpleName}.md.cram \
        -M ${cram.simpleName}.md.metrics \
        --reference ${reference} \
        --tmp-dir . 
    """
    //--java-options ${markdup_java_options} 
    //--spark-master local[${task.cpus}]  
    //Prob not needed as I am using crams now      --create-output-bam-index true \

    //   export GATK_LOCAL_JAR=/root/gatk.jar
    // gatk --java-options "-Dsamjdk.compression_level=~{compression_level} -Xmx~{java_memory_size}g" \
    //   MarkDuplicatesSpark \
    //   --input ~{sep=' --input ' input_bams} \
    //   --output ~{output_bam_location} \
    //   --metrics-file ~{metrics_filename} \
    //   --read-validation-stringency SILENT \ -> set by default
    //   ~{"--read-name-regex " + read_name_regex} \
    //   --optical-duplicate-pixel-distance 2500 \ -> by default much smaller, not sure why they have such a large value here
    //   --treat-unsorted-as-querygroup-ordered \ -> warning to use it, so maybe i should skip this for now
    //   --create-output-bam-index false \

    //TODO: I should try this later maybe this finally helps to speed things up
    //   -- --conf spark.local.dir=/mnt/tmp --spark-master 'local[16]' --conf 'spark.kryo.referenceTracking=false'
    //                                                                   , apparently the above could improve perfomrance, but not sure whether this is safe?
    //        --tmp-dir . \ #TODO: make sure htis is really correct, there was something weird with it

}