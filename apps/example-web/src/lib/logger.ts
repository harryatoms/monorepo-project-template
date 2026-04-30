/**
 * Structured browser logger.
 *
 * Mirrors the event/attribute convention used by the backend StructLogger:
 *   logger.emit("api.sample_resource.request.completed", { latency_ms: 42 })
 */

type Level = 'debug' | 'info' | 'warning' | 'error';
type Attributes = Record<string, unknown>;

interface LogEntry {
	timestamp: string;
	level: Level;
	event: string;
	service: string;
	attributes: Attributes;
}

const SERVICE = 'example-web';

const LEVEL_STYLES: Record<Level, string> = {
	debug: 'color: #8b91a8',
	info: 'color: #6c7fff; font-weight: bold',
	warning: 'color: #fbbf24; font-weight: bold',
	error: 'color: #f87171; font-weight: bold',
};

function buildEntry(level: Level, event: string, attrs: Attributes): LogEntry {
	return {
		timestamp: new Date().toISOString(),
		level,
		event,
		service: SERVICE,
		attributes: attrs,
	};
}

function writeConsole(entry: LogEntry): void {
	if (import.meta.env.DEV) {
		const attrStr =
			Object.keys(entry.attributes).length > 0
				? ' ' + JSON.stringify(entry.attributes)
				: '';
		console.log(
			`%c[${entry.level.toUpperCase()}] ${entry.event}${attrStr}`,
			LEVEL_STYLES[entry.level],
		);
	} else {
		const fn = entry.level === 'error' ? console.error : console.log;
		fn(JSON.stringify(entry));
	}
}

function emit(event: string, attrs?: Attributes, level: Level = 'info'): void {
	const entry = buildEntry(level, event, attrs ?? {});
	writeConsole(entry);
}

export const logger = {
	emit,
	debug: (event: string, attrs?: Attributes) => emit(event, attrs, 'debug'),
	info: (event: string, attrs?: Attributes) => emit(event, attrs, 'info'),
	warning: (event: string, attrs?: Attributes) => emit(event, attrs, 'warning'),
	error: (event: string, attrs?: Attributes) => emit(event, attrs, 'error'),
};
