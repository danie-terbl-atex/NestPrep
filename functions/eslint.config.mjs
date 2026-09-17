import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';

export default defineConfig(
  { ignores: ['lib/**', 'node_modules/**'] },
  tseslint.configs.strictTypeChecked,
  // Plain Node scripts are not part of the TypeScript program, so the
  // type-aware rules have no types to work from. They are still linted for
  // everything that does not need them (ENG-16).
  {
    files: ['tools/**/*.mjs'],
    extends: [tseslint.configs.disableTypeChecked],
    languageOptions: { parserOptions: { projectService: false } },
    rules: { '@typescript-eslint/explicit-function-return-type': 'off' },
  },
  {
    files: ['src/**/*.ts', 'test/**/*.ts', '*.ts', '*.mjs'],
    ignores: ['tools/**'],
    languageOptions: {
      parserOptions: {
        projectService: { allowDefaultProject: ['eslint.config.mjs'] },
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/explicit-function-return-type': 'error',
    },
  },
);
