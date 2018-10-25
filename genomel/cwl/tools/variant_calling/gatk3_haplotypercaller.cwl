#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: registry.gitlab.com/uc-cdis/genomel-exome-variant-detection/haplotypecaller:1.0

inputs:
  job_uuid: string
  bam_file:
    type: File
    secondaryFiles: '^.bai'
  reference:
    type: File
    secondaryFiles:
      - '.fai'
      - '^.dict'
  interval: File
  snp_ref:
    type: File
    secondaryFiles: '.tbi'

outputs:
  gvcf_list:
    type: File[]
    outputBinding:
      glob: '*g.vcf.gz'
    secondaryFiles: '.tbi'
  time_metrics:
    type: File
    outputBinding:
      glob: $(inputs.job_uuid + '.gatk3_haplotypecaller.time.json')

baseCommand: []
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      /usr/bin/time -f \"{\"real_time\": \"%E\", \"user_time\": %U, \"system_time\": %S, \"wall_clock\": %e, \"maximum_resident_set_size\": %M, \"average_total_mem\": %K, \"percent_of_cpu\": \"%P\"}\"
      -o $(inputs.job_uuid + '.gatk3_haplotypecaller.time.json')
      python /opt/gatk3_genomel_variant_calling.py
      -b $(inputs.bam_file.path) -j $(inputs.job_uuid) -r $(inputs.reference.path)
      -i $(inputs.interval.path) -s $(inputs.snp_ref.path) -c 25 -t haplotypecaller
