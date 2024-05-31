**SSH Key Generation**

    ssh-keygen -t ed25519 -C "your_email@example.com"
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/<private ssh file>

| Action                         | Command                                                                           |
|--------------------------------|-----------------------------------------------------------------------------------|
| **Initialize Repository**      | `git init`                                                                        |
| **Clone Repository**           | `git clone <repository_url>`                                                      |
| **Check Status**               | `git status`                                                                      |
| **Add Changes**                | `git add <filename>`                                                              |
|                                | `git add .`                                                                       |
| **Commit Changes**             | `git commit -m "Commit message"`                                                  |
| **Add, Commit & push**         | `git commit -am "Your commit message" && git push`                                |
| **Update Last Commit**         | `git commit --amend`                                                              |
| **Create Branch**              | `git branch <branch_name>`                                                        |
| **Switch Branch**              | `git checkout <branch_name>`                                                      |
| **Pull Changes**               | `git pull origin <branch_name>`                                                   |
| **Merge Changes**              | `git merge <branch_name>`                                                         |
| **Rebase Branch**              | `git rebase <base_branch>`                                                        |
| **Interactive Rebase**         | `git rebase -i <base_branch>`                                                     |
| **Push Changes**               | `git push origin <branch_name>`                                                   |
| **Force Push Changes**         | `git push origin <branch_name> --force`                                           |
| **Stash Changes**              | `git stash`                                                                       |
| **Apply Stashed Changes**      | `git stash apply`                                                                 |
| **Pop Stash**                  | `git stash pop`                                                                   |
| **List Stashes**               | `git stash list` \n `git stash list --pretty=format:"%h - %gd: %gs" --date=local` |
| **Drop Stash**                 | `git stash drop`                                                                  |
| **Purge Remote Branch**        | `git push origin --delete <branch_name>`                                          |
| **Create and Switch Branch**   | `git checkout -b <branch_name>`                                                   |
| **Fetch Changes**              | `git fetch`                                                                       |
| **Merge with Fast-Forward**    | `git merge --ff-only <branch_name>`                                               |
| **Merge with Commit**          | `git merge --no-ff <branch_name>`                                                 |
| **Rebase Interactively**       | `git rebase -i <base_branch>`                                                     |
| **Cherry-pick a Commit**       | `git cherry-pick <commit_hash>`                                                   |
| **View Commit History**        | `git log`                                                                         |
| **View Remote URLs**           | `git remote -v`                                                                   |
| **Add Remote Repository**      | `git remote add <remote_name> <remote_url>`                                       |
| **Remove Remote**              | `git remote remove <remote_name>`                                                 |
| **Undo Last Commit (Local)**   | `git reset HEAD^`                                                                 |
| **Undo Last Commit (Remote)**  | `git push origin +HEAD^:<branch_name>`                                            |
| **Create Tag**                 | `git tag <tag_name>`                                                              |
| **Show Tags**                  | `git show <tag_name>`                                                             |
| **Delete Local Branch**        | `git branch -d <branch_name>`                                                     |
| **Delete Remote Branch**       | `git push origin --delete <branch_name>`                                          |
| **Configure User Information** | `git config --global user.name "Your Name"`                                       |
| **Configure User Email**       | `git config --global user.email "your.email@example.com"`                         |

| Action                                        | Command                                                                                      |
|-----------------------------------------------|----------------------------------------------------------------------------------------------|
| **Stash Untracked Files**                     | `git stash -u`                                                                               |
| **Create and Apply a Patch**                  | `git diff > patchfile`<br/>`git apply < patchfile`                                           |
| **Undo a Commit and Keep Changes**            | `git reset --soft HEAD^`                                                                     |
| **Undo a Commit and Discard Changes**         | `git reset --hard HEAD^`                                                                     |
| **Amend the Author of the Last Commit**       | `git commit --amend --author="Author Name <email>"`                                          |
| **Undo Changes in Staging Area**              | `git reset`                                                                                  |
| **View Changes in a Specific Commit**         | `git show <commit_hash>`                                                                     |
| **View Remote Branches with Details**         | `git remote show origin`                                                                     |
| **List Tags with Commit Information**         | `git tag -n`                                                                                 |
| **List Only Merged Branches**                 | `git branch --merged`                                                                        |
| **List Only Unmerged Branches**               | `git branch --no-merged`                                                                     |
| **Delete Tag Locally and Remotely**           | `git tag -d <tag_name>`<br/>`git push origin --delete tag <tag_name>`                        |
| **Rename Local and Remote Branch**            | `git branch -m <new_branch_name>`<br/>`git push origin :<old_branch_name> <new_branch_name>` |
| **View Git Configurations**                   | `git config --list`                                                                          |
| **Clone a Specific Branch from a Repository** | `git clone -b <branch_name> <repository_url>`                                                |

| Action                              | Command                                                     |
|-------------------------------------|-------------------------------------------------------------|
| **Create Lightweight Tag**          | `git tag <tag_name>`                                        |
| **Create Annotated Tag**            | `git tag -a <tag_name> -m "Tag message"`                    |
| **List Tags**                       | `git tag`                                                   |
| **Tag a Specific Commit**           | `git tag -a <tag_name> <commit_hash> -m "Tag message"`      |
| **Push a Specific Tag to Remote**   | `git push origin <tag_name>`                                |
| **Push All Tags to Remote**         | `git push origin --tags`                                    |
| **Delete Local Tag**                | `git tag -d <tag_name>`                                     |
| **Delete Remote Tag**               | `git push origin --delete <tag_name>`                       |
| **View Tag Information**            | `git show <tag_name>`                                       |
| **Checkout a Specific Tag**         | `git checkout tags/<tag_name>` or `git checkout <tag_name>` |
| **Create Annotated Tag with Sign**  | `git tag -s <tag_name> -m "Tag message"`                    |
| **Verify a Signed Tag**             | `git tag -v <tag_name>`                                     |
| **List Only Tags Matching Pattern** | `git tag -l "<pattern>"`                                    |

| Action                               | Command                                                                                       |
|--------------------------------------|-----------------------------------------------------------------------------------------------|
| **Check SSH Version**                | `ssh -v` or `ssh -V`                                                                          |
| **Check SSH Agent**                  | `ssh-add -l`                                                                                  |
| **Add SSH Key to Agent**             | `ssh-add <private_key_path>`                                                                  |
| **List SSH Keys in Agent**           | `ssh-add -L`                                                                                  |
| **Test SSH Connection to Host**      | `ssh -T git@<hostname>` or `ssh -T -p <port_number> git@<hostname>`                           |
| **Check SSH Configuration**          | `cat ~/.ssh/config` or `cat /etc/ssh/ssh_config`                                              |
| **Check Known Hosts**                | `cat ~/.ssh/known_hosts`                                                                      |
| **SSH to Host with Verbose Output**  | `ssh -v git@<hostname>` or `ssh -v -p <port_number> git@<hostname>`                           |
| **Generate SSH Key Pair**            | `ssh-keygen -t rsa -b 4096 -C "your_email@example.com"`                                       |
| **Copy SSH Public Key to Clipboard** | `pbcopy < ~/.ssh/id_rsa.pub` (for macOS) or `xclip -sel clip < ~/.ssh/id_rsa.pub` (for Linux) |
| **Check SSH Connection via Telnet**  | `telnet <hostname> <port_number>`                                                             |
| **Check Listening Ports**            | `netstat -tulpn` or `lsof -i :<port_number>`                                                  |
| **Generate SSH Debug Output**        | `ssh -vvv git@<hostname>` or `ssh -vvv -p <port_number> git@<hostname>`                       |

| Action                           | Command                                  |
|----------------------------------|------------------------------------------|
| **Create Patch**                 | `git diff > my_changes.patch`            |
| **Apply Patch**                  | `git apply < my_changes.patch`           |
| **Create Patch Series**          | `git format-patch origin/main`           |
| **Apply Patch from Email**       | `git am < my_patch.eml`                  |
| **Check Patch Status**           | `git apply --check < my_changes.patch`   |
| **Show Patch Information**       | `git show -p < my_changes.patch`         |
| **Apply Patch with Reversed**    | `git apply --reverse < my_changes.patch` |
| **Create and Apply Stash**       | `git stash -p` and `git stash apply`     |
| **Interactively Apply Patches**  | `git add -p && git commit`               |
| **Apply Patch with 3-way Merge** | `git apply --3way < my_changes.patch`    |

| Action                                                      | Command                                                                              |
|-------------------------------------------------------------|--------------------------------------------------------------------------------------|
| **Show Commit History**                                     | `git log`                                                                            |
| **Show Commit History with Details**                        | `git log -p`                                                                         |
| **Show One-Line Commit Summary**                            | `git log --oneline`                                                                  |
| **Show Graphical Commit History**                           | `git log --graph` or `git log --oneline --graph --all`                               |
| **Show Commit History for a File**                          | `git log <file_path>`                                                                |
| **Show Commit History for a Author**                        | `git log --author="Author Name"`                                                     |
| **Show Commit History Since Date**                          | `git log --since="YYYY-MM-DD"`                                                       |
| **Show Commit History Until Date**                          | `git log --until="YYYY-MM-DD"`                                                       |
| **Show Commit History in a Range**                          | `git log <commit_hash1>..<commit_hash2>` or `git log <branch_name1>..<branch_name2>` |
| **Show Commit History with Stats**                          | `git log --stat`                                                                     |
| **Show Commit History in a Pretty Format**                  | `git log --pretty=format:"%h - %an, %ar : %s"`                                       |
| **Show Commit History with Graph and Details**              | `git log --graph --pretty=oneline --abbrev-commit`                                   |
| **Show Commit History Across All Branches**                 | `git log --all`                                                                      |
| **Show Only Merged Commits**                                | `git log --merges` or `git log --no-merges`                                          |
| **Show Commits That Touched a Specific Line**               | `git log -L <start>,<end>:<file>`                                                    |
| **Show Commits in Reverse Order**                           | `git log --reverse`                                                                  |
| **Show Commit History with Grep**                           | `git log --grep="search_term"`                                                       |
| **Show Commit History with Short Stat**                     | `git log --stat --shortstat`                                                         |
| **Show Commit History with Author Date**                    | `git log --pretty="format:%ad"`                                                      |
| **Show Commit History with Commits from a Specific Author** | `git log --author="Author Name" --oneline`                                           |

| Action                                          | Command                                                                                          |
|-------------------------------------------------|--------------------------------------------------------------------------------------------------|
| **Merge Branch into Current Branch**            | `git merge <branch_name>`                                                                        |
| **Fast-Forward Merge**                          | `git merge --ff-only <branch_name>`                                                              |
| **Create a Merge Commit Always**                | `git merge --no-ff <branch_name>`                                                                |
| **Merge Branch with Commit Message**            | `git merge --message "Merge branch feature-branch"`                                              |
| **Merge with Automatic Conflict Resolution**    | `git merge -X theirs <branch_name>`                                                              |
| **Merge with Manual Conflict Resolution**       | `git merge --no-commit <branch_name>` followed by manual resolution and `git merge --continue`   |
| **Abort a Merge in Progress**                   | `git merge --abort`                                                                              |
| **Recursive vs. Octopus Merge**                 | `git merge -s recursive <branch_name>` or `git merge -s octopus <branch1> <branch2>`             |
| **Show the Branch that Caused the Merge**       | `git merge --show-current`                                                                       |
| **Preview Changes Before Merging**              | `git merge --no-commit --no-ff <branch_name>`                                                    |
| **Merge Only Specific Commits**                 | `git cherry-pick <commit_hash>` followed by resolving conflicts and committing                   |
| **Merge Upstream Changes in Forked Repository** | 1. Add the original repository as a remote (`git remote add upstream <original_repository_url>`) |
|                                                 | 2. Fetch upstream changes (`git fetch upstream`)                                                 |
|                                                 | 3. Switch to the branch you want to update (`git checkout <branch_name>`)                        |
|                                                 | 4. Merge changes (`git merge upstream/main` or the branch you want)                              |
| **Rebase Instead of Merge**                     | `git pull --rebase origin <branch_name>`                                                         |

| Action                                                            | Command                                                           |
|-------------------------------------------------------------------|-------------------------------------------------------------------|
| **Switch to a Branch**                                            | `git checkout <branch_name>`                                      |
| **Create and Switch to a New Branch**                             | `git checkout -b <new_branch_name>`                               |
| **Switch to the Previous Branch**                                 | `git checkout -` or `git checkout @{-1}`                          |
| **Switch to a Specific Commit**                                   | `git checkout <commit_hash>`                                      |
| **Switch to a Specific Tag**                                      | `git checkout tags/<tag_name>` or `git checkout <tag_name>`       |
| **Switch to a Detached HEAD State**                               | `git checkout <commit_hash>`                                      |
| **Create and Switch to a Branch at a Specific Commit**            | `git checkout -b <branch_name> <commit_hash>`                     |
| **Switch to a Remote Branch**                                     | `git checkout -b <branch_name> origin/<branch_name>`              |
| **Discard Changes in a File**                                     | `git checkout -- <file>` or `git restore <file>`                  |
| **Discard Uncommitted Changes in All Files**                      | `git checkout -- .` or `git restore .`                            |
| **Undo a Specific Commit Locally**                                | `git checkout <commit_hash>^ -- .`                                |
| **Undo Last Commit and Keep Changes**                             | `git reset --soft HEAD^` followed by `git checkout .`             |
| **Undo Last Commit and Discard Changes**                          | `git reset --hard HEAD^`                                          |
| **Switch to a Specific File Version in a Specific Commit**        | `git checkout <commit_hash> -- <file>`                            |
| **Switch to the Next or Previous Branch Interactively**           | `git checkout -` and then choose the branch you want              |
| **Switch to the Main Branch (Default Branch)**                    | `git checkout main` or `git checkout master`                      |
| **Switch to a Specific Remote Branch**                            | `git checkout -b <local_branch_name> origin/<remote_branch_name>` |
| **Create and Switch to a Specific Branch at a Remote Commit**     | `git checkout -b <branch_name> origin/<branch_name> --no-track`   |
| **Create and Switch to an Orphan Branch**                         | `git checkout --orphan <branch_name>`                             |
| **Create and Switch to a Specific Commit in Detached HEAD State** | `git checkout <commit_hash>`                                      |

| Action                                        | Command                                                                                     |
|-----------------------------------------------|---------------------------------------------------------------------------------------------|
| **List Local Branches**                       | `git branch`                                                                                |
| **List Remote Branches**                      | `git branch -r` or `git branch -a`                                                          |
| **Create a New Branch**                       | `git branch <branch_name>`                                                                  |
| **Create and Switch to New Branch**           | `git checkout -b <branch_name>` or `git switch -c <branch_name>`                            |
| **Delete Local Branch**                       | `git branch -d <branch_name>` or `git branch -D <branch_name>`                              |
| **Rename Local Branch**                       | `git branch -m <new_branch_name>`                                                           |
| **Switch to a Branch**                        | `git checkout <branch_name>` or `git switch <branch_name>`                                  |
| **Create a Branch at a Specific Commit**      | `git branch <branch_name> <commit_hash>`                                                    |
| **Show Last Commit on Each Branch**           | `git branch -v`                                                                             |
| **List Remote Branches Verbosely**            | `git branch -vv`                                                                            |
| **Show Merged/Unmerged Branches**             | `git branch --merged` or `git branch --no-merged`                                           |
| **List Branches by Date of Last Commit**      | `git for-each-ref --sort=-committerdate refs/heads/`                                        |
| **Show Branches with Selected Commit**        | `git branch --contains <commit_hash>`                                                       |
| **Create a Branch at Remote Commit**          | `git branch <branch_name> origin/<branch_name>`                                             |
| **Set Upstream Branch for Existing Branch**   | `git branch -u origin/<branch_name>` or `git branch --set-upstream-to=origin/<branch_name>` |
| **List Remote Tracking Branches**             | `git branch -r` or `git for-each-ref --format='%(upstream:short)' refs/heads`               |
| **Show Remote Branch with Tracking Info**     | `git remote show origin` or `git branch -vv`                                                |
| **Show All References**                       | `git show-ref` or `git show-ref --heads --tags`                                             |
| **Delete Remote Branch Locally and Remotely** | `git branch -d <branch_name>` followed by `git push origin --delete <branch_name>`          |
| **Delete Remote Tracking Branch**             | `git branch -dr <remote>/<branch>`                                                          |
| **Delete Merged Branches**                    | `git branch --merged                                                                        | grep -v "\*" | xargs -n 1 git branch -d` |
| **Delete All Local Branches Except Master**   | `git branch                                                                                 | grep -v "master" | xargs git branch -d` |
| **Prune Remote Tracking Branches**            | `git remote prune origin` or `git fetch --prune origin`                                     |
| **List Branches with Details**                | `git show-branch -a`                                                                        |
| **List Branches by Author**                   | `git shortlog -s -n`                                                                        |

ssh -T git@github.com
ssh -T -p 443 git@ssh.github.com