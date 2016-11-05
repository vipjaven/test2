#!/bin/bash

set_authorized_keys()
{
    if [ ! -z "${AUTHORIZED_KEYS}" ]; then
        IFS=$'\n'
        AUTHORIZED_KEY_ARR=$(echo ${AUTHORIZED_KEYS} | tr "," "\n")
        for k in $AUTHORIZED_KEY_ARR
        do
            k=$(echo $k |sed -e 's/^ *//' -e 's/ *$//')
            cat /root/.ssh/authorized_keys | grep "$k" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "Adding SSH public key: $k"
                echo $k >> /root/.ssh/authorized_keys
            fi
        done
    fi
    chmod 600 /root/.ssh/authorized_keys
}

set_root_password()
{
    if [ ! -f /scripts/root_password_set ]; then
        if [ -z "$ROOT_PASSWORD" ]; then
            ROOT_PASSWORD="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)"
        fi
        echo "root:${ROOT_PASSWORD}" | chpasswd
        echo "Root's Password: $ROOT_PASSWORD"
        touch /scripts/root_password_set
    fi
}

restart_supervisor() {
	if [ -x /etc/init.d/supervisord ]; then

		if [ -d "$KCPTUN_LOG_DIR" ]; then
			rm -f "$KCPTUN_LOG_DIR"/*
		else
			mkdir -p "$KCPTUN_LOG_DIR"
		fi

		if ! service supervisord restart; then
			cat >&2 <<-'EOF'

			重启 Supervisor 失败, Kcptun 无法正常启动!
			EOF

			exit_with_error
		fi
	else
		cat >&2 <<-'EOF'

		未找到 Supervisor 服务, 请手动检查!
		EOF

		exit_with_error
	fi

    /etc/init.d/shadowsocks start
}

set_authorized_keys
set_root_password
restart_supervisor

exec $@
