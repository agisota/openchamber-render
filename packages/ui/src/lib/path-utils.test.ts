import { describe, expect, test } from 'bun:test';

import {
  getDirectoryForFilePath,
  getRelativeFilePath,
  isAbsoluteFilePath,
  isFilePathWithinDirectory,
  normalizeFilePath,
  toAbsoluteFilePath,
} from './path-utils';

describe('path-utils', () => {
  test('normalizes Windows paths without losing drive roots', () => {
    expect(normalizeFilePath('C:\\Users\\Rox Operator\\projects\\rox-space\\')).toBe('C:/Users/Rox Operator/projects/rox-space');
    expect(normalizeFilePath('C:/')).toBe('C:/');
    expect(normalizeFilePath('\\\\server\\share\\project')).toBe('//server/share/project');
  });

  test('recognizes Windows absolute paths', () => {
    expect(isAbsoluteFilePath('C:/Users/file.ts')).toBe(true);
    expect(isAbsoluteFilePath('C:\\Users\\file.ts')).toBe(true);
    expect(isAbsoluteFilePath('C:relative/file.ts')).toBe(false);
    expect(isAbsoluteFilePath('src/file.ts')).toBe(false);
  });

  test('does not prefix Windows absolute targets with the workspace directory', () => {
    expect(toAbsoluteFilePath('C:/Users/Rox Operator/projects/rox-space', 'C:/Users/Rox Operator/projects/rox-space/packages/ui/Button.tsx')).toBe(
      'C:/Users/Rox Operator/projects/rox-space/packages/ui/Button.tsx',
    );
  });

  test('joins relative targets under Windows workspaces', () => {
    expect(toAbsoluteFilePath('C:/Users/Rox Operator/projects/rox-space', 'packages/ui/Button.tsx')).toBe(
      'C:/Users/Rox Operator/projects/rox-space/packages/ui/Button.tsx',
    );
    expect(toAbsoluteFilePath('C:/Users/Rox Operator/projects/rox-space/packages/ui', '../web/package.json')).toBe(
      'C:/Users/Rox Operator/projects/rox-space/packages/web/package.json',
    );
  });

  test('compares Windows workspace containment case-insensitively', () => {
    expect(isFilePathWithinDirectory(
      'c:/users/rox operator/projects/rox-space/packages/ui/button.tsx',
      'C:/Users/Rox Operator/projects/rox-space',
    )).toBe(true);
    expect(getRelativeFilePath(
      'C:/Users/Rox Operator/projects/rox-space/packages/ui/Button.tsx',
      'c:/users/rox operator/projects/rox-space',
    )).toBe('packages/ui/Button.tsx');
  });

  test('falls back to file parent when current directory does not contain the path', () => {
    expect(getDirectoryForFilePath(
      'C:/Users/Rox Operator/projects/other',
      'C:/Users/Rox Operator/projects/rox-space/packages/ui/Button.tsx',
    )).toBe('C:/Users/Rox Operator/projects/rox-space/packages/ui');
    expect(getDirectoryForFilePath('', '/tmp/file.txt')).toBe('/tmp');
  });
});
