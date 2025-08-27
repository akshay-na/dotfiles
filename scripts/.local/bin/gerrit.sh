#!/bin/bash

set -e

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helpers
print_table() {
  column -t -s $'\t'
}

header() {
  echo -e "CHANGE\tPROJECT\tOWNER\tREVIEWERS\tSTATUS\tSUBJECT\tURL"
  echo -e "------\t--------\t-------------------\t---------------------\t--------\t----------------------------------------\t---------------------------------------------"
}

query_gerrit() {
  ssh gerrit gerrit query "$@" --format=JSON --all-reviewers |
    jq -r '
  select(.type != "stats") |
  [
    .number,
    .project,
    .owner.name,
    (.allReviewers | map(.name | split(" ")[0]) | unique | join(", ")),
    .status,
    (.subject | if length > 40 then (.[:37] + "...") else . end),
    .url
  ] | @tsv'
}

case "$1" in
--mine)
  echo -e "${BLUE}[ Your Open Changes ]${NC}\n"
  {
    header
    query_gerrit "owner:self status:open"
  } | print_table
  ;;

--reviews)
  echo -e "${BLUE}[ Changes Assigned to You for Review ]${NC}\n"
  {
    header
    query_gerrit "reviewer:self status:open"
  } | print_table
  ;;

--debt)
  echo -e "${BLUE}[ Review Debt by Developer ]${NC}\n"
  {
    header
    query_gerrit "status:open AND (reviewer:self OR owner:self)"
  } | print_table
  ;;

--stale)
  AGE="${2:-7d}"
  echo -e "${BLUE}[ Stale Reviews Older than $AGE ]${NC}\n"
  {
    header
    query_gerrit "status:open age:>$AGE"
  } | print_table
  ;;

--topic)
  if [ -z "$2" ]; then
    echo -e "${RED}Usage: $0 --topic <topic>${NC}"
    exit 1
  fi
  echo -e "${BLUE}[ Changes in Topic: $2 ]${NC}\n"
  {
    header
    query_gerrit "topic:$2"
  } | print_table
  ;;

--bug)
  if [ -z "$2" ]; then
    echo -e "${RED}Usage: $0 --bug <BUG-ID>${NC}"
    exit 1
  fi
  echo -e "${BLUE}[ Changes Mentioning Bug: $2 ]${NC}\n"
  {
    header
    query_gerrit "message:$2"
  } | print_table
  ;;

--project)
  if [ -z "$2" ]; then
    echo -e "${RED}Usage: $0 --project <PROJECT-NAME>${NC}"
    exit 1
  fi
  echo -e "${BLUE}[ Open Changes by Project ]${NC}\n"
  ssh gerrit gerrit query "status:open project:$2" --format=JSON |
    jq -r 'select(.type != "stats") | .project' | sort | uniq -c | sort -nr
  ;;

--help | -h | *)
  echo -e "${CYAN}Gerrit CLI Power Tool${NC}"
  echo "Usage: $0 [option]"
  echo "Options:"
  echo -e "  ${GREEN}--mine${NC}                    Show your open changes"
  echo -e "  ${GREEN}--reviews${NC}                 Changes assigned to you for review"
  echo -e "  ${GREEN}--stale [days]${NC}            Show reviews older than N days (default 7d)"
  echo -e "  ${GREEN}--debt${NC}                    Review debt (who's waiting on you)"
  echo -e "  ${GREEN}--topic <name>${NC}            All changes under a topic"
  echo -e "  ${GREEN}--bug <BUG-ID>${NC}            Changes mentioning a bug ID"
  echo -e "  ${GREEN}--project <PROJECT-NAME>${NC}  Open changes for a project"
  echo -e "  ${GREEN}--help${NC}                    Show this help"
  ;;
esac
