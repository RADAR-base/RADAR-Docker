#!/usr/bin/env python3

import sys, csv, json
import os
import os.path

def parse_logs(input_directory, output_directory):
    subject_token = {}

    for log_file in os.listdir(input_directory):
        # Finding out the executed ones
        if not log_file.endswith('.log'):
            continue

        ouput_file_name = log_file.split('.')[0]
        log_path = os.path.join(input_directory, log_file)
        exec_path = os.path.join(output_directory, "{}_executions.csv".format(ouput_file_name))
        delivery_path = os.path.join(output_directory, "{}_delivery.csv".format(ouput_file_name))
        error_path = os.path.join(output_directory, "{}_error.csv".format(ouput_file_name))

        with open(log_path) as f,\
                 open(exec_path, 'w') as exec_output,\
                 open(delivery_path, 'w') as delivery_output,\
                 open(error_path, 'w') as error_output:
            exec_writer = csv.writer(exec_output, delimiter=',',
                    quotechar='|', quoting=csv.QUOTE_MINIMAL)
            delivery_writer = csv.writer(delivery_output, delimiter=',',
                    quotechar='|', quoting=csv.QUOTE_MINIMAL)
            error_writer = csv.writer(error_output, delimiter=',',
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
                    error_writer.writerow([line])
                    print(line)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: {} <input_directory> <output_directory>".format(sys.argv[0]))
        sys.exit(1)

    input_directory = sys.argv[1]
    output_directory = sys.argv[2]
    parse_logs(input_directory, output_directory)
