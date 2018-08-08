cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo $(pwd)
. lib/util.sh

echo "==> Copying templates"
copy_template_if_absent /etc/systemd/system/radar-docker.service lib/systemd/radar-docker.service.template
copy_template_if_absent /etc/systemd/system/radar-output.service lib/systemd/radar-output.service.template
copy_template_if_absent /etc/systemd/system/radar-output.timer lib/systemd/radar-output.timer.template
copy_template_if_absent /etc/systemd/system/radar-check-health.service lib/systemd/radar-check-health.service.template
copy_template_if_absent /etc/systemd/system/radar-check-health.timer lib/systemd/radar-check-health.timer.template
copy_template_if_absent /etc/systemd/system/radar-renew-certificate.service lib/systemd/radar-renew-certificate.service.template
copy_template_if_absent /etc/systemd/system/radar-renew-certificate.timer lib/systemd/radar-renew-certificate.timer.template

echo "==> Inlining variables"
inline_variable 'WorkingDirectory=' "$PWD" /etc/systemd/system/radar-docker.service
inline_variable 'ExecStart=' "$PWD/bin/radar-docker foreground" /etc/systemd/system/radar-docker.service

inline_variable 'WorkingDirectory=' "$PWD/hdfs" /etc/systemd/system/radar-output.service
inline_variable 'ExecStart=' "$PWD/bin/hdfs-restructure-process" /etc/systemd/system/radar-output.service

inline_variable 'WorkingDirectory=' "$PWD" /etc/systemd/system/radar-check-health.service
inline_variable 'ExecStart=' "$PWD/bin/radar-docker health" /etc/systemd/system/radar-check-health.service

inline_variable 'WorkingDirectory=' "$DIR" /etc/systemd/system/radar-renew-certificate.service
inline_variable 'ExecStart=' "$PWD/bin/radar-docker cert-renew" /etc/systemd/system/radar-renew-certificate.service

echo "==> Reloading systemd"
systemctl daemon-reload
systemctl enable radar-docker
systemctl enable radar-output.timer
systemctl enable radar-check-health.timer
systemctl enable radar-renew-certificate.timer
systemctl start radar-docker
systemctl start radar-output.timer
systemctl start radar-check-health.timer
systemctl start radar-renew-certificate.timer
