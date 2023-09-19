_() {
  #########################################################################################################
  # Function to prompt user for a variable value 
  prompt_and_set_variable() {
    local variable_name="$1"
    local prompt_text="$2"
    local default_value="$3"
    
    echo "$prompt_text"
    read -r "$variable_name"
    [ -z "${!variable_name}" ] && eval "$variable_name=$default_value"
  }

  # Function to get a random component of a date
  get_random_component() {
    local COMPONENT_NAME="$1"

    case "$COMPONENT_NAME" in
      Y) echo "$(( (RANDOM % 23) + 2001 ))" ;;
      m) echo "$(( ( RANDOM % 12 )  + 1 ))" ;;
      d) echo "$(( ( RANDOM % 30 )  + 1 ))" ;;
      H) echo "$(( ( RANDOM % 24 )  + 1 ))" ;;
      M) echo "$(( ( RANDOM % 60 )  + 1 ))" ;;
      S) echo "$(( ( RANDOM % 60 )  + 1 ))" ;;
      *) echo "Invalid component_name" && exit 1;;
    esac
  }

  # Function to get a specific component of a date
  get_commit_date_component() {
    local component_name="$1"
    local commit="$2"
    local default_value="$3"
    local format_string="%$component_name"

    local value=$(git log -1 --pretty=format:%cd --date=format:"$format_string" "$commit" 2>/dev/null)

    if [ "$default_value" = "NONE" ]; then
      echo "$value"
    elif [ "$default_value" = "R" ]; then
      echo "$(get_random_component "$component_name")"
    else
      echo "$default_value"
    fi
  }

  #########################################################################################################

  # Read all user values
  echo "GitHub Repository (URI): "
  read -r REPOSITORY_URI

  if [ -z "$REPOSITORY_URI" ]; then
    echo "You need to provide a URI :s"
    exit 1
  fi

  prompt_and_set_variable COMMIT "Enter a specific commit hash (or press ENTER for default 'ALL')" "ALL"
  prompt_and_set_variable YEAR "Enter a year, R for RANDOM, or press ENTER for default 'NONE'" "NONE"
  prompt_and_set_variable MONTH "Enter a month, R for RANDOM, or press ENTER for default 'NONE'" "NONE"
  prompt_and_set_variable DAY "Enter a day, R for RANDOM, or press ENTER for default 'NONE'" "NONE"
  prompt_and_set_variable HOUR "Enter an hour, R for RANDOM, or press ENTER for default 'NONE'" "NONE"
  prompt_and_set_variable MINUTE "Enter a minute, R for RANDOM, or press ENTER for default 'NONE'" "NONE"
  prompt_and_set_variable SECOND "Enter seconds, R for RANDOM, or press ENTER for default 'NONE'" "NONE"

  if [ "$YEAR" = "NONE" ] && [ "$MONTH" = "NONE" ] && [ "$DAY" = "NONE" ] && [ "$HOUR" = "NONE" ] && [ "$MINUTE" = "NONE" ] && [ "$SECOND" = "NONE" ]; then
    echo "All variables are set to NONE. Exiting..."
    exit 1
  fi

  #########################################################################################################
  
  # Clone repository and move to folder
  git clone "$REPOSITORY_URI"
  repository_name="$(basename "$REPOSITORY_URI")"
  cd "$repository_name"

  # Set the commits to be rewritten
  if [ "$COMMIT" = "ALL" ]; then
    GIT_COMMITS=$(git log --pretty=format:'%H')
  else
    GIT_COMMITS=$COMMIT
  fi

  export FILTER_BRANCH_SQUELCH_WARNING=1

  for commit in $GIT_COMMITS
    do
    UPDATED_YEAR=$(get_commit_date_component 'Y' "$commit" "$YEAR")
    UPDATED_MONTH=$(get_commit_date_component 'm' "$commit" "$MONTH")
    UPDATED_DAY=$(get_commit_date_component 'd' "$commit"  "$DAY")
    UPDATED_HOUR=$(get_commit_date_component 'H' "$commit" "$HOUR")
    UPDATED_MINUTE=$(get_commit_date_component 'M' "$commit" "$MINUTE")
    UPDATED_SECOND=$(get_commit_date_component 'S' "$commit" "$SECOND")

    # Set the author date for the current commit as a properly formatted string
    GIT_DATE="${UPDATED_YEAR}-${UPDATED_MONTH}-${UPDATED_DAY}T${UPDATED_HOUR}:${UPDATED_MINUTE}:${UPDATED_SECOND}"

    # Use git filter-branch to update both the author date and committer date of the commit
    export GIT_DATE 
    git filter-branch --env-filter '
        if [ "$GIT_COMMIT" = '"$commit"' ]; then
            export GIT_AUTHOR_DATE="$GIT_DATE"
            export GIT_COMMITTER_DATE="$GIT_DATE"
        fi
    ' --force
  done  

  # THE END
  clear
  echo "********************************************************************************"
  echo "*  It's done, now go to your local repository and push to remote repository :) *"
  echo "*              Thank's to test my script <3 - @matheusinfo                     *"     
  echo "********************************************************************************"        
} && _

unset -f _