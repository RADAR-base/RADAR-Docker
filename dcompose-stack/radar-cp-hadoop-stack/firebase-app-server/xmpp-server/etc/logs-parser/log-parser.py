#!/usr/bin/env python3

import sys, csv, json
from os import listdir
from os.path import isfile, join

input_directory = sys.argv[1]
output_directory = sys.argv[2]
subject_token = {}

for file in listdir(input_directory):
    # Finding out the executed ones
    if file.endswith('.log'):
        ouput_file_name = file.split('.')[0]
        with open(join(input_directory, file)) as f:

            with open(join(output_directory, "%s_%s.%s" %(ouput_file_name, 'executions', 'csv')), 'w') as exec_output:
                with open(join(output_directory, "%s_%s.%s" %(ouput_file_name, 'delivery', 'csv')), 'w') as delivery_output:
                    exec_writer = csv.writer(exec_output, delimiter=',',
                            quotechar='|', quoting=csv.QUOTE_MINIMAL)
                    delivery_writer = csv.writer(delivery_output, delimiter=',',
                            quotechar='|', quoting=csv.QUOTE_MINIMAL)

                    exec_writer.writerow(['date', 'time', 'subject_id', 'fcm_token', 'scheduled_time', 'executed?'])
                    delivery_writer.writerow(['date', 'time', 'subject_id', 'fcm_token', 'message_sent_timestamp', 'message_status'])
                    for line in f:
                        data = line.split()
                        if len(data) < 2:
                            continue
                        date = data[0]
                        time = data[1]
                        if "Executing Execution" in line:
                            #print(line)
                            #print(str(data))
                            ids = data[7].split('=')[1].split('+')
                            fcm_token = ids[0]
                            subject_id = ids[1]
                            scheduled_time = data[8].split('=')[1].split(',')[0]
                            subject_token[fcm_token] = subject_id
                            exec_writer.writerow([date, time, subject_id, fcm_token, scheduled_time, 'true'])
                            #print(str(ids))
                            #break
                        elif "message_type\":\"receipt" in line:
                            #print(line)
                            parsed_data = data[9].split('>')[1].split('<')[0]
                            json_data = json.loads(parsed_data)
                            message_status = json_data['data']['message_status']
                            message_sent_timestamp = json_data['data']['message_sent_timestamp']
                            fcm_token = json_data['data']['device_registration_id']
                            try:
                                subject_id = subject_token[fcm_token]
                            except KeyError:
                                subject_id = 'unknown'
                                pass
                            #print(message_status, message_sent_timestamp, fcm_token, subject_id)
                            delivery_writer.writerow([date, time, subject_id, fcm_token, message_sent_timestamp, message_status])
                        elif 'message_type":"nack' in line:
                            with open(join(output_directory, "%s_%s.%s" %(ouput_file_name, 'error', 'csv')), 'w') as error_output:
                                error_writer = csv.writer(error_output, delimiter=',',
                                        quotechar='|', quoting=csv.QUOTE_MINIMAL)
                                error_writer.writerow([line])
                            print(line)
