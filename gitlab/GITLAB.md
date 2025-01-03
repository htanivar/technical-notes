# glab CLI Commands

## Authentication

| Command             | Description                            |
|---------------------|----------------------------------------|
| `glab auth login`   | Login to GitLab from the command line. |
| `glab auth logout`  | Logout from GitLab in the CLI.         |
| `glab auth refresh` | Refresh authentication token.          |
| `glab auth status`  | Check authentication status.           |

## Issues

| Command              | Description                           |
|----------------------|---------------------------------------|
| `glab issues list`   | List issues in a repository.          |
| `glab issues view`   | View a specific issue by ID or URL.   |
| `glab issues create` | Create a new issue in the repository. |
| `glab issues close`  | Close an issue.                       |
| `glab issues reopen` | Reopen a closed issue.                |

## Merge Requests (MR)

| Command            | Description                                 |
|--------------------|---------------------------------------------|
| `glab mr list`     | List merge requests for a repository.       |
| `glab mr view`     | View a specific merge request by ID or URL. |
| `glab mr create`   | Create a new merge request.                 |
| `glab mr checkout` | Checkout a merge request to a local branch. |
| `glab mr approve`  | Approve a merge request.                    |
| `glab mr comment`  | Comment on a merge request.                 |

## Releases

| Command               | Description                             |
|-----------------------|-----------------------------------------|
| `glab release list`   | List all releases in a repository.      |
| `glab release create` | Create a new release in the repository. |
| `glab release view`   | View a specific release.                |
| `glab release delete` | Delete a release from the repository.   |

## Projects

| Command                 | Description                                |
|-------------------------|--------------------------------------------|
| `glab project view`     | View details of the project.               |
| `glab project edit`     | Edit project settings.                     |
| `glab project pipeline` | Show the pipeline for the current project. |

## Repository (Repo)

| Command            | Description                               |
|--------------------|-------------------------------------------|
| `glab repo clone`  | Clone a repository from GitLab.           |
| `glab repo create` | Create a new repository on GitLab.        |
| `glab repo delete` | Delete a repository on GitLab.            |
| `glab repo view`   | View repository details.                  |
| `glab repo fork`   | Fork a repository to your GitLab account. |
| `glab repo rename` | Rename a repository.                      |

## Secrets

| Command              | Description                     |
|----------------------|---------------------------------|
| `glab secret list`   | List repository secrets.        |
| `glab secret create` | Create a new repository secret. |
| `glab secret delete` | Delete a repository secret.     |

## Groups

| Command                    | Description                        |
|----------------------------|------------------------------------|
| `glab group list`          | List GitLab groups.                |
| `glab group create`        | Create a new GitLab group.         |
| `glab group edit`          | Edit an existing GitLab group.     |
| `glab group delete`        | Delete a GitLab group.             |
| `glab group member add`    | Add a user to a GitLab group.      |
| `glab group member remove` | Remove a user from a GitLab group. |
| `glab group member list`   | List members of a GitLab group.    |

## Pipelines & Jobs

| Command                 | Description                                         |
|-------------------------|-----------------------------------------------------|
| `glab ci status`        | Show the status of CI pipelines for the repository. |
| `glab ci trace`         | Show detailed trace logs for a given pipeline.      |
| `glab project pipeline` | Show the pipeline for the current project.          |

## Custom API Requests

| Command    | Description                       |
|------------|-----------------------------------|
| `glab api` | Make a custom GitLab API request. |

## Miscellaneous

| Command        | Description                               |
|----------------|-------------------------------------------|
| `glab alias`   | Set up or list command aliases.           |
| `glab help`    | Display help information about commands.  |
| `glab version` | Show the version of `glab`.               |
| `glab config`  | Manage configuration settings for `glab`. |
