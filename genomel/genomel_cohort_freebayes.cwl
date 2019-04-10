#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: MultipleInputFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  job_uuid: string
  bed_files: File[]
  reference:
    type: File
    secondaryFiles: [.fai, ^.dict]
  cromwell_engine: boolean

  ###Freebayes
  bam_files:
    type: File[]
    secondaryFiles: [^.bai]
  freebayes_thread_count: int
  number_of_chunks_for_freebayes: int

  ###Upload
  aws_config: File
  aws_shared_credentials: File
  upload_s3_profile: string
  upload_s3_endpoint: string
  upload_s3_bucket: string

outputs:
  freebayes_vcf:
    type: File
    outputSource: sort_freebayes/sorted_vcf

  time_logs:
    type: File[]
    outputSource: extract_time_log/output

steps:
  freebayes_cohort_genotyping:
    run: ./cwl/workflows/variant_calling/freebayes.cwl
    scatter: [bed_file, output_prefix]
    scatterMethod: dotproduct
    in:
      job_uuid: job_uuid
      bam_files: bam_files
      reference: reference
      bed_file: bed_files
      thread_count: freebayes_thread_count
      number_of_chunks: number_of_chunks_for_freebayes
      output_prefix:
        source: bed_files
        valueFrom: $(self.nameroot)
      cromwell_engine: cromwell_engine
    out: [time_metrics_from_freebayes,
          time_metrics_from_picard_sortvcf,
          time_metrics_from_selectvariants,
          freebayes_vcf]

  sort_freebayes:
    run: ./cwl/tools/variant_calling/picard_sortvcf.cwl
    in:
      job_uuid: job_uuid
      vcf: freebayes_cohort_genotyping/freebayes_vcf
      reference_dict:
        source: reference
        valueFrom: $(self.secondaryFiles[1])
      output_prefix:
        valueFrom: 'genomel_cohort.freebayes.genomel_all'
    out: [sorted_vcf, time_metrics]

  upload_freebayes_vcf:
    run: ./cwl/tools/utils/awscli_upload.cwl
    in:
      aws_config: aws_config
      aws_shared_credentials: aws_shared_credentials
      input: sort_freebayes/sorted_vcf
      s3uri:
        source: [upload_s3_bucket, sort_freebayes/sorted_vcf]
        valueFrom: $(self[0])/$(self[1].basename)
      s3_profile: upload_s3_profile
      s3_endpoint: upload_s3_endpoint
    out: [output, time_metrics]

  upload_freebayes_vcf_index:
    run: ./cwl/tools/utils/awscli_upload.cwl
    in:
      aws_config: aws_config
      aws_shared_credentials: aws_shared_credentials
      input:
        source: sort_freebayes/sorted_vcf
        valueFrom: $(self.secondaryFiles[0])
      s3uri:
        source: [upload_s3_bucket, sort_freebayes/sorted_vcf]
        valueFrom: $(self[0])/$(self[1].secondaryFiles[0].basename)
      s3_profile: upload_s3_profile
      s3_endpoint: upload_s3_endpoint
    out: [output, time_metrics]

  extract_time_log:
    run: ./cwl/tools/utils/extract_outputs.cwl
    in:
      file_array:
        source: [freebayes_cohort_genotyping/time_metrics_from_freebayes,
                 freebayes_cohort_genotyping/time_metrics_from_picard_sortvcf,
                 freebayes_cohort_genotyping/time_metrics_from_selectvariants,
                 sort_freebayes/time_metrics,
                 upload_freebayes_vcf/time_metrics,
                 upload_freebayes_vcf_index/time_metrics]
        valueFrom: |
          ${
            var log_list = []
            for (var i = 0; i < self.length; i++){
              if (Array.isArray(self[i])){
                if (Array.isArray(self[i][0])){
                  for (var j = 0; j < self[i][0].length; j++){
                    log_list.push(self[i][0][j])
                  }
                } else { log_list.push(self[i][0]) }
              } else {
                log_list.push(self[i])
              }
            }
            return log_list
          }
    out: [output]