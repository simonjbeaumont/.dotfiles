#!/usr/bin/env bash
# Just run `wemux status_users` for tmux-powerline

run_segment() {


	local wemux_users=$(wemux status_users)
	if [[ $wemux_users && ($wemux_users != "No wemux server"*) &&
          ($wemux_users != "failed to connect to server"*) ]]; then
		echo wmx="$wemux_users"
	fi

	return 0
}
