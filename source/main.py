import os
import sys
import json
import logging
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions, StandardOptions
from JsonReader import GetTopicTable

def GetEnvVar():
    env_var=dict()

    #print(os.environ)
    print(os.getcwd())
    
    env_var['JOB_NAME'] = os.environ['JOB_NAME']
    env_var['PROJECT'] = os.environ['PROJECT']
    env_var['REGION'] = os.environ['REGION']
    env_var['TMP_LOCATION'] = os.environ['TMP_LOCATION']
    env_var['TEMPLATE_FILE'] = os.environ['TEMPLATE_FILE']
    env_var['SUBSCRIPTION'] = os.environ['SUBSCRIPTION']
    env_var['DATA_SET'] = os.environ['DATA_SET']

    return env_var

class GetPayLoad(beam.DoFn):

    def process(self, element):
        logging.getLogger().setLevel(logging.INFO)
        parsed = json.loads(element.decode("utf-8"))
        event_payload=parsed['event_payload']
        event_type=parsed['event_type']
        logging.info('usagemediation:GetPayLoad:process %s', event_payload)
        logging.info('usagemediation:GetPayLoad:process %s', event_type)
        event_payload['event_type']=event_type
        logging.info('usagemediation:GetPayLoad:process %s', event_payload)
        yield event_payload

class PrintValue(beam.DoFn):

    def process(self, element):
        logging.getLogger().setLevel(logging.INFO)
        logging.info('usagemediation:PrintValue %s', element)

def run():
    logging.getLogger().setLevel(logging.INFO)

    env_var = GetEnvVar() 

    print(env_var)

    pipeline_options = PipelineOptions(
        runner='DataflowRunner',
        project=env_var['PROJECT'],
        job_name=env_var['JOB_NAME'],
        region=env_var['REGION'],
        temp_location=env_var['TMP_LOCATION'],
        template_location=env_var['TEMPLATE_FILE'],
	#service_account_email='pubsub-sandbox@mm-ucaas.iam.gserviceaccount.com',
	#service_account_email='template-sa@mm-ucaas.iam.gserviceaccount.com',
    )

    # Creating pipeline options
    #pipeline_options = PipelineOptions(pipeline_args)
    pipeline_options.view_as(StandardOptions).streaming = True
    
    #project=pipeline_options.get_all_options()['project']
    #dataset=known_args.data_set
    project=env_var['PROJECT']
    dataset=env_var['DATA_SET']

    topics, tables=GetTopicTable()
    
    tables=[project + ':' + dataset + '.' + table for table in tables ]
    
    topic_mappings=list(zip(topics, tables))

    # Defining our pipeline and its steps
    with beam.Pipeline(options=pipeline_options) as p:
        read_data = p | "ReadFromPubSub" >> beam.io.gcp.pubsub.ReadFromPubSub(
                subscription=env_var['SUBSCRIPTION'], timestamp_attribute=None
            )

        table_names = p | "Create Table Name" >> beam.Create(topic_mappings)

        event_payload = read_data | "PayloadParser" >> beam.ParDo(GetPayLoad())

        (
            event_payload
            | "WriteToBigQuery" >> beam.io.WriteToBigQuery(
                table=lambda row, table_name: table_name[row['event_type']],
                table_side_inputs=(beam.pvalue.AsDict(table_names), ),
                create_disposition=beam.io.BigQueryDisposition.CREATE_NEVER,
                write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
            )
        )
        
if __name__ == "__main__":
    #print(os.environ['VIRTUAL_ENV'])
    print('Using version:', sys.version[:5])
    run()

