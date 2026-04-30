<script lang="ts">
	import '../app.css';
	import type { Snippet } from 'svelte';

	let { children }: { children: Snippet } = $props();
</script>

<div class="layout">
	<header class="site-header">
		<div class="header-inner">
			<div class="logo">
				<span class="logo-icon">◈</span>
				<span class="logo-text">Example Monorepo</span>
			</div>
			<p class="tagline">Reusable full-stack boilerplate</p>
		</div>
	</header>

	<main class="main-content">
		{@render children()}
	</main>

	<footer class="site-footer">
		<p>Example Monorepo Boilerplate</p>
	</footer>
</div>

<style>
	.layout {
		display: flex;
		flex-direction: column;
		min-height: 100vh;
	}

	.site-header {
		border-bottom: 1px solid var(--color-border);
		background-color: var(--color-surface);
	}

	.header-inner {
		max-width: 860px;
		margin: 0 auto;
		padding: 20px 24px;
		display: flex;
		align-items: center;
		gap: 20px;
		flex-wrap: wrap;
	}

	.logo {
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.logo-icon {
		font-size: 20px;
		color: var(--color-accent);
	}

	.logo-text {
		font-size: 18px;
		font-weight: 700;
		color: var(--color-text-primary);
		letter-spacing: -0.02em;
	}

	.tagline {
		font-size: 13px;
		color: var(--color-text-muted);
		border-left: 1px solid var(--color-border);
		padding-left: 20px;
	}

	.main-content {
		flex: 1;
		max-width: 860px;
		width: 100%;
		margin: 0 auto;
		padding: 40px 24px;
	}

	.site-footer {
		border-top: 1px solid var(--color-border);
		padding: 20px 24px;
		text-align: center;
		font-size: 13px;
		color: var(--color-text-muted);
	}

	@media (max-width: 600px) {
		.header-inner {
			padding: 16px;
			gap: 12px;
		}

		.tagline {
			border-left: none;
			padding-left: 0;
		}

		.main-content {
			padding: 24px 16px;
		}
	}
</style>
