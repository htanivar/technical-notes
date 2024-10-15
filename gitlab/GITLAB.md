| Command                               | Description                                             |
|---------------------------------------|---------------------------------------------------------|
| `glab auth login`                     | Authenticate to your GitLab instance.                   |
| `glab auth logout`                    | Log out from the current GitLab instance.               |
| `glab config set <key> <value>`       | Set a configuration key-value pair.                     |
| `glab config get`                     | Get the current configuration settings.                 |
| `glab repo list`                      | List all repositories you have access to.               |
| `glab repo view <repo>`               | View details of a specific repository.                  |
| `glab repo create <repo-name>`        | Create a new repository.                                |
| `glab issue list`                     | List issues in the current repository.                  |
| `glab issue create --title <title>`   | Create a new issue with a specified title.              |
| `glab issue view <issue-id>`          | View details of a specific issue.                       |
| `glab merge-request list`             | List merge requests in the current repository.          |
| `glab merge-request create`           | Create a new merge request.                             |
| `glab merge-request view <mr-id>`     | View details of a specific merge request.               |
| `glab pipeline list`                  | List pipelines for the current repository.              |
| `glab pipeline run`                   | Trigger a new pipeline for the current branch.          |
| `glab pipeline view <pipeline-id>`    | View details of a specific pipeline.                    |
| `glab release list`                   | List releases in the current repository.                |
| `glab release create --tag <tag>`     | Create a new release with a specified tag.              |
| `glab project list`                   | List all projects accessible to the authenticated user. |
| `glab project fork <repo>`            | Fork a repository to your namespace.                    |
| `glab project star <repo>`            | Star a repository.                                      |
| `glab project unstar <repo>`          | Unstar a repository.                                    |
| `glab snippet list`                   | List your snippets.                                     |
| `glab snippet create --title <title>` | Create a new snippet.                                   |
| `glab snippet view <snippet-id>`      | View details of a specific snippet.                     |
| `glab group list`                     | List groups you are a member of.                        |
| `glab group view <group-id>`          | View details of a specific group.                       |
| `glab ci lint <file>`                 | Lint a CI configuration file.                           |
| `glab webhook list`                   | List webhooks for the current repository.               |
| `glab webhook add <url>`              | Add a new webhook.                                      |
| `glab webhook remove <hook-id>`       | Remove a webhook.                                       |
| `glab label list`                     | List labels in the current repository.                  |
| `glab label create <label>`           | Create a new label.                                     |
| `glab label delete <label>`           | Delete a label.                                         |
