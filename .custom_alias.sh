alias c='clear'
alias service-logs="c && kubectl logs --tail=1000 --timestamps -f"
alias kd="kubectl get deploy,po,svc"
alias get-node-process="ps -eo pid,lstart,cmd | grep node"
alias ls='ls --color -alh'

## For windows (wt - windows terminal)
alias new='wt.exe -w 0 -d "$(pwd)"'
alias V='wt.exe sp -d "$(pwd)" -V'
alias H='wt.exe sp -d "$(pwd)" -H'
alias cmd='start "" "C:\Windows\system32\cmd.exe"'
alias bash='start "" "C:\Program Files\Git\git-bash.exe"'
alias open='explorer .'

export PATH=$PATH:"~/bin":"~/.local/bin"

########################################## DO NOT CHANGE THE FOLLOWING ######################################

# Function to delete branch locally and remotely
function delete_branch() {
  branch=$1
  # Check if branch exists locally
  if git show-ref --verify --quiet refs/heads/$branch; then
    # Delete branch locally
    echo -e "Deleting $branch from local repo"
    git branch -d $branch
  fi

  # Check if branch exists on remote
  if git ls-remote --heads origin $branch | grep $branch; then
    # Delete branch on remote
    echo -e "Deleting $branch from remote repo \n"
    git push origin --delete $branch
  fi
}

function gitworktree_add() {
  # Variables
  BRANCH_NAME=$1
  WORKTREE_PATH="../$BRANCH_NAME"

  # Find the root of the git repository
  GIT_ROOT=$(git rev-parse --show-toplevel)

  # Convert to Windows path format if on Git Bash or Cygwin on Windows
  case "$(uname -s)" in
  MINGW* | CYGWIN*)
    GIT_ROOT=$(cygpath -u "$GIT_ROOT")
    ;;
  esac

  # Check if we are inside a git repository
  if [ -z "$GIT_ROOT" ]; then
    echo "Error: This command must be run inside a git repository."
    return 1
  fi

  cd "$GIT_ROOT"

  # Check if the branch exists remotely
  REMOTE_BRANCH=$(git ls-remote --heads origin "$BRANCH_NAME")

  if [ -z "$REMOTE_BRANCH" ]; then
    # If the branch doesn't exist remotely, create a new branch from the current branch
    echo "Branch '$BRANCH_NAME' does not exist remotely. Creating a new branch..."
    git checkout -b "$BRANCH_NAME"
    git push -u origin "$BRANCH_NAME"
  else
    # If the branch exists remotely, set it up locally
    echo "Branch '$BRANCH_NAME' exists remotely. Setting up locally..."
    git fetch origin "$BRANCH_NAME:$BRANCH_NAME"
  fi

  # Add the worktree for the specified branch from the Git root
  git worktree add -B "$WORKTREE_PATH" "$BRANCH_NAME"

  cd "$WORKTREE_PATH"

  echo "Worktree added for branch '$BRANCH_NAME'."
}

function gac() {
  if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    # displays help with
    # gac | gac -h | gac --help
    echo "------"
    echo "Cannot commit without comments. Semantic reminder:"
    echo "chore:        c"
    echo "docs:         d"
    echo "feat:         f"
    echo "refactor:     r"
    echo "style:        s"
    echo "test:         t"
    echo "fix:          x"
    echo "------"
    return 1
  fi

  SHORTCUT=$1
  shift
  COMMENT=$@

  # Chore
  if [ "$SHORTCUT" = "c" ]; then
    SHORTCUT="chore:"

  # Chore
  elif [ "$SHORTCUT" = "u" ]; then
    SHORTCUT="USAPBT-776"

  # Write or edit existing documentation
  elif [ "$SHORTCUT" = "d" ]; then
    SHORTCUT="docs:"

  # Add new feature
  elif [ "$SHORTCUT" = "f" ]; then
    SHORTCUT="feat:"

  # Refator your code base
  elif [ "$SHORTCUT" = "r" ]; then
    SHORTCUT="refactor:"

  # Styling actions
  elif [ "$SHORTCUT" = "s" ]; then
    SHORTCUT="style:"

  # Test your code
  elif [ "$SHORTCUT" = "t" ]; then
    SHORTCUT="test:"

  # Working on a feature
  elif [ "$SHORTCUT" = "x" ]; then
    SHORTCUT="fix:"
  fi

  # res with or without semantic
  git add -A && git commit -m "$SHORTCUT $COMMENT"
  return 1
}

## Kubectl Alias
alias k=kubectl
alias kca='_kca(){ kubectl "$@" --all-namespaces;  unset -f _kca; }; _kca'
alias kaf='kubectl apply -f'
alias keti='kubectl exec -t -i'
alias kcuc='kubectl config use-context'
alias kcsc='kubectl config set-context'
alias kcdc='kubectl config delete-context'
alias kccc='kubectl config current-context'
alias kcgc='kubectl config get-contexts'
alias kdel='kubectl delete'
alias kdelf='kubectl delete -f'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods --all-namespaces'
alias kgpw='kgp --watch'
alias kgpwide='kgp -o wide'
alias kep='kubectl edit pods'
alias kdp='kubectl describe pods'
alias kdelp='kubectl delete pods'
alias kgpall='kubectl get pods --all-namespaces -o wide'
alias kgpl='kgp -l'
alias kgpn='kgp -n'
alias kgs='kubectl get svc'
alias kgsa='kubectl get svc --all-namespaces'
alias kgsw='kgs --watch'
alias kgswide='kgs -o wide'
alias kes='kubectl edit svc'
alias kds='kubectl describe svc'
alias kdels='kubectl delete svc'
alias kgi='kubectl get ingress'
alias kgia='kubectl get ingress --all-namespaces'
alias kei='kubectl edit ingress'
alias kdi='kubectl describe ingress'
alias kdeli='kubectl delete ingress'
alias kgns='kubectl get namespaces'
alias kens='kubectl edit namespace'
alias kdns='kubectl describe namespace'
alias kdelns='kubectl delete namespace'
alias kcn='kubectl config set-context --current --namespace'
alias kgcm='kubectl get configmaps'
alias kgcma='kubectl get configmaps --all-namespaces'
alias kecm='kubectl edit configmap'
alias kdcm='kubectl describe configmap'
alias kdelcm='kubectl delete configmap'
alias kgsec='kubectl get secret'
alias kgseca='kubectl get secret --all-namespaces'
alias kdsec='kubectl describe secret'
alias kdelsec='kubectl delete secret'
alias kgd='kubectl get deployment'
alias kgda='kubectl get deployment --all-namespaces'
alias kgdw='kgd --watch'
alias kgdwide='kgd -o wide'
alias ked='kubectl edit deployment'
alias kdd='kubectl describe deployment'
alias kdeld='kubectl delete deployment'
alias ksd='kubectl scale deployment'
alias krsd='kubectl rollout status deployment'
alias kgrs='kubectl get replicaset'
alias kdrs='kubectl describe replicaset'
alias kers='kubectl edit replicaset'
alias krh='kubectl rollout history'
alias kru='kubectl rollout undo'
alias kgss='kubectl get statefulset'
alias kgssa='kubectl get statefulset --all-namespaces'
alias kgssw='kgss --watch'
alias kgsswide='kgss -o wide'
alias kess='kubectl edit statefulset'
alias kdss='kubectl describe statefulset'
alias kdelss='kubectl delete statefulset'
alias ksss='kubectl scale statefulset'
alias krsss='kubectl rollout status statefulset'
alias kpf="kubectl port-forward"
alias kga='kubectl get all'
alias kgaa='kubectl get all --all-namespaces'
alias kl='kubectl logs'
alias kl1h='kubectl logs --since 1h'
alias kl1m='kubectl logs --since 1m'
alias kl1s='kubectl logs --since 1s'
alias klf='kubectl logs -f'
alias klf1h='kubectl logs --since 1h -f'
alias klf1m='kubectl logs --since 1m -f'
alias klf1s='kubectl logs --since 1s -f'
alias kcp='kubectl cp'
alias kgno='kubectl get nodes'
alias keno='kubectl edit node'
alias kdno='kubectl describe node'
alias kdelno='kubectl delete node'
alias kgpvc='kubectl get pvc'
alias kgpvca='kubectl get pvc --all-namespaces'
alias kgpvcw='kgpvc --watch'
alias kepvc='kubectl edit pvc'
alias kdpvc='kubectl describe pvc'
alias kdelpvc='kubectl delete pvc'
alias kdsa="kubectl describe sa"
alias kdelsa="kubectl delete sa"
alias kgds='kubectl get daemonset'
alias kgdsw='kgds --watch'
alias keds='kubectl edit daemonset'
alias kdds='kubectl describe daemonset'
alias kdelds='kubectl delete daemonset'
alias kgcj='kubectl get cronjob'
alias kecj='kubectl edit cronjob'
alias kdcj='kubectl describe cronjob'
alias kdelcj='kubectl delete cronjob'
alias kgj='kubectl get job'
alias kej='kubectl edit job'
alias kdj='kubectl describe job'
alias kdelj='kubectl delete job'

## VSCODE alias
alias vsc="code ."
alias vsca="code --add"
alias vscd="code --diff"
alias vscg="code --goto"
alias vscn="code --new-window"
alias vscr="code --reuse-window"
alias vscw="code --wait"
alias vscu="code --user-data-dir"
alias vsced="code --extensions-dir"
alias vscie="code --install-extension"
alias vscue="code --uninstall-extension"
alias vscv="code --verbose"
alias vscl="code --log"
alias vscde="code --disable-extensions"

## NPM alias
alias npmg="npm i -g "
alias npmS="npm i -S "
alias npmD="npm i -D "
alias npmF='npm i -f'
alias npmE='PATH="$(npm bin)":"$PATH"'
alias npmO="npm outdated"
alias npmU="npm update"
alias npmV="npm -v"
alias npmL="npm list"
alias npmL0="npm ls --depth=0"
alias npmst="npm start"
alias npmt="npm test"
alias npmR="npm run"
alias npmP="npm publish"
alias npmI="npm init"
alias npmi="npm info"
alias npmSe="npm search"
alias npmrd="npm run dev"

## GIT Alias
alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'
alias ggpur='ggu'
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gav='git add --verbose'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gam='git am'
alias gama='git am --abort'
alias gamc='git am --continue'
alias gamscp='git am --show-current-patch'
alias gams='git am --skip'
alias gap='git apply'
alias gapt='git apply --3way'
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsn='git bisect new'
alias gbso='git bisect old'
alias gbsr='git bisect reset'
alias gbss='git bisect start'
alias gbl='git blame -w'
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'
alias gbgd='LANG=C git branch --no-color -vv | grep ": gone\]" | awk '"'"'{print $1}'"'"' | xargs git branch -d'
alias gbgD='LANG=C git branch --no-color -vv | grep ": gone\]" | awk '"'"'{print $1}'"'"' | xargs git branch -D'
alias gbm='git branch --move'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias gbg='LANG=C git branch -vv | grep ": gone\]"'
alias gco='git checkout'
alias gcor='git checkout --recurse-submodules'
alias gcb='git checkout -b'
alias gcd='git checkout $(git_develop_branch)'
alias gcm='git checkout $(git_main_branch)'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gclean='git clean --interactive -d'
alias gcl='git clone --recurse-submodules'
alias gcam='git commit --all --message'
alias gcas='git commit --all --signoff'
alias gcasm='git commit --all --signoff --message'
alias gcs='git commit --gpg-sign'
alias gcss='git commit --gpg-sign --signoff'
alias gcssm='git commit --gpg-sign --signoff --message'
alias gcmsg='git commit --message'
alias gcsm='git commit --signoff --message'
alias gc='git commit --verbose'
alias gca='git commit --verbose --all'
alias gca!='git commit --verbose --all --amend'
alias gcan!='git commit --verbose --all --no-edit --amend'
alias gcans!='git commit --verbose --all --signoff --no-edit --amend'
alias gc!='git commit --verbose --amend'
alias gcn!='git commit --verbose --no-edit --amend'
alias gcf='git config --list'
alias gdct='git describe --tags $(git rev-list --tags --max-count=1)'
alias gd='git diff'
alias gdca='git diff --cached'
alias gdcw='git diff --cached --word-diff'
alias gds='git diff --staged'
alias gdw='git diff --word-diff'
alias gdup='git diff @{upstream}'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gf='git fetch'
alias gfo='git fetch origin'
alias gg='git gui citool'
alias gga='git gui citool --amend'
alias ghh='git help'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
alias glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glp='_git_log_prettily'
alias glg='git log --stat'
alias glgp='git log --stat --patch'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias gfg='git ls-files | grep'
alias gm='git merge'
alias gma='git merge --abort'
alias gms="git merge --squash"
alias gmom='git merge origin/$(git_main_branch)'
alias gmum='git merge upstream/$(git_main_branch)'
alias gmtl='git mergetool --no-prompt'
alias gmtlvim='git mergetool --no-prompt --tool=vimdiff'
alias gl='git pull'
alias gpr='git pull --rebase'
alias gup='git pull --rebase'
alias gupa='git pull --rebase --autostash'
alias gupav='git pull --rebase --autostash --verbose'
alias gupv='git pull --rebase --verbose'
alias gupom='git pull --rebase origin $(git_main_branch)'
alias gupomi='git pull --rebase=interactive origin $(git_main_branch)'
alias ggpull='git pull origin "$(git_current_branch)"'
alias gluc='git pull upstream $(git_current_branch)'
alias glum='git pull upstream $(git_main_branch)'
alias gp='git push'
alias gpd='git push --dry-run'
alias gpf!='git push --force'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gpv='git push --verbose'
alias gpoat='git push origin --all && git push origin --tags'
alias gpod='git push origin --delete'
alias ggpush='git push origin "$(git_current_branch)"'
alias gpu='git push upstream'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase --interactive'
alias grbo='git rebase --onto'
alias grbs='git rebase --skip'
alias grbd='git rebase $(git_develop_branch)'
alias grbm='git rebase $(git_main_branch)'
alias grbom='git rebase origin/$(git_main_branch)'
alias gr='git remote'
alias grv='git remote --verbose'
alias gra='git remote add'
alias grrm='git remote remove'
alias grmv='git remote rename'
alias grset='git remote set-url'
alias grup='git remote update'
alias grh='git reset'
alias gru='git reset --'
alias grhh='git reset --hard'
alias grhk='git reset --keep'
alias grhs='git reset --soft'
alias gpristine='git reset --hard && git clean --force -dfx'
alias groh='git reset origin/$(git_current_branch) --hard'
alias grs='git restore'
alias grss='git restore --source'
alias grst='git restore --staged'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
alias grev='git revert'
alias grm='git rm'
alias grmc='git rm --cached'
alias gcount='git shortlog --summary --numbered'
alias gsh='git show'
alias gsps='git show --pretty=short --show-signature'
alias gstall='git stash --all'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --patch'
alias gst='git status'
alias gss='git status --short'
alias gsb='git status --short --branch'
alias gsi='git submodule init'
alias gsu='git submodule update'
alias gsd='git svn dcommit'
alias git-svn-dcommit-push='git svn dcommit && git push github $(git_main_branch):svntrunk'
alias gsr='git svn rebase'
alias gsw='git switch'
alias gswc='git switch --create'
alias gswd='git switch $(git_develop_branch)'
alias gswm='git switch $(git_main_branch)'
alias gta='git tag --annotate'
alias gts='git tag --sign'
alias gtv='git tag | sort -V'
alias gignore='git update-index --assume-unchanged'
alias gunignore='git update-index --no-assume-unchanged'
alias gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'
alias gstu='gsta --include-untracked'
alias gtl='gtl(){ git tag --sort=-v:refname -n --list "${1}*" }; noglob gtl'
alias gk='\gitk --all --branches &!'
alias gke='\gitk --all $(git log --walk-reflogs --pretty=%h) &!'
