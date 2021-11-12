import json

def GetTopicTable():
    with open('input_topic_table_map.json') as file:
        data=json.load(file)

        topics=[]
        tables=[]

        for element in data:
            topics.append(element['topic'])
            tables.append(element['table'])

    return topics, tables

