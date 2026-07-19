# Contributing

1. Keep installation scripts idempotent.
2. Never overwrite a real user file or directory with a symbolic link.
3. Do not commit Vortex binaries or Nexus authentication data.
4. Run `make test` and `make lint` before opening a pull request.
5. Pin catalog installers to immutable OpenModLinux tags and stable official
   Vortex release URLs.
6. Include the distribution, Lutris package type, Wine runner, desktop session,
   GPU and relevant log excerpts in bug reports.
