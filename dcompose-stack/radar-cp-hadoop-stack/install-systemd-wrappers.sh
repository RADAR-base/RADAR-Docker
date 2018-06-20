#!/bin/bash

. ./util.sh

check_command_exists systemctl

copy_template_if_absent /etc/systemd/system/radar-docker.service lib/systemd/radar-docker.service.template
copy_template_if_absent /etc/systemd/system/radar-output.service lib/systemd/radar-output.service.template
copy_template_if_absent /etc/systemd/system/radar-output.timer lib/systemd/radar-output.timer.template
copy_template_if_absent /etc/systemd/system/radar-check-health.service lib/systemd/radar-check-health.service.template
copy_template_if_absent /etc/systemd/system/radar-check-health.timer lib/systemd/radar-check-health.timer.template
copy_template_if_absent /etc/systemd/system/radar-renew-certificate.service lib/systemd/radar-renew-certificate.service.template
copy_template_if_absent /etc/systemd/system/radar-renew-certificate.timer lib/systemd/radar-renew-certificate.timer.template

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

inline_variable 'WorkingDirectory=' "$DIR" /etc/systemd/system/radar-docker.service
inline_variable 'ExecStart=' "$DIR/lib/systemd/start-radar-stack.sh" /etc/systemd/system/radar-docker.service

inline_variable 'WorkingDirectory=' "$DIR/hdfs-restructure" /etc/systemd/system/radar-output.service
inline_variable 'ExecStart=' "$DIR/hdfs-restructure/restructure_backup_hdfs.sh" /etc/systemd/system/radar-output.service

inline_variable 'WorkingDirectory=' "$DIR" /etc/systemd/system/radar-check-health.service
inline_variable 'ExecStart=' "$DIR/check-health.sh" /etc/systemd/system/radar-check-health.service

inline_variable 'WorkingDirectory=' "$DIR" /etc/systemd/system/radar-renew-certificate.service
inline_variable 'ExecStart=' "$DIR/renew_ssl_certificate.sh" /etc/systemd/system/radar-renew-certificate.service


sudo systemctl daemon-reload
sudo systemctl enable radar-docker
sudo systemctl enable radar-output.timer
sudo systemctl enable radar-check-health.timer
sudo systemctl enable radar-renew-certificate.timer
sudo systemctl start radar-docker
sudo systemctl start radar-output.timer
sudo systemctl start radar-check-health.timer
sudo systemctl start radar-renew-certificate.timer
