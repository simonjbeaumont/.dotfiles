#!/usr/bin/env bash
# Return the number of work items to do and blocked

run_segment() {
    local t="todo -d /home/simonbe/Dropbox/todo/config"
    local task_count=$(( $($t ls | wc -l) - 2))
    local blocked_count=$(( $($t lf blocked.txt | wc -l) - 2))

	if [ $task_count -gt 0 -o $blocked_count -gt 0 ]; then
		echo "⚡︎ ${task_count}|${blocked_count}"
	fi

	return 0
}
