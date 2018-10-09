#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: registry.gitlab.com/uc-cdis/genomel-primary-analysis:0.2d

inputs:
  - id: input_bam_path
    type: File
    doc: Input bam file
    inputBinding:
      position: 2

stdout: readgroups
outputs:
  - id: readgroups
    type: string
    type:
      type: array
      items: string
    outputBinding:
      glob: readgroups
      loadContents: true
      outputEval: $(self[0].contents.trim().split('\n'))


baseCommand: ['/home/ubuntu/tools/samtools/samtools', 'view']
arguments:
  - valueFrom: "-H"
    position: 1
  - valueFrom: "grep"
    position: 3
    prefix: "|"
  - valueFrom: "^@RG"
    position: 4
