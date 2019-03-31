#!/bin/bash

basedir="/data/cromwell_workdir"
project="genomel_prod"
batch_id="aws_freebayes_01"
job_uuid="13189d29-db47-4830-a895-f2b907a39167"
bam_files_manifest="/data/cromwell_workdir/bam_local_path.list"
freebayes_thread_count=""
number_of_chunks_for_freebayes=""
upload_s3_bucket="s3://genomel/cohort_genotyping_output/"
cromwell_jar_path="/data/cromwell_workdir/cromwell-36.jar"
repository="git@github.com:uc-cdis/genomel_pipelines.git"

cd $basedir

git clone feat/aws $repository genomel_pipelines

/home/ubuntu/.virtualenvs/p2/bin/python \
$basedir/genomel_pipelines/genomel/aws/aws_cohort_freebayes_runner.py \
--basedir $basedir \
--project $project \
--batch_id $batch_id \
--job_uuid $job_uuid \
--bam_files_manifest $bam_files_manifest \
--freebayes_thread_count $freebayes_thread_count \
--number_of_chunks_for_freebayes $number_of_chunks_for_freebayes \
--upload_s3_bucket $upload_s3_bucket \
--cromwell_jar_path $cromwell_jar_path
