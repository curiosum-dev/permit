import Config

config :versioce,
  files: ["README.md", "mix.exs"],
  post_hooks: [Versioce.PostHooks.Git.Release]

config :versioce, :git,
  commit_message_template: "Bump version to {version}",
  tag_template: "v{version}",
  tag_message_template: "Release v{version}"

config :versioce, :changelog,
  changelog_file: "CHANGELOG.md",
  datagrabber: Versioce.Changelog.DataGrabber.Git,
  formatter: Versioce.Changelog.Formatter.Keepachangelog,
  anchors: %{
    added: ["add:", "build:", "Add", "Introduce"],
    changed: ["chore:", "refactor:", "feat:", "docs:", "ci:", "Update", "Refactor", "Rename"],
    deprecated: [],
    removed: ["revert:", "Remove"],
    fixed: ["fix:", "perf:", "Fix", "Make up", "Restore"],
    security: []
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
