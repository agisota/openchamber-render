import type { Session } from '@opencode-ai/sdk/v2';

export type SessionMetadataRecord = Record<string, unknown>;

type RoxSpaceMetadata = {
  kind?: 'review';
  originalSessionID?: string;
  reviewSessionID?: string;
};

const isRecord = (value: unknown): value is Record<string, unknown> =>
  Boolean(value && typeof value === 'object' && !Array.isArray(value));

export const getSessionMetadata = (session: Session | null | undefined): SessionMetadataRecord => {
  const metadata = (session as (Session & { metadata?: unknown }) | null | undefined)?.metadata;
  return isRecord(metadata) ? metadata : {};
};

const getRoxSpaceMetadata = (metadata: SessionMetadataRecord): RoxSpaceMetadata => {
  const value = metadata.openchamber;
  return isRecord(value) ? value as RoxSpaceMetadata : {};
};

export const getReviewSessionID = (session: Session | null | undefined): string | null => {
  const value = getRoxSpaceMetadata(getSessionMetadata(session)).reviewSessionID;
  return typeof value === 'string' && value.trim().length > 0 ? value : null;
};

export const getOriginalSessionID = (session: Session | null | undefined): string | null => {
  const value = getRoxSpaceMetadata(getSessionMetadata(session)).originalSessionID;
  return typeof value === 'string' && value.trim().length > 0 ? value : null;
};

export const isReviewSession = (session: Session | null | undefined): boolean =>
  getRoxSpaceMetadata(getSessionMetadata(session)).kind === 'review' && Boolean(getOriginalSessionID(session));

export const withReviewSessionLink = (
  metadata: SessionMetadataRecord,
  reviewSessionID: string,
): SessionMetadataRecord => {
  const current = getRoxSpaceMetadata(metadata);
  return {
    ...metadata,
    openchamber: {
      ...current,
      reviewSessionID,
    },
  };
};

export const withReviewSessionMarker = (
  metadata: SessionMetadataRecord,
  originalSessionID: string,
): SessionMetadataRecord => {
  const current = getRoxSpaceMetadata(metadata);
  return {
    ...metadata,
    openchamber: {
      ...current,
      kind: 'review' as const,
      originalSessionID,
    },
  };
};

export const withoutReviewSessionLink = (
  metadata: SessionMetadataRecord,
  reviewSessionID: string,
): SessionMetadataRecord => {
  const current = getRoxSpaceMetadata(metadata);
  if (current.reviewSessionID !== reviewSessionID) return metadata;

  const restRoxSpace = { ...current };
  delete restRoxSpace.reviewSessionID;
  const next: SessionMetadataRecord = { ...metadata };
  if (Object.keys(restRoxSpace).length > 0) {
    next.openchamber = restRoxSpace;
  } else {
    delete next.openchamber;
  }
  return next;
};
