#!/usr/bin/env bash
# Return the number of work items to do and blocked

todo_file="/work/todo.txt"

run_segment() {
	if [ ! -f "$todo_file" ]; then
		return 1
	fi

	local blocked_count=$(grep "@ HELD" ${todo_file} | wc -l)
	local todo_count=$(grep "  -" ${todo_file} | grep -v "    " | wc -l)
    todo_count=$(( $todo_count - $blocked_count ))

	if [ "$todo_count" -gt "0" ]; then
		echo "⚡︎ ${todo_count}|${blocked_count}"
	fi

	return 0
}
