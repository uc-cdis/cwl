'''
Postgres tables for the PDC CWL Workflow
'''
from sqlalchemy.orm import sessionmaker, mapper
from sqlalchemy import MetaData, Table
from sqlalchemy import Column, String
import re


class Metrics(object):
    pass


class BamFiles(object):
    pass


class FastqFiles(object):
    pass

# Organize rows of genomel_fastq_input to dictionary


def retrive_reads(cases):
    s = dict()
    for row in cases:
        s.setdefault(row.aliquot, {})
        s[row.aliquot].setdefault(row.read_group, {})
        s[row.aliquot][row.read_group].setdefault('input_id_r1', [])
        s[row.aliquot][row.read_group]['input_id_r1'].append(row.input_id_r1)
        s[row.aliquot][row.read_group].setdefault('input_id_r2', [])
        s[row.aliquot][row.read_group]['input_id_r2'].append(row.input_id_r2)
        s[row.aliquot][row.read_group].setdefault('md5_r1', [])
        s[row.aliquot][row.read_group]['md5_r1'].append(row.md5_r1)
        s[row.aliquot][row.read_group].setdefault('md5_r2', [])
        s[row.aliquot][row.read_group]['md5_r2'].append(row.md5_r2)
        s[row.aliquot][row.read_group].setdefault('size_r1', [])
        s[row.aliquot][row.read_group]['size_r1'].append(row.size_r1)
        s[row.aliquot][row.read_group].setdefault('size_r2', [])
        s[row.aliquot][row.read_group]['size_r2'].append(row.size_r2)
        s[row.aliquot][row.read_group].setdefault('s3_url_r1', [])
        s[row.aliquot][row.read_group]['s3_url_r11'].append(row.s3_url_r1)
        s[row.aliquot][row.read_group].setdefault('s3_url_r2', [])
        s[row.aliquot][row.read_group]['s3_url_r2'].append(row.s3_url_r2)
        s[row.aliquot]['s3_profile'] = row.s3_profile
        s[row.aliquot]['s3_endpoint'] = row.s3_endpoint
        s[row.aliquot]['project'] = row.project
    return s

# Organize rows of genomel_bam_input to dictionary


def retrive_bams(cases):
    s = dict()
    for row in cases:
        s.setdefault(row.aliquot, {})
        s[row.aliquot].setdefault('input_id', [])
        s[row.aliquot]['input_id'].append(row.input_id)
        s[row.aliquot].setdefault('md5', [])
        s[row.aliquot]['md5'].append(row.md5)
        s[row.aliquot].setdefault('s3_url', [])
        s[row.aliquot]['s3_url'].append(row.s3_url)
        s[row.aliquot].setdefault('file_size', [])
        s[row.aliquot]['file_size'].append(row.file_size)
        s[row.aliquot]['s3_profile'] = row.s3_profile
        s[row.aliquot]['s3_endpoint'] = row.s3_endpoint
        s[row.aliquot]['project'] = row.project
    return s

# collect input information from genomel_fastq_input tables


def get_reads(engine, genomel_fastq_input, input_primary_column="id"):
    Session = sessionmaker()
    Session.configure(bind=engine)
    session = Session()
    meta = MetaData(engine)
    # read the input table
    data = Table(genomel_fastq_input, meta, Column(input_primary_column, String, primary_key=True), autoload=True)
    mapper(FastqFiles, data)
    cases = session.query(FastqFiles).all()
    return retrive_reads(cases)

# collect input information from genomel_bam_input tables


def get_bams(engine, genomel_bam_input, input_primary_column="id"):
    Session = sessionmaker()
    Session.configure(bind=engine)
    session = Session()
    meta = MetaData(engine)
    # read the input table
    data = Table(genomel_bam_input, meta, Column(input_primary_column, String, primary_key=True), autoload=True)
    mapper(BamFiles, data)
    cases = session.query(BamFiles).all()
    return retrive_bams(cases)

# collect input information from metrics tables


def get_case_from_metrics(engine, metrics_table, input_primary_column, genomel_fastq_input, genomel_bam_input):
    Session = sessionmaker()
    Session.configure(bind=engine)
    session = Session()
    meta = MetaData(engine)

    # read input tables
    fastqfiles = Table(genomel_fastq_input, meta, autoload=True)
    mapper(FastqFiles, fastqfiles)
    fastq_cases = session.query(FastqFiles).all()

    bamfiles = Table(genomel_bam_inpu, meta, autoload=True)
    mapper(BamFiles, bamfiles)
    bam_cases = session.query(BamFiles).all()

    # read the metrics table
    metrics = Table(metrics_table, meta, autoload=True)
    mapper(Metrics, metrics)
    cases = session.query(Metrics).all()
    input_ids = list()
    for row in cases:
        if row.status != 'COMPLETED':
            input_id = re.sub('[{}]', '', row.input_id)
            input_id = input_id.split(",")
            for instance in input_id:
                if input_id not in input_ids:
                    input_ids.append(input_id)

    fastq_cases_filter = list(filter(lambda x: x.input_id_r1 in input_ids, fastq_cases))
    bam_cases_filter = list(filter(lambda x: x.input_id in input_ids, bam_cases))
    if fastq_cases_filter:
        reads_ids = retrive_reads(fastq_cases_filter)
    if bam_cases_filter:
        bam_ids = retrive_bams(bam_cases_filter)
    return(reads_ids, bam_ids)
