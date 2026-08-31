<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $documentation['title'] }}</title>
    <style>
        :root {
            color-scheme: light;
            --bg: #f6f8fb;
            --panel: #ffffff;
            --ink: #17202a;
            --muted: #5f6f83;
            --line: #d8e0ea;
            --accent: #0f766e;
            --accent-soft: #d9f4ef;
            --code-bg: #111827;
            --code-ink: #e5e7eb;
            --warning: #8a4b05;
            --warning-bg: #fff3d6;
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            background: var(--bg);
            color: var(--ink);
            font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            line-height: 1.55;
        }

        header {
            border-bottom: 1px solid var(--line);
            background: var(--panel);
        }

        .header-inner,
        main {
            width: min(1120px, calc(100% - 32px));
            margin: 0 auto;
        }

        .header-inner {
            padding: 28px 0;
        }

        h1,
        h2,
        h3 {
            margin: 0;
            line-height: 1.2;
        }

        h1 {
            font-size: clamp(2rem, 5vw, 3.25rem);
        }

        h2 {
            font-size: 1.45rem;
            margin-bottom: 14px;
        }

        h3 {
            font-size: 1.05rem;
        }

        p {
            margin: 8px 0 0;
            color: var(--muted);
        }

        main {
            padding: 28px 0 56px;
            display: grid;
            grid-template-columns: 260px minmax(0, 1fr);
            gap: 24px;
            align-items: start;
        }

        nav,
        section,
        article {
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 8px;
        }

        nav {
            position: sticky;
            top: 20px;
            padding: 18px;
        }

        nav a {
            display: block;
            color: var(--ink);
            text-decoration: none;
            padding: 8px 0;
            font-weight: 650;
        }

        nav a:hover {
            color: var(--accent);
        }

        .content {
            display: grid;
            gap: 18px;
        }

        section {
            padding: 22px;
        }

        article {
            padding: 18px;
            margin-top: 14px;
        }

        .meta {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 16px;
        }

        .pill {
            display: inline-flex;
            align-items: center;
            min-height: 30px;
            border-radius: 999px;
            padding: 5px 10px;
            background: var(--accent-soft);
            color: #07534d;
            font-size: .88rem;
            font-weight: 700;
        }

        .pill.neutral {
            background: #e9eef5;
            color: #344256;
        }

        .pill.warning {
            background: var(--warning-bg);
            color: var(--warning);
        }

        .endpoint-title {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            align-items: center;
        }

        .method {
            min-width: 64px;
            text-align: center;
            border-radius: 6px;
            padding: 5px 8px;
            background: #183a5a;
            color: white;
            font-size: .82rem;
            font-weight: 800;
        }

        .path {
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
            overflow-wrap: anywhere;
        }

        .block {
            margin-top: 14px;
        }

        .block-title {
            margin: 0 0 8px;
            color: var(--ink);
            font-weight: 800;
        }

        pre {
            margin: 0;
            padding: 14px;
            overflow: auto;
            background: var(--code-bg);
            color: var(--code-ink);
            border-radius: 8px;
            font-size: .9rem;
            line-height: 1.55;
        }

        code {
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
        }

        ol {
            margin: 10px 0 0;
            padding-left: 20px;
        }

        .language {
            color: var(--muted);
            font-size: .85rem;
            font-weight: 700;
            text-transform: uppercase;
        }

        li + li {
            margin-top: 6px;
        }

        @media (max-width: 820px) {
            main {
                grid-template-columns: 1fr;
            }

            nav {
                position: static;
            }
        }
    </style>
</head>
<body>
    <header>
        <div class="header-inner">
            <h1>{{ $documentation['title'] }}</h1>
            <p>Base URL: <code>{{ $documentation['base_url'] }}</code></p>
            <div class="meta">
                <span class="pill">Version {{ $documentation['version'] }}</span>
                <span class="pill neutral">{{ $documentation['authentication_type'] }}</span>
            </div>
        </div>
    </header>

    <main>
        <nav aria-label="Modules de documentation">
            <strong>Modules</strong>
            @foreach ($documentation['modules'] as $module)
                <a href="#{{ $module['slug'] }}">{{ $module['name'] }}</a>
            @endforeach
            <a href="#flutter">Exemples Flutter</a>
        </nav>

        <div class="content">
            <section>
                <h2>Headers importants</h2>
                <pre><code>{{ json_encode($documentation['important_headers'], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) }}</code></pre>
            </section>

            <section>
                <h2>Etapes cote frontend</h2>
                <ol>
                    @foreach ($documentation['frontend_steps'] as $step)
                        <li>{{ $step }}</li>
                    @endforeach
                </ol>
            </section>

            @foreach ($documentation['modules'] as $module)
                <section id="{{ $module['slug'] }}">
                    <h2>{{ $module['name'] }}</h2>
                    <p>{{ $module['description'] }}</p>

                    @foreach ($module['endpoints'] as $endpoint)
                        <article>
                            <div class="endpoint-title">
                                <span class="method">{{ $endpoint['method'] }}</span>
                                <h3>{{ $endpoint['name'] }}</h3>
                                <span class="path">{{ $endpoint['path'] }}</span>
                                <span class="pill {{ $endpoint['protected'] ? 'warning' : 'neutral' }}">
                                    {{ $endpoint['protected'] ? 'Token requis' : 'Public' }}
                                </span>
                            </div>

                            <p>{{ $endpoint['description'] }}</p>

                            <div class="block">
                                <div class="block-title">Headers</div>
                                <pre><code>{{ json_encode($endpoint['headers'], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) }}</code></pre>
                            </div>

                            <div class="block">
                                <div class="block-title">Body a envoyer</div>
                                <pre><code>{{ $endpoint['request_body'] === null ? 'Aucun body' : json_encode($endpoint['request_body'], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) }}</code></pre>
                            </div>

                            @foreach ($endpoint['responses'] as $response)
                                <div class="block">
                                    <div class="block-title">Reponse {{ $response['status'] }} - {{ $response['title'] }}</div>
                                    <pre><code>{{ json_encode($response['body'], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) }}</code></pre>
                                </div>
                            @endforeach
                        </article>
                    @endforeach
                </section>
            @endforeach

            <section id="flutter">
                <h2>Exemples Flutter</h2>
                <p>Ces exemples montrent comment une app Flutter peut appeler le backend, recuperer le token Sanctum et l'utiliser sur les routes protegees.</p>

                @foreach ($documentation['flutter_examples'] as $example)
                    <article>
                        <div class="endpoint-title">
                            <h3>{{ $example['title'] }}</h3>
                            <span class="language">{{ $example['language'] }}</span>
                        </div>
                        <div class="block">
                            <pre><code>{{ $example['code'] }}</code></pre>
                        </div>
                    </article>
                @endforeach
            </section>
        </div>
    </main>
</body>
</html>
