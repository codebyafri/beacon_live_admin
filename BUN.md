# Bun tooling in this fork

This branch starts at Beacon LiveAdmin v0.4.3. Use Bun 1.4.1 for JavaScript installation, build scripts, formatting and browser-test commands. Both the root and assets directories have committed `bun.lock` files. Existing npm lockfiles remain historical upstream files and are not used by these commands.

The asset package reads Phoenix and LiveSvelte JavaScript from Mix dependencies under `deps`. Resolve the host's pinned Mix dependencies first. This branch's application integration is verified with Phoenix 1.8.14, LiveView 1.2.11 and LiveSvelte 0.18.0; the historical standalone Mix lock remains separate. Revalidate JavaScript/Elixir compatibility when changing those versions.

`bun build.js --deploy` in `assets` builds both controller-served JavaScript variants and the optional SSR artifact. Building the SSR artifact does not execute a Node server. Consumers that do not need SSR set `config :live_svelte, ssr: false` and do not start `NodeJS.Supervisor`.

The lock updates compatible JavaScript dependencies, including Svelte/PostCSS fixes. `@tailwindcss/forms` is declared explicitly so Bun's Tailwind CLI can load the existing config. Prebuilt controller assets are regenerated with this dependency set.

This is an integration fork, not a claim of complete compatibility across all host versions. The optional Vue compiler advisory in Phoenix's documentation tooling remains outside the runtime bundle; review dependency advisories before releasing a consuming application.
