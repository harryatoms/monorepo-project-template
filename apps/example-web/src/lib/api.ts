import { env } from '$env/dynamic/public';
import { logger } from './logger';
import type { HealthResponse, RootMetadataResponse, SampleResourceResponse } from './types';

const API_URL = env.PUBLIC_API_URL ?? 'http://localhost:8000';

export class ApiRequestError extends Error {
	constructor(
		message: string,
		public readonly code: string,
		public readonly status: number,
	) {
		super(message);
		this.name = 'ApiRequestError';
	}
}

async function getJson<T>(path: string, eventPrefix: string): Promise<T> {
	const start = performance.now();
	logger.emit(`${eventPrefix}.started`);

	const response = await fetch(`${API_URL}${path}`);
	const latency_ms = Math.round(performance.now() - start);

	if (!response.ok) {
		let code = 'request_failed';
		let message = `Request failed with status ${response.status}`;

		try {
			const body = await response.json();
			code = body?.error?.code ?? code;
			message = body?.error?.message ?? message;
		} catch {
			// Non-JSON error body; use defaults.
		}

		logger.emit(`${eventPrefix}.failed`, {
			status: response.status,
			error_code: code,
			latency_ms,
		});

		throw new ApiRequestError(message, code, response.status);
	}

	const data: T = await response.json();
	logger.emit(`${eventPrefix}.completed`, { latency_ms });
	return data;
}

export function fetchRootMetadata(): Promise<RootMetadataResponse> {
	return getJson<RootMetadataResponse>('/', 'api.root.request');
}

export function fetchHealth(): Promise<HealthResponse> {
	return getJson<HealthResponse>('/health', 'api.health.request');
}

export function fetchSampleResource(): Promise<SampleResourceResponse> {
	return getJson<SampleResourceResponse>(
		'/sample-resource',
		'api.sample_resource.request',
	);
}
