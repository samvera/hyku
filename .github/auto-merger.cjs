module.exports = async ({ github, context }) => {
  const currentBranch = context.ref.replace('refs/heads/', '')
  const merges = {
    staging: { head: 'staging', base: 'main' },
    production: { head: 'production', base: 'staging' }
  }
  const merge = merges[currentBranch]

  if (!merge) return

  const commits = await getCommits(merge.base, merge.head)
  const pullRequests = await getMergedPullRequests(commits, merge)

  if (pullRequests.length === 0) {
    console.log(`No non-${merge.base} PRs to merge from ${merge.head} into ${merge.base}.`)
    return
  }

  await prepareMerge(merge, pullRequests)

  async function getCommits(base, head) {
    const commits = []
    let page = 1

    while (true) {
      const response = await github.request('GET /repos/{owner}/{repo}/compare/{basehead}', {
        owner: context.repo.owner,
        repo: context.repo.repo,
        basehead: `${base}...${head}`,
        page,
        per_page: 100
      })

      commits.push(...response.data.commits)
      if (response.data.total_commits <= page * 100) return commits
      page += 1
    }
  }

  async function getMergedPullRequests(commits, { head, base }) {
    const pullRequests = new Map()

    for (const commit of commits) {
      const response = await github.rest.repos.listPullRequestsAssociatedWithCommit({
        owner: context.repo.owner,
        repo: context.repo.repo,
        commit_sha: commit.sha
      })

      for (const pullRequest of response.data) {
        if (
          pullRequest.merged_at &&
          pullRequest.base.ref === head &&
          pullRequest.head.ref !== base
        ) {
          pullRequests.set(pullRequest.number, pullRequest)
        }
      }
    }

    return [...pullRequests.values()]
  }

  async function prepareMerge({ head, base }, pullRequests) {
    const marker = '<!-- hyku-auto-merger -->'
    const date = new Date().toISOString().split('T')[0]
    const title = `\`${head}\` -> \`${base}\` ${date}`
    const pullRequestList = pullRequests.map(pullRequest => `- #${pullRequest.number}`).join('\n')
    const body = `${marker}\nBrings the following changes to \`${base}\`:\n\n${pullRequestList}`

    const openPullRequests = await github.rest.pulls.list({
      owner: context.repo.owner,
      repo: context.repo.repo,
      state: 'open',
      head: `${context.repo.owner}:${head}`,
      base,
      sort: 'created',
      direction: 'desc'
    })
    const autoMergePullRequest = openPullRequests.data.find(pullRequest => pullRequest.body && pullRequest.body.includes(marker))

    if (autoMergePullRequest) {
      console.log(`Updating ${head} -> ${base} PR #${autoMergePullRequest.number}.`)
      await github.rest.pulls.update({
        owner: context.repo.owner,
        repo: context.repo.repo,
        pull_number: autoMergePullRequest.number,
        title,
        body
      })
    } else if (openPullRequests.data.length === 0) {
      console.log(`Creating ${head} -> ${base} PR.`)
      await github.rest.pulls.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        title,
        body,
        head,
        base,
        draft: true
      })
    } else {
      console.log(`A manually opened ${head} -> ${base} PR already exists; leaving it alone.`)
    }
  }
}