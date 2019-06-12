#!/usr/bin/env nextflow

import Helper
import CollectInitialMetadata

// Pipeline version
if (workflow.commitId){
    version = "0.1 $workflow.revision"
} else {
    version = "0.1 (local version)"
}

params.help = false
if (params.help){
    Help.print_help(params)
    exit 0
}

def infoMap = [:]
if (params.containsKey("fastq")){
    infoMap.put("fastq", file(params.fastq).size())
}
if (params.containsKey("fasta")){
    if (file(params.fasta) instanceof LinkedList){
        infoMap.put("fasta", file(params.fasta).size())
    } else {
        infoMap.put("fasta", 1) 
    }
}
if (params.containsKey("accessions")){
    // checks if params.accessions is different from null
    if (params.accessions) {
        BufferedReader reader = new BufferedReader(new FileReader(params.accessions));
        int lines = 0;
        while (reader.readLine() != null) lines++;
        reader.close();
        infoMap.put("accessions", lines)
    }
}

Help.start_info(infoMap, "$workflow.start", "$workflow.profile")
CollectInitialMetadata.print_metadata(workflow)
    

// Placeholder for main input channels
if (params.fastq instanceof Boolean){exit 1, "'fastq' must be a path pattern. Provide value:'$params.fastq'"}
if (!params.fastq){ exit 1, "'fastq' parameter missing"}
IN_fastq_raw = Channel.fromFilePairs(params.fastq).ifEmpty { exit 1, "No fastq files provided with pattern:'${params.fastq}'" }

// Placeholder for secondary input channels


// Placeholder for extra input channels


// Placeholder to fork the raw input channel

IN_fastq_raw.set{ bwa_in_1_0 }


bwaIndexId_1_1 = Channel.value(params.bwaIndex.split("/").last())
bwaIndex_1_1 = Channel.fromPath("${params.bwaIndex}.*").collect().toList()

process bwa_1_1 {

        if ( params.platformHTTP != null ) {
        beforeScript "PATH=${workflow.projectDir}/bin:\$PATH; export PATH; set_dotfiles.sh; startup_POST.sh $params.projectId $params.pipelineId 1_1 $params.platformHTTP"
        afterScript "final_POST.sh $params.projectId $params.pipelineId 1_1 $params.platformHTTP; report_POST.sh $params.projectId $params.pipelineId 1_1 $params.sampleName $params.reportHTTP $params.currentUserName $params.currentUserId bwa_1_1 \"$params.platformSpecies\" true"
    } else {
        beforeScript "PATH=${workflow.projectDir}/bin:\$PATH; set_dotfiles.sh"
        }

    publishDir "results/mapping/bwa_1_1"

    input:
    set sample_id, file(fastq_pair) from bwa_in_1_0
    each index from bwaIndexId_1_1
    each file(index_file) from bwaIndex_1_1
   
    output:
    set sample_id, file("${sample_id}.bam"), file("${sample_id}.bam.bai") into bwa_out_1_0
    set sample_id, val("1_1_bwa"), file(".status"), file(".warning"), file(".fail"), file(".command.log") into STATUS_bwa_1_1
set sample_id, val("bwa_1_1"), val("1_1"), file(".report.json"), file(".versions"), file(".command.trace") into REPORT_bwa_1_1
file ".versions"

    """
    bwa mem -M -R '@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:Illumina' -t $task.cpus $index $fastq_pair > ${sample_id}.sam
    samtools sort -o ${sample_id}.bam -O BAM ${sample_id}.sam
    samtools index ${sample_id}.bam
    """
}


process mark_duplicates_1_2 {

        if ( params.platformHTTP != null ) {
        beforeScript "PATH=${workflow.projectDir}/bin:\$PATH; export PATH; set_dotfiles.sh; startup_POST.sh $params.projectId $params.pipelineId 1_2 $params.platformHTTP"
        afterScript "final_POST.sh $params.projectId $params.pipelineId 1_2 $params.platformHTTP; report_POST.sh $params.projectId $params.pipelineId 1_2 $params.sampleName $params.reportHTTP $params.currentUserName $params.currentUserId mark_duplicates_1_2 \"$params.platformSpecies\" true"
    } else {
        beforeScript "PATH=${workflow.projectDir}/bin:\$PATH; set_dotfiles.sh"
        }

    input:
    set sample_id, file(bam), file(bai) from bwa_out_1_0
   
    output:
    set val(sample_id), file("${sample_id}_mark_dup.bam"), file("${sample_id}_mark_dup.bai") into mark_duplicates_out_1_1
    set file("metrics.txt") into markDupMultiQC_1_2
    set sample_id, val("1_2_mark_duplicates"), file(".status"), file(".warning"), file(".fail"), file(".command.log") into STATUS_mark_duplicates_1_2
set sample_id, val("mark_duplicates_1_2"), val("1_2"), file(".report.json"), file(".versions"), file(".command.trace") into REPORT_mark_duplicates_1_2
file ".versions"

    """
    gatk MarkDuplicates \
      -I $bam \
      -M metrics.txt \
      -O ${sample_id}_mark_dup.bam \
      --CREATE_INDEX
    """
}


baseRecalibratorFasta_1_3 = Channel.value(params.reference.split("/").last())
baseRecalibratorRef_1_3 = Channel.fromPath("${params.reference}.*").collect().toList()
baseRecalibratorDbsnp_1_3 = Channel.fromPath("${params.dbsnp}")
baseRecalibratorDbsnpIdx_1_3 = Channel.fromPath("${params.dbsnpIdx}")
baseRecalibratorGoldenIndel_1_3 = Channel.fromPath("${params.goldenIndel}")
baseRecalibratorGoldenIndelIdx_1_3 = Channel.fromPath("${params.goldenIndelIdx}")

process base_recalibrator_1_3 {

        if ( params.platformHTTP != null ) {
        beforeScript "PATH=${workflow.projectDir}/bin:\$PATH; export PATH; set_dotfiles.sh; startup_POST.sh $params.projectId $params.pipelineId 1_3 $params.platformHTTP"
        afterScript "final_POST.sh $params.projectId $params.pipelineId 1_3 $params.platformHTTP; report_POST.sh $params.projectId $params.pipelineId 1_3 $params.sampleName $params.reportHTTP $params.currentUserName $params.currentUserId base_recalibrator_1_3 \"$params.platformSpecies\" true"
    } else {
        beforeScript "PATH=${workflow.projectDir}/bin:\$PATH; set_dotfiles.sh"
        }

    publishDir "results/mapping/base_recalibrator_1_3"

    input:
    set val(sample_id), file(bam), file(bai) from mark_duplicates_out_1_1
    each file(reference) from baseRecalibratorRef_1_3
    val(fasta) from baseRecalibratorFasta_1_3
    each file(dbsnp) from baseRecalibratorDbsnp_1_3
    each file(dbsnp_idx) from baseRecalibratorDbsnpIdx_1_3
    each file(golden_indel) from baseRecalibratorGoldenIndel_1_3
    each file(golden_indel_idx) from baseRecalibratorGoldenIndelIdx_1_3
    
    output:
    set sample_id, file("${sample_id}_recal_data.table") into baserecalibrator_table
    set sample_id, val("1_3_base_recalibrator"), file(".status"), file(".warning"), file(".fail"), file(".command.log") into STATUS_base_recalibrator_1_3
set sample_id, val("base_recalibrator_1_3"), val("1_3"), file(".report.json"), file(".versions"), file(".command.trace") into REPORT_base_recalibrator_1_3
file ".versions"

    """
    # gunzip dbsnp & golden_indel if gzipped
    [[ "\$(file --mime-type $dbsnp | cut -d' ' -f2)" == "application/x-gzip" ]] && gzip -d --force $dbsnp
    dbsnp=\$(basename $dbsnp .gz)
    [[ "\$(file --mime-type $dbsnp_idx | cut -d' ' -f2)" == "application/x-gzip" ]] && gzip -d --force $dbsnp_idx
    [[ "\$(file --mime-type $golden_indel | cut -d' ' -f2)" == "application/x-gzip" ]] && gzip -d --force $golden_indel
    golden_indel=\$(basename $golden_indel .gz)
    [[ "\$(file --mime-type $golden_indel_idx | cut -d' ' -f2)" == "application/x-gzip" ]] && gzip -d --force $golden_indel_idx

    gatk BaseRecalibrator \
      -I $bam \
      --known-sites \$dbsnp \
      --known-sites \$golden_indel \
      -O ${sample_id}_recal_data.table \
      -R ${fasta}.fasta
    """
}



/** STATUS
Reports the status of a sample in any given process.
*/
process status {

    tag { sample_id }
    publishDir "pipeline_status/$task_name"

    input:
    set sample_id, task_name, status, warning, fail, file(log) from STATUS_bwa_1_1.mix(STATUS_mark_duplicates_1_2,STATUS_base_recalibrator_1_3)

    output:
    file '*.status' into master_status
    file '*.warning' into master_warning
    file '*.fail' into master_fail
    file '*.log'

    """
    echo $sample_id, $task_name, \$(cat $status) > ${sample_id}_${task_name}.status
    echo $sample_id, $task_name, \$(cat $warning) > ${sample_id}_${task_name}.warning
    echo $sample_id, $task_name, \$(cat $fail) > ${sample_id}_${task_name}.fail
    echo "\$(cat .command.log)" > ${sample_id}_${task_name}.log
    """
}

process compile_status_buffer {

    input:
    file status from master_status.buffer( size: 5000, remainder: true)
    file warning from master_warning.buffer( size: 5000, remainder: true)
    file fail from master_fail.buffer( size: 5000, remainder: true)

    output:
    file 'master_status_*.csv' into compile_status_buffer
    file 'master_warning_*.csv' into compile_warning_buffer
    file 'master_fail_*.csv' into compile_fail_buffer

    """
    cat $status >> master_status_${task.index}.csv
    cat $warning >> master_warning_${task.index}.csv
    cat $fail >> master_fail_${task.index}.csv
    """
}

process compile_status {

    publishDir 'reports/status'

    input:
    file status from compile_status_buffer.collect()
    file warning from compile_warning_buffer.collect()
    file fail from compile_fail_buffer.collect()

    output:
    file "*.csv"

    """
    cat $status >> master_status.csv
    cat $warning >> master_warning.csv
    cat $fail >> master_fail.csv
    """

}


/** Reports
Compiles the reports from every process
*/
process report {

    tag { sample_id }

    input:
    set sample_id,
            task_name,
            pid,
            report_json,
            version_json,
            trace from REPORT_bwa_1_1.mix(REPORT_mark_duplicates_1_2,REPORT_base_recalibrator_1_3)

    output:
    file "*" optional true into master_report

    """
    prepare_reports.py $report_json $version_json $trace $sample_id $task_name 1 $pid $workflow.scriptId $workflow.runName
    """

}


process compile_reports {

    publishDir "pipeline_report/", mode: "copy"

    if ( params.reportHTTP != null ){
        beforeScript "PATH=${workflow.projectDir}/bin:\$PATH; export PATH;"
        afterScript "metadata_POST.sh $params.projectId $params.pipelineId 0 $params.sampleName $params.reportHTTP $params.currentUserName $params.currentUserId 0 \"$params.platformSpecies\""
    }

    input:
    file report from master_report.collect()
    file forks from Channel.fromPath("${workflow.projectDir}/.forkTree.json")
    file dag from Channel.fromPath("${workflow.projectDir}/.treeDag.json")
    file js from Channel.fromPath("${workflow.projectDir}/resources/main.js.zip")

    output:
    file "pipeline_report.json"
    file "pipeline_report.html"
    file "src/main.js"

    script:
    template "compile_reports.py"
}

workflow.onComplete {
  // Display complete message
  log.info "Completed at: " + workflow.complete
  log.info "Duration    : " + workflow.duration
  log.info "Success     : " + workflow.success
  log.info "Exit status : " + workflow.exitStatus
}

workflow.onError {
  // Display error message
  log.info "Workflow execution stopped with the following message:"
  log.info "  " + workflow.errorMessage
}
