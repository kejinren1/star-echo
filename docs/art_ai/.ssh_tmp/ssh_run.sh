#!/bin/sh
# 用法: ./ssh_run.sh "远程命令"
SSH_PASS='Rz#2v' SSH_ASKPASS=/d/30DAYS/docs/art_ai/.ssh_tmp/askpass.sh SSH_ASKPASS_REQUIRE=force ssh -p 24098 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -o NumberOfPasswordPrompts=1 root@175.155.64.171 "$1"
