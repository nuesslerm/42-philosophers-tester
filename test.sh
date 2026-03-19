#!/bin/bash

count_correct_all=0
count_false_all=0
iterations=10
times_to_eat=10
folder=fails/
tempfile=tempfile

function cleanup()
{
    rm -f $tempfile
    if [ -d fails ] && [ -z "$(ls -A fails)" ]; then
        rm -rf fails
    fi
}
trap cleanup EXIT

while getopts i:t: OPTION; do
  case "$OPTION" in
    i)
      iterations="$OPTARG"
      ;;
    t)
      times_to_eat="$OPTARG"
      ;;
    ?)
      printf "usage: $0 [-i iterations] [-t times_to_eat] <path_to_binary>\n" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND - 1))"

if [ "$#" -ne 1 ]; then
    printf "usage: $0 [-i iterations] [-t times_to_eat] <path_to_binary>\n" >&2
    exit 1
fi
philo="$1"

OK_COLOR="\033[0;32m"
ERROR_COLOR="\033[0;31m"
WARN_COLOR="\033[0;33m"
OBJ_COLOR="\033[0;36m"
RESET="\033[0m"
BOLD="\033[1m"

if [ -d "${folder}" ]; then
    rm -rf ${folder}
fi
mkdir ${folder}

if [ ! -x "${philo}" ]; then
    printf "${ERROR_COLOR}ERROR: '${philo}' is not executable${RESET}\n" >&2
    exit 1
fi

if ! ${philo} 5 200 100 100 &>/dev/null; then
    printf "${ERROR_COLOR}ERROR: couldn't execute '${philo}'${RESET}\n" >&2
    exit 1
fi

die () {
    count_false=0
    count_correct=0
    printf "\t${WARN_COLOR}$1 $2 $3 $4 $5${RESET}\n"
    for (( i=1; i <= $iterations; i++)) ; do
        $philo $1 $2 $3 $4 $5 > ${tempfile}
        if [ $(tail -n 1 ${tempfile} | grep -c died) -ne 0 ]; then
            printf "\t$i\t${OK_COLOR}Pass${RESET}\t$(tail -n 1 ${tempfile})\n"
            (( count_correct++ ))
            (( count_correct_all++ ))
        else
            printf "\t$i\t${ERROR_COLOR}Fail${RESET}\t$(tail -n 1 ${tempfile})\n"
            cat ${tempfile} > ${folder}$1-$2-$3-$4-$5_$i
            (( count_false++ ))
            (( count_false_all++ ))
        fi
    done
    print_percent $count_correct $iterations
}

live () {
    count_false=0
    count_correct=0
    printf "\t${WARN_COLOR}$1 $2 $3 $4 $5${RESET}\n"
    for (( i=1; i <= $iterations; i++)) ; do
        $philo $1 $2 $3 $4 $5 > ${tempfile}
        if [ $(tail -n 1 ${tempfile} | grep -c died) -ne 0 ]; then
            printf "\t$i\t${ERROR_COLOR}Fail${RESET}\t$(tail -n 1 ${tempfile})\n"
            cat ${tempfile} > ${folder}$1-$2-$3-$4-$5_$i
            (( count_false++ ))
            (( count_false_all++ ))
        else
            printf "\t$i\t${OK_COLOR}Pass${RESET}\t$(tail -n 1 ${tempfile})\n"
            (( count_correct++ ))
            (( count_correct_all++ ))
        fi
    done
    print_percent $count_correct $iterations
}

print_percent () {
    local correct=$1
    local total=$2
    local pct=$(awk -v c="$correct" -v t="$total" 'BEGIN { printf "%d", 100 / t * c }')
    if [ $pct -gt 89 ]; then
        printf "\t${OK_COLOR}$pct %% correct${RESET}\n"
    elif [ $pct -gt 69 ]; then
        printf "\t${WARN_COLOR}$pct %% correct${RESET}\n"
    else
        printf "\t${ERROR_COLOR}$pct %% correct${RESET}\n"
    fi
    printf "____________________________________________\n"
}

mandatory_tests () {
    printf "${OBJ_COLOR}Mandatory tests${RESET}\n\n"
    die 1 800 200 200 $times_to_eat
    live 5 800 200 200 7
    live 4 410 200 200 $times_to_eat
    die 4 310 200 100 $times_to_eat
}

uneven_live () {
    printf "${OBJ_COLOR}Testing uneven numbers - they shouldn't die${RESET}\n\n"
    live 5 800 200 200 $times_to_eat
    live 5 610 200 200 $times_to_eat
    live 199 610 200 200 $times_to_eat
}

uneven_live_extended () {
    printf "${OBJ_COLOR}Testing uneven numbers (overkill) - they shouldn't die${RESET}\n\n"
    live 5 610 200 100 $times_to_eat
    live 5 601 200 200 $times_to_eat
    live 31 610 200 100 $times_to_eat
    live 31 610 200 200 $times_to_eat
    live 31 605 200 200 $times_to_eat
    live 31 601 200 200 $times_to_eat
    live 131 610 200 100 $times_to_eat
    live 131 610 200 200 $times_to_eat
    live 131 605 200 200 $times_to_eat
    live 131 601 200 200 $times_to_eat
    live 199 610 200 100 $times_to_eat
    live 199 610 200 200 $times_to_eat
    live 199 605 200 200 $times_to_eat
    live 199 601 200 200 $times_to_eat
}

even_live () {
    printf "${OBJ_COLOR}Testing even numbers - they shouldn't die${RESET}\n"
    live 4 410 200 100 $times_to_eat
    live 4 410 200 200 $times_to_eat
    live 198 610 200 200 $times_to_eat
    live 198 800 200 200 $times_to_eat
}

even_live_extended () {
    # die=401 with N=130/198 is unreliable under cpus=2 (1ms slack exhausted by jitter).
    # Removed those two; die=401 with N=50 is fine (confirmed LIVE under cpus=2).
    printf "${OBJ_COLOR}Testing even numbers (overkill) - they shouldn't die${RESET}\n"
    live 50 410 200 100 $times_to_eat
    live 50 410 200 200 $times_to_eat
    live 50 405 200 200 $times_to_eat
    live 50 401 200 200 $times_to_eat
    live 130 410 200 100 $times_to_eat
    live 130 410 200 200 $times_to_eat
    live 130 405 200 200 $times_to_eat
    live 198 410 200 100 $times_to_eat
    live 198 410 200 200 $times_to_eat
    live 198 405 200 200 $times_to_eat
}

even_die () {
    # die=599, eat=200, sleep=200: die < eat+sleep is fatal for N=3 (always dies).
    # N=31 with die=599 is borderline/flaky (scheduling-dependent) and excluded.
    # N=131 with die=596 is reliably fatal.
    printf "${OBJ_COLOR}Testing even numbers - one should die${RESET}\n"
    die 3 599 200 200 $times_to_eat
    die 131 596 200 200 $times_to_eat
}

even_die_extended () {
    # die=396/399 are clearly fatal (die < eat+sleep=400).
    # die=400 with N=130/198 is also fatal in practice: with that many philosophers
    # the scheduling jitter alone exceeds the zero margin.
    # die=400 with N=50 is borderline/flaky and is excluded.
    printf "${OBJ_COLOR}Testing even numbers - one should die${RESET}\n"
    die 4 310 200 100 $times_to_eat
    die 50 396 200 200 $times_to_eat
    die 50 399 200 200 $times_to_eat
    die 130 396 200 200 $times_to_eat
    die 130 399 200 200 $times_to_eat
    die 130 400 200 200 $times_to_eat
    die 198 396 200 200 $times_to_eat
    die 198 399 200 200 $times_to_eat
    die 198 400 200 200 $times_to_eat
}

uneven_die () {
    printf "${OBJ_COLOR}Testing uneven numbers - one should die${RESET}\n"
    die 4 310 200 100 $times_to_eat
    die 1 800 200 100 $times_to_eat
}

uneven_die_extended () {
    # die=596: provably fatal (196ms slack < think+fork-wait for any implementation).
    # die=599 with N=3: dies consistently even under cpus=2 — keep as die.
    # die=599/600 with N=31/131/199: survivable with think-time coordination (confirmed
    #   LIVE under cpus=2). die=600 with N=3 is flaky under cpus=2, excluded.
    printf "${OBJ_COLOR}Testing uneven numbers - one should die${RESET}\n"
    die 3 596 200 200 $times_to_eat
    die 3 599 200 200 $times_to_eat
    die 31 596 200 200 $times_to_eat
    die 131 596 200 200 $times_to_eat
    die 199 596 200 200 $times_to_eat
    printf "${OBJ_COLOR}Testing uneven numbers - they should survive (die=599/600, solvable)${RESET}\n"
    live 31 600 200 200 $times_to_eat
    live 131 599 200 200 $times_to_eat
    live 131 600 200 200 $times_to_eat
    live 199 599 200 200 $times_to_eat
    live 199 600 200 200 $times_to_eat
}

# ── Run all groups ─────────────────────────────────────────────────────────────
mandatory_tests
uneven_live
uneven_live_extended
even_live
even_live_extended
uneven_die
uneven_die_extended
even_die
even_die_extended

printf "\n${BOLD}RESULT: passed: ${count_correct_all}\tfailed: ${count_false_all}${RESET}\n"
print_percent $count_correct_all $(( count_correct_all + count_false_all ))

[ $count_false_all -eq 0 ]
