export interface HealthResponse {
	status: string;
	version: string;
}

export interface SampleResourceResponse {
	id: string;
	name: string;
	description: string;
	tags: string[];
}

export interface RootMetadataResponse {
	service: string;
	version: string;
}

export interface ApiError {
	error: {
		code: string;
		message: string;
	};
	request_id: string;
}
