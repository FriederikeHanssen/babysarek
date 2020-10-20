#!/usr/bin/env nextflow
/*
========================================================================================
                         FriederikeHanssen/babysarek
========================================================================================
 FriederikeHanssen/babysarek Analysis Pipeline.
 #### Homepage / Documentation
 https://github.com/FriederikeHanssen/babysarek
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl=2

// Print help message if required

// if (params.help) {
//     def command = "nextflow run FriederikeHanssen/babysarek -profile docker --input sample.tsv"
//     log.info Schema.params_help("$baseDir/nextflow_schema.json", command)
//     exit 0
// }

/*
================================================================================
                        INCLUDE SAREK FUNCTIONS
================================================================================
*/

/*
================================================================================
                        INCLUDE SAREK FUNCTIONS
================================================================================
*/

include {
    extract_fastq;
} from './modules/local/functions'

/*
================================================================================
                         SET UP CONFIGURATION VARIABLES
================================================================================
*/

// Check parameters

//Checks.aws_batch(workflow, params)     // Check AWS batch settings
//Checks.hostname(workflow, params, log) // Check the hostnames against configured profiles

/*
================================================================================
                         INCLUDE MODULES - Generic things
================================================================================
*/

def modules = params.modules.clone()

/*
================================================================================
                         INCLUDE LOCAL PIPELINE MODULES
================================================================================
*/


/*
================================================================================
                       INCLUDE LOCAL PIPELINE SUBWORKFLOWS
================================================================================
*/
include { PREPROCESSING } from './modules/subworkflows/preprocessing.nf' addParams( seqkit_options: modules['seqkit'])
/*
================================================================================
                        INCLUDE nf-core PIPELINE MODULES
================================================================================
*/

/*
================================================================================
                      INCLUDE nf-core PIPELINE SUBWORKFLOWS
================================================================================
*/

//include { PREPROCESSING } from './modules/subworkflows/preprocessing.nf'

/*
================================================================================
                        RUN THE WORKFLOW
================================================================================
*/

if (params.input) { 
    // Channel.from(params.input)
    //        .map { row -> [ row[0], file(row[1][0], checkIfExists: true), file(row[1][1], checkIfExists: true) ] }
    //        .ifEmpty { exit 1, "params.input was empty - no input files supplied" }
    //        .set { ch_input }
    ch_input = extract_fastq(params.input)

} else { 
    exit 1, "Input samplesheet file not specified!" 
}

workflow {

    /*
    ================================================================================
                                    PREPROCESSING
    ================================================================================
    */

    // CHECK_SAMPLESHEET(ch_input)
    //     .splitCsv(header:true, sep:',')
    //     .map { check_samplesheet_paths(it) }
    //     .set { ch_raw_reads }
    //ch_input.dump()

    //OPTION 1: Use seqkit
    PREPROCESSING(ch_input)

    split_read_pairs = PREPROCESSING.out.split_reads.map{
        key, reads ->
            //TODO maybe this can be replaced by a regex to include part_001 etc.

            //sorts list of split fq files by :
            //[R1.part_001, R2.part_001, R1.part_002, R2.part_002,R1.part_003, R2.part_003,...]
            //TODO: determine whether it is possible to have an uneven number of parts, so remainder: true woud need to be used
            return [key, reads.sort{ a,b -> a.getName().tokenize('.')[ a.getName().tokenize('.').size() - 3] <=> b.getName().tokenize('.')[ b.getName().tokenize('.').size() - 3]}
                                       .collate(2)]
    }.transpose()

    //OPTION 2: Use nextflow build in
    //ch_input.splitFastq( by: 10000 , file:true, pe: true, compress: true).set{split_read_pairs}


    split_read_pairs.dump()


    
    /*
    ================================================================================
                                BASERECALIBRATION
    ================================================================================
    */

    /*
    ================================================================================
                                GERMLINE VARIANT CALLING
    ================================================================================
    */
 
    /*
    ================================================================================
                                SOMATIC VARIANT CALLING
    ================================================================================
    */

    /*
    ================================================================================
                                    ANNOTATION
    ================================================================================
    */

    //these steps we should probably completely omit (for time comparison at least), this is what big sarek is for 

    /*
    ================================================================================
                                        MultiQC
    ================================================================================
    */
    // OUTPUT_DOCUMENTATION(
    //     output_docs,
    //     output_docs_images)

    // GET_SOFTWARE_VERSIONS()

    // MULTIQC(
    //     GET_SOFTWARE_VERSIONS.out.yml,
    //     multiqc_config,
    //     multiqc_custom_config.ifEmpty([]),
    //     report_markduplicates.collect().ifEmpty([]),
    //     workflow_summary)
}

/*
================================================================================
                        SEND COMPLETION EMAIL
================================================================================
 */

// workflow.onComplete {
//     def multiqc_report = []
//     Completion.email(workflow, params, summary, run_name, baseDir, multiqc_report, log)
//     Completion.summary(workflow, params, log)
// }
