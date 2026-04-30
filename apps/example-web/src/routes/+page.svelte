<script lang="ts">
	import { ApiRequestError, fetchHealth, fetchRootMetadata, fetchSampleResource } from '$lib/api';
	import { logger } from '$lib/logger';
	import type { HealthResponse, RootMetadataResponse, SampleResourceResponse } from '$lib/types';

	let loading = $state(false);
	let rootMetadata = $state<RootMetadataResponse | null>(null);
	let health = $state<HealthResponse | null>(null);
	let sampleResource = $state<SampleResourceResponse | null>(null);
	let errorMessage = $state<string | null>(null);

	async function loadDemoData() {
		loading = true;
		errorMessage = null;

		try {
			[rootMetadata, health, sampleResource] = await Promise.all([
				fetchRootMetadata(),
				fetchHealth(),
				fetchSampleResource(),
			]);
		} catch (err) {
			if (err instanceof ApiRequestError) {
				errorMessage = err.message;
			} else {
				logger.error('api.demo.unexpected_error', {
					error_type: err instanceof Error ? err.constructor.name : 'unknown',
				});
				errorMessage = 'Unable to load the API demo data.';
			}
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Example Monorepo</title>
</svelte:head>

<div class="page">
	<section class="hero">
		<p class="eyebrow">Full-stack starter</p>
		<h1 class="page-title">Build from a clean monorepo boilerplate.</h1>
		<p class="page-subtitle">
			This demo keeps the app thin and shows the contract between a SvelteKit
			frontend and a FastAPI backend through health and sample-resource endpoints.
		</p>
		<button class="primary-button" type="button" onclick={loadDemoData} disabled={loading}>
			{loading ? 'Loading API data...' : 'Load API Demo Data'}
		</button>
	</section>

	{#if errorMessage}
		<div class="error-banner" role="alert">{errorMessage}</div>
	{/if}

	<div class="card-grid">
		<section class="card">
			<div class="card-label">API Metadata</div>
			{#if rootMetadata}
				<dl class="data-list">
					<div><dt>Service</dt><dd>{rootMetadata.service}</dd></div>
					<div><dt>Version</dt><dd>{rootMetadata.version}</dd></div>
				</dl>
			{:else}
				<p class="muted">Load the demo to fetch root metadata from the API.</p>
			{/if}
		</section>

		<section class="card">
			<div class="card-label">Health</div>
			{#if health}
				<div class="status-row">
					<span class="status-pill">{health.status}</span>
					<span class="muted">build {health.version}</span>
				</div>
			{:else}
				<p class="muted">The health endpoint is ready to check service availability.</p>
			{/if}
		</section>
	</div>

	<section class="card sample-card">
		<div class="card-label">Sample Resource</div>
		{#if sampleResource}
			<h2>{sampleResource.name}</h2>
			<p>{sampleResource.description}</p>
			<div class="tag-row">
				{#each sampleResource.tags as tag}
					<span class="tag">{tag}</span>
				{/each}
			</div>
			<pre>{JSON.stringify(sampleResource, null, 2)}</pre>
		{:else}
			<p class="muted">`GET /sample-resource` returns deterministic structured data.</p>
		{/if}
	</section>
</div>
