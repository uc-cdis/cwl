#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: registry.gitlab.com/uc-cdis/genomel-primary-analysis/harmonization_with_bwa:1.0
  - class: ShellCommandRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  bam: File

stdout: readgroups_header
outputs:
  readgroup_lines:
    type: string[]
    outputBinding:
      glob: readgroups_header
      loadContents: true
      outputEval: |
        ${
          var rg_line = [];
          for (var i = 0; i < self[0].contents.trim().split('\n').length; i++ ){
            rg_line.push(self[0].contents.trim().split('\n')[i])
          };
          return rg_line
        }

  readgroup_names:
    type: string[]
    outputBinding:
      glob: readgroups_header
      loadContents: true
      outputEval: |
        ${
          var rg_name = [];
          for (var i = 0; i < self[0].contents.trim().split('\n').length; i++ ){
            rg_name.push(self[0].contents.trim().split('\n')[i].split('\t')[1].replace('ID:', '').replace(/\#/g, '%2'))
          };
          return rg_name
        }

baseCommand: []
arguments:
  - valueFrom: >-
      samtools view -H $(inputs.bam.path) | grep "^@RG"
    shellQuote: False
